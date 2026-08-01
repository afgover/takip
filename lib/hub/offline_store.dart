import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../github/trees_api.dart';
import 'hub_connections.dart';

/// Hub içeriğinin cihazdaki kopyası (B-057).
///
/// ETag önbelleğinden (B-046) farkı **niyet**: o, gidilen yolu ucuzlatan bir
/// önbellektir ve yalnızca açılmış belgeleri tutar; burası ise hub'ın
/// tamamının kasıtlı olarak indirilmiş kopyasıdır. Kullanıcı hiç açmadığı bir
/// oturum kaydını uçakta okuyabilsin diye var.
///
/// Kayıtlar **repo başına** ayrılır. Ayrılmasaydı A reposunun belgeleri B'ye
/// geçtiğinde de listede kalırdı — kullanıcının gördüğü içerik ile bulunduğu
/// repo birbirini tutmazdı.
class OfflineStore {
  const OfflineStore(this.slug);

  /// `owner/repo` — anahtar öneki.
  final String slug;

  static const _prefix = 'offline';

  String _docKey(String path) => '$_prefix:$slug:doc:$path';
  String get _treeKey => '$_prefix:$slug:__tree';
  String get _metaKey => '$_prefix:$slug:__meta';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Kayıtlı belge; yoksa null.
  Future<StoredDoc?> readDoc(String path) async {
    final raw = (await _prefs).getString(_docKey(path));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StoredDoc(
        sha: map['sha'] as String,
        content: map['content'] as String,
      );
    } catch (_) {
      return null; // bozuk kayıt yokmuş sayılır, senkron yeniden indirir
    }
  }

  Future<void> writeDoc(String path, StoredDoc doc) async {
    await (await _prefs).setString(
      _docKey(path),
      jsonEncode({'sha': doc.sha, 'content': doc.content}),
    );
  }

  Future<void> removeDoc(String path) async =>
      (await _prefs).remove(_docKey(path));

  /// Kayıtlı ağaç — listeler ağdan değil buradan çizilir.
  Future<List<TreeEntry>?> readTree() async {
    final raw = (await _prefs).getString(_treeKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => TreeEntry(
                path: e['path'] as String,
                sha: e['sha'] as String,
                isFile: e['isFile'] as bool,
                size: e['size'] as int?,
              ))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeTree(List<TreeEntry> entries) async {
    await (await _prefs).setString(
      _treeKey,
      jsonEncode([
        for (final e in entries)
          {
            'path': e.path,
            'sha': e.sha,
            'isFile': e.isFile,
            if (e.size != null) 'size': e.size,
          },
      ]),
    );
  }

  Future<OfflineMeta?> readMeta() async {
    final raw = (await _prefs).getString(_metaKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return OfflineMeta(
        syncedAt: DateTime.parse(map['syncedAt'] as String),
        docCount: map['docCount'] as int? ?? 0,
        bytes: map['bytes'] as int? ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeMeta(OfflineMeta meta) async {
    await (await _prefs).setString(
      _metaKey,
      jsonEncode({
        'syncedAt': meta.syncedAt.toIso8601String(),
        'docCount': meta.docCount,
        'bytes': meta.bytes,
      }),
    );
  }

  /// Bu reponun bütün offline kaydını siler.
  Future<void> clear() async {
    final prefs = await _prefs;
    final mine = prefs.getKeys().where((k) => k.startsWith('$_prefix:$slug:'));
    for (final key in mine.toList()) {
      await prefs.remove(key);
    }
  }

  /// Kayıtlı belge yollarının kümesi — senkron, silinmiş dosyaları
  /// temizlerken kullanır.
  Future<Set<String>> storedPaths() async {
    final prefix = '$_prefix:$slug:doc:';
    return (await _prefs)
        .getKeys()
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length))
        .toSet();
  }
}

class StoredDoc {
  const StoredDoc({required this.sha, required this.content});
  final String sha;
  final String content;
}

class OfflineMeta {
  const OfflineMeta({
    required this.syncedAt,
    required this.docCount,
    required this.bytes,
  });

  final DateTime syncedAt;
  final int docCount;
  final int bytes;
}

/// Aktif reponun offline deposu.
final offlineStoreProvider = Provider<OfflineStore?>((ref) {
  final slug = ref.watch(_activeSlugProvider);
  return slug == null ? null : OfflineStore(slug);
});

/// Yalnız slug'ı izler: token değişince depo yeniden kurulmasın.
final _activeSlugProvider = Provider<String?>((ref) {
  return ref.watch(hubConnectionsProvider.select(
    (value) => value.valueOrNull?.active?.slug,
  ));
});
