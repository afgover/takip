import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/all_tasks.dart';
import '../../hub/hub_sync.dart';
import '../../hub/hub_watcher.dart';
import '../../hub/models/task.dart';
import '../../hub/models/task_draft.dart';
import '../../hub/outbox.dart';
import '../../hub/reported_waiting.dart';
import '../common/hub_error_view.dart';
import 'task_detail_screen.dart';
import '../../l10n/app_localizations.dart';

/// Bekleyen görevler — **aktif repodan** (`inbox` + `active` + `waiting`).
///
/// Kapsam, üstteki repo şeridinde yazan repo: görevin gösterildiği yer ile
/// eklendiğinde gideceği yer aynı olsun diye. Başka projenin işleri kaybolmuş
/// değil, şeritten repo değiştirilince görünür.
///
/// Liste cihazdaki kopyadan çizilir (B-057), bu yüzden her satır önceliğini ve
/// kategorisini de gösterebiliyor; klasör listelemesiyle çizilseydi bu alanlar
/// dosya indirilmeden bilinemezdi (B-031). Yerel kopya henüz yoksa liste
/// ağdan çizilir.
///
/// Henüz gönderilememiş görevler (B-032) listenin en üstünde ayrı gösterilir.
class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  static const listKey = Key('pending-list');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(activeRepoPendingTasksProvider);
    final status = ref.watch(hubWatcherProvider);
    final queued = ref.watch(queuedForActiveRepoProvider);
    final filter = ref.watch(taskFilterProvider);
    final order = ref.watch(taskOrderProvider);
    final reported =
        ref.watch(reportedWaitingProvider).valueOrNull?.keys.toSet() ??
            const <String>{};
    final l = L.of(context);

    Future<void> refresh() async {
      await ref.read(hubWatcherProvider.notifier).checkNow();
      await ref.read(outboxProvider.notifier).flush();
      await ref.read(hubSyncProvider.notifier).syncNow();
      ref.invalidate(activeRepoPendingTasksProvider);
      await ref.read(activeRepoPendingTasksProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.pendingTitle),
        actions: [
          if (status.checking)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: l.pendingRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: refresh,
            ),
        ],
      ),
      body: Column(
        children: [
          const TaskToolbar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: _list(context, ref, tasks, queued, filter, order, reported),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TaskSummary>> tasks,
    List<TaskDraft> queued,
    TaskFilter filter,
    TaskOrder order,
    Set<String> reported,
  ) {
    return switch (tasks) {
      AsyncData(:final value) when value.isEmpty && queued.isEmpty =>
        _Scrollable(
          child: HubEmptyView(
            icon: Icons.inbox_outlined,
            title: L.of(context).pendingEmptyTitle,
            subtitle: L.of(context).pendingEmptySubtitle,
          ),
        ),
      AsyncData(:final value) => Builder(
          builder: (context) {
            final shown = order.apply(value.where(filter.allows).toList());
            if (shown.isEmpty && queued.isEmpty) {
              return _Scrollable(
                child: HubEmptyView(
                  icon: Icons.filter_alt_off_outlined,
                  title: L.of(context).pendingFilterEmptyTitle,
                  subtitle:
                      L.of(context).pendingFilterEmptySubtitle(value.length),
                ),
              );
            }
            return ListView.separated(
              key: listKey,
              itemCount: queued.length + shown.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => i < queued.length
                  ? _QueuedTile(draft: queued[i])
                  : _TaskTile(
                      task: shown[i - queued.length],
                      // Bildirilmiş bekleme listede **kalır** (B-135): app
                      // dosyayı `waiting/`ten taşıyamıyor (R-001) ve gizlemek,
                      // agent işlemezse sessiz kayıp demek olurdu (K-022).
                      // Görünür kalıyor ama artık "senden bir şey isteniyor"
                      // demiyor.
                      reported: reported.contains(
                        ReportedWaiting.keyFor(
                          shown[i - queued.length].repoSlug,
                          shown[i - queued.length].path,
                        ),
                      ),
                    ),
            );
          },
        ),
      AsyncError(:final error) => _Scrollable(
          child: HubErrorView(
            error: error,
            onRetry: () => ref.invalidate(activeRepoPendingTasksProvider),
          ),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Boş/hata durumlarında da "aşağı çekip yenile" çalışsın diye kaydırılabilir
/// bir kabuk gerekiyor.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, this.reported = false});

  final TaskSummary task;

  /// Bildirimi gönderilmiş bekleme (B-135). Yalnız `waiting/` için anlamlı:
  /// diğer durumlarda kullanıcıdan bir şey istenmiyor, dolayısıyla
  /// bildirilecek bir şey de yok.
  final bool reported;

  bool get _showsReported => reported && task.status.needsUser;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        switch (task.status) {
          TaskStatus.waiting => Icons.pan_tool_outlined,
          TaskStatus.active => Icons.play_circle_outline,
          _ => Icons.fiber_new_outlined,
        },
        // Bildirilmiş bekleme dikkat çekmeyi bırakır: vurgu rengi "senden bir
        // şey isteniyor" demek ve artık istenmiyor — sıra agent'ta.
        color: task.status.needsUser && !reported ? colors.tertiary : null,
      ),
      title: Text(task.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_showsReported
              ? L.of(context).pendingReportedSubtitle
              : formatTaskDate(task.date) ?? task.fileName),
          TaskTagRow(task: task),
        ],
      ),
      isThreeLine: true,
      // Durum rozetinin **yerine** geçiyor, yanına değil: satırda tek bir
      // "bu iş nerede" cevabı olsun. "Bekliyor" ile "Bildirildi" yan yana
      // dursaydı hangisinin geçerli olduğu okunmazdı.
      trailing: _showsReported
          ? const _ReportedBadge()
          : TaskStatusChip(status: task.status),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskDetailScreen(summary: task),
        ),
      ),
    );
  }
}

/// "Bildirildi" rozeti — kuyruk rozetiyle aynı sessiz tonda, çünkü ikisi de
/// aynı şeyi söylüyor: iş kullanıcıdan çıktı, sıra başkasında.
class _ReportedBadge extends StatelessWidget {
  const _ReportedBadge();

  static const key_ = Key('pending-reported-badge');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: key_,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        L.of(context).pendingReportedBadge,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}

/// Kuyrukta bekleyen (henüz hub'a gitmemiş) görev. Hub'da karşılığı olmadığı
/// için detayı açılamaz; sözleşmedeki durumlardan biri de değildir — bu
/// yalnızca cihazdaki bir ara durumdur.
class _QueuedTile extends StatelessWidget {
  const _QueuedTile({required this.draft});

  final TaskDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.cloud_upload_outlined, color: colors.outline),
      title: Text(draft.title),
      subtitle: Text(L.of(context).outboxQueuedSubtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          L.of(context).outboxQueuedBadge,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}

String? formatTaskDate(DateTime? date) {
  if (date == null) return null;
  final d = date.toLocal();
  return '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      TaskStatus.inbox => (
          colors.secondaryContainer,
          colors.onSecondaryContainer
        ),
      TaskStatus.active => (
          colors.primaryContainer,
          colors.onPrimaryContainer
        ),
      // Kullanıcıyı bekleyen iş listede göze çarpmalı: tek "senden bir şey
      // isteniyor" durumu bu.
      TaskStatus.waiting => (
          colors.tertiaryContainer,
          colors.onTertiaryContainer
        ),
      TaskStatus.done => (
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

/// Görev satırının etiketleri: öncelik ve kategori.
///
/// Repo etiketi **yok**: liste tek repoya ait olduğu için her satıra aynı adı
/// basmak, öncelik ve kategoriyi sağa iten bir tekrar olurdu. "Hangi repo"
/// sorusunun cevabı listenin üstündeki şeritte, satır başına bir kez değil.
class TaskTagRow extends StatelessWidget {
  const TaskTagRow({super.key, required this.task});

  final TaskSummary task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final tags = <(String, Color)>[
      if (task.priority != null)
        (task.priority!, _priorityColor(task.priority!, colors)),
      if (task.category != null) (task.category!, colors.surfaceContainerHighest),
    ];
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final (text, background) in tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(text, style: theme.textTheme.labelSmall),
            ),
        ],
      ),
    );
  }

  /// Yalnız acil ve yüksek öne çıkar; `normal`/`low` gürültü yapmasın.
  static Color _priorityColor(String priority, ColorScheme colors) =>
      switch (priority) {
        'urgent' => colors.errorContainer,
        'high' => colors.tertiaryContainer,
        _ => colors.surfaceContainerHighest,
      };
}

/// Bekleyenler'in filtre + sıralama şeridi (T-016).
///
/// Önceki hâli yan yana dizilmiş çiplerdi: her repo, her kategori ve her
/// öncelik için ayrı bir çip. Değer sayısı arttıkça şerit yatay kaydırma
/// gerektiriyordu, yani **hangi seçeneklerin var olduğu görünmüyordu** —
/// kullanıcı kaydırmadan bilemiyordu. Üç menü, seçenek sayısından bağımsız
/// olarak sabit genişlikte duruyor.
///
/// Sıralama da bu şeride indi: dördü `AppBar`'a sığmıyor (başlık ve yenile
/// zaten orada) ve seçicilerin bir arada olması, "neyi göster" ile "hangi
/// sırayla"nın aynı işin iki yüzü olduğunu gösteriyor.
class TaskToolbar extends ConsumerWidget {
  const TaskToolbar({super.key});

  static const barKey = Key('task-filter-bar');
  static const resetKey = Key('task-filter-clear');
  static Key menuKey(String kind) => Key('task-filter-menu-$kind');
  static Key chipKey(String kind, String value) =>
      Key('task-filter-$kind-$value');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final facets = ref.watch(taskFacetsProvider);
    final filter = ref.watch(taskFilterProvider);
    final order = ref.watch(taskOrderProvider);
    if (!facets.hasAnything) return const SizedBox.shrink();

    final notifier = ref.read(taskFilterProvider.notifier);
    final theme = Theme.of(context);

    return Container(
      key: barKey,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Repo menüsü yok: liste zaten tek repo (aktif olan) ve
                  // hangisi olduğu üstteki şeritte yazıyor. Tek değerli bir
                  // filtre, seçilince hiçbir şeyi süzmeyen bir menüdür.
                  _FilterMenu(
                    kind: 'category',
                    label: l.filterCategory,
                    icon: Icons.label_outline,
                    values: {for (final c in facets.categories) c: c},
                    selected: filter.categories,
                    onToggle: (v) => notifier.toggle(category: v),
                  ),
                  _FilterMenu(
                    kind: 'priority',
                    label: l.filterPriority,
                    icon: Icons.flag_outlined,
                    values: {for (final p in facets.priorities) p: p},
                    selected: filter.priorities,
                    onToggle: (v) => notifier.toggle(priority: v),
                  ),
                  const TaskSortButton(),
                ],
              ),
            ),
          ),
          // Sıfırla yalnız **bir şey seçiliyken** var: hiçbir şey seçili
          // değilken duran bir sıfırlama düğmesi, dokunulunca hiçbir şey
          // yapmayan bir düğmedir.
          if (filter.activeCount > 0 || !order.isDefault)
            IconButton(
              key: resetKey,
              tooltip: l.filterReset,
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: () {
                notifier.clear();
                ref.read(taskOrderProvider.notifier).reset();
              },
            ),
        ],
      ),
    );
  }
}

/// Tek bir boyutun çoklu seçim menüsü.
///
/// Menü seçimde **kapanmıyor** (`PopupMenuItem` yerine durum tutan bir
/// gövde): "birden fazla seçenek seçilebilsin" isteğinin karşılığı, her
/// seçimde menüyü yeniden açtırmamak.
class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.kind,
    required this.label,
    required this.icon,
    required this.values,
    required this.selected,
    required this.onToggle,
  });

  final String kind;
  final String label;
  final IconData icon;

  /// değer → görünen ad
  final Map<String, String> values;
  final Set<String> selected;
  final void Function(String value) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = values.keys.where(selected.contains).length;
    final on = active > 0;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        key: TaskToolbar.menuKey(kind),
        tooltip: label,
        // Kapanmasın diye seçim `onTap` üzerinden gidiyor; `PopupMenuItem`in
        // kendi `value` yolu menüyü kapatırdı.
        itemBuilder: (context) => values.isEmpty
            ? [
                PopupMenuItem(
                  enabled: false,
                  child: Text(L.of(context).filterNone),
                ),
              ]
            : [
                for (final entry in values.entries)
                  PopupMenuItem(
                    key: TaskToolbar.chipKey(kind, entry.key),
                    padding: EdgeInsets.zero,
                    child: _MenuRow(
                      label: entry.value,
                      selected: selected.contains(entry.key),
                      onChanged: () => onToggle(entry.key),
                    ),
                  ),
              ],
        child: Chip(
          avatar: Icon(icon,
              size: 16,
              color: on ? theme.colorScheme.onSecondaryContainer : null),
          // Sayı, menüyü açmadan kaç seçenek seçili olduğunu söylüyor —
          // kapalı bir menünün içeriği başka türlü görünmez.
          label: Text(on ? '$label ($active)' : label),
          backgroundColor: on ? theme.colorScheme.secondaryContainer : null,
          side: on ? BorderSide.none : null,
          deleteIcon: const Icon(Icons.arrow_drop_down, size: 18),
          onDeleted: null,
        ),
      ),
    );
  }
}

/// Menü satırı — kendi seçili durumunu tutar ki menü kapanmadan işaret
/// değişsin. Üstteki durum yine tek kaynakta (`taskFilterProvider`); buradaki
/// yalnız açık menünün görüntüsü.
class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final VoidCallback onChanged;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  late bool _selected = widget.selected;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () {
          setState(() => _selected = !_selected);
          widget.onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(
                _selected ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(widget.label),
            ],
          ),
        ),
      );
}

class TaskSortButton extends ConsumerWidget {
  const TaskSortButton({super.key});

  static const buttonKey = Key('task-sort-button');
  static Key itemKey(TaskSort sort) => Key('task-sort-${sort.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final order = ref.watch(taskOrderProvider);

    String nameOf(TaskSort sort) => switch (sort) {
          TaskSort.waitingFirst => l.sortWaitingFirst,
          TaskSort.date => l.sortByDate,
          TaskSort.priority => l.sortByPriority,
        };

    String label(TaskSort sort) {
      // Yön yalnız **seçili** ölçütte yazılıyor: seçili olmayanın yönünü
      // göstermek, dokunmadan önce ne olacağını yanlış vaat ederdi (ikinci
      // dokunuş yönü çevirir).
      if (!sort.hasDirection || sort != order.sort) return nameOf(sort);
      return '${nameOf(sort)} · '
          '${order.ascending ? l.sortAscending : l.sortDescending}';
    }

    return PopupMenuButton<TaskSort>(
      key: buttonKey,
      tooltip: l.sortTooltip,
      onSelected: ref.read(taskOrderProvider.notifier).select,
      itemBuilder: (context) => [
        for (final sort in TaskSort.values)
          PopupMenuItem(
            key: itemKey(sort),
            value: sort,
            child: Row(
              children: [
                Icon(
                  sort != order.sort
                      ? Icons.remove
                      : (!sort.hasDirection
                          ? Icons.check
                          : (order.ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward)),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(label(sort)),
              ],
            ),
          ),
      ],
      child: Chip(
        avatar: Icon(
          Icons.sort,
          size: 16,
          color:
              order.isDefault ? null : theme.colorScheme.onSecondaryContainer,
        ),
        label: Text(order.isDefault ? l.sortTooltip : nameOf(order.sort)),
        backgroundColor:
            order.isDefault ? null : theme.colorScheme.secondaryContainer,
        side: order.isDefault ? null : BorderSide.none,
        deleteIcon: const Icon(Icons.arrow_drop_down, size: 18),
        onDeleted: null,
      ),
    );
  }
}
