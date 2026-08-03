import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/errors.dart';
import '../github/client.dart';
import '../github/contents_api.dart';
import 'hub_config.dart';
import 'hub_connections.dart';
import 'hub_watcher.dart';
import 'models/task.dart';
import 'models/task_draft.dart';

/// Görev deposu — sözleşme (SYSTEM.md §4) ile Contents API arasındaki köprü.
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
  ///
  /// Ad çakışmasını (B-033) iki farklı duruma ayırır — ikisi de gerçekte
  /// oluyor:
  ///
  /// 1. **Aynı görev zaten gönderilmiş.** Outbox yeniden denerken yazma
  ///    başarılı olup yanıt kaybolmuş olabilir. Bu durumda dosya aynı içerikle
  ///    duruyordur; kopya oluşturmak yanlış olur, işlem başarılı sayılır.
  /// 2. **Aynı gün aynı başlıkla başka bir görev.** Dosya var ama içeriği
  ///    farklı; kullanıcının önceki görevinin üstüne yazmak yerine ad
  ///    sonuna sayı eklenir.
  ///
  /// Ayrımı yapmanın tek yolu dosyayı okumak — sözleşmedeki "yeniden oku,
  /// yeniden dene" tam olarak bu.
  Future<TaskSummary> send(TaskDraft draft) async {
    var attempt = draft;

    for (var tries = 1; tries <= _maxWriteAttempts; tries++) {
      try {
        final sha = await writeToInbox(
          attempt.fileName,
          content: attempt.content,
          commitMessage: attempt.commitMessage,
        );
        return _inboxSummary(attempt.fileName, sha);
      } on HubConflictError {
        final existing = await _readInboxIfExists(attempt.fileName);

        if (existing == null) {
          continue; // dosya bu arada silinmiş: aynı adla yeniden dene
        }
        if (existing.content == attempt.content) {
          return _inboxSummary(attempt.fileName, existing.sha);
        }
        attempt = draft.withFileName(_numbered(draft.fileName, tries + 1));
      }
    }

    throw HubConflictError(
      '${draft.fileName} yazılamadı: aynı adla $_maxWriteAttempts dosya var.',
    );
  }

  static const _maxWriteAttempts = 5;

  TaskSummary _inboxSummary(String fileName, String sha) =>
      TaskSummary.fromEntry(
        path: '${Hub.inboxDir}/$fileName',
        name: fileName,
        sha: sha,
        status: TaskStatus.inbox,
      )!;

  Future<RepoFile?> _readInboxIfExists(String fileName) async {
    try {
      return await _api.getFile('${Hub.inboxDir}/$fileName');
    } on HubNotFoundError {
      return null;
    }
  }

  /// `2026-07-30-market.md` → `2026-07-30-market-2.md`
  static String _numbered(String fileName, int n) {
    final stem = fileName.endsWith('.md')
        ? fileName.substring(0, fileName.length - 3)
        : fileName;
    return '$stem-$n.md';
  }

  /// Bekleyenler: `inbox/` + `active/` + `waiting/`. İçerik indirilmez (B-031).
  ///
  /// `waiting/` de buraya girer çünkü kullanıcı açısından hepsi "kapanmamış
  /// iş"tir; ayrımı durum rozeti ve sıralama yapar (kullanıcıyı bekleyenler
  /// en üstte).
  Future<List<TaskSummary>> listPending() async {
    final lists = await Future.wait([
      _list(Hub.inboxDir, TaskStatus.inbox),
      _list(Hub.activeDir, TaskStatus.active),
      _list(Hub.waitingDir, TaskStatus.waiting),
    ]);
    return _sorted(lists.expand((e) => e).toList());
  }

  /// Kullanıcının kendi eklediği bir kaydı **inbox'tan** siler (sözleşme 1.7).
  ///
  /// Yalnız `inbox/` — agent kaydı `active/`e almışsa dosya orada değildir ve
  /// silme sessizce başarısız olur; bu bilinçli, çünkü ele alınmış bir işi yok
  /// etmek agent'ın çalışmasını çöpe atardı.
  ///
  /// Yol değil dosya adı alır: R-001'in yapısal kapısı burada da geçerli,
  /// app'in başka bir klasöre dokunması mümkün olmasın diye.
  Future<bool> deleteFromInbox(String fileName) async {
    if (fileName.contains('/')) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        'Yol değil, dosya adı bekleniyor (R-001).',
      );
    }
    try {
      final file = await _api.getFile('${Hub.inboxDir}/$fileName');
      await _api.deleteFile(
        '${Hub.inboxDir}/$fileName',
        sha: file.sha,
        commitMessage: "task(pending): inbox'tan silindi (app)",
      );
      return true;
    } on HubNotFoundError {
      return false; // agent almış olabilir; dokunmuyoruz
    }
  }

  /// Kullanıcı "Yaptım" dediğinde `inbox/`a yazılan bildirim görevi
  /// (sözleşme 1.4).
  ///
  /// Asıl görevi **app taşımaz**: R-001 gereği app'in yazma alanı tek
  /// klasördür ve bu garanti derleme zamanı sabitidir. App yalnızca haber
  /// verir; `waiting/ → done/` geçişini agent yapar.
  Future<TaskSummary> reportWaitingDone(HubTask task) =>
      send(TaskDraft.waitingDone(task));

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

  /// Önce **kullanıcıyı bekleyenler**, sonra yeniden eskiye; tarihi okunamayan
  /// dosyalar sona.
  ///
  /// `waiting/` öne alınıyor çünkü listedeki tek "senden bir şey isteniyor"
  /// kalemi o; tarihe göre araya karışsa, agent'ın beklediği iş eski diye
  /// listenin dibinde kalabilirdi — görünmemesi zaten çözmeye çalıştığımız
  /// sorundu (K-022).
  List<TaskSummary> _sorted(List<TaskSummary> tasks) {
    tasks.sort((a, b) {
      if (a.status.needsUser != b.status.needsUser) {
        return a.status.needsUser ? -1 : 1;
      }
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

/// **Belirli bir repo** için görev deposu.
///
/// Bekleyenler artık bütün repoların işlerini gösteriyor; bir göreve
/// dokunulduğunda onu **kendi** reposundan okumak gerekiyor. Aktif repodan
/// okumak, başka repodaki bir görevi açarken "Bulunamadı" veriyordu (L-031).
///
/// Paylaşılan istemci kullanılıyor: token isteğin yolundan seçildiği için
/// (L-019) her repo için doğru kimlikle gidiyor ve ETag önbelleği korunuyor.
final taskRepoForSlugProvider =
    Provider.family<TaskRepo, String?>((ref, slug) {
  final connections = ref.watch(hubConnectionsProvider).valueOrNull;
  final connection =
      slug == null ? null : connections?.bySlug(slug);
  if (connection == null) return ref.watch(taskRepoProvider);

  return TaskRepo(ContentsApi(
    ref.watch(githubDioProvider),
    owner: connection.owner,
    repo: connection.repo,
  ));
});

/// **Aktif olmayan** bir bağlantıya yazmak için tek seferlik görev deposu
/// (T-003). Outbox, kuyrukta başka repolara ait taslak varken kullanır.
///
/// Kendi Dio'sunu açıp kapatır; paylaşılan istemci kullanılamaz çünkü o,
/// token'ı her istekte **aktif** bağlantıdan okur. ETag önbelleğinden
/// yararlanmaması sorun değil: buradan yalnız PUT geçer, önbellek GET'lidir.
Future<T> withTaskRepoFor<T>(
  HubConfig config,
  Future<T> Function(TaskRepo repo) body,
) async {
  final dio = buildGithubDio((_) => config.token);
  try {
    return await body(
      TaskRepo(ContentsApi(dio, owner: config.owner, repo: config.repo)),
    );
  } finally {
    dio.close();
  }
}

/// Bir taslağı belirli bir bağlantıya gönderir.
typedef DraftSender = Future<void> Function(HubConfig target, TaskDraft draft);

/// Outbox'ın aktif olmayan repoya yazarken kullandığı gönderici.
///
/// Provider olarak veriliyor ki testler ağa çıkmadan hedef repoyu
/// doğrulayabilsin — [withTaskRepoFor] kendi Dio'sunu açtığı için doğrudan
/// çağrılsa sahte adaptörle değiştirilemezdi.
final draftSenderProvider = Provider<DraftSender>(
  (ref) => (target, draft) => withTaskRepoFor(target, (repo) => repo.send(draft)),
);

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
  // Görev kendi reposundan okunur; liste çoklu repo olduğu için aktif repo
  // doğru kaynak değil.
  return ref.watch(taskRepoForSlugProvider(summary.repoSlug)).read(summary);
});
