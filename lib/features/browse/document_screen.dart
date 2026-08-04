import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/browse_repo.dart';
import '../../hub/frontmatter.dart';
import '../common/annotated_document.dart';
import '../common/hub_error_view.dart';

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
    this.repoSlug,
  });

  final String path;
  final String title;

  /// Belgenin hangi bağlantıda olduğu. Verilmezse aktif bağlantı — tarayıcının
  /// kendi listeleri zaten aktif repoyu gezer. İşaretler listesi (v1.12) bütün
  /// repoları birleştirdiği için oradan açılırken doldurulur (L-031).
  final String? repoSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (repoSlug: repoSlug, path: path);
    final content = ref.watch(docContentForProvider(key));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (content) {
        AsyncData(:final value) => _Document(raw: value, path: path),
        AsyncError(:final error) => HubErrorView(
            error: error,
            onRetry: () => ref.invalidate(docContentForProvider(key)),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Document extends StatelessWidget {
  const _Document({required this.raw, required this.path});

  final String raw;

  /// Belgenin hub yolu — seçimden üretilen kaydın `source` alanı olur.
  final String path;

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
        AnnotatedDocument(
          data: fm.body,
          sourcePath: path,
          padding: const EdgeInsets.only(top: 8),
        ),
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
