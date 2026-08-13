import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/browse_repo.dart';
import '../../hub/frontmatter.dart';
import '../../hub/hub_link.dart';
import '../common/annotated_document.dart';
import '../common/hub_error_view.dart';
import '../common/hub_link_nav.dart';
import '../../l10n/app_localizations.dart';

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
    this.anchor,
  });

  final String path;
  final String title;

  /// Açılışta kaydırılacak kayıt ID'si (sözleşme 1.25 §15). Bulunamazsa belge
  /// baştan açılır — kırık bir çapa, belgeyi hiç açmamak için sebep değil.
  final String? anchor;

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
        AsyncData(:final value) => _Document(
            raw: value,
            path: path,
            anchor: anchor,
            repoSlug: repoSlug,
          ),
        AsyncError(:final error) => HubErrorView(
            error: error,
            onRetry: () => ref.invalidate(docContentForProvider(key)),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Document extends StatefulWidget {
  const _Document({
    required this.raw,
    required this.path,
    this.anchor,
    this.repoSlug,
  });

  final String raw;

  /// Belgenin hub yolu — seçimden üretilen kaydın `source` alanı olur.
  final String path;

  final String? anchor;
  final String? repoSlug;

  @override
  State<_Document> createState() => _DocumentState();
}

class _DocumentState extends State<_Document> {
  final _anchorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.anchor != null) {
      // İlk çizimden sonra: hedef widget ancak çizildikten sonra bir konuma
      // sahip oluyor.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _anchorKey.currentContext;
        if (target == null) return; // çapa bulunamadı — belge baştan kalır
        Scrollable.ensureVisible(target, alignment: 0.1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fm = Frontmatter.parse(widget.raw);
    final split = _splitAtAnchor(fm.body, widget.anchor);

    void onTapLink(String _, String? href, String __) => openHubLink(
          context,
          href: href,
          fromPath: widget.path,
          repoSlug: widget.repoSlug,
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (fm.isMalformed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(L.of(context).docMalformedFrontmatter),
          ),
        if (fm.hasFrontmatter) ...[
          _MetaChips(fields: fm.fields),
          const SizedBox(height: 8),
          const Divider(),
        ],
        if (split == null)
          AnnotatedDocument(
            data: fm.body,
            sourcePath: widget.path,
            padding: const EdgeInsets.only(top: 8),
            onTapLink: onTapLink,
          )
        else ...[
          // Belge çapada **ikiye bölünerek** çiziliyor: aradaki işaretin
          // konumu, kaydırmanın hedefi oluyor. Alternatif, çizilmiş metinde
          // bir satırın konumunu hesaplamaktı — markdown'ın kendi sarma ve
          // blok kurallarını uygulamadan tahmin etmek demek olurdu.
          if (split.before.trim().isNotEmpty)
            AnnotatedDocument(
              data: split.before,
              sourcePath: widget.path,
              padding: const EdgeInsets.only(top: 8),
              onTapLink: onTapLink,
            ),
          SizedBox(key: _anchorKey, height: 1),
          AnnotatedDocument(
            data: split.after,
            sourcePath: widget.path,
            onTapLink: onTapLink,
          ),
        ],
      ],
    );
  }
}

/// Gövdeyi çapanın bulunduğu satırdan ikiye ayırır; çapa yoksa `null`.
({String before, String after})? _splitAtAnchor(String body, String? anchor) {
  if (anchor == null) return null;
  final line = anchorLineOf(body, anchor);
  if (line == null || line == 0) return null;

  final lines = body.split('\n');
  return (
    before: lines.take(line).join('\n'),
    after: lines.skip(line).join('\n'),
  );
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
