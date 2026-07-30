import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../github/contents_api.dart';
import 'models/task.dart';

/// Görev deposu — sözleşme (SYSTEM.md §4) ile Contents API arasındaki köprü.
///
/// TODO(B-030): addTask — frontmatter'lı dosya üret (id: pending,
///   created_by: user), `tasks/inbox/<tarih>-<slug>.md` olarak PUT,
///   commit mesajı: `task(pending): inbox'a eklendi (app)`.
/// TODO(B-031): listPending — inbox+active klasör listesi (içerik indirmeden),
///   detay görünümünde getFile ile içerik.
/// TODO(B-032): offline outbox — PUT başarısızsa lokal kuyruğa al.
class TaskRepo {
  TaskRepo(this._api);
  final ContentsApi _api;

  Future<void> addTask(HubTask task) => throw UnimplementedError('B-030');

  /// Uygulamanın **tek yazma kapısı** (R-001).
  ///
  /// Yol değil *dosya adı* alır ve önüne her zaman `tasks/inbox/` ekler;
  /// böylece kural runtime kontrolüne bırakılmaz, app'in başka bir klasöre
  /// yazması yapısal olarak mümkün olmaz. Dosya adı sözleşmedeki biçimdedir
  /// (`<YYYY-MM-DD>-<slug>.md`, bkz. `core/utils.dart`).
  Future<String> writeToInbox(
    String fileName, {
    required String content,
    required String commitMessage,
  }) {
    if (fileName.contains('/')) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        'Yol değil, dosya adı bekleniyor (R-001: app yalnızca inbox\'a yazar).',
      );
    }
    return _api.putFile(
      '${Hub.inboxDir}/$fileName',
      content,
      commitMessage: commitMessage,
    );
  }

  Future<List<RepoEntry>> listPending() async => [
        ...await _api.listDir(Hub.inboxDir),
        ...await _api.listDir(Hub.activeDir),
      ];

  Future<List<RepoEntry>> listDone() => _api.listDir(Hub.doneDir);
}

final taskRepoProvider =
    Provider<TaskRepo>((ref) => TaskRepo(ref.watch(contentsApiProvider)));
