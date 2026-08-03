import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../github/commits_api.dart';
import 'hub_config.dart';
import 'hub_connections.dart';
import 'settings.dart';

/// Yoklamanın o anki durumu. Ekranlar [headSha]'yı izler: değeri değiştiğinde
/// hub'da bir şey değişmiş demektir, veriyi yeniden çekerler.
class HubStatus {
  const HubStatus({
    this.headSha,
    this.heads = const {},
    this.changedSlugs = const {},
    this.lastCheckedAt,
    this.lastChangedAt,
    this.error,
    this.checking = false,
    this.watching = false,
  });

  /// **Aktif** reponun son görülen commit sha'sı ("3 dakika önce güncellendi"
  /// göstergesi bunu anlatır).
  final String? headSha;

  /// slug → son görülen commit sha'sı, **bütün bağlantılar için**.
  ///
  /// Senkron baştan beri tüm repoları indiriyordu ama tetikleyicisi yalnız
  /// aktif repoydu; aktif olmayan bir repoya yapılan push hiçbir sinyal
  /// üretmiyor ve uygulamada hiç görünmüyordu (L-034).
  final Map<String, String> heads;

  /// Son yoklamada başı değişen repolar. Senkron bunu izler.
  final Set<String> changedSlugs;
  final DateTime? lastCheckedAt;

  /// [headSha]'nın en son değiştiği an — "3 dakika önce güncellendi" için.
  final DateTime? lastChangedAt;

  /// Son yoklamanın hatası; başarılı yoklamada temizlenir.
  final HubError? error;

  final bool checking;

  /// Zamanlayıcı çalışıyor mu (uygulama ön planda mı).
  final bool watching;

  HubStatus copyWith({
    String? headSha,
    Map<String, String>? heads,
    Set<String>? changedSlugs,
    DateTime? lastCheckedAt,
    DateTime? lastChangedAt,
    HubError? error,
    bool clearError = false,
    bool? checking,
    bool? watching,
  }) =>
      HubStatus(
        headSha: headSha ?? this.headSha,
        heads: heads ?? this.heads,
        changedSlugs: changedSlugs ?? this.changedSlugs,
        lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
        lastChangedAt: lastChangedAt ?? this.lastChangedAt,
        error: clearError ? null : (error ?? this.error),
        checking: checking ?? this.checking,
        watching: watching ?? this.watching,
      );
}

/// Yoklama aralığı — ayarlardan değiştirilebilir (B-051).
final pollIntervalProvider = Provider<Duration>(
  (ref) => ref.watch(appSettingsProvider).pollInterval,
);

/// Hub'ı ön planda yoklayan servis (B-024).
///
/// Değişiklik sinyali olarak reponun son commit'i kullanılır: klasör klasör
/// tarama yerine tek istek. ETag katmanı sayesinde değişiklik yokken yanıt
/// 304'tür ve istek limitinden düşmez (SK-002), yani 45 saniyelik yoklama
/// pratikte bedavadır.
///
/// Ön plan/arka plan geçişini bu sınıf bilmez; [start] ve [stop] dışarıdan
/// çağrılır (`features/common/hub_watcher_scope.dart`) — hub katmanı UI'yi
/// bilmez ilkesi korunur.
class HubWatcher extends Notifier<HubStatus> {
  Timer? _timer;
  bool _inFlight = false;
  String? _configSlug;

  /// Rate limit yendiğinde bu ana kadar istek atılmaz.
  DateTime? _pausedUntil;

  @override
  HubStatus build() {
    // Kullanıcı aralığı değiştirince yeni değer bir sonraki açılışa kalmasın.
    ref.listen<Duration>(pollIntervalProvider, (previous, next) {
      if (previous == next || _timer == null) return;
      _cancelTimer();
      _timer = Timer.periodic(next, (_) => checkNow());
    });

    ref.onDispose(_cancelTimer);
    return const HubStatus();
  }

  void start() {
    if (_timer != null) return;
    final interval = ref.read(pollIntervalProvider);
    _timer = Timer.periodic(interval, (_) => checkNow());
    state = state.copyWith(watching: true);
    unawaited(checkNow());
  }

  void stop() {
    _cancelTimer();
    state = state.copyWith(watching: false, checking: false);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Tek yoklama. Kullanıcı "aşağı çekip yenile" yaptığında da çağrılır.
  ///
  /// **Bütün bağlantılar** yoklanır, yalnız aktif olan değil. Maliyeti düşük:
  /// değişiklik yokken yanıt ETag sayesinde 304 ve istek limitinden düşmüyor
  /// (SK-002). Aktif repoyla sınırlı olduğu sürece başka bir repoya yapılan
  /// push uygulamada hiç görünmüyordu (L-034).
  Future<void> checkNow() async {
    if (_inFlight) return; // yavaş ağda istekler üst üste binmesin

    final config = ref.read(hubConfigProvider).value;
    if (config == null) return;

    final now = clock.now();
    if (_pausedUntil != null && now.isBefore(_pausedUntil!)) return;
    _pausedUntil = null;

    // Repo değiştiyse **aktif** repoyu anlatan alanlar sıfırlanır; diğer
    // repoların bilinen başları korunur, onlar repo değişiminden etkilenmez.
    if (_configSlug != config.slug) {
      _configSlug = config.slug;
      state = HubStatus(
        heads: state.heads,
        watching: state.watching,
      );
    }

    final connections =
        ref.read(hubConnectionsProvider).valueOrNull?.connections ??
            <HubConfig>[config];

    _inFlight = true;
    state = state.copyWith(checking: true);
    try {
      final heads = {...state.heads};
      final changed = <String>{};
      HubError? firstError;

      for (final connection in connections) {
        try {
          final sha = await ref
              .read(commitsApiForSlugProvider(connection.slug))
              .headSha();
          if (sha == null) continue;
          if (heads[connection.slug] != sha) changed.add(connection.slug);
          heads[connection.slug] = sha;
        } on HubError catch (e) {
          // Bir repo okunamazsa (token kapsamıyor) diğerleri yoklanmaya devam
          // etsin; hata yalnız aktif repodan geliyorsa kullanıcıya gösterilir.
          if (connection.slug == config.slug) firstError = e;
        }
      }

      if (firstError != null) throw firstError;

      state = state.copyWith(
        headSha: heads[config.slug],
        heads: heads,
        changedSlugs: changed,
        lastCheckedAt: clock.now(),
        lastChangedAt: changed.contains(config.slug) ? clock.now() : null,
        checking: false,
        clearError: true,
      );
    } on HubError catch (e) {
      // Token geçersizse yoklamayı sürdürmenin anlamı yok; kullanıcı
      // ayarlardan düzeltince yeniden başlatılır.
      if (e is HubAuthError) _cancelTimer();
      if (e is HubRateLimitError) _pausedUntil = e.resetAt;

      state = state.copyWith(
        error: e,
        checking: false,
        lastCheckedAt: clock.now(),
        watching: e is HubAuthError ? false : null,
      );
    } finally {
      _inFlight = false;
    }
  }
}

final hubWatcherProvider =
    NotifierProvider<HubWatcher, HubStatus>(HubWatcher.new);
