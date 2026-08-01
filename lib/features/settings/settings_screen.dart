import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../github/client.dart';
import '../../hub/hub_config.dart';
import '../../hub/hub_connections.dart';
import '../../hub/hub_watcher.dart';
import '../../hub/outbox.dart';
import '../../hub/settings.dart';
import '../common/hub_error_view.dart';
import 'backup_screen.dart';
import 'connections_screen.dart';

/// Ayarlar (B-051): bağlantı, yoklama aralığı, önbellek, durum.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const reposKey = Key('settings-repos');
  static const backupKey = Key('settings-backup');
  static const intervalKey = Key('settings-poll-interval');
  static const clearCacheKey = Key('settings-clear-cache');
  static const resetKey = Key('settings-reset');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(hubConfigProvider).value;
    final status = ref.watch(hubWatcherProvider);
    final interval = ref.watch(appSettingsProvider).pollInterval;
    final queued = ref.watch(outboxProvider).valueOrNull ?? const [];
    final connectionCount =
        ref.watch(hubConnectionsProvider).valueOrNull?.length ?? 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          const _SectionTitle('Bağlantı'),
          ListTile(
            key: reposKey,
            leading: const Icon(Icons.folder_copy_outlined),
            title: const Text('Repolar'),
            subtitle: Text(
              connectionCount <= 1
                  ? (config?.displayName ?? '—')
                  : '${config?.displayName ?? '—'} · $connectionCount repo kayıtlı',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ConnectionsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              status.error == null
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off,
            ),
            title: const Text('Durum'),
            subtitle: Text(_statusText(status)),
          ),
          const Divider(),
          const _SectionTitle('Yoklama'),
          ListTile(
            key: intervalKey,
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Kontrol aralığı'),
            trailing: DropdownButton<Duration>(
              value: interval,
              underline: const SizedBox.shrink(),
              items: [
                for (final choice in AppSettings.intervalChoices)
                  DropdownMenuItem(
                    value: choice,
                    child: Text(_intervalLabel(choice)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(appSettingsProvider.notifier).setPollInterval(value);
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Değişiklik yokken kontroller GitHub istek limitinden düşmez, '
              'bu yüzden sık yoklamanın maliyeti yalnız batarya.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          ListTile(
            key: backupKey,
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Yedekleme'),
            subtitle: const Text(
              'Bağlantıları parolayla şifreli tek metne çevir / geri yükle',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
            ),
          ),
          const Divider(),
          const _SectionTitle('Veri'),
          if (queued.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text('${queued.length} görev kuyrukta'),
              subtitle: const Text('Bağlantı gelince gönderilecek'),
              trailing: TextButton(
                onPressed: () => ref.read(outboxProvider.notifier).flush(),
                child: const Text('Şimdi dene'),
              ),
            ),
          ListTile(
            key: clearCacheKey,
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Önbelleği temizle'),
            subtitle: const Text('Her şey hub\'dan yeniden indirilir'),
            onTap: () {
              ref.read(etagCacheProvider).clear();
              ref.invalidate(hubWatcherProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Önbellek temizlendi.')),
              );
            },
          ),
          const Divider(),
          ListTile(
            key: resetKey,
            leading: const Icon(Icons.logout),
            title: Text(
              connectionCount <= 1
                  ? 'Bağlantıyı sıfırla'
                  : 'Tüm bağlantıları sıfırla',
            ),
            subtitle: Text(
              connectionCount <= 1
                  ? 'Token silinir, onboarding\'e dönülür'
                  : '$connectionCount reponun token\'ı silinir, onboarding\'e dönülür',
            ),
            onTap: () =>
                _confirmReset(context, ref, queued.length, connectionCount),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    WidgetRef ref,
    int queuedCount,
    int connectionCount,
  ) async {
    final scope = connectionCount <= 1
        ? 'Token cihazdan silinir'
        : '$connectionCount reponun token\'ı cihazdan silinir';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          connectionCount <= 1
              ? 'Bağlantı sıfırlansın mı?'
              : 'Bütün bağlantılar sıfırlansın mı?',
        ),
        content: Text(
          queuedCount == 0
              ? '$scope ve onboarding ekranına dönersin.'
              : '$scope. Kuyrukta bekleyen $queuedCount görev '
                  'gönderilemeden kalır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(hubConfigProvider.notifier).clear();
    }
  }

  static String _statusText(HubStatus status) {
    if (status.error != null) return describeHubError(status.error!).headline;
    if (status.lastCheckedAt == null) return 'Henüz kontrol edilmedi';

    final ago = DateTime.now().difference(status.lastCheckedAt!);
    if (ago.inMinutes < 1) return 'Az önce kontrol edildi';
    if (ago.inHours < 1) return '${ago.inMinutes} dakika önce kontrol edildi';
    return '${ago.inHours} saat önce kontrol edildi';
  }

  static String _intervalLabel(Duration interval) => interval.inSeconds < 60
      ? '${interval.inSeconds} saniye'
      : '${interval.inMinutes} dakika';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}
