import 'package:flutter/gestures.dart';
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
class HubMarkdown extends StatefulWidget {
  const HubMarkdown(
    this.data, {
    super.key,
    this.onTapLink,
    this.selectable = true,
    this.padding = EdgeInsets.zero,
    this.annotations = const [],
    this.onTapAnnotation,
  });

  final String data;

  /// Bu belgeye bağlı kayıtlar; metinde işaretlenirler (sözleşme 1.5).
  final List<Annotation> annotations;

  /// İşarete dokunulunca çağrılır — kaydı gösterip silmek için.
  final void Function(Annotation annotation)? onTapAnnotation;

  /// Bağlantıya dokunma. Hub içi göreli bağlantılar (`artifacts/…md`) Faz 4'te
  /// uygulama içi gezinmeye bağlanacak; burada karar verilmez, yukarı iletilir.
  final void Function(String text, String? href, String title)? onTapLink;

  final bool selectable;
  final EdgeInsets padding;

  @override
  State<HubMarkdown> createState() => _HubMarkdownState();
}

class _HubMarkdownState extends State<HubMarkdown> {
  late final Map<String, MarkdownElementBuilder> _builders = {
    for (final tag in const [markHighlightTag, markUnderlineTag, markCommentTag])
      tag: _MarkBuilder(tag, _tap),
  };

  /// İşaretin taşıdığı sıra numarasını kayda çevirir.
  void _tap(int index) {
    final annotations = widget.annotations;
    if (index < 0 || index >= annotations.length) return;
    widget.onTapAnnotation?.call(annotations[index]);
  }

  /// Belge ya da kayıtlar değişince markdown baştan ayrıştırılıyor; eski
  /// dokunma tanıyıcılarının sahibi kalmıyor, bırakılmaları gerekiyor.
  @override
  void didUpdateWidget(HubMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.annotations.length != widget.annotations.length) {
      _releaseRecognizers();
    }
  }

  @override
  void dispose() {
    _releaseRecognizers();
    super.dispose();
  }

  void _releaseRecognizers() {
    for (final builder in _builders.values) {
      (builder as _MarkBuilder).release();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: MarkdownBody(
        data: markAnnotations(widget.data, widget.annotations),
        selectable: widget.selectable,
        extensionSet: md.ExtensionSet.gitHubWeb,
        styleSheet: hubMarkdownStyleSheet(Theme.of(context)),
        onTapLink: widget.onTapLink,
        inlineSyntaxes: [
          _MarkSyntax(_highlightOpen, _highlightClose, markHighlightTag),
          _MarkSyntax(_underlineOpen, _underlineClose, markUnderlineTag),
          _MarkSyntax(_commentOpen, _commentClose, markCommentTag),
        ],
        builders: _builders,
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

  final sheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
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

  return sheet;
}

// İşaretler markdown kaynağına, metinde geçmesi mümkün olmayan **özel kullanım
// alanı** karakterleriyle gömülüyor (U+E000…). Böylece kullanıcı metninde
// kazara aynı deseni yazmak imkânsız — `==vurgu==` gibi görünür bir sözdizimi
// seçilseydi belgenin kendi metni işaret sanılabilirdi.
const _highlightOpen = '\uE000';
const _highlightClose = '\uE001';
const _underlineOpen = '\uE002';
const _underlineClose = '\uE003';
const _commentOpen = '\uE004';
const _commentClose = '\uE005';

const markHighlightTag = 'hubMarkHighlight';
const markUnderlineTag = 'hubMarkUnderline';
const markCommentTag = 'hubMarkComment';

({String open, String close, String tag}) _delimitersFor(TaskMark mark) =>
    switch (mark) {
      TaskMark.highlight =>
        (open: _highlightOpen, close: _highlightClose, tag: markHighlightTag),
      TaskMark.underline =>
        (open: _underlineOpen, close: _underlineClose, tag: markUnderlineTag),
      TaskMark.comment =>
        (open: _commentOpen, close: _commentClose, tag: markCommentTag),
    };

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

  final projection = _plainProjection(source);

  // Uzun alıntı önce: kısa bir alıntı uzununun içinde geçiyorsa, önce kısayı
  // işaretlemek uzunu bulunamaz hâle getirirdi.
  final ordered = [...annotations]
    ..sort((a, b) => b.quote.trim().length.compareTo(a.quote.trim().length));

  // Aralıklar **özgün metin üzerinde** toplanıp en sonda uygulanıyor. Sırayla
  // yerine koymak, ikinci alıntının birincinin işaretinin içine düşmesine ve
  // dıştaki işaretin bölünmesine yol açıyordu (L-021).
  final claimed = <({int start, int end, TaskMark mark, int index})>[];

  for (final annotation in ordered) {
    final range = _locate(source, projection, annotation.quote);
    if (range == null) continue; // belge değişmiş olabilir — kayıt yine geçerli

    final overlaps =
        claimed.any((r) => range.start < r.end && range.end > r.start);
    if (overlaps) continue;

    claimed.add((
      start: range.start,
      end: range.end,
      mark: annotation.mark,
      // Kaydın listedeki sırası işaretin içine gömülüyor: kullanıcı işarete
      // dokununca hangi kaydı sildiğimizi bilmek zorundayız. Metinden geri
      // bulmak, aynı kelime birden çok kayıtta geçtiğinde belirsiz olurdu.
      index: annotations.indexOf(annotation),
    ));
  }

  // Sondan başa doğru ekle ki daha önceki konumlar kaymasın.
  claimed.sort((a, b) => b.start.compareTo(a.start));
  var out = source;
  for (final range in claimed) {
    final d = _delimitersFor(range.mark);
    out = out.replaceRange(
      range.start,
      range.end,
      '${d.open}${range.index}$_markIdSeparator'
      '${source.substring(range.start, range.end)}${d.close}',
    );
  }
  return out;
}

/// Alıntının kaynak metindeki yeri.
///
/// **Neden düz arama yetmiyor:** kullanıcı *çizilmiş* metni seçiyor, biz *ham
/// markdown*'da arıyoruz. Aradaki üç fark eşleşmeyi sessizce bozuyordu:
/// `**kalın**` işaretleri seçimde yok, satır sarmaları kaynakta `\n` ama
/// seçimde boşluk, girintiler seçimde yok. Sonuç: kayıt oluşuyor ama işaret
/// hiç çizilmiyordu (L-023).
///
/// Çözüm: kaynağın **düzleştirilmiş** bir izdüşümünde aranıp konum geri
/// haritalanıyor. Önce birebir arama denenir; tutarsa daha kesindir.
({int start, int end})? _locate(
  String source,
  _Projection projection,
  String rawQuote,
) {
  final quote = rawQuote.trim();
  if (quote.isEmpty) return null;

  final exact = source.indexOf(quote);
  if (exact >= 0) return (start: exact, end: exact + quote.length);

  final flatQuote = _flatten(quote);
  if (flatQuote.isEmpty) return null;

  final at = projection.plain.indexOf(flatQuote);
  if (at < 0) return null;

  return (
    start: projection.map[at],
    end: projection.map[at + flatQuote.length - 1] + 1,
  );
}

class _Projection {
  const _Projection(this.plain, this.map);

  /// Vurgu işaretleri atılmış, boşlukları teke inmiş metin.
  final String plain;

  /// `plain` içindeki her karakterin kaynak metindeki konumu.
  final List<int> map;
}

/// Markdown vurgu işaretleri atılırken her karakterin kaynaktaki yeri
/// saklanıyor; işaret sonunda **kaynağa** uygulanacak.
_Projection _plainProjection(String source) {
  final buffer = StringBuffer();
  final map = <int>[];
  var lastWasSpace = true;

  for (var i = 0; i < source.length; i++) {
    final ch = source[i];
    if (_emphasis.contains(ch)) continue;
    if (ch == ' ' || ch == '\n' || ch == '\t' || ch == '\r') {
      if (lastWasSpace) continue;
      buffer.write(' ');
      map.add(i);
      lastWasSpace = true;
      continue;
    }
    buffer.write(ch);
    map.add(i);
    lastWasSpace = false;
  }
  return _Projection(buffer.toString(), map);
}

/// Alıntıyı izdüşümle aynı kurallara göre düzleştirir.
String _flatten(String value) {
  final buffer = StringBuffer();
  var lastWasSpace = true;
  for (var i = 0; i < value.length; i++) {
    final ch = value[i];
    if (_emphasis.contains(ch)) continue;
    if (ch == ' ' || ch == '\n' || ch == '\t' || ch == '\r') {
      if (lastWasSpace) continue;
      buffer.write(' ');
      lastWasSpace = true;
      continue;
    }
    buffer.write(ch);
    lastWasSpace = false;
  }
  return buffer.toString().trim();
}

const _emphasis = {'*', '_', '`', '~'};

/// İşaretin içindeki sıra numarasını metinden ayıran görünmez karakter.
const _markIdSeparator = '\u001F';

/// Sıra numarasının düğümde taşındığı öznitelik.
const _markIndexAttr = 'ann';

/// Gömülü işareti markdown düğümüne çevirir; çizimi `_MarkBuilder` yapar.
class _MarkSyntax extends md.InlineSyntax {
  _MarkSyntax(this.open, this.close, this.tag)
      : super('${RegExp.escape(open)}(\\d+)$_markIdSeparator'
            '([^${RegExp.escape(close)}]+)${RegExp.escape(close)}');

  final String open;
  final String close;
  final String tag;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(
      md.Element.text(tag, match[2]!)..attributes[_markIndexAttr] = match[1]!,
    );
    return true;
  }
}

/// Alıntının altında bulunduğu en yakın markdown başlığı.
///
/// Kayda "nerede" bilgisi olarak yazılıyor: agent alıntıyı bütün belgede
/// aramak yerine doğrudan o bölüme gidebilsin diye. Başlık bulunamazsa null.
String? sectionOf(String source, String quote) {
  final projection = _plainProjection(source);
  final range = _locate(source, projection, quote);
  if (range == null) return null;

  String? heading;
  for (final match in RegExp(r'^#{1,6}\s+(.+)$', multiLine: true)
      .allMatches(source)) {
    if (match.start > range.start) break;
    heading = match.group(1)?.trim();
  }
  return heading;
}

/// İşareti **`Text.rich` olarak** çizer — bu tercih işin püf noktası.
///
/// flutter_markdown, paragrafın satır içi çocuklarını `_mergeInlineChildren`
/// ile birleştiriyor: çocuk `Text`/`RichText` ise komşularıyla **tek bir
/// `RichText`e** kaynıyor, değilse `Wrap` içinde **atomik bir kutu** olarak
/// duruyor. Önceki denemeler işareti sıradan bir widget olarak döndürdüğü için
/// işaretten sonraki metin kalan boşluğa sığmıyor ve tamamı alt satıra
/// iniyordu (L-032). `Text.rich` döndürünce satır kırılması işaretsiz metinle
/// birebir aynı oluyor.
///
/// Dokunma tanıyıcısı da burada takılıyor; kullanıcı işarete dokununca kayıt
/// kartı açılıyor (silme buradan yapılıyor).
class _MarkBuilder extends MarkdownElementBuilder {
  _MarkBuilder(this.tag, this.onTap);

  final String tag;
  final void Function(int index) onTap;
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final theme = Theme.of(context);
    // Ana stil paragraftan geliyor; işaret yalnız rengi/çizgiyi ekliyor, yazı
    // tipini ve satır yüksekliğini değiştirmiyor — yoksa işaretli satır
    // diğerlerinden farklı yükseklikte olurdu.
    final base = parentStyle ?? preferredStyle ?? theme.textTheme.bodyMedium!;
    final index = int.tryParse(element.attributes[_markIndexAttr] ?? '') ?? -1;

    final recognizer = TapGestureRecognizer()..onTap = () => onTap(index);
    _recognizers.add(recognizer);

    return Text.rich(
      TextSpan(
        text: element.textContent,
        style: _styleFor(tag, base, theme.colorScheme),
        recognizer: recognizer,
      ),
    );
  }

  void release() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }
}

/// İşaret renkleri. Yorum sarıdan **ayrı** olmak zorunda: "işaretledim" ile
/// "not düştüm" ekranda aynı görünmemeli (sözleşme 1.8).
TextStyle _styleFor(String tag, TextStyle base, ColorScheme colors) =>
    switch (tag) {
      markHighlightTag => base.copyWith(
          backgroundColor: const Color(0xFFFFE082),
          color: Colors.black87,
        ),
      markCommentTag => base.copyWith(
          backgroundColor: const Color(0xFFA5D6A7),
          color: Colors.black87,
        ),
      _ => base.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: colors.error,
          decorationThickness: 2,
        ),
    };
