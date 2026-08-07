import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/hub_watcher.dart';
import '../../hub/outbox.dart';
import 'hub_error_view.dart';
import '../../l10n/app_localizations.dart';

/// Uygulamanın her ekranında görünen durum şeridi (B-050).
///
/// Hata mesajını yalnız o an açık olan listenin göstermesi yetmiyor: kullanıcı
/// "Görev Ekle" ekranındayken token'ın geçersiz olduğunu bilmeli, çünkü
/// göndereceği görev sessizce kuyruğa düşecek. Şerit sorunu bağlamdan bağımsız
/// söyler ve çıkış yolunu (ayarlar) gösterir.
class HubStatusBanner extends ConsumerWidget {
  const HubStatusBanner({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  static const bannerKey = Key('hub-status-banner');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(hubWatcherProvider);
    final queued = ref.watch(outboxProvider).valueOrNull ?? const [];
    final theme = Theme.of(context);

    if (status.error == null) {
      if (queued.isEmpty) return const SizedBox.shrink();
      // Hata yok ama kuyruk boşalmadıysa kullanıcı bunu bilmeli.
      return _Bar(
        key: bannerKey,
        icon: Icons.cloud_upload_outlined,
        text: L.of(context).statusQueued(queued.length),
        background: theme.colorScheme.secondaryContainer,
        foreground: theme.colorScheme.onSecondaryContainer,
      );
    }

    final detail = describeHubError(status.error!, L.of(context));
    return _Bar(
      key: bannerKey,
      icon: detail.icon,
      text: detail.headline,
      background: theme.colorScheme.errorContainer,
      foreground: theme.colorScheme.onErrorContainer,
      action: detail.suggestsSettings && onOpenSettings != null
          ? TextButton(
              onPressed: onOpenSettings,
              child: const Text('Ayarlar'),
            )
          : TextButton(
              onPressed: () => ref.read(hubWatcherProvider.notifier).checkNow(),
              child: const Text('Yeniden dene'),
            ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    super.key,
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
    this.action,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: foreground),
              ),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}
