import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/hub_watcher.dart';
import '../../hub/models/task.dart';
import '../../hub/task_repo.dart';
import '../common/hub_error_view.dart';
import 'pending_screen.dart' show TaskStatusChip, formatTaskDate;
import 'task_detail_screen.dart';

/// Tamamlanan görevler: `tasks/done` (SYSTEM.md §9).
///
/// Sözleşme done'daki dosyaların silinmemesini şart koşuyor (R-004), yani bu
/// liste geçmişin tamamıdır; en yeni üstte.
class DoneScreen extends ConsumerWidget {
  const DoneScreen({super.key});

  static const listKey = Key('done-list');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(doneTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tamamlananlar')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(hubWatcherProvider.notifier).checkNow();
        },
        child: switch (tasks) {
          AsyncData(:final value) when value.isEmpty => const _Scrollable(
              child: HubEmptyView(
                icon: Icons.task_alt,
                title: 'Tamamlanan görev yok',
                subtitle: 'Agent bir görevi bitirince burada arşivlenir.',
              ),
            ),
          AsyncData(:final value) => ListView.separated(
              key: listKey,
              itemCount: value.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _DoneTile(task: value[i]),
            ),
          AsyncError(:final error) => _Scrollable(
              child: HubErrorView(
                error: error,
                onRetry: () => ref.invalidate(doneTasksProvider),
              ),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _DoneTile extends StatelessWidget {
  const _DoneTile({required this.task});

  final TaskSummary task;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(task.title),
        subtitle: Text(formatTaskDate(task.date) ?? task.fileName),
        trailing: const TaskStatusChip(status: TaskStatus.done),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskDetailScreen(summary: task),
          ),
        ),
      );
}

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
