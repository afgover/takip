import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../hub/browse_repo.dart';
import '../pending/done_screen.dart';
import '../pending/pending_screen.dart';
import 'activity_screen.dart';
import 'doc_list_screen.dart';
import 'document_screen.dart';
import 'knowledge_screen.dart';
import 'roadmap_screen.dart';

/// Hub tarayıcı — SYSTEM.md §9'daki kategoriler (B-040).
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = <_Category>[
      _Category(
        'Bekleyen görevler',
        Icons.pending_actions,
        'tasks/inbox + active',
        (_) => const PendingScreen(),
      ),
      _Category(
        'Tamamlananlar',
        Icons.task_alt,
        'tasks/done',
        (_) => const DoneScreen(),
      ),
      _Category(
        'Oturumlar',
        Icons.forum,
        'sessions/',
        (_) => DocListScreen(
          title: 'Oturumlar',
          provider: sessionsProvider,
          emptyTitle: 'Oturum kaydı yok',
          emptySubtitle: 'Agent her çalışma oturumunu buraya yazar.',
        ),
      ),
      _Category(
        'Raporlar & Planlar',
        Icons.description,
        'artifacts/',
        (_) => DocListScreen(
          title: 'Raporlar & Planlar',
          provider: artifactsProvider,
          emptyTitle: 'Henüz artifact yok',
          emptySubtitle: 'Agent ürettiği rapor ve planları buraya kaydeder.',
          showTypeFilter: true,
        ),
      ),
      _Category(
        'Bilgi tabanı',
        Icons.school,
        'knowledge/',
        (_) => const KnowledgeScreen(),
      ),
      _Category(
        'Yol haritası',
        Icons.map,
        'BACKLOG.md · EVOLUTION.md',
        (_) => const RoadmapScreen(),
      ),
      _Category(
        'Aktivite',
        Icons.history,
        'commit geçmişi',
        (_) => const ActivityScreen(),
      ),
      _Category(
        'Sözleşme',
        Icons.gavel,
        'SYSTEM.md',
        (_) => const DocumentScreen(
          path: '${Hub.basePath}/SYSTEM.md',
          title: 'Format Sözleşmesi',
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Hub Tarayıcı')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final category in categories)
            Card(
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: category.builder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(category.icon, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        category.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.source,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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

class _Category {
  const _Category(this.title, this.icon, this.source, this.builder);

  final String title;
  final IconData icon;
  final String source;
  final WidgetBuilder builder;
}
