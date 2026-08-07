import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/hub_config.dart';
import '../../hub/hub_connections.dart';
import '../../hub/hub_watcher.dart';
import '../../hub/outbox.dart';
import '../settings/connection_screen.dart';
import '../settings/connections_screen.dart';
import '../../l10n/app_localizations.dart';

/// Aktif repoyu gösteren ve değiştiren şerit (T-003).
///
/// Tek repo varken de görünür: hem "hangi projedeyim" sorusunu her ekranda
/// cevaplar, hem ikinci repoyu eklemenin keşfedilir yolu olur. Ayarların
/// içine gömülseydi, çoklu repo özelliği varlığı bilinmeyen bir özellik olurdu.
class RepoSwitcher extends ConsumerWidget {
  const RepoSwitcher({super.key});

  static const barKey = Key('repo-switcher-bar');
  static const sheetKey = Key('repo-switcher-sheet');
  static Key tileKey(String slug) => Key('repo-switcher-tile-$slug');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(hubConfigProvider).value;
    if (active == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final count =
        ref.watch(hubConnectionsProvider).valueOrNull?.length ?? 1;

    return Material(
      color: colors.surfaceContainerHighest,
      child: InkWell(
        key: barKey,
        onTap: () => _openSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.folder_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  active.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (count > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '$count repo',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              Icon(Icons.unfold_more, size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => const _RepoSheet(key: sheetKey),
    );
  }
}

class _RepoSheet extends ConsumerWidget {
  const _RepoSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(hubConnectionsProvider).valueOrNull ?? const HubConnectionsState();
    final activeSlug = state.active?.slug;
    final queued = ref.watch(outboxProvider).valueOrNull ?? const [];

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Repolar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final connection in state.connections)
            _RepoTile(
              connection: connection,
              isActive: connection.slug == activeSlug,
              // Kuyruktaki iş repo başına sayılır; kullanıcı hangi projede
              // bekleyen gönderim olduğunu görür.
              queuedCount: queued
                  .where((d) => (d.repoSlug ?? activeSlug) == connection.slug)
                  .length,
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Repo ekle'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ConnectionScreen(mode: ConnectionMode.add),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(L.of(context).manageRepos),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ConnectionsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RepoTile extends ConsumerWidget {
  const _RepoTile({
    required this.connection,
    required this.isActive,
    required this.queuedCount,
  });

  final HubConfig connection;
  final bool isActive;
  final int queuedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: RepoSwitcher.tileKey(connection.slug),
      selected: isActive,
      leading: Icon(isActive ? Icons.check_circle : Icons.circle_outlined),
      title: Text(connection.displayName),
      subtitle: connection.displayName == connection.slug
          ? (queuedCount > 0
              ? Text(L.of(context).queuedTasks(queuedCount))
              : null)
          : Text(
              queuedCount > 0
                  ? L.of(context)
                      .queuedTasksWithSlug(connection.slug, queuedCount)
                  : connection.slug,
            ),
      onTap: isActive
          ? () => Navigator.of(context).pop()
          : () async {
              Navigator.of(context).pop();
              await switchToRepo(ref, connection.slug);
            },
    );
  }
}

/// Aktif repoyu değiştirir ve yoklamayı hemen tetikler.
///
/// Listeler kendiliğinden tazelenir: `contentsApiProvider` aktif bağlantıyı
/// izlediği için görev sağlayıcıları zaten yeniden kurulur. Yoklamayı elle
/// tetiklemek yalnızca durum şeridinin geç kalmamasını sağlar.
Future<void> switchToRepo(WidgetRef ref, String slug) async {
  await ref.read(hubConnectionsProvider.notifier).setActive(slug);
  ref.read(hubWatcherProvider.notifier).start();
  unawaited(ref.read(hubWatcherProvider.notifier).checkNow());
}
