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

  Future<List<RepoEntry>> listPending() async => [
        ...await _api.listDir(Hub.inboxDir),
        ...await _api.listDir(Hub.activeDir),
      ];

  Future<List<RepoEntry>> listDone() => _api.listDir(Hub.doneDir);
}

final taskRepoProvider =
    Provider<TaskRepo>((ref) => TaskRepo(ref.watch(contentsApiProvider)));
