import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../github/client.dart';
import '../../hub/hub_config.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          _SectionTitle(L.of(context).settingsLanguage),
          const _LanguageTile(),
          const Divider(),
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
          const _SectionTitle('Çevrimdışı'),
          ListTile(
            key: offlineKey,
            leading: Icon(
              sync.syncing
                  ? Icons.cloud_download_outlined
                  : (sync.hasOfflineCopy
                      ? Icons.offline_pin_outlined
                      : Icons.cloud_off_outlined),
            ),
            title: const Text('Cihazdaki kopya'),
            subtitle: Text(_offlineText(sync)),
            trailing: sync.syncing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    key: syncNowKey,
                    onPressed: () => ref.read(hubSyncProvider.notifier).syncNow(),
                    child: const Text('Şimdi indir'),
                  ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Tarayıcıdaki her şey cihaza indirilir ve hub değiştikçe '
              'kendiliğinden güncellenir; ağ yokken de açılır. Yalnızca '
              'değişen dosyalar indirilir.',
              style: TextStyle(fontSize: 12),
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
            subtitle: const Text('Cihazdaki kopya dahil, her şey yeniden iner'),
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
                  const SnackBar(content: Text('Temizlendi, yeniden indiriliyor.')),
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

  static String _offlineText(SyncStatus sync) {
    if (sync.syncing) {
      return sync.total == 0
          ? 'Değişiklik aranıyor…'
          : '${sync.done}/${sync.total} belge indiriliyor…';
    }
    if (!sync.hasOfflineCopy) {
      return sync.error == null
          ? 'Henüz indirilmedi'
          : 'İndirilemedi — ${describeHubError(sync.error!).headline}';
    }

    final base = '${sync.docCount} belge indirildi';
    if (sync.syncedAt == null) return base;

    final ago = DateTime.now().difference(sync.syncedAt!);
    if (ago.inMinutes < 1) return '$base · az önce güncellendi';
    if (ago.inHours < 1) return '$base · ${ago.inMinutes} dakika önce';
    if (ago.inDays < 1) return '$base · ${ago.inHours} saat önce';
    return '$base · ${ago.inDays} gün önce';
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

/// Arayüz dili seçici (sözleşme 1.18).
///
/// Varsayılan **sistem dili**: cihazı Türkçe olan kullanıcı hiçbir şey
/// değiştirmeden Türkçe görür, başkası İngilizce. Seçim yalnız arayüzü
/// etkiliyor; hub'a yazılan görev ve notların biçimi sözleşmeyle sabit ve
/// dile göre değişmiyor — değişselerdi mevcut kayıtlar ayrıştırılamaz olurdu.
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  static const tileKey = Key('settings-language');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final code = ref.watch(appSettingsProvider.select((s) => s.localeCode));

    String label(String? c) => switch (c) {
          'tr' => l.langTurkish,
          'en' => l.langEnglish,
          _ => l.langSystem,
        };

    return ListTile(
      key: tileKey,
      leading: const Icon(Icons.translate),
      title: Text(l.settingsLanguage),
      subtitle: Text(l.settingsLanguageHelp),
      isThreeLine: true,
      trailing: DropdownButton<String?>(
        value: code,
        items: [
          for (final c in <String?>[null, 'tr', 'en'])
            DropdownMenuItem(
              key: Key('settings-language-${c ?? "system"}'),
              value: c,
              child: Text(label(c)),
            ),
        ],
        onChanged: (value) =>
            ref.read(appSettingsProvider.notifier).setLocale(value),
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
