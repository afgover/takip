import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../hub/browse_repo.dart';
import '../common/hub_error_view.dart';
import '../common/hub_markdown.dart';

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
          title: const Text('Yol Haritası'),
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
          children: [HubMarkdown(value)],
        ),
      AsyncError(:final error) => HubErrorView(
          error: error,
          onRetry: () => ref.invalidate(docContentProvider(path)),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
