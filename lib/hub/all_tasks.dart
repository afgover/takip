import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'frontmatter.dart';
import 'hub_config.dart';
import 'hub_connections.dart';
import 'hub_sync.dart';
import 'hub_watcher.dart';
import 'models/task.dart';
import 'offline_store.dart';
import 'task_repo.dart';

/// Bekleyenler listesinin filtresi. Boş küme = "hepsi".
class TaskFilter {
  const TaskFilter({
    this.repos = const {},
    this.priorities = const {},
    this.categories = const {},
  });

  final Set<String> repos;
  final Set<String> priorities;
  final Set<String> categories;

  bool get isEmpty =>
      repos.isEmpty && priorities.isEmpty && categories.isEmpty;

  int get activeCount =>
      (repos.isEmpty ? 0 : 1) +
      (priorities.isEmpty ? 0 : 1) +
      (categories.isEmpty ? 0 : 1);

  bool allows(TaskSummary task) {
    if (repos.isNotEmpty && !repos.contains(task.repoSlug)) return false;
    // Etiketi bilinmeyen görev (yerel kopya henüz inmemiş) filtreye takılmaz:
    // "önceliği high olanlar" derken, önceliği okunamamış bir görevi gizlemek
    // onu kaybetmek olurdu.
    if (priorities.isNotEmpty &&
        task.priority != null &&
        !priorities.contains(task.priority)) {
      return false;
    }
    if (categories.isNotEmpty &&
        task.category != null &&
        !categories.contains(task.category)) {
      return false;
    }
    return true;
  }

  TaskFilter toggled({String? repo, String? priority, String? category}) {
    Set<String> flip(Set<String> current, String? value) {
      if (value == null) return current;
      final next = {...current};
      next.contains(value) ? next.remove(value) : next.add(value);
      return next;
    }

    return TaskFilter(
      repos: flip(repos, repo),
      priorities: flip(priorities, priority),
      categories: flip(categories, category),
    );
  }

  TaskFilter get cleared => const TaskFilter();
}

final taskFilterProvider =
    NotifierProvider<TaskFilterNotifier, TaskFilter>(TaskFilterNotifier.new);

/// Bekleyenler listesinin sıralaması (T-013).
///
/// Varsayılan [waitingFirst] korunuyor: `waiting/` listedeki tek "senden bir
/// şey isteniyor" kalemi ve tarihe karışırsa eski bir bekleme listenin dibinde
/// kaybolur — görünmemesi zaten K-022'nin çözdüğü sorundu. Ama kullanıcı
/// **açıkça** bir sıralama seçtiyse ona uyuluyor: seçimin üstüne sessizce
/// binen bir kural, sıralamayı bozuk gösterir.
enum TaskSort {
  waitingFirst,
  date,
  priority;

  /// Yön yalnız [date] ve [priority] için anlamlı.
  bool get hasDirection => this != waitingFirst;
}

/// Öncelik sırası — sözleşme §4'teki değerler. Bilinmeyen (yerel kopya henüz
/// inmemiş ya da serbest değer) **sona** düşer: bilinmeyeni "normal" saymak,
/// okunamamış bir görevi olduğundan önemli ya da önemsiz gösterirdi.
const _priorityRank = {'urgent': 0, 'high': 1, 'normal': 2, 'low': 3};

class TaskOrder {
  const TaskOrder({this.sort = TaskSort.waitingFirst, this.ascending = false});

  final TaskSort sort;

  /// `false` = azalan (yeniden eskiye, yüksekten düşüğe) — listelerin
  /// alışılmış yönü.
  final bool ascending;

  bool get isDefault => sort == TaskSort.waitingFirst;

  List<TaskSummary> apply(List<TaskSummary> tasks) {
    if (sort == TaskSort.waitingFirst) return tasks;

    final sorted = [...tasks];
    sorted.sort((a, b) {
      // Değeri bilinmeyen görev **yönden bağımsız** olarak sona gider. Yönün
      // içine karışsaydı "artan"da listenin tepesi bilgisizlerle dolardı;
      // bilinmeyen öncelik/tarih gerçek bir durum (yerel kopya inmeden
      // okunamıyor), gizlemek de öne almak da yanlış cevap olurdu.
      final known = _known(a);
      if (known != _known(b)) return known ? -1 : 1;
      if (!known) return a.fileName.compareTo(b.fileName);

      final cmp = switch (sort) {
        TaskSort.date => a.date!.compareTo(b.date!),
        // Rank küçük = öncelik yüksek; kullanıcı için "azalan" yüksekten
        // düşüğe demek, o yüzden burada ters çevriliyor.
        TaskSort.priority =>
          _priorityRank[b.priority]!.compareTo(_priorityRank[a.priority]!),
        TaskSort.waitingFirst => 0,
      };
      // Eşitlikte dosya adı: aynı listeyi iki kez çizerken sıra oynamasın,
      // yoksa kullanıcı listenin kendiliğinden değiştiğini sanır.
      return cmp != 0
          ? (ascending ? cmp : -cmp)
          : a.fileName.compareTo(b.fileName);
    });
    return sorted;
  }

  bool _known(TaskSummary t) => switch (sort) {
        TaskSort.date => t.date != null,
        TaskSort.priority => _priorityRank.containsKey(t.priority),
        TaskSort.waitingFirst => true,
      };

  TaskOrder with_({TaskSort? sort, bool? ascending}) => TaskOrder(
        sort: sort ?? this.sort,
        ascending: ascending ?? this.ascending,
      );
}

class TaskOrderNotifier extends Notifier<TaskOrder> {
  @override
  TaskOrder build() => const TaskOrder();

  /// Aynı ölçüte ikinci dokunuş **yönü çevirir** — ayrı bir yön düğmesi
  /// koymaktansa, listelerde alışılmış davranış.
  void select(TaskSort sort) => state = sort == state.sort && sort.hasDirection
      ? state.with_(ascending: !state.ascending)
      : TaskOrder(sort: sort, ascending: false);
}

final taskOrderProvider =
    NotifierProvider<TaskOrderNotifier, TaskOrder>(TaskOrderNotifier.new);

class TaskFilterNotifier extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => const TaskFilter();

  void toggle({String? repo, String? priority, String? category}) =>
      state = state.toggled(repo: repo, priority: priority, category: category);

  void clear() => state = const TaskFilter();
}

/// Yolun bir görev dosyası olup olmadığı (dört durum klasöründen biri).
/// Kullanıcının kendi notu mu? Not **görev değildir**: bekleyen işlerde
/// görünmez, ama belgede işaretini taşır (sözleşme 1.9 §11).
bool isNotePath(String path) => path.startsWith('${Hub.notesDir}/');

bool isTaskPath(String path) =>
    path.startsWith('${Hub.inboxDir}/') ||
    path.startsWith('${Hub.activeDir}/') ||
    path.startsWith('${Hub.waitingDir}/') ||
    path.startsWith('${Hub.doneDir}/');

/// Bir reponun cihazdaki kopyasından bekleyen görevleri çıkarır.
///
/// Kaynak **yerel kopya** (B-057): görev dosyalarının içeriği zaten indirilmiş
/// olduğu için öncelik ve kategori etiketleri ağa çıkmadan okunabiliyor.
/// Klasör listesinden çizilseydi (B-031) bu alanlar bilinemezdi — liste
/// çizmek için dosya indirmemek oradaki bilinçli tercihti.
Future<List<TaskSummary>> pendingFromStore(HubConfig connection) async {
  final store = OfflineStore(connection.slug);
  final tree = await store.readTree();
  if (tree == null) return const [];

  const dirs = {
    Hub.inboxDir: TaskStatus.inbox,
    Hub.activeDir: TaskStatus.active,
    Hub.waitingDir: TaskStatus.waiting,
  };

  final tasks = <TaskSummary>[];
  for (final entry in tree) {
    if (!entry.isFile) continue;
    final dir = dirs.keys.firstWhere(
      (d) => entry.path.startsWith('$d/'),
      orElse: () => '',
    );
    if (dir.isEmpty) continue;

    final summary = TaskSummary.fromEntry(
      path: entry.path,
      name: entry.path.split('/').last,
      sha: entry.sha,
      status: dirs[dir]!,
    );
    if (summary == null) continue;

    final doc = await store.readDoc(entry.path);
    if (doc == null) {
      tasks.add(summary.withContext(
        repoSlug: connection.slug,
        repoLabel: connection.displayName,
      ));
      continue;
    }

    final fm = Frontmatter.parse(doc.content);
    final title = fm.str('title');
    tasks.add(summary.withContext(
      repoSlug: connection.slug,
      repoLabel: connection.displayName,
      priority: fm.str('priority'),
      category: fm.str('category'),
      waitingFor: fm.str('for'),
      title: (title != null && title.trim().isNotEmpty) ? title.trim() : null,
    ));
  }
  return tasks;
}

/// **Bütün repolardaki** bekleyen işler, tek listede.
///
/// Aktif repo kavramı burada yok: kullanıcı hangi repoda olursa olsun açık
/// işlerinin tamamını görür. Sıralama görev deposundakiyle aynı ilkeye uyar —
/// önce kullanıcıyı bekleyenler, sonra yeniden eskiye.
final allPendingTasksProvider = FutureProvider<List<TaskSummary>>((ref) async {
  ref.watch(hubWatcherProvider.select((s) => s.headSha));
  ref.watch(hubSyncProvider.select((s) => s.version));

  final state =
      ref.watch(hubConnectionsProvider).valueOrNull ?? const HubConnectionsState();
  // Liste boşsa aktif bağlantıya düşülür: bağlantı listesi henüz yüklenmemiş
  // olabilir ve o anda elde tek doğru bilgi `hubConfigProvider`dır.
  final active = state.active ?? ref.watch(hubConfigProvider).value;
  final connections =
      state.connections.isNotEmpty
          ? state.connections
          : (active == null ? const <HubConfig>[] : [active]);
  if (connections.isEmpty) return const [];

  final all = <TaskSummary>[];
  var anyFromStore = false;
  for (final connection in connections) {
    final fromStore = await pendingFromStore(connection);
    if (fromStore.isNotEmpty) anyFromStore = true;
    all.addAll(fromStore);
  }

  // İlk senkron bitmeden yerel kopya boş olur; o durumda en azından aktif
  // reponun listesi ağdan çizilsin, kullanıcı boş ekran görmesin.
  if (!anyFromStore) {
    if (active != null) {
      final live = await ref.read(taskRepoProvider).listPending();
      all.addAll(live.map((t) => t.withContext(
            repoSlug: active.slug,
            repoLabel: active.displayName,
          )));
    }
  }

  all.sort((a, b) {
    if (a.status.needsUser != b.status.needsUser) {
      return a.status.needsUser ? -1 : 1;
    }
    if (a.date == null && b.date == null) return a.fileName.compareTo(b.fileName);
    if (a.date == null) return 1;
    if (b.date == null) return -1;
    final byDate = b.date!.compareTo(a.date!);
    return byDate != 0 ? byDate : a.fileName.compareTo(b.fileName);
  });
  return all;
});

/// Filtre çubuğunun sunacağı seçenekler — listede gerçekten geçen değerler.
final taskFacetsProvider = Provider<TaskFacets>((ref) {
  final tasks = ref.watch(allPendingTasksProvider).valueOrNull ?? const [];
  final repos = <String, String>{};
  final priorities = <String>{};
  final categories = <String>{};
  for (final t in tasks) {
    if (t.repoSlug != null) repos[t.repoSlug!] = t.repoName;
    if (t.priority != null) priorities.add(t.priority!);
    if (t.category != null) categories.add(t.category!);
  }
  return TaskFacets(
    repos: repos,
    // Öncelikler sözleşmedeki sırayla; kalanlar (serbest değer) sona.
    priorities: [
      ...Hub.priorities.where(priorities.contains),
      ...priorities.where((p) => !Hub.priorities.contains(p)),
    ],
    categories: categories.toList()..sort(),
  );
});

class TaskFacets {
  const TaskFacets({
    required this.repos,
    required this.priorities,
    required this.categories,
  });

  /// slug → görünen ad
  final Map<String, String> repos;
  final List<String> priorities;
  final List<String> categories;

  bool get hasAnything =>
      repos.length > 1 || priorities.isNotEmpty || categories.isNotEmpty;
}
