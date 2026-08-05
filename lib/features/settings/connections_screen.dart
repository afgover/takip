import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../hub/annotations.dart';
import '../../hub/hub_config.dart';
import '../../hub/hub_connections.dart';
import '../../hub/outbox.dart';
import '../common/repo_switcher.dart';
import 'connection_screen.dart';

/// Kayıtlı repoların listesi: geçiş, düzenleme, silme, ekleme (T-003).
class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  static const addKey = Key('connections-add');
  static Key removeKey(String slug) => Key('connections-remove-$slug');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(hubConnectionsProvider).valueOrNull ?? const HubConnectionsState();
    final activeSlug = state.active?.slug;
    final queued = ref.watch(outboxProvider).valueOrNull ?? const [];
    final versions =
        ref.watch(contractVersionsProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('Repolar')),
      body: ListView(
        children: [
          for (final connection in state.connections)
            ListTile(
              leading: Icon(
                connection.slug == activeSlug
                    ? Icons.check_circle
                    : Icons.circle_outlined,
              ),
              title: Text(connection.displayName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(connection.slug),
                  _IdentityLine(login: connection.login),
                  _ContractLine(version: versions[connection.slug]),
                ],
              ),
              isThreeLine: true,
              onTap: connection.slug == activeSlug
                  ? null
                  : () => switchToRepo(ref, connection.slug),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Düzenle',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ConnectionScreen(
                          mode: ConnectionMode.edit,
                          initial: connection,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: removeKey(connection.slug),
                    tooltip: 'Kaldır',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmRemove(
                      context,
                      ref,
                      connection,
                      queued
                          .where((d) => (d.repoSlug ?? activeSlug) == connection.slug)
                          .length,
                      isLast: state.length == 1,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          ListTile(
            key: addKey,
            leading: const Icon(Icons.add),
            title: const Text('Repo ekle'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ConnectionScreen(mode: ConnectionMode.add),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              'Her repo kendi token\'ıyla saklanır. Bir token yalnızca kendi '
              'reposunu kapsamalı — tek token\'ı bütün repolara yetkilendirmek, '
              'telefonu kaybettiğinde kaybın büyümesi demektir.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    HubConfig connection,
    int queuedCount, {
    required bool isLast,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${connection.displayName} kaldırılsın mı?'),
        content: Text(
          [
            'Bu reponun token\'ı cihazdan silinir.',
            if (queuedCount > 0)
              'Kuyrukta bu repoya ait $queuedCount görev var; '
                  'repo kaldırılırsa gönderilemezler.',
            if (isLast) 'Bu son repo — kaldırırsan onboarding ekranına dönersin.',
          ].join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(hubConnectionsProvider.notifier).remove(connection.slug);
      messenger.showSnackBar(
        SnackBar(content: Text('${connection.displayName} kaldırıldı.')),
      );
    }
  }
}

/// Bağlantının sözleşme sürümü ve ana kopyaya göre durumu (§10).
///
/// Geriden gelen bir hub, agent fark etmese bile burada görünür — sözleşme
/// 1.3'te kalmış bir repo, 1.4'te gelen `waiting/` klasörünü tanımıyor
/// demektir ve bu sessizce yanlış davranmaya yol açar (L-020).
/// Bu bağlantıda kayıtların hangi kimlikle yazıldığı (sözleşme 1.15).
///
/// Görünür olması şart: kimlik `author` alanına sessizce yazılıyor ve
/// görünmezse kullanıcı ne çalıştığını ne de çalışmadığını anlayabilir —
/// L-039'un aynı kalıbı. Boşsa ne yapılacağını da söylüyor.
class _IdentityLine extends StatelessWidget {
  const _IdentityLine({required this.login});

  static const emptyText = 'Kimlik yok — Düzenle\'den yazabilirsin';

  final String? login;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final known = login != null && login!.trim().isNotEmpty;

    return Row(
      children: [
        Icon(
          known ? Icons.person_outline : Icons.person_off_outlined,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            known ? login! : emptyText,
            style: theme.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ContractLine extends StatelessWidget {
  const _ContractLine({required this.version});

  final String? version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (version == null) {
      return Text(
        'Sözleşme sürümü okunamadı',
        style: theme.textTheme.labelSmall,
      );
    }

    final stale = isContractStale(version!);
    return Row(
      children: [
        Icon(
          stale ? Icons.warning_amber_outlined : Icons.verified_outlined,
          size: 14,
          color: stale ? theme.colorScheme.error : theme.colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            stale
                ? 'Sözleşme $version — ana kopya ${Hub.contractVersion}, '
                    'agent güncellemeli'
                : 'Sözleşme $version',
            style: theme.textTheme.labelSmall?.copyWith(
              color: stale ? theme.colorScheme.error : null,
            ),
          ),
        ),
      ],
    );
  }
}
