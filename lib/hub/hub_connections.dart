import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'hub_config.dart';

/// Cihazda kayıtlı hub bağlantıları ve hangisinin aktif olduğu (T-003).
///
/// Sıra kullanıcının eklediği sıradır; repo seçicide de böyle görünür.
class HubConnectionsState {
  const HubConnectionsState({this.connections = const [], this.activeSlug});

  final List<HubConfig> connections;
  final String? activeSlug;

  /// Aktif bağlantı — liste boşsa null (onboarding gösterilir).
  ///
  /// Aktif kayıt silinmişse ya da hiç seçilmemişse **ilk bağlantıya düşer**:
  /// elde çalışan bir bağlantı varken kullanıcıyı onboarding'e atmak, hiçbir
  /// şey kaybetmemişken her şeyi kaybetmiş gibi hissettirir.
  HubConfig? get active {
    if (connections.isEmpty) return null;
    for (final c in connections) {
      if (c.slug == activeSlug) return c;
    }
    return connections.first;
  }

  bool get isEmpty => connections.isEmpty;
  int get length => connections.length;

  HubConfig? bySlug(String slug) {
    for (final c in connections) {
      if (c.slug == slug) return c;
    }
    return null;
  }
}

/// Bağlantı listesinin kalıcı deposu. Token içerdiği için **tamamı** secure
/// storage'da durur (R-005); `shared_preferences` kullanılmaz.
class HubConnectionsStore {
  const HubConnectionsStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  static const listKey = 'hub_connections';
  static const activeKey = 'hub_active';

  // T-003 öncesi tek bağlantının tutulduğu anahtarlar; göç için okunuyor.
  static const legacyOwnerKey = 'hub_owner';
  static const legacyRepoKey = 'hub_repo';
  static const legacyTokenKey = 'hub_token';

  Future<HubConnectionsState> load() async {
    final raw = await _storage.read(key: listKey);
    if (raw == null) return _migrateLegacy();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const HubConnectionsState();
      final connections = decoded
          .whereType<Map<String, dynamic>>()
          .map((m) {
            try {
              return HubConfig.fromJson(m);
            } catch (_) {
              return null; // bozuk kayıt listeyi kilitlemesin
            }
          })
          .whereType<HubConfig>()
          .toList();
      return HubConnectionsState(
        connections: connections,
        activeSlug: await _storage.read(key: activeKey),
      );
    } catch (_) {
      // Bozuk JSON'da bağlantıyı silmek yerine boş dönüyoruz: kullanıcı
      // onboarding'den yeniden bağlanabilir, ama elimizdeki kaydı da
      // kendiliğinden yok etmiyoruz.
      return const HubConnectionsState();
    }
  }

  /// T-003 öncesi kurulumları taşır: uygulama güncellendiğinde kullanıcının
  /// token'ı yeniden girmesi gerekmesin. Göç bir kez çalışır; eski anahtarlar
  /// yeni biçim yazıldıktan **sonra** silinir, yazma yarıda kalırsa kayıt
  /// eskide sağlam durur.
  Future<HubConnectionsState> _migrateLegacy() async {
    final owner = await _storage.read(key: legacyOwnerKey);
    final repo = await _storage.read(key: legacyRepoKey);
    final token = await _storage.read(key: legacyTokenKey);
    if (owner == null || repo == null || token == null) {
      return const HubConnectionsState();
    }

    final migrated = HubConfig(owner: owner, repo: repo, token: token);
    final state = HubConnectionsState(
      connections: [migrated],
      activeSlug: migrated.slug,
    );
    await save(state);

    await _storage.delete(key: legacyOwnerKey);
    await _storage.delete(key: legacyRepoKey);
    await _storage.delete(key: legacyTokenKey);
    return state;
  }

  Future<void> save(HubConnectionsState state) async {
    await _storage.write(
      key: listKey,
      value: jsonEncode([for (final c in state.connections) c.toJson()]),
    );
    final active = state.active;
    if (active == null) {
      await _storage.delete(key: activeKey);
    } else {
      await _storage.write(key: activeKey, value: active.slug);
    }
  }

  Future<void> clear() => _storage.deleteAll();
}

final hubConnectionsStoreProvider =
    Provider<HubConnectionsStore>((ref) => const HubConnectionsStore());

final hubConnectionsProvider =
    AsyncNotifierProvider<HubConnections, HubConnectionsState>(
  HubConnections.new,
);

class HubConnections extends AsyncNotifier<HubConnectionsState> {
  @override
  Future<HubConnectionsState> build() async {
    try {
      return await ref.watch(hubConnectionsStoreProvider).load();
    } catch (_) {
      // Güvenli depo okunamazsa (kilitli cihaz, platform hatası) uygulama
      // çökmemeli; onboarding gösterilir.
      return const HubConnectionsState();
    }
  }

  HubConnectionsState get _current =>
      state.valueOrNull ?? const HubConnectionsState();

  /// Bağlantıyı ekler (ya da aynı repo kayıtlıysa günceller) ve aktif yapar.
  ///
  /// Aynı repoyu ikinci kez eklemek **kopya oluşturmaz**: kullanıcı çoğu zaman
  /// süresi dolmuş token'ı yenilemek için aynı repoyu yeniden girer.
  Future<void> upsertAndActivate(HubConfig config) async {
    final existing = _current.connections;
    final index = existing.indexWhere((c) => c.slug == config.slug);

    final connections = [...existing];
    if (index >= 0) {
      // Ad alanı boş geldiyse kullanıcının önceki adını koru.
      connections[index] = config.label == null
          ? config.copyWith(label: existing[index].label)
          : config;
    } else {
      connections.add(config);
    }

    await _write(
      HubConnectionsState(connections: connections, activeSlug: config.slug),
    );
  }

  /// Aktif repoyu değiştirir. Bilinmeyen slug yok sayılır.
  Future<void> setActive(String slug) async {
    final current = _current;
    if (current.activeSlug == slug || current.bySlug(slug) == null) return;
    await _write(
      HubConnectionsState(connections: current.connections, activeSlug: slug),
    );
  }

  /// Tek bağlantıyı siler. Silinen aktifse sıradaki bağlantı aktif olur;
  /// liste boşalırsa uygulama onboarding'e döner.
  Future<void> remove(String slug) async {
    final current = _current;
    final connections =
        current.connections.where((c) => c.slug != slug).toList();
    if (connections.length == current.connections.length) return;

    await _write(
      HubConnectionsState(
        connections: connections,
        activeSlug:
            current.activeSlug == slug ? connections.firstOrNull?.slug : current.activeSlug,
      ),
    );
  }

  /// Hepsini siler (ayarlardaki "bağlantıyı sıfırla").
  Future<void> removeAll() async {
    await ref.read(hubConnectionsStoreProvider).clear();
    state = const AsyncData(HubConnectionsState());
  }

  Future<void> _write(HubConnectionsState next) async {
    await ref.read(hubConnectionsStoreProvider).save(next);
    state = AsyncData(next);
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
