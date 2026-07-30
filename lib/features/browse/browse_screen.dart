import 'package:flutter/material.dart';

/// Hub tarayıcı — SYSTEM.md §9 kategorileri.
/// TODO(B-040..B-045): her kategori için liste + markdown görüntüleme,
/// aktivite akışı (commit geçmişi).
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  static const _categories = [
    ('Bekleyen görevler', Icons.pending_actions, 'tasks/inbox + active'),
    ('Tamamlananlar', Icons.task_alt, 'tasks/done'),
    ('Oturumlar', Icons.forum, 'sessions/'),
    ('Raporlar & Planlar', Icons.description, 'artifacts/'),
    ('Bilgi tabanı', Icons.school, 'knowledge/'),
    ('Yol haritası', Icons.map, 'BACKLOG.md · EVOLUTION.md'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hub Tarayıcı')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final (title, icon, source) in _categories)
            Card(
              child: InkWell(
                onTap: () {}, // TODO(B-040)
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 40),
                      const SizedBox(height: 8),
                      Text(title, textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(source,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
