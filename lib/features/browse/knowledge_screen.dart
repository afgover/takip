import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/browse_repo.dart';
import '../../hub/models/hub_doc.dart';
import '../common/annotated_document.dart';
import '../common/hub_error_view.dart';
import '../common/hub_link_nav.dart';
import '../../l10n/app_localizations.dart';

/// Bilgi tabanı (B-043): kurallar, skiller, dersler.
///
/// Üç dosya sekme olarak; her kayıt (`R-001`, `SK-002`, `L-003`) açılıp
/// kapanan bir madde. Geçersizleşen kayıtlar silinmediği için (R-004) listede
/// dururlar — başlığı üstü çizili gösterilir, yoksa geçersiz bir kural
/// geçerliymiş gibi okunur.
class KnowledgeScreen extends ConsumerWidget {
  const KnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: KnowledgeFile.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(L.of(context).knowledgeTitle),
          bottom: TabBar(
            tabs: [
              for (final file in KnowledgeFile.values) Tab(text: file.label),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final file in KnowledgeFile.values) _KnowledgeTab(file: file),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeTab extends ConsumerWidget {
  const _KnowledgeTab({required this.file});

  final KnowledgeFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(knowledgeProvider(file));

    return switch (entries) {
      AsyncData(:final value) when value.isEmpty => HubEmptyView(
          icon: Icons.school_outlined,
          title: L.of(context).knowledgeEmptyTitle(file.label),
          subtitle: L.of(context).knowledgeEmptySubtitle,
        ),
      AsyncData(:final value) => ListView.separated(
          itemCount: value.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) =>
              _EntryTile(entry: value[i], sourcePath: file.path),
        ),
      AsyncError(:final error) => HubErrorView(
          error: error,
          onRetry: () => ref.invalidate(knowledgeProvider(file)),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.sourcePath});

  final KnowledgeEntry entry;

  /// Kaydın okunduğu bilgi tabanı dosyası (`hub/knowledge/rules.md` gibi).
  final String sourcePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return ExpansionTile(
      leading: Text(
        entry.id,
        style: theme.textTheme.labelMedium?.copyWith(
          color: entry.isInvalidated ? muted : theme.colorScheme.primary,
        ),
      ),
      title: Text(
        entry.title,
        style: entry.isInvalidated
            ? theme.textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: muted,
              )
            : null,
      ),
      subtitle: entry.isInvalidated
          ? Text(L.of(context).knowledgeSuperseded)
          : (entry.date == null ? null : Text(entry.date!)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AnnotatedDocument(
            data: entry.body,
            sourcePath: sourcePath,
            onTapLink: (_, href, __) =>
                openHubLink(context, href: href, fromPath: sourcePath),
          ),
        ),
      ],
    );
  }
}
