import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/all_tasks.dart';
import '../../hub/hub_sync.dart';
import '../../hub/hub_watcher.dart';
import '../../hub/models/task.dart';
import '../../hub/models/task_draft.dart';
import '../../hub/outbox.dart';
import '../common/hub_error_view.dart';
import 'task_detail_screen.dart';
import '../../l10n/app_localizations.dart';

/// Bekleyen görevler — **bütün repolardan** (`inbox` + `active` + `waiting`).
///
/// Liste cihazdaki kopyadan çizilir (B-057), bu yüzden her satır önceliğini ve
/// kategorisini de gösterebiliyor; klasör listelemesiyle çizilseydi bu alanlar
/// dosya indirilmeden bilinemezdi (B-031). Yerel kopya henüz yoksa aktif
/// reponun listesi ağdan çizilir.
///
/// Henüz gönderilememiş görevler (B-032) listenin en üstünde ayrı gösterilir.
class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  static const listKey = Key('pending-list');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(allPendingTasksProvider);
    final status = ref.watch(hubWatcherProvider);
    final queued = ref.watch(outboxProvider).valueOrNull ?? const [];
    final filter = ref.watch(taskFilterProvider);
    final order = ref.watch(taskOrderProvider);
    final l = L.of(context);

    Future<void> refresh() async {
      await ref.read(hubWatcherProvider.notifier).checkNow();
      await ref.read(outboxProvider.notifier).flush();
      await ref.read(hubSyncProvider.notifier).syncNow();
      ref.invalidate(allPendingTasksProvider);
      await ref.read(allPendingTasksProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.pendingTitle),
        actions: [
          const TaskSortButton(),
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
          const TaskFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: _list(context, ref, tasks, queued, filter, order),
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
                  : _TaskTile(task: shown[i - queued.length]),
            );
          },
        ),
      AsyncError(:final error) => _Scrollable(
          child: HubErrorView(
            error: error,
            onRetry: () => ref.invalidate(allPendingTasksProvider),
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
  const _TaskTile({required this.task});

  final TaskSummary task;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        switch (task.status) {
          TaskStatus.waiting => Icons.pan_tool_outlined,
          TaskStatus.active => Icons.play_circle_outline,
          _ => Icons.fiber_new_outlined,
        },
        color: task.status.needsUser
            ? Theme.of(context).colorScheme.tertiary
            : null,
      ),
      title: Text(task.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatTaskDate(task.date) ?? task.fileName),
          TaskTagRow(task: task),
        ],
      ),
      isThreeLine: true,
      trailing: TaskStatusChip(status: task.status),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskDetailScreen(summary: task),
        ),
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

/// Bekleyenler listesinin filtre çubuğu: repo, öncelik, kategori.
///
/// Seçenekler sabit değil, **listede gerçekten geçen** değerlerden türer —
/// hiç kullanılmayan bir kategoriyi filtre olarak sunmak, boş sonuç vaat
/// etmek olurdu. Tek repo varken repo satırı hiç görünmez.
class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({super.key});

  static const barKey = Key('task-filter-bar');
  static const clearKey = Key('task-filter-clear');
  static Key chipKey(String kind, String value) =>
      Key('task-filter-$kind-$value');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facets = ref.watch(taskFacetsProvider);
    final filter = ref.watch(taskFilterProvider);
    if (!facets.hasAnything) return const SizedBox.shrink();

    final notifier = ref.read(taskFilterProvider.notifier);
    final theme = Theme.of(context);

    return Container(
      key: barKey,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (filter.activeCount > 0) ...[
              ActionChip(
                key: clearKey,
                avatar: const Icon(Icons.close, size: 16),
                label: Text(L.of(context).filterClear),
                onPressed: notifier.clear,
              ),
              const SizedBox(width: 12),
            ],
            for (final entry in facets.repos.entries)
              if (facets.repos.length > 1)
                _Chip(
                  key: TaskFilterBar.chipKey('repo', entry.key),
                  label: entry.value,
                  icon: Icons.folder_outlined,
                  selected: filter.repos.contains(entry.key),
                  onTap: () => notifier.toggle(repo: entry.key),
                ),
            for (final priority in facets.priorities)
              _Chip(
                key: TaskFilterBar.chipKey('priority', priority),
                label: priority,
                icon: Icons.flag_outlined,
                selected: filter.priorities.contains(priority),
                onTap: () => notifier.toggle(priority: priority),
              ),
            for (final category in facets.categories)
              _Chip(
                key: TaskFilterBar.chipKey('category', category),
                label: category,
                icon: Icons.label_outline,
                selected: filter.categories.contains(category),
                onTap: () => notifier.toggle(category: category),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          avatar: Icon(icon, size: 16),
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          visualDensity: VisualDensity.compact,
        ),
      );
}

/// Görev satırındaki etiketler: repo · öncelik · kategori.
///
/// Öncelik ve kategori yalnız cihazdaki kopyadan okunabildiği için (B-057)
/// null olabilirler; o durumda etiket hiç çizilmez — boş bir rozet
/// göstermek "bilgi yok"u "değer yok" gibi gösterirdi.
class TaskTagRow extends StatelessWidget {
  const TaskTagRow({super.key, required this.task, this.showRepo = true});

  final TaskSummary task;
  final bool showRepo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final tags = <(String, Color)>[
      if (showRepo && task.repoName.isNotEmpty)
        (task.repoName, colors.surfaceContainerHighest),
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

/// Sıralama seçici (T-013).
///
/// Menü, çip şeridine değil **başlığa** kondu: filtre çipleri "neyi
/// göster"i, sıralama "hangi sırayla"yı anlatıyor ve ikisi aynı şeritte
/// olunca seçili bir sıralama çipi filtreymiş gibi okunuyordu.
class TaskSortButton extends ConsumerWidget {
  const TaskSortButton({super.key});

  static const buttonKey = Key('task-sort-button');
  static Key itemKey(TaskSort sort) => Key('task-sort-${sort.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final order = ref.watch(taskOrderProvider);

    String label(TaskSort sort) {
      final base = switch (sort) {
        TaskSort.waitingFirst => l.sortWaitingFirst,
        TaskSort.date => l.sortByDate,
        TaskSort.priority => l.sortByPriority,
      };
      // Yön yalnız **seçili** ölçütte yazılıyor: seçili olmayanın yönünü
      // göstermek, dokunmadan önce ne olacağını yanlış vaat ederdi (ikinci
      // dokunuş yönü çevirir).
      if (!sort.hasDirection || sort != order.sort) return base;
      return '$base · ${order.ascending ? l.sortAscending : l.sortDescending}';
    }

    return PopupMenuButton<TaskSort>(
      key: buttonKey,
      tooltip: l.sortTooltip,
      icon: Icon(order.isDefault ? Icons.sort : Icons.sort_rounded,
          color: order.isDefault ? null : Theme.of(context).colorScheme.primary),
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
    );
  }
}
