import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../github/contents_api.dart';
import 'hub_watcher.dart';
import 'models/task.dart';
import 'models/task_draft.dart';

/// Görev deposu — sözleşme (SYSTEM.md §4) ile Contents API arasındaki köprü.
///
/// TODO(B-032): offline outbox — PUT başarısızsa lokal kuyruğa al.
class TaskRepo {
  TaskRepo(this._api);
  final ContentsApi _api;

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

  /// Yeni görevi sözleşmeye uygun biçimde `tasks/inbox/`'a yazar (B-030).
  ///
  /// `id: pending` bilinçlidir: ID'yi agent ilk işleyişte atar (SYSTEM.md §4),
  /// app numara uydurmaz. Commit mesajı §8 biçimindedir.
  Future<TaskSummary> addTask({
    required String title,
    String description = '',
    String priority = 'normal',
    String category = 'gorev',
    List<String> tags = const [],
  }) async {
    return send(
      TaskDraft.create(
        title: title,
        description: description,
        priority: priority,
        category: category,
        tags: tags,
      ),
    );
  }

  /// Hazır taslağı hub'a gönderir. Outbox (B-032) bekleyen taslakları da
  /// buradan gönderir — yazma yolu tek.
  Future<TaskSummary> send(TaskDraft draft) async {
    final sha = await writeToInbox(
      draft.fileName,
      content: draft.content,
      commitMessage: draft.commitMessage,
    );

    return TaskSummary.fromEntry(
      path: '${Hub.inboxDir}/${draft.fileName}',
      name: draft.fileName,
      sha: sha,
      status: TaskStatus.inbox,
    )!;
  }

  /// Bekleyenler: `inbox/` + `active/`. İçerik indirilmez (B-031).
  Future<List<TaskSummary>> listPending() async {
    final lists = await Future.wait([
      _list(Hub.inboxDir, TaskStatus.inbox),
      _list(Hub.activeDir, TaskStatus.active),
    ]);
    return _sorted(lists.expand((e) => e).toList());
  }

  Future<List<TaskSummary>> listDone() async =>
      _sorted(await _list(Hub.doneDir, TaskStatus.done));

  Future<List<TaskSummary>> _list(String dir, TaskStatus status) async {
    final entries = await _api.listDir(dir);
    return entries
        .where((e) => !e.isDirectory)
        .map((e) => TaskSummary.fromEntry(
              path: e.path,
              name: e.name,
              sha: e.sha,
              status: status,
            ))
        .whereType<TaskSummary>()
        .toList();
  }

  /// Yeniden eskiye; tarihi okunamayan dosyalar sona.
  List<TaskSummary> _sorted(List<TaskSummary> tasks) {
    tasks.sort((a, b) {
      if (a.date == null && b.date == null) return a.fileName.compareTo(b.fileName);
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      final byDate = b.date!.compareTo(a.date!);
      return byDate != 0 ? byDate : a.fileName.compareTo(b.fileName);
    });
    return tasks;
  }

  /// Görev dosyasının tam içeriği — detay ekranı açılınca çekilir.
  Future<HubTask> read(TaskSummary summary) async {
    final file = await _api.getFile(summary.path);
    return HubTask.parse(
      path: file.path,
      content: file.content,
      status: summary.status,
      sha: file.sha,
    );
  }
}

final taskRepoProvider =
    Provider<TaskRepo>((ref) => TaskRepo(ref.watch(contentsApiProvider)));

/// Bekleyen görevler. Yoklama hub'da değişiklik görürse (B-024) `headSha`
/// değişir ve liste kendiliğinden tazelenir.
final pendingTasksProvider = FutureProvider<List<TaskSummary>>((ref) {
  ref.watch(hubWatcherProvider.select((s) => s.headSha));
  return ref.watch(taskRepoProvider).listPending();
});

final doneTasksProvider = FutureProvider<List<TaskSummary>>((ref) {
  ref.watch(hubWatcherProvider.select((s) => s.headSha));
  return ref.watch(taskRepoProvider).listDone();
});

/// Tek görevin içeriği (detay ekranı).
final taskDetailProvider =
    FutureProvider.autoDispose.family<HubTask, TaskSummary>((ref, summary) {
  ref.watch(hubWatcherProvider.select((s) => s.headSha));
  return ref.watch(taskRepoProvider).read(summary);
});
