import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../github/client.dart';
import '../../hub/hub_config.dart';
import '../../hub/hub_language.dart';
import '../../hub/hub_connections.dart';
import '../../hub/hub_sync.dart';
import '../../hub/hub_watcher.dart';
import '../../hub/outbox.dart';
import '../../hub/settings.dart';
import '../../l10n/app_localizations.dart';
import '../common/hub_error_view.dart';
import 'backup_screen.dart';
import 'connections_screen.dart';

/// Ayarlar (B-051): bağlantı, yoklama aralığı, önbellek, durum.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const reposKey = Key('settings-repos');
  static const backupKey = Key('settings-backup');
  static const offlineKey = Key('settings-offline');
  static const syncNowKey = Key('settings-sync-now');
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
    final sync = ref.watch(hubSyncProvider);
    final l = L.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          _SectionTitle(l.settingsLanguage),
          const _LanguageTile(),
          const Divider(),
          _SectionTitle(l.secConnection),
          ListTile(
            key: reposKey,
            leading: const Icon(Icons.folder_copy_outlined),
            title: Text(l.repos),
            subtitle: Text(
              connectionCount <= 1
                  ? (config?.displayName ?? '—')
                  : l.reposSubtitle(config?.displayName ?? '—', connectionCount),
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
            title: Text(l.statusTitle),
            subtitle: Text(_statusText(l, status)),
          ),
          const Divider(),
          _SectionTitle(l.secPolling),
          ListTile(
            key: intervalKey,
            leading: const Icon(Icons.timer_outlined),
            title: Text(l.pollIntervalTitle),
            trailing: DropdownButton<Duration>(
              value: interval,
              underline: const SizedBox.shrink(),
              items: [
                for (final choice in AppSettings.intervalChoices)
                  DropdownMenuItem(
                    value: choice,
                    child: Text(_intervalLabel(l, choice)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(appSettingsProvider.notifier).setPollInterval(value);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l.pollIntervalHelp,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          ListTile(
            key: backupKey,
            leading: const Icon(Icons.shield_outlined),
            title: Text(l.backup),
            subtitle: Text(l.backupSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
            ),
          ),
          const Divider(),
          _SectionTitle(l.secOffline),
          ListTile(
            key: offlineKey,
            leading: Icon(
              sync.syncing
                  ? Icons.cloud_download_outlined
                  : (sync.hasOfflineCopy
                      ? Icons.offline_pin_outlined
                      : Icons.cloud_off_outlined),
            ),
            title: Text(l.offlineCopyTitle),
            subtitle: Text(_offlineText(l, sync)),
            trailing: sync.syncing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    key: syncNowKey,
                    onPressed: () => ref.read(hubSyncProvider.notifier).syncNow(),
                    child: Text(l.downloadNow),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l.offlineHelp, style: const TextStyle(fontSize: 12)),
          ),
          const Divider(),
          _SectionTitle(l.secData),
          if (queued.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(l.queuedTasks(queued.length)),
              subtitle: Text(l.outboxQueuedSubtitle),
              trailing: TextButton(
                onPressed: () => ref.read(outboxProvider.notifier).flush(),
                child: Text(l.trySendNow),
              ),
            ),
          ListTile(
            key: clearCacheKey,
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text(l.clearCache),
            subtitle: Text(l.clearCacheSubtitle),
            onTap: () async {
              ref.read(etagCacheProvider).clear();
              // Yerel kopya da gitmeli: yalnız ETag önbelleği silinseydi
              // tarayıcı eski kopyayı göstermeye devam eder ve "temizledim
              // ama değişmedi" denirdi.
              await ref.read(hubSyncProvider.notifier).clearOfflineCopy();
              ref.invalidate(hubWatcherProvider);
              unawaited(ref.read(hubSyncProvider.notifier).syncNow());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.cacheCleared)),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            key: resetKey,
            leading: const Icon(Icons.logout),
            title: Text(
              connectionCount <= 1
                  ? l.resetConnection
                  : l.resetAllConnections,
            ),
            subtitle: Text(
              connectionCount <= 1
                  ? l.resetSubtitleOne
                  : l.resetSubtitleAll(connectionCount),
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
    final l = L.of(context);
    final scope = connectionCount <= 1
        ? l.resetScopeOne
        : l.resetScopeAll(connectionCount);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          connectionCount <= 1
              ? l.resetConfirmOne
              : l.resetConfirmAll,
        ),
        content: Text(
          queuedCount == 0
              ? l.resetBody(scope)
              : l.resetBodyQueued(scope, queuedCount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.reset),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(hubConfigProvider.notifier).clear();
    }
  }

  static String _offlineText(L l, SyncStatus sync) {
    if (sync.syncing) {
      return sync.total == 0
          ? l.syncChecking
          : l.syncDownloading(sync.done, sync.total);
    }
    if (!sync.hasOfflineCopy) {
      return sync.error == null
          ? l.syncNever
          : l.syncFailed(describeHubError(sync.error!, l).headline);
    }

    final base = l.syncDocsDownloaded(sync.docCount);
    if (sync.syncedAt == null) return base;

    final ago = DateTime.now().difference(sync.syncedAt!);
    if (ago.inMinutes < 1) return l.syncJustNow(base);
    if (ago.inHours < 1) return l.syncMinutes(base, ago.inMinutes);
    if (ago.inDays < 1) return l.syncHours(base, ago.inHours);
    return l.syncDays(base, ago.inDays);
  }

  static String _statusText(L l, HubStatus status) {
    if (status.error != null) return describeHubError(status.error!, l).headline;
    if (status.lastCheckedAt == null) return l.watchNever;

    final ago = DateTime.now().difference(status.lastCheckedAt!);
    if (ago.inMinutes < 1) return l.watchJustNow;
    if (ago.inHours < 1) return l.watchMinutes(ago.inMinutes);
    return l.watchHours(ago.inHours);
  }

  static String _intervalLabel(L l, Duration interval) =>
      interval.inSeconds < 60
          ? l.intervalSeconds(interval.inSeconds)
          : l.intervalMinutes(interval.inMinutes);
}

/// Hub dilini **gösterir** (sözleşme 1.19) — bir tercih değil.
///
/// Dil hub'ın özelliği: `SYSTEM.md`'de yazılı ve arayüz, sözleşme, yeni
/// kayıtlar onu izliyor. Uygulama bunu değiştiremez çünkü `SYSTEM.md`'ye
/// yazamaz (R-001: yazma alanı `tasks/inbox/` ve `notes/`) — dili kurulumda
/// agent belirler.
///
/// Yine de **görünür** olmalı: görünmeyen bir ayar, kullanıcının neden o dili
/// gördüğünü açıklayamaz ve yanlışsa düzeltilecek yeri de göstermez (L-040).
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  static const tileKey = Key('settings-language');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final language = ref.watch(activeHubLanguageProvider).valueOrNull;

    return ListTile(
      key: tileKey,
      leading: const Icon(Icons.translate),
      title: Text(l.settingsLanguage),
      subtitle: Text(l.languageFromHub),
      isThreeLine: true,
      trailing: Text(
        switch (language) {
          HubLanguage.tr => l.langTurkish,
          HubLanguage.en => l.langEnglish,
          null => '—',
        },
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
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
