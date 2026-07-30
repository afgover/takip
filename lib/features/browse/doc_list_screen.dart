import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/hub_watcher.dart';
import '../../hub/models/hub_doc.dart';
import '../common/hub_error_view.dart';
import '../pending/pending_screen.dart' show formatTaskDate;
import 'document_screen.dart';

/// Oturumlar ve artifact'lar için ortak liste ekranı (B-041, B-042).
///
/// İkisi de "tarihli, başlıklı belge listesi"; ayrım yalnızca hangi
/// provider'dan beslendiği ve isteğe bağlı tür filtresi.
class DocListScreen extends ConsumerStatefulWidget {
  const DocListScreen({
    super.key,
    required this.title,
    required this.provider,
    required this.emptyTitle,
    this.emptySubtitle,
    this.showTypeFilter = false,
  });

  final String title;
  final ProviderListenable<AsyncValue<List<HubDoc>>> provider;
  final String emptyTitle;
  final String? emptySubtitle;

  /// Artifact'larda frontmatter `type`'ına göre süzme (B-042).
  final bool showTypeFilter;

  static const listKey = Key('doc-list');
  static const filterKey = Key('doc-list-filter');

  @override
  ConsumerState<DocListScreen> createState() => _DocListScreenState();
}

class _DocListScreenState extends ConsumerState<DocListScreen> {
  String? _type;

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(widget.provider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(hubWatcherProvider.notifier).checkNow();
        },
        child: switch (docs) {
          AsyncData(:final value) when value.isEmpty => _scrollable(
              HubEmptyView(
                icon: Icons.folder_off_outlined,
                title: widget.emptyTitle,
                subtitle: widget.emptySubtitle,
              ),
            ),
          AsyncData(:final value) => _list(value),
          AsyncError(:final error) => _scrollable(
              HubErrorView(
                error: error,
                onRetry: () => ref.invalidate(hubWatcherProvider),
              ),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _list(List<HubDoc> all) {
    final types = all
        .map((d) => d.subtitle)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final visible =
        _type == null ? all : all.where((d) => d.subtitle == _type).toList();

    return Column(
      children: [
        if (widget.showTypeFilter && types.isNotEmpty)
          SizedBox(
            height: 56,
            child: ListView(
              key: DocListScreen.filterKey,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final type in [null, ...types])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: FilterChip(
                      label: Text(type ?? 'Hepsi'),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            key: DocListScreen.listKey,
            itemCount: visible.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _DocTile(doc: visible[i]),
          ),
        ),
      ],
    );
  }

  Widget _scrollable(Widget child) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      );
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.doc});

  final HubDoc doc;

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (doc.date != null) formatTaskDate(doc.date)!,
      if (doc.subtitle != null) doc.subtitle!,
    ];

    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(doc.title),
      subtitle: Text(parts.isEmpty ? doc.path : parts.join(' · ')),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DocumentScreen(path: doc.path, title: doc.title),
        ),
      ),
    );
  }
}
