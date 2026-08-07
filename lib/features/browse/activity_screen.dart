import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../github/commits_api.dart';
import '../../hub/hub_watcher.dart';
import '../../hub/models/activity.dart';
import '../common/hub_error_view.dart';
import '../../l10n/app_localizations.dart';

/// Aktivite akışı (B-045): commit geçmişi, sözleşmenin §8 öneklerine göre
/// insan diline çevrilmiş.
///
/// K-012'den beri kod ve hub aynı repoda olduğu için akışta uygulama
/// commit'leri de var. Varsayılan görünüm yalnız hub kayıtları; kod
/// commit'leri isteğe bağlı açılır.
final activityProvider = FutureProvider<List<ActivityEntry>>((ref) async {
  ref.watch(hubWatcherProvider.select((s) => s.headSha));
  final commits = await ref.watch(commitsApiProvider).recent();
  return commits
      .map((c) => ActivityEntry.fromCommit(
            message: c.message,
            sha: c.sha,
            date: c.date,
          ))
      .toList();
});

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  static const listKey = Key('activity-list');
  static const codeToggleKey = Key('activity-code-toggle');

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  bool _showCode = false;

  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(activityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivite'),
        actions: [
          IconButton(
            key: ActivityScreen.codeToggleKey,
            tooltip: _showCode
                ? L.of(context).activityHubOnly
                : L.of(context).activityShowCode,
            icon: Icon(_showCode ? Icons.code_off : Icons.code),
            onPressed: () => setState(() => _showCode = !_showCode),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(hubWatcherProvider.notifier).checkNow();
        },
        child: switch (activity) {
          AsyncData(:final value) => _list(value),
          AsyncError(:final error) => HubErrorView(
              error: error,
              onRetry: () => ref.invalidate(activityProvider),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _list(List<ActivityEntry> all) {
    final visible =
        _showCode ? all : all.where((e) => e.kind.isHubRecord).toList();

    if (visible.isEmpty) {
      return HubEmptyView(
        icon: Icons.history,
        title: L.of(context).activityEmptyTitle,
        subtitle: L.of(context).activityEmptySubtitle,
      );
    }

    return ListView.separated(
      key: ActivityScreen.listKey,
      itemCount: visible.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _ActivityTile(entry: visible[i]),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry});

  final ActivityEntry entry;

  static const _icons = {
    ActivityKind.task: Icons.check_circle_outline,
    ActivityKind.session: Icons.forum_outlined,
    ActivityKind.artifact: Icons.description_outlined,
    ActivityKind.backlog: Icons.checklist,
    ActivityKind.evolution: Icons.timeline,
    ActivityKind.knowledge: Icons.school_outlined,
    ActivityKind.note: Icons.sticky_note_2_outlined,
    ActivityKind.security: Icons.shield_outlined,
    ActivityKind.system: Icons.gavel,
    ActivityKind.code: Icons.code,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = [
      entry.kind.label,
      if (entry.date != null) _formatTime(entry.date!),
    ];

    return ListTile(
      leading: Icon(
        _icons[entry.kind],
        color: entry.kind.isHubRecord
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
      ),
      title: Text(entry.text),
      subtitle: Text(parts.join(' · ')),
      dense: true,
    );
  }

  static String _formatTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
