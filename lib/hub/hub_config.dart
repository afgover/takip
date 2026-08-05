import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hub_connections.dart';

/// Tek bir hub bağlantısı: repo + o repoya erişen token.
/// Token yalnızca secure storage'da durur (R-002: sadece hub'a scope'lu PAT).
///
/// T-003'ten beri uygulama birden çok bağlantı tutabiliyor; bu tip **bir**
/// bağlantıyı temsil eder, listesi [HubConnectionsState]'tedir.
class HubConfig {
  const HubConfig({
    required this.owner,
    required this.repo,
    required this.token,
    this.label,
    this.login,
  });

  factory HubConfig.fromJson(Map<String, dynamic> json) => HubConfig(
        owner: json['owner'] as String,
        repo: json['repo'] as String,
        token: json['token'] as String,
        label: json['label'] as String?,
        login: json['login'] as String?,
      );

  final String owner;
  final String repo;
  final String token;

  /// Kullanıcının verdiği ad. Boşsa listede [slug] gösterilir.
  final String? label;

  /// Token'ın sahibi olan GitHub hesabı (sözleşme 1.15, çoklu kullanıcı).
  ///
  /// Kayıtlara `author:` olarak yazılır; "bu görevi kim açtı" sorusunun cevabı
  /// budur. `created_by` bunun yerine geçmez — o bir **rol** (`user`/`agent`),
  /// kimlik değil.
  ///
  /// **Null olabilir ve bu bir hata değildir:** onboarding'de tek seferlik bir
  /// istekle okunur, istek başarısız olursa bağlantı yine kurulur ve kayıtlar
  /// `author` alanı olmadan yazılır — yani tek kullanıcılı dönemdeki hâl.
  /// Kimliği zorunlu kılmak, çalışan bir bağlantıyı reddetmek olurdu (B-092'de
  /// verilen kararla aynı çizgi).
  final String? login;

  String get slug => '$owner/$repo';

  /// Listede ve repo seçicide görünen ad.
  String get displayName =>
      (label != null && label!.trim().isNotEmpty) ? label!.trim() : slug;

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'repo': repo,
        'token': token,
        if (label != null) 'label': label,
        if (login != null) 'login': login,
      };

  HubConfig copyWith({String? token, String? label, String? login}) =>
      HubConfig(
        owner: owner,
        repo: repo,
        token: token ?? this.token,
        label: label ?? this.label,
        login: login ?? this.login,
      );

  /// Kullanıcının yazdığı repo alanını ayrıştırır. `owner/ad` beklenir ama
  /// adres çubuğundan kopyalanan tam URL de kabul edilir (yaygın davranış).
  /// Biçim tutmuyorsa null.
  static ({String owner, String repo})? parseRepo(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;

    s = s.replaceFirst(
      RegExp(r'^(https?://)?(www\.)?github\.com/', caseSensitive: false),
      '',
    );
    s = s.replaceFirst(RegExp(r'\.git$'), '');
    s = s.replaceAll(RegExp(r'^/+|/+$'), '');

    final parts = s.split('/');
    if (parts.length != 2) return null;

    final owner = parts[0].trim();
    final repo = parts[1].trim();
    if (!_segment.hasMatch(owner) || !_segment.hasMatch(repo)) return null;
    return (owner: owner, repo: repo);
  }

  static final _segment = RegExp(r'^[A-Za-z0-9._-]+$');
}

/// **Aktif** hub bağlantısı; null → onboarding gösterilir.
///
/// Uygulamanın geri kalanı (istemci, Contents/Commits/Trees API'leri, yoklama,
/// görev deposu) yalnızca bu provider'ı tanır ve "o an hangi repodayız"
/// sorusunu buradan sorar. Çoklu repo desteği (T-003) bu darboğazın **altına**
/// bir katman olarak girdi: liste [hubConnectionsProvider]'da tutulur, burası
/// onun aktif elemanını yayınlar. Böylece repo değiştirmek, uygulamanın geri
/// kalanı için token değiştirmekten farksız hâle geldi.
final hubConfigProvider =
    AsyncNotifierProvider<HubConfigNotifier, HubConfig?>(HubConfigNotifier.new);

class HubConfigNotifier extends AsyncNotifier<HubConfig?> {
  @override
  Future<HubConfig?> build() async {
    final connections = await ref.watch(hubConnectionsProvider.future);
    return connections.active;
  }

  /// Bağlantıyı kaydeder ve aktif yapar. Aynı repo zaten kayıtlıysa üstüne
  /// yazar (kopya bağlantı oluşmaz).
  ///
  /// Çağıranlar (onboarding, bağlantı ekranı) burayı **yalnızca doğrulama
  /// geçtikten sonra** çağırır (B-022).
  Future<void> save(HubConfig config) =>
      ref.read(hubConnectionsProvider.notifier).upsertAndActivate(config);

  /// Tüm bağlantıları ve token'ları siler → onboarding.
  Future<void> clear() =>
      ref.read(hubConnectionsProvider.notifier).removeAll();
}

/// Belirli bir repoya yazarken kullanılacak kimlik (sözleşme 1.15).
///
/// Token isteğin gittiği repoya göre seçiliyordu (L-019); `author` da aynı
/// mantıkla seçilmeli, yoksa A reposuna yazılan kayda B bağlantısının sahibi
/// yazılır. Bilinmiyorsa null — kayıt `author` alanı olmadan gider.
final loginForRepoProvider = Provider.family<String?, String?>((ref, slug) {
  final connections = ref.watch(hubConnectionsProvider).valueOrNull;
  final match = slug == null ? null : connections?.bySlug(slug);
  return (match ?? ref.watch(hubConfigProvider).value)?.login;
});
