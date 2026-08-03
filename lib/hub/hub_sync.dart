import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/errors.dart';
import '../github/client.dart';
import '../github/contents_api.dart';
import '../github/trees_api.dart';
import 'hub_config.dart';
import 'hub_connections.dart';
import 'hub_watcher.dart';
import 'offline_store.dart';

/// Senkronun o anki durumu.
class SyncStatus {
  const SyncStatus({
    this.syncing = false,
    this.done = 0,
    this.total = 0,
    this.syncedAt,
    this.docCount = 0,
    this.error,
    this.version = 0,
  });

  final bool syncing;

  /// İndirilen / indirilecek belge sayısı (yalnız değişenler sayılır).
  final int done;
  final int total;

  final DateTime? syncedAt;
  final int docCount;
  final HubError? error;

  /// Her başarılı senkrondan sonra artar. Ekranlar bunu izleyerek
  /// yeni içeriği çizer.
  final int version;

  bool get hasOfflineCopy => docCount > 0;

  SyncStatus copyWith({
    bool? syncing,
    int? done,
    int? total,
    DateTime? syncedAt,
    bool clearSyncedAt = false,
    int? docCount,
    HubError? error,
    bool clearError = false,
    int? version,
  }) =>
      SyncStatus(
        syncing: syncing ?? this.syncing,
        done: done ?? this.done,
        total: total ?? this.total,
        syncedAt: clearSyncedAt ? null : (syncedAt ?? this.syncedAt),
        docCount: docCount ?? this.docCount,
        error: clearError ? null : (error ?? this.error),
        version: version ?? this.version,
      );
}

/// Hub'ın tamamını cihaza indirir ve güncel tutar (B-057).
///
/// **Neden ağaç farkı:** Git ağacı her dosyanın blob SHA'sını tek istekte
/// veriyor (K-014). SHA değişmemişse dosya da değişmemiştir — yani ilk
/// senkrondan sonra indirilecek dosya sayısı, değişen dosya sayısı kadardır.
/// Hub günde birkaç dosya değiştiği için pratikte her senkron tek ağaç
/// isteği + birkaç küçük indirmedir. Ağaç isteği de ETag'li olduğu için
/// değişiklik yokken istek limitinden düşmez (SK-002).
class HubSync extends Notifier<SyncStatus> {
  bool _inFlight = false;

  @override
  SyncStatus build() {
    // Yoklama hub'da değişiklik görürse (B-024) kendiliğinden senkron ol.
    // Yoklama **herhangi bir** repoda değişiklik görürse senkron ol (B-024).
    // Önceden yalnız aktif reponun başı izleniyordu; senkron tüm repoları
    // indirdiği hâlde tetikleyici tek repoya bakıyordu, yani aktif olmayan
    // bir repoya yapılan push uygulamada hiç görünmüyordu (L-034).
    ref.listen<Set<String>>(
      hubWatcherProvider.select((s) => s.changedSlugs),
      (previous, next) {
        if (next.isNotEmpty) unawaited(syncNow());
      },
    );
    unawaited(_restoreMeta());
    return const SyncStatus();
  }

  Future<void> _restoreMeta() async {
    final store = ref.read(offlineStoreProvider);
    if (store == null) return;
    final meta = await store.readMeta();
    if (meta == null) return;
    state = state.copyWith(
      syncedAt: meta.syncedAt,
      docCount: meta.docCount,
    );
  }

  /// Hub'ın indirilecek kısmı: sözleşmedeki markdown kayıtları.
  ///
  /// Kod dosyaları dışarıda — uygulama onları göstermiyor, indirmek boşuna
  /// yer ve istek olurdu.
  static bool isSyncable(TreeEntry entry) =>
      entry.isFile &&
      entry.path.startsWith('${Hub.basePath}/') &&
      entry.path.endsWith('.md');

  /// **Bağlı bütün repoları** günceller (aktif olanla başlar).
  ///
  /// Tümü indiriliyor çünkü Bekleyenler artık repolar arası: kullanıcı hangi
  /// repoda olursa olsun bütün açık işlerini görüyor. Yalnız aktif repo
  /// inseydi, liste ancak o repoya geçildiğinde dolardı.
  Future<void> syncNow() async {
    if (_inFlight) return;
    final connections =
        ref.read(hubConnectionsProvider).valueOrNull ?? const HubConnectionsState();
    final active = connections.active;
    if (active == null) return;

    _inFlight = true;
    state = state.copyWith(syncing: true, done: 0, total: 0, clearError: true);
    try {
      await _syncConnection(active);
      for (final other in connections.connections) {
        if (other.slug == active.slug) continue;
        // Bir repo indirilemezse (token kapsamıyor, ağ koptu) diğerleri
        // etkilenmesin; hata aktif repodan geliyorsa zaten yukarı çıkar.
        try {
          await _syncConnection(other);
        } on HubError {
          continue;
        }
      }
      state = state.copyWith(syncing: false, version: state.version + 1);
    } on HubError catch (e) {
      // Ağ yoksa bu beklenen durumdur: elde eski kopya varken hata göstermek
      // yerine sessizce bırakılır, bağlantı gelince yeniden denenir.
      state = state.copyWith(syncing: false, error: e);
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _syncConnection(HubConfig connection) async {
    final store = OfflineStore(connection.slug);
    // İlerleme ve "son güncelleme" göstergeleri aktif repoyu anlatır; arka
    // planda inen diğer repolar sayacı oynatmaz.
    final isActive = connection.slug ==
        ref.read(hubConnectionsProvider).valueOrNull?.active?.slug;

    // Paylaşılan istemci her repo için kullanılabiliyor: L-019 düzeltmesinden
    // beri token isteğin **yolundan** seçiliyor. Ayrı bir Dio açmak ETag
    // önbelleğini de kaybettirirdi — değişmemiş ağaç 304 dönüyor ve istek
    // limitinden düşmüyor (SK-002).
    final dio = ref.read(githubDioProvider);
    final contents =
        ContentsApi(dio, owner: connection.owner, repo: connection.repo);
    final trees = TreesApi(dio, owner: connection.owner, repo: connection.repo);
    {
      final tree = await trees.recursive();
      final wanted = tree.where(isSyncable).toList();

      // Silinmiş dosyalar yerel kopyadan da düşsün; yoksa kullanıcı hub'da
      // olmayan bir belgeyi listede görmeye devam ederdi.
      final wantedPaths = {for (final e in wanted) e.path};
      for (final stale in (await store.storedPaths()).difference(wantedPaths)) {
        await store.removeDoc(stale);
      }

      // SHA'sı değişmemiş dosya indirilmez.
      final stale = <TreeEntry>[];
      for (final entry in wanted) {
        final existing = await store.readDoc(entry.path);
        if (existing == null || existing.sha != entry.sha) stale.add(entry);
      }

      if (isActive) state = state.copyWith(total: stale.length);

      var done = 0;
      for (final entry in stale) {
        final file = await contents.getFile(entry.path);
        await store.writeDoc(
          entry.path,
          StoredDoc(sha: entry.sha, content: file.content),
        );
        done++;
        if (isActive) state = state.copyWith(done: done);
      }

      // Ağaç en sona yazılır: indirme yarıda kalırsa ağaç eski kalsın ve
      // bir sonraki senkron eksikleri yeniden denesin.
      await store.writeTree(wanted);

      var bytes = 0;
      for (final entry in wanted) {
        bytes += entry.size ?? 0;
      }
      final meta = OfflineMeta(
        syncedAt: clock.now(),
        docCount: wanted.length,
        bytes: bytes,
      );
      await store.writeMeta(meta);

      if (isActive) {
        state = state.copyWith(
          syncedAt: meta.syncedAt,
          docCount: meta.docCount,
          clearError: true,
        );
      }
    }
  }

  /// Yerel kopyayı siler (ayarlardan).
  Future<void> clearOfflineCopy() async {
    await ref.read(offlineStoreProvider)?.clear();
    state = state.copyWith(
      docCount: 0,
      clearSyncedAt: true,
      version: state.version + 1,
    );
  }
}

final hubSyncProvider =
    NotifierProvider<HubSync, SyncStatus>(HubSync.new);
