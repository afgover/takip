import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

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
  });

  final String data;

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
        data: data,
        selectable: selectable,
        extensionSet: md.ExtensionSet.gitHubWeb,
        styleSheet: hubMarkdownStyleSheet(Theme.of(context)),
        onTapLink: onTapLink,
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
