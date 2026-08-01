import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/errors.dart';
import '../github/contents_api.dart';
import '../github/trees_api.dart';
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
    ref.listen<String?>(
      hubWatcherProvider.select((s) => s.headSha),
      (previous, next) {
        if (next != null && previous != next) unawaited(syncNow());
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

  Future<void> syncNow() async {
    if (_inFlight) return;
    final store = ref.read(offlineStoreProvider);
    if (store == null) return;

    _inFlight = true;
    state = state.copyWith(syncing: true, done: 0, total: 0, clearError: true);
    try {
      final tree = await ref.read(treesApiProvider).recursive();
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

      state = state.copyWith(total: stale.length);

      final contents = ref.read(contentsApiProvider);
      var done = 0;
      for (final entry in stale) {
        final file = await contents.getFile(entry.path);
        await store.writeDoc(
          entry.path,
          StoredDoc(sha: entry.sha, content: file.content),
        );
        done++;
        state = state.copyWith(done: done);
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

      state = state.copyWith(
        syncing: false,
        syncedAt: meta.syncedAt,
        docCount: meta.docCount,
        clearError: true,
        version: state.version + 1,
      );
    } on HubError catch (e) {
      // Ağ yoksa bu beklenen durumdur: elde eski kopya varken hata göstermek
      // yerine sessizce bırakılır, bağlantı gelince yeniden denenir.
      state = state.copyWith(syncing: false, error: e);
    } finally {
      _inFlight = false;
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
