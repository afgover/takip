import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../github/commits_api.dart';
import 'hub_config.dart';
import 'settings.dart';

/// Yoklamanın o anki durumu. Ekranlar [headSha]'yı izler: değeri değiştiğinde
/// hub'da bir şey değişmiş demektir, veriyi yeniden çekerler.
class HubStatus {
  const HubStatus({
    this.headSha,
    this.lastCheckedAt,
    this.lastChangedAt,
    this.error,
    this.checking = false,
    this.watching = false,
  });

  /// Son görülen commit sha'sı (hub'ın "sürümü").
  final String? headSha;
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
    DateTime? lastCheckedAt,
    DateTime? lastChangedAt,
    HubError? error,
    bool clearError = false,
    bool? checking,
    bool? watching,
  }) =>
      HubStatus(
        headSha: headSha ?? this.headSha,
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
  Future<void> checkNow() async {
    if (_inFlight) return; // yavaş ağda istekler üst üste binmesin

    final config = ref.read(hubConfigProvider).value;
    if (config == null) return;

    final now = clock.now();
    if (_pausedUntil != null && now.isBefore(_pausedUntil!)) return;
    _pausedUntil = null;

    // Repo değiştiyse önceki hub'ın sürümü ile karşılaştırmak anlamsız.
    if (_configSlug != config.slug) {
      _configSlug = config.slug;
      state = const HubStatus().copyWith(watching: state.watching);
    }

    _inFlight = true;
    state = state.copyWith(checking: true);
    try {
      final sha = await ref.read(commitsApiProvider).headSha();
      final changed = sha != null && sha != state.headSha;

      state = state.copyWith(
        headSha: sha,
        lastCheckedAt: clock.now(),
        lastChangedAt: changed ? clock.now() : null,
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
