import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../hub/models/task.dart';
import '../../hub/models/task_draft.dart';
import '../../hub/outbox.dart';
import '../../hub/task_repo.dart';
import '../common/annotated_document.dart';
import '../common/hub_error_view.dart';
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
        AsyncData(:final value) => _TaskBody(task: value, summary: summary),
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
  const _TaskBody({required this.task, required this.summary});

  final HubTask task;
  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (task.status.needsUser) ...[
          _WaitingBanner(task: task, summary: summary),
          const SizedBox(height: 16),
        ],
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
        AnnotatedDocument(
          data: task.body,
          sourcePath: task.path,
          padding: const EdgeInsets.only(top: 8),
        ),
      ],
    );
  }
}

/// `waiting/`teki görevin üstündeki şerit: ne beklendiğini söyler ve
/// "Yaptım" düğmesini taşır (sözleşme 1.4).
class _WaitingBanner extends ConsumerStatefulWidget {
  const _WaitingBanner({required this.task, required this.summary});

  final HubTask task;
  final TaskSummary summary;

  @override
  ConsumerState<_WaitingBanner> createState() => _WaitingBannerState();
}

class _WaitingBannerState extends ConsumerState<_WaitingBanner> {
  static const doneButtonKey = Key('waiting-done-button');

  bool _busy = false;
  String? _error;
  bool _reported = false;

  Future<void> _report() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final draft = TaskDraft.waitingDone(widget.task);
    try {
      await ref.read(taskRepoProvider).send(draft);
      _finish('Agent\'a bildirildi.');
    } on HubNetworkError {
      // Ağ yokken bildirim kaybolmasın: normal görevlerle aynı kuyruk (B-032).
      await ref.read(outboxProvider.notifier).add(draft);
      _finish('Ağ yok — bildirim kuyruğa alındı.');
    } on HubError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish(String message) {
    ref.invalidate(pendingTasksProvider);
    if (!mounted) return;
    setState(() => _reported = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.pan_tool_outlined,
                  size: 20, color: colors.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu iş seni bekliyor. Ne beklendiği aşağıdaki notlarda '
                  'yazılı; yaptıktan sonra agent\'a haber ver.',
                  style: TextStyle(color: colors.onTertiaryContainer),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: doneButtonKey,
              // Bir kez bildirildikten sonra düğme kapanır: aynı iş için
              // ikinci bildirim, agent'ın kuyruğunda kopya demek olurdu.
              onPressed: (_busy || _reported) ? null : _report,
              icon: Icon(_reported ? Icons.check : Icons.done),
              label: Text(_reported ? 'Bildirildi' : 'Yaptım'),
            ),
          ),
        ],
      ),
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
