import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../github/client.dart';
import '../../hub/all_tasks.dart';
import '../../hub/hub_access.dart';
import '../../hub/hub_config.dart';
import '../../hub/hub_language.dart';
import '../../hub/hub_connections.dart';
import '../../hub/token_scope.dart';
import '../../hub/hub_sync.dart';
import '../../hub/hub_watcher.dart';
import '../../hub/models/task_draft.dart';
import '../../hub/outbox.dart';
import 'queued_drafts_sheet.dart';
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
    // Kuyruk **ikiye ayrılmış** okunuyor (B-140): "bağlantı gelince
    // gönderilecek" sözü yalnız gidebilecekler için doğru. Tek sayıda
    // toplandığında kullanıcı, hiç gitmeyecek bir taslağı da bekleyen
    // sanıyordu.
    final queue = ref.watch(queueSplitProvider);
    final queued = queue.deliverable;
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
          const _TokenScopeTile(),
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
              // Satır artık dokunulabilir (T-021): kuyruk yalnız sayı değil,
              // içine bakılıp düzeltilebilen bir liste. Alt yazı bunu söylüyor.
              subtitle: Text('${l.outboxQueuedSubtitle} · ${l.queuedTasksTapHint}'),
              onTap: () => QueuedDraftsSheet.show(context),
              trailing: TextButton(
                onPressed: () => ref.read(outboxProvider.notifier).flush(),
                child: Text(l.trySendNow),
              ),
            ),
          // Hedefi kalmayan taslaklar **ayrı** satırda: "şimdi göndermeyi
          // dene" onlar için sessizce hiçbir şey yapmıyordu ve alt yazı
          // tutulamayacak bir söz veriyordu. Satır hangi repoyu beklediğini
          // söylüyor — kullanıcı ya repoyu geri ekler (taslak kendiliğinden
          // gider) ya siler.
          if (queue.orphaned.isNotEmpty)
            _StuckQueueTile(orphaned: queue.orphaned),
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

/// Token kapsam ölçümü (B-103) — kullanıcı isteyince koşar.
///
/// **Neden elle:** kontrol bağlantı kurulurken de koşuyor ama orada tek bir ana
/// bakar. "All repositories" ile üretilmiş bir token, hesaba yeni repo
/// eklendikçe **sessizce genişler**; bağlantı kurulduğu gün K'dan fazla repo
/// görmüyor olabilir ve o gün doğru olan cevap bir ay sonra yanlış olur.
/// Düzenli koşan bir kontrol de yazılabilirdi; bu ilk adım, çünkü "ne zaman
/// koştu" durumunu diske yazmayı gerektirmiyor ve soruyu soran kullanıcının
/// kendisi.
///
/// Üç sonucu **ayrı** gösteriyor ve "ölçülemedi" ile "fazla erişim yok" asla
/// aynı kutuya girmiyor: bilinmeyeni temiz saymak, bu kontrolün önlemek için
/// yazıldığı hatanın ta kendisi (L-035, L-009).
class _TokenScopeTile extends ConsumerStatefulWidget {
  const _TokenScopeTile();

  static const tileKey = Key('settings-token-scope');

  @override
  ConsumerState<_TokenScopeTile> createState() => _TokenScopeTileState();
}

class _TokenScopeTileState extends ConsumerState<_TokenScopeTile> {
  bool _measuring = false;

  /// Ölçüm koştu mu, koştuysa ne çıktı. `null` = henüz koşmadı.
  ({int? visible, int needed, TokenScopeWarning? warning})? _result;

  Future<void> _measure(HubConfig config) async {
    setState(() => _measuring = true);

    // Klasik token'da ölçmeye gerek yok: kapsamı zaten hesabın tamamı ve
    // uyarısı önekten okunuyor (B-092) — bir istek harcamıyoruz.
    final classic = inspectTokenScope(
      token: config.token,
      oauthScopes: null,
      slug: config.slug,
    );

    final connections =
        ref.read(hubConnectionsProvider).valueOrNull?.connections ?? const [];
    final needed = reposNeededForToken(connections, config);

    final visible = classic != null
        ? null
        : await ref.read(tokenScopeMeasureProvider)(config);

    if (!mounted) return;
    setState(() {
      _measuring = false;
      _result = (
        visible: visible,
        needed: needed,
        warning: classic ??
            tokenScopeExcess(
              visibleRepos: visible,
              neededRepos: needed,
              slug: config.slug,
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final config = ref.watch(hubConfigProvider).value;
    final result = _result;

    final (String subtitle, Color? color) = switch ((_measuring, result)) {
      (true, _) => (l.tokenScopeMeasuring, null),
      (_, null) => (l.tokenScopeSubtitle, null),
      (_, final r?) when r.warning != null => (
          r.visible == null
              ? r.warning!.title
              : l.tokenScopeExcessFound(r.visible!, r.needed),
          Theme.of(context).colorScheme.error,
        ),
      (_, final r?) when r.visible == null => (l.tokenScopeUnknown, null),
      (_, final r?) => (l.tokenScopeOk(r.visible!, r.needed), null),
    };

    return ListTile(
      key: _TokenScopeTile.tileKey,
      leading: const Icon(Icons.key_outlined),
      title: Text(l.tokenScopeTitle),
      subtitle: Text(subtitle, style: TextStyle(color: color)),
      isThreeLine: true,
      trailing: _measuring
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: config == null || _measuring
          ? null
          : () {
              final warning = result?.warning;
              if (warning != null) {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    icon: const Icon(Icons.gpp_maybe_outlined),
                    title: Text(warning.title),
                    content: SingleChildScrollView(child: Text(warning.body)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l.close),
                      ),
                    ],
                  ),
                );
              } else {
                unawaited(_measure(config));
              }
            },
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

/// Hedef reposu kaldırılmış kuyruk taslakları (B-140).
///
/// Silme onaylı: kullanıcının yazdığı ve **hiç gönderilmemiş** bir iş
/// siliniyor, geri getirilemiyor. Kuyruğun kendisi hiçbir şeyi kendiliğinden
/// atmıyor — o karar `Outbox.flush`'ta bilerek verilmemişti.
class _StuckQueueTile extends ConsumerWidget {
  const _StuckQueueTile({required this.orphaned});

  static const tileKey = Key('settings-stuck-queue');
  static const discardKey = Key('settings-stuck-discard');

  final List<TaskDraft> orphaned;

  Set<String> get _slugs => {
        for (final d in orphaned)
          if (d.repoSlug != null) d.repoSlug!,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      key: tileKey,
      leading: Icon(Icons.cloud_off_outlined, color: colors.error),
      title: Text(l.outboxStuckTitle(orphaned.length)),
      subtitle: Text(l.outboxStuckSubtitle(_slugs.join(', '))),
      isThreeLine: true,
      trailing: TextButton(
        key: discardKey,
        onPressed: () => _confirmDiscard(context, ref),
        child: Text(l.outboxStuckDiscard),
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Metin diyalog açılmadan hazırlanıyor (L-029'un kalıbı).
    final doneText = l.outboxStuckDiscarded;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(L.of(dialogContext).outboxStuckConfirmTitle(orphaned.length)),
        content: Text(L.of(dialogContext).outboxStuckConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(L.of(dialogContext).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(L.of(dialogContext).outboxStuckDiscard),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(outboxProvider.notifier).discardForRepos(_slugs);
      messenger.showSnackBar(SnackBar(content: Text(doneText)));
    }
  }
}
