import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../hub/annotations.dart';
import '../../hub/models/task.dart';

/// Hub dosyalarını ekranda gösteren ortak markdown görüntüleyici.
///
/// Hub içeriğinin tamamı markdown'dır; oturum kayıtları, artifact'lar, backlog
/// ve bilgi tabanı hep bu widget'la çizilir (Faz 3–4). Sözleşmenin kendi
/// yazım alışkanlıkları render ayarlarını belirler:
///
/// - `~~üstü çizili~~` — geçersizleşen kayıtların işareti (R-004),
/// - `- [x]` görev kutuları — `BACKLOG.md`'nin tamamı,
/// - tablolar — `SYSTEM.md` şema tabloları.
///
/// Bunlar temel markdown'da yok; bu yüzden GitHub eklenti seti kullanılır ve
/// GitHub'da nasıl görünüyorsa app'te de öyle görünür.
class HubMarkdown extends StatelessWidget {
  const HubMarkdown(
    this.data, {
    super.key,
    this.onTapLink,
    this.selectable = true,
    this.padding = EdgeInsets.zero,
    this.annotations = const [],
  });

  final String data;

  /// Bu belgeye bağlı kayıtlar; metinde işaretlenirler (sözleşme 1.5).
  final List<Annotation> annotations;

  /// Bağlantıya dokunma. Hub içi göreli bağlantılar (`artifacts/…md`) Faz 4'te
  /// uygulama içi gezinmeye bağlanacak; burada karar verilmez, yukarı iletilir.
  final void Function(String text, String? href, String title)? onTapLink;

  final bool selectable;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: MarkdownBody(
        data: markAnnotations(data, annotations),
        selectable: selectable,
        extensionSet: md.ExtensionSet.gitHubWeb,
        styleSheet: hubMarkdownStyleSheet(Theme.of(context)),
        onTapLink: onTapLink,
        inlineSyntaxes: [
          _MarkSyntax(_highlightOpen, _highlightClose, markHighlightTag),
          _MarkSyntax(_underlineOpen, _underlineClose, markUnderlineTag),
        ],
        builders: {
          markHighlightTag: _MarkBuilder(TaskMark.highlight),
          markUnderlineTag: _MarkBuilder(TaskMark.underline),
        },
      ),
    );
  }
}

/// Uygulama temasından türeyen markdown stili. Tema değişince (açık/koyu)
/// otomatik uyar; sabit renk kullanılmaz.
MarkdownStyleSheet hubMarkdownStyleSheet(ThemeData theme) {
  final colors = theme.colorScheme;
  final mono = theme.textTheme.bodyMedium?.copyWith(
    fontFamily: 'monospace',
    fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) - 1,
  );

  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
    h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    a: TextStyle(
      color: colors.primary,
      decoration: TextDecoration.underline,
      decorationColor: colors.primary.withValues(alpha: 0.4),
    ),
    code: mono?.copyWith(
      backgroundColor: colors.surfaceContainerHighest,
      color: colors.onSurface,
    ),
    codeblockPadding: const EdgeInsets.all(12),
    codeblockDecoration: BoxDecoration(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    blockquoteDecoration: BoxDecoration(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      border: Border(left: BorderSide(color: colors.primary, width: 3)),
    ),
    tableBorder: TableBorder.all(color: colors.outlineVariant),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    tableHead: theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: colors.outlineVariant)),
    ),
    listBullet: theme.textTheme.bodyMedium,
  );
}

// İşaretler markdown kaynağına, metinde geçmesi mümkün olmayan **özel kullanım
// alanı** karakterleriyle gömülüyor (U+E000…). Böylece kullanıcı metninde
// kazara aynı deseni yazmak imkânsız — `==vurgu==` gibi görünür bir sözdizimi
// seçilseydi belgenin kendi metni işaret sanılabilirdi.
const _highlightOpen = '\uE000';
const _highlightClose = '\uE001';
const _underlineOpen = '\uE002';
const _underlineClose = '\uE003';

const markHighlightTag = 'hubMarkHighlight';
const markUnderlineTag = 'hubMarkUnderline';

/// Kayıtlardaki alıntıları markdown kaynağında işaretler.
///
/// Alıntı bulunamazsa **sessizce atlanır**: belge kayıt yazıldıktan sonra
/// değişmiş olabilir ve bu beklenen bir durumdur (sözleşme §4). Kayıt yine
/// listelerde durur, yalnız işaret çizilmez.
///
/// Alıntı içinde markdown olabilir; işaret metnin ham hâline uygulanıyor,
/// yani biçimlendirme sınırını kesen bir seçim işaretlenemez. Bu bilinçli:
/// yarım kalmış bir vurgu, belgeyi bozup okunamaz hâle getirirdi.
String markAnnotations(String source, List<Annotation> annotations) {
  if (annotations.isEmpty) return source;

  // Uzun alıntı önce: kısa bir alıntı uzununun içinde geçiyorsa, önce kısayı
  // işaretlemek uzunu bulunamaz hâle getirirdi.
  final ordered = [...annotations]
    ..sort((a, b) => b.quote.trim().length.compareTo(a.quote.trim().length));

  // Aralıklar **özgün metin üzerinde** toplanıp en sonda uygulanıyor. Sırayla
  // yerine koymak, ikinci alıntının birincinin işaretinin içine düşmesine ve
  // dıştaki işaretin bölünmesine yol açıyordu.
  final claimed = <({int start, int end, TaskMark mark})>[];

  for (final annotation in ordered) {
    final quote = annotation.quote.trim();
    if (quote.isEmpty) continue;

    final start = source.indexOf(quote);
    if (start < 0) continue; // belge değişmiş olabilir — kayıt yine geçerli
    final end = start + quote.length;

    final overlaps = claimed.any((r) => start < r.end && end > r.start);
    if (overlaps) continue;

    claimed.add((start: start, end: end, mark: annotation.mark));
  }

  // Sondan başa doğru ekle ki daha önceki konumlar kaymasın.
  claimed.sort((a, b) => b.start.compareTo(a.start));
  var out = source;
  for (final range in claimed) {
    final (open, close) = range.mark == TaskMark.highlight
        ? (_highlightOpen, _highlightClose)
        : (_underlineOpen, _underlineClose);
    out = out.replaceRange(
      range.start,
      range.end,
      '$open${source.substring(range.start, range.end)}$close',
    );
  }
  return out;
}

class _MarkSyntax extends md.InlineSyntax {
  _MarkSyntax(this.open, this.close, this.tag)
      : super('${RegExp.escape(open)}([^${RegExp.escape(close)}]+)'
            '${RegExp.escape(close)}');

  final String open;
  final String close;
  final String tag;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text(tag, match[1]!));
    return true;
  }
}

class _MarkBuilder extends MarkdownElementBuilder {
  _MarkBuilder(this.mark);

  final TaskMark mark;

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Builder(
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        final base = preferredStyle ?? Theme.of(context).textTheme.bodyMedium;
        return Text(
          element.textContent,
          style: mark == TaskMark.highlight
              ? base?.copyWith(
                  backgroundColor: const Color(0xFFFFE082),
                  color: Colors.black87,
                )
              : base?.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: colors.error,
                  decorationThickness: 2,
                ),
        );
      },
    );
  }
}
