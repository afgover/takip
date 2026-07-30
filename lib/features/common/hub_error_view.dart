import 'package:flutter/material.dart';

import '../../core/errors.dart';

/// Hata gösteriminin tek yeri. Mesajlar `HubError` tiplerinden gelir; bu
/// widget yalnız sunar ve mümkünse bir çıkış yolu (yeniden dene) verir.
///
/// TODO(B-050): tip bazlı özel eylemler — token hatasında ayarlara git,
/// rate limit'te bekleme süresini göster.
class HubErrorView extends StatelessWidget {
  const HubErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  String get _message => switch (error) {
        HubError(:final message) => message,
        _ => 'Beklenmeyen hata: $error',
      };

  IconData get _icon => switch (error) {
        HubNetworkError() => Icons.wifi_off,
        HubAuthError() => Icons.key_off,
        HubRateLimitError() => Icons.hourglass_top,
        _ => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 40, color: colors.error),
            const SizedBox(height: 12),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Yeniden dene'),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
