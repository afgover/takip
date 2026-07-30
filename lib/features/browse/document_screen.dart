import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/browse_repo.dart';
import '../../hub/frontmatter.dart';
import '../common/hub_error_view.dart';
import '../common/hub_markdown.dart';

/// Hub'daki herhangi bir markdown dosyasını gösteren ortak görüntüleyici
/// (oturumlar, artifact'lar, yol haritası).
///
/// Frontmatter varsa üstte rozet olarak özetlenir, gövde markdown olarak
/// çizilir. Bozuk frontmatter'lı bir dosya da açılır: parser içeriği
/// gizlemeden ham hâliyle verir (bkz. `Frontmatter.isMalformed`).
class DocumentScreen extends ConsumerWidget {
  const DocumentScreen({
    super.key,
    required this.path,
    required this.title,
  });

  final String path;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(docContentProvider(path));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (content) {
        AsyncData(:final value) => _Document(raw: value),
        AsyncError(:final error) => HubErrorView(
            error: error,
            onRetry: () => ref.invalidate(docContentProvider(path)),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Document extends StatelessWidget {
  const _Document({required this.raw});

  final String raw;

  @override
  Widget build(BuildContext context) {
    final fm = Frontmatter.parse(raw);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (fm.isMalformed)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Bu dosyanın başlık bloğu okunamadı; içerik ham hâliyle '
              'gösteriliyor.',
            ),
          ),
        if (fm.hasFrontmatter) ...[
          _MetaChips(fields: fm.fields),
          const SizedBox(height: 8),
          const Divider(),
        ],
        HubMarkdown(fm.body, padding: const EdgeInsets.only(top: 8)),
      ],
    );
  }
}

class _MetaChips extends StatelessWidget {
  const _MetaChips({required this.fields});

  final Map<String, dynamic> fields;

  /// Rozet olarak göstermeye değer alanlar; uzun listeler (artifacts,
  /// tasks_touched) gövdede zaten görünür.
  static const _shown = ['id', 'date', 'status', 'type', 'session', 'created'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];

    for (final key in _shown) {
      final value = fields[key]?.toString().trim();
      if (value == null || value.isEmpty || value == 'none') continue;
      chips.add(_chip(theme, '$key: $value'));
    }
    for (final topic in _list(fields['topics'])) {
      chips.add(_chip(theme, topic));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  static List<String> _list(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : const [];

  Widget _chip(ThemeData theme, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: theme.textTheme.labelSmall),
      );
}
