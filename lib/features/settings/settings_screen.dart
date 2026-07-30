import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/hub_config.dart';

/// Ayarlar: bağlantı bilgisi, polling aralığı, önbellek.
/// TODO(B-051): polling aralığı ayarı, önbellek temizleme.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(hubConfigProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Bağlı repo'),
            subtitle: Text(
                config == null ? '—' : '${config.owner}/${config.repo}'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Bağlantıyı sıfırla'),
            subtitle: const Text('Token silinir, onboarding\'e dönülür'),
            onTap: () => ref.read(hubConfigProvider.notifier).clear(),
          ),
        ],
      ),
    );
  }
}
