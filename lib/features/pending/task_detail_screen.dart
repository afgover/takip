import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/models/task.dart';
import '../../hub/task_repo.dart';
import '../common/hub_error_view.dart';
import '../common/hub_markdown.dart';
import 'pending_screen.dart' show TaskStatusChip;

/// Görev detayı — dosya ancak bu ekran açılınca indirilir (B-031).
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskDetailProvider(summary));

    return Scaffold(
      appBar: AppBar(
        title: Text(task.valueOrNull?.title.isNotEmpty == true
            ? task.valueOrNull!.title
            : summary.title),
      ),
      body: switch (task) {
        AsyncData(:final value) => _TaskBody(task: value),
        AsyncError(:final error) => HubErrorView(
            error: error,
            onRetry: () => ref.invalidate(taskDetailProvider(summary)),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TaskBody extends StatelessWidget {
  const _TaskBody({required this.task});

  final HubTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TaskStatusChip(status: task.status),
            _MetaChip(icon: Icons.label_outline, text: task.category),
            _MetaChip(icon: Icons.flag_outlined, text: task.priority),
            // Agent henüz ID atamadıysa görev hub'a yeni düşmüş demektir.
            if (!task.isPending)
              _MetaChip(icon: Icons.tag, text: task.id)
            else
              const _MetaChip(
                icon: Icons.schedule,
                text: 'agent henüz ele almadı',
              ),
            for (final tag in task.tags)
              _MetaChip(icon: Icons.sell_outlined, text: tag),
          ],
        ),
        if (task.hasResult) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 20, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.result,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Divider(),
        HubMarkdown(task.body, padding: const EdgeInsets.only(top: 8)),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
