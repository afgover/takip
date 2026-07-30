import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'client.dart';

/// Contents API sarmalayıcısı — dosya okuma/yazma/silme, SHA yönetimi.
/// Uygulamanın hub'a dokunduğu TEK yazma yolu burasıdır ve yalnızca
/// `tasks/inbox/` altına yazar (hub kuralı R-001).
///
/// TODO(B-023): implementasyon —
///   listDir  : GET  /repos/{o}/{r}/contents/{dir}          → ad+sha listesi
///   getFile  : GET  /repos/{o}/{r}/contents/{path}         → içerik(base64)+sha
///   putFile  : PUT  /repos/{o}/{r}/contents/{path}         → create/update
///              (update'te sha zorunlu; 409 → HubConflictError)
///   deleteFile: DELETE /repos/{o}/{r}/contents/{path}      → sha zorunlu
/// TODO(B-033): 409'da yeniden oku → yeniden dene akışı.
class ContentsApi {
  ContentsApi(this._ref);
  final Ref _ref;

  Future<List<RepoEntry>> listDir(String dir) =>
      throw UnimplementedError('B-023');

  Future<RepoFile> getFile(String path) => throw UnimplementedError('B-023');

  Future<void> putFile(String path, String content,
          {String? sha, required String commitMessage}) =>
      throw UnimplementedError('B-023');

  Future<void> deleteFile(String path,
          {required String sha, required String commitMessage}) =>
      throw UnimplementedError('B-023');
}

class RepoEntry {
  const RepoEntry({required this.name, required this.path, required this.sha});
  final String name;
  final String path;
  final String sha;
}

class RepoFile {
  const RepoFile({required this.path, required this.sha, required this.content});
  final String path;
  final String sha;
  final String content; // çözülmüş (base64 değil)
}

final contentsApiProvider = Provider<ContentsApi>((ref) {
  ref.watch(githubDioProvider);
  return ContentsApi(ref);
});
