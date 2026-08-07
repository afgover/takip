import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../l10n/app_localizations.dart';

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
    final detail = describeHubError(error, L.of(context));

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
                    label: Text(L.of(context).errSettingsButton),
                  ),
                if (onRetry != null)
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(L.of(context).errRetry),
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
///
/// Metinler `L` üzerinden geliyor ve `L` **parametre olarak** alınıyor: bu saf
/// bir fonksiyon, `BuildContext`i yok. Çağıranın dili vermesi, fonksiyonun
/// gizlice global bir dile bağlanmasından iyi — test dili açıkça verebilir.
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

HubErrorDetail describeHubError(Object error, L l, {DateTime? now}) {
  switch (error) {
    case HubNetworkError():
      return HubErrorDetail(
        icon: Icons.wifi_off,
        headline: l.errNetworkTitle,
        message: l.errNetworkBody,
      );

    case HubAuthError(:final message):
      return HubErrorDetail(
        icon: Icons.key_off,
        headline: l.errAuthTitle,
        message: l.errAuthBody(message),
        suggestsSettings: true,
      );

    case HubRateLimitError(:final resetAt):
      return HubErrorDetail(
        icon: Icons.hourglass_top,
        headline: l.errRateTitle,
        message: resetAt == null
            ? l.errRateBody
            : l.errRateBodyIn(_remaining(resetAt, l, now)),
      );

    case HubNotFoundError(:final message):
      return HubErrorDetail(
        icon: Icons.search_off,
        headline: l.errNotFoundTitle,
        message: message,
        suggestsSettings: true,
      );

    case HubError(:final message):
      return HubErrorDetail(
        icon: Icons.error_outline,
        headline: l.errGenericTitle,
        message: message,
      );

    default:
      return HubErrorDetail(
        icon: Icons.error_outline,
        headline: l.errUnexpectedTitle,
        message: '$error',
      );
  }
}

String _remaining(DateTime resetAt, L l, DateTime? now) {
  final left = resetAt.difference(now ?? DateTime.now());
  if (left.isNegative || left.inSeconds < 60) return l.errLeftSoon;
  if (left.inMinutes < 60) return l.errLeftMinutes(left.inMinutes);
  return l.errLeftHours(left.inHours);
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
