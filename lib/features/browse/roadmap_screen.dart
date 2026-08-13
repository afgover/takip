import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../hub/browse_repo.dart';
import '../common/annotated_document.dart';
import '../common/hub_error_view.dart';
import '../common/hub_link_nav.dart';
import '../../l10n/app_localizations.dart';

/// Yol haritası (B-044): `BACKLOG.md` ve `EVOLUTION.md`.
///
/// İkisi de düz markdown olarak gösterilir — backlog'un görev kutuları ve
/// evrimin üstü çizili kararları `HubMarkdown`'ın GitHub eklenti setiyle
/// GitHub'daki gibi çizilir (B-025).
class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(L.of(context).roadmapTitle),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Backlog'),
              Tab(text: 'Evrim'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MarkdownTab(path: Hub.backlogFile),
            _MarkdownTab(path: Hub.evolutionFile),
          ],
        ),
      ),
    );
  }
}

class _MarkdownTab extends ConsumerWidget {
  const _MarkdownTab({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(docContentProvider(path));

    return switch (content) {
      AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AnnotatedDocument(
              data: value,
              sourcePath: path,
              // Backlog maddeleri görevlere ve güvenlik kayıtlarına bağlantı
              // veriyor (sözleşme §15); dokunulunca hedef açılır.
              onTapLink: (_, href, __) =>
                  openHubLink(context, href: href, fromPath: path),
            ),
          ],
        ),
      AsyncError(:final error) => HubErrorView(
          error: error,
          onRetry: () => ref.invalidate(docContentProvider(path)),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
