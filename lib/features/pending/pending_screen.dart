import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/hub_watcher.dart';
import '../../hub/models/task.dart';
import '../../hub/task_repo.dart';
import '../common/hub_error_view.dart';
import 'task_detail_screen.dart';

/// Bekleyen görevler: `tasks/inbox` + `tasks/active`.
///
/// Liste klasör listelemesiyle çizilir, dosyalar indirilmez (B-031); içerik
/// ancak detaya girilince çekilir. Yoklama hub'da değişiklik görürse liste
/// kendiliğinden tazelenir (B-024).
///
/// TODO(B-032): outbox'taki "gönderilecek" görevler en üstte.
class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  static const listKey = Key('pending-list');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(pendingTasksProvider);
    final status = ref.watch(hubWatcherProvider);

    Future<void> refresh() async {
      await ref.read(hubWatcherProvider.notifier).checkNow();
      ref.invalidate(pendingTasksProvider);
      await ref.read(pendingTasksProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bekleyenler'),
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
              tooltip: 'Yenile',
              icon: const Icon(Icons.refresh),
              onPressed: refresh,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: switch (tasks) {
          AsyncData(:final value) when value.isEmpty => const _Scrollable(
              child: HubEmptyView(
                icon: Icons.inbox_outlined,
                title: 'Bekleyen görev yok',
                subtitle: 'Eklediğin görevler agent ele alana kadar burada '
                    'görünür.',
              ),
            ),
          AsyncData(:final value) => ListView.separated(
              key: listKey,
              itemCount: value.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _TaskTile(task: value[i]),
            ),
          AsyncError(:final error) => _Scrollable(
              child: HubErrorView(
                error: error,
                onRetry: () => ref.invalidate(pendingTasksProvider),
              ),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
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
        task.status == TaskStatus.active
            ? Icons.play_circle_outline
            : Icons.fiber_new_outlined,
      ),
      title: Text(task.title),
      subtitle: Text(formatTaskDate(task.date) ?? task.fileName),
      trailing: TaskStatusChip(status: task.status),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskDetailScreen(summary: task),
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
