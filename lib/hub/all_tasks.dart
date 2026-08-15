import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'frontmatter.dart';
import 'hub_config.dart';
import 'hub_connections.dart';
import 'hub_sync.dart';
import 'hub_watcher.dart';
import 'models/task.dart';
import 'models/task_draft.dart';
import 'offline_store.dart';
import 'outbox.dart';
import 'task_repo.dart';

/// Bekleyenler listesinin filtresi. Boş küme = "hepsi".
///
/// Repo boyutu **yok**: liste yalnız aktif reponun işlerini gösteriyor
/// ([activeRepoPendingTasksProvider]), yani süzecek ikinci bir repo kalmadı.
/// Bırakılsaydı görünmeyen bir seçim (tek repolu listede repo menüsü
/// çizilmez) listeyi sessizce boşaltabilirdi.
class TaskFilter {
  const TaskFilter({
    this.priorities = const {},
    this.categories = const {},
  });

  final Set<String> priorities;
  final Set<String> categories;

  bool get isEmpty => priorities.isEmpty && categories.isEmpty;

  int get activeCount =>
      (priorities.isEmpty ? 0 : 1) + (categories.isEmpty ? 0 : 1);

  bool allows(TaskSummary task) {
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

  TaskFilter toggled({String? priority, String? category}) {
    Set<String> flip(Set<String> current, String? value) {
      if (value == null) return current;
      final next = {...current};
      next.contains(value) ? next.remove(value) : next.add(value);
      return next;
    }

    return TaskFilter(
      priorities: flip(priorities, priority),
      categories: flip(categories, category),
    );
  }
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
  static const _sortKey = 'task_sort';
  static const _ascKey = 'task_sort_ascending';

  @override
  TaskOrder build() {
    unawaited(_restore());
    return const TaskOrder();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_sortKey);
      if (name == null) return;
      final sort = TaskSort.values.firstWhere(
        (s) => s.name == name,
        // Tanınmayan değer (eski/yeni sürüm) varsayılana düşer; sıralama
        // bilinmeyen bir duruma girmektense bilinen bir duruma dönmeli.
        orElse: () => TaskSort.waitingFirst,
      );
      state = TaskOrder(
        sort: sort,
        ascending: prefs.getBool(_ascKey) ?? false,
      );
    } catch (_) {
      // Okunamazsa varsayılan sıralamayla devam.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sortKey, state.sort.name);
      await prefs.setBool(_ascKey, state.ascending);
    } catch (_) {}
  }

  /// Sıfırlama filtreyle **birlikte** çalışıyor: kullanıcı "sıfırla"ya
  /// bastığında listenin tamamen bilinen bir hâle dönmesini bekler, yarısının
  /// dönmesini değil.
  void reset() {
    state = const TaskOrder();
    unawaited(_persist());
  }

  /// Aynı ölçüte ikinci dokunuş **yönü çevirir** — ayrı bir yön düğmesi
  /// koymaktansa, listelerde alışılmış davranış.
  void select(TaskSort sort) {
    state = sort == state.sort && sort.hasDirection
        ? state.with_(ascending: !state.ascending)
        : TaskOrder(sort: sort, ascending: false);
    unawaited(_persist());
  }
}

final taskOrderProvider =
    NotifierProvider<TaskOrderNotifier, TaskOrder>(TaskOrderNotifier.new);

/// Filtre ve sıralama **kalıcı** (T-016).
///
/// Ayarlarla aynı desen (`AppSettings`): senkron bir varsayılanla başlanıyor,
/// disktekiler gelince güncelleniyor. Liste, tercih okunsun diye beklemiyor —
/// beklerse açılışta bir kare boş görünürdü.
///
/// Yazma tarafında bir tuzak var: seçilen değer o an listede olmayabilir
/// (ilgili repo silinmiş, o kategoride görev kalmamış). Kaydedilen değer
/// **olduğu gibi** saklanıyor, mevcut değerlerle kesişimi alınmıyor: görev
/// yeniden ortaya çıktığında kullanıcının seçimi de geri gelsin diye. Filtre
/// zaten olmayan değeri süzemez, yani zararsız.
class TaskFilterNotifier extends Notifier<TaskFilter> {
  static const _key = 'task_filter';

  @override
  TaskFilter build() {
    unawaited(_restore());
    return const TaskFilter();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      Set<String> read(String k) =>
          ((json[k] as List?)?.cast<String>() ?? const <String>[]).toSet();
      // Eski kayıttaki `repos` **okunmuyor**: repo boyutu kalkınca o seçim
      // hem menüsüz hem görünmez kalırdı ve başka bir repo aktifken listeyi
      // sessizce boşaltırdı. Yok saymak, kullanıcının bir daha açamayacağı
      // bir filtreyi diriltmekten iyidir.
      state = TaskFilter(
        priorities: read('priorities'),
        categories: read('categories'),
      );
    } catch (_) {
      // Bozuk ya da okunamayan tercih listeyi engellemez: filtresiz açılır.
      // Burada "her şeyi göster" güvenli taraf — yanlış bir filtre, görevleri
      // sessizce gizlerdi.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'priorities': state.priorities.toList(),
          'categories': state.categories.toList(),
        }),
      );
    } catch (_) {
      // Yazılamazsa oturum içinde çalışmaya devam eder.
    }
  }

  void toggle({String? priority, String? category}) {
    state = state.toggled(priority: priority, category: category);
    unawaited(_persist());
  }

  void clear() {
    state = const TaskFilter();
    unawaited(_persist());
  }
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

/// **Aktif repodaki** bekleyen işler.
///
/// Liste bir dönem bütün bağlı repoları tek listede birleştiriyordu (B-067).
/// Pratikte bunun bedeli, kullanıcının "şu an hangi projedeyim" sorusunu
/// kaybetmesi oldu: ekranda üç projenin işi bir aradayken eklenen görev
/// sessizce **aktif** repoya gidiyor ve hepsi tek bir agent'ın kuyruğunda
/// toplanıyordu. Kapsam artık üstteki repo şeridinde yazan repo — gösterilen
/// yer ile yazılan yer aynı. Diğer projeler repo şeridinden bir dokunuş
/// uzakta; hiçbir iş kaybolmuyor, yalnız karışmıyor.
///
/// Sıralama görev deposundakiyle aynı ilkeye uyar — önce kullanıcıyı
/// bekleyenler, sonra yeniden eskiye.
final activeRepoPendingTasksProvider =
    FutureProvider<List<TaskSummary>>((ref) async {
  ref.watch(hubWatcherProvider.select((s) => s.headSha));
  ref.watch(hubSyncProvider.select((s) => s.version));

  final state =
      ref.watch(hubConnectionsProvider).valueOrNull ?? const HubConnectionsState();
  // Liste boşsa aktif bağlantıya düşülür: bağlantı listesi henüz yüklenmemiş
  // olabilir ve o anda elde tek doğru bilgi `hubConfigProvider`dır.
  final active = state.active ?? ref.watch(hubConfigProvider).value;
  if (active == null) return const [];

  // Kopya: `pendingFromStore` kopya yokken **sabit** liste döndürüyor ve
  // aşağıdaki ağ yedeği ona ekleme yapıyor.
  final all = [...await pendingFromStore(active)];

  // İlk senkron bitmeden yerel kopya boş olur; o durumda liste ağdan çizilsin,
  // kullanıcı boş ekran görmesin.
  if (all.isEmpty) {
    final live = await ref.read(taskRepoProvider).listPending();
    all.addAll(live.map((t) => t.withContext(
          repoSlug: active.slug,
          repoLabel: active.displayName,
        )));
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

/// Kuyrukta bekleyen taslaklardan **aktif repoya ait** olanlar.
///
/// Liste aktif repoya daralınca kuyruk da daralmak zorunda: başka projeye
/// yazılmayı bekleyen bir taslağı bu reponun listesinin tepesinde göstermek,
/// düzeltilen karışıklığın kuyruk tarafından geri getirilmesi olurdu.
///
/// Damgasız taslak (T-003 öncesi kuyruğa girmiş) aktif repoya ait sayılıyor —
/// repo şeridindeki sayaçla aynı kural, iki yer aynı şeyi saymalı.
final queuedForActiveRepoProvider = Provider<List<TaskDraft>>((ref) {
  final state =
      ref.watch(hubConnectionsProvider).valueOrNull ?? const HubConnectionsState();
  final activeSlug =
      (state.active ?? ref.watch(hubConfigProvider).value)?.slug;
  final queued = ref.watch(outboxProvider).valueOrNull ?? const <TaskDraft>[];
  return queued.where((d) => (d.repoSlug ?? activeSlug) == activeSlug).toList();
});

/// Filtre çubuğunun sunacağı seçenekler — listede gerçekten geçen değerler.
final taskFacetsProvider = Provider<TaskFacets>((ref) {
  final tasks = ref.watch(activeRepoPendingTasksProvider).valueOrNull ?? const [];
  final priorities = <String>{};
  final categories = <String>{};
  for (final t in tasks) {
    if (t.priority != null) priorities.add(t.priority!);
    if (t.category != null) categories.add(t.category!);
  }
  return TaskFacets(
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
    required this.priorities,
    required this.categories,
  });

  final List<String> priorities;
  final List<String> categories;

  bool get hasAnything => priorities.isNotEmpty || categories.isNotEmpty;
}
