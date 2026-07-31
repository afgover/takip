import 'package:flutter/material.dart';

import '../../core/errors.dart';

/// Hata gösteriminin tek yeri (B-050).
///
/// Mesaj `HubError` tiplerinden gelir; bu widget yalnız sunar ve her tip için
/// **yapılabilecek bir şey** önerir: token hatasında ayarlara gitmek, rate
/// limit'te ne kadar bekleneceğini bilmek, ağ hatasında yeniden denemek.
/// "Bir hata oluştu" deyip kullanıcıyı çıkışsız bırakmamak esas.
class HubErrorView extends StatelessWidget {
  const HubErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.onOpenSettings,
  });

  final Object error;
  final VoidCallback? onRetry;

  /// Token/yetki hatasında bağlantı ayarlarına götürür.
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = describeHubError(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(detail.icon, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              detail.headline,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              detail.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (detail.suggestsSettings && onOpenSettings != null)
                  FilledButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Bağlantı ayarları'),
                  ),
                if (onRetry != null)
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeniden dene'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hata tipinin kullanıcıya nasıl anlatılacağı — banner ve tam ekran gösterim
/// aynı metni kullansın diye tek yerde.
class HubErrorDetail {
  const HubErrorDetail({
    required this.icon,
    required this.headline,
    required this.message,
    this.suggestsSettings = false,
  });

  final IconData icon;

  /// Kısa başlık ("Bağlantı yok").
  final String headline;

  /// Ne olduğu ve ne yapılabileceği.
  final String message;

  final bool suggestsSettings;
}

HubErrorDetail describeHubError(Object error, {DateTime? now}) {
  switch (error) {
    case HubNetworkError():
      return const HubErrorDetail(
        icon: Icons.wifi_off,
        headline: 'Bağlantı yok',
        message: 'İnternete bağlanılamadı. Eklediğin görevler kuyrukta bekler '
            've bağlantı gelince kendiliğinden gönderilir.',
      );

    case HubAuthError(:final message):
      return HubErrorDetail(
        icon: Icons.key_off,
        headline: 'Token kabul edilmedi',
        message: '$message\nAyarlardan token\'ı yenileyebilirsin; izinler '
            'Contents: Read and write ve Metadata: Read olmalı.',
        suggestsSettings: true,
      );

    case HubRateLimitError(:final resetAt):
      return HubErrorDetail(
        icon: Icons.hourglass_top,
        headline: 'İstek limiti doldu',
        message: resetAt == null
            ? 'GitHub istek limiti doldu; bir süre sonra kendiliğinden açılır.'
            : 'GitHub istek limiti doldu. ${_remaining(resetAt, now)} sonra '
                'yeniden denenecek.',
      );

    case HubNotFoundError(:final message):
      return HubErrorDetail(
        icon: Icons.search_off,
        headline: 'Bulunamadı',
        message: message,
        suggestsSettings: true,
      );

    case HubError(:final message):
      return HubErrorDetail(
        icon: Icons.error_outline,
        headline: 'Bir sorun çıktı',
        message: message,
      );

    default:
      return HubErrorDetail(
        icon: Icons.error_outline,
        headline: 'Beklenmeyen hata',
        message: '$error',
      );
  }
}

String _remaining(DateTime resetAt, DateTime? now) {
  final left = resetAt.difference(now ?? DateTime.now());
  if (left.isNegative || left.inSeconds < 60) return 'Birazdan';
  if (left.inMinutes < 60) return '${left.inMinutes} dakika';
  return '${left.inHours} saat';
}

/// Liste boşken gösterilen bilgilendirme.
class HubEmptyView extends StatelessWidget {
  const HubEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
