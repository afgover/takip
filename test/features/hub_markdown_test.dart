import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/common/hub_markdown.dart';

Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('başlık, liste ve metni çizer', (tester) async {
    await tester.pumpWidget(wrap(const HubMarkdown('''
# Oturum: Deneme

Gövde metni.

- birinci
- ikinci
''')));

    expect(find.textContaining('Oturum: Deneme'), findsOneWidget);
    expect(find.textContaining('Gövde metni.'), findsOneWidget);
    expect(find.textContaining('birinci'), findsOneWidget);
  });

  testWidgets('tablo çizilir (SYSTEM.md şema tabloları)', (tester) async {
    await tester.pumpWidget(wrap(const HubMarkdown('''
| Dosya | Amaç |
|---|---|
| SYSTEM.md | Sözleşme |
''')));

    expect(find.byType(Table), findsOneWidget);
    expect(find.textContaining('SYSTEM.md'), findsOneWidget);
  });

  testWidgets('görev kutuları işaretli/işaretsiz çizilir (BACKLOG.md)',
      (tester) async {
    await tester.pumpWidget(wrap(const HubMarkdown('''
- [x] B-023 tamamlandı
- [ ] B-025 sürüyor
''')));

    expect(
      find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.check_box,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.check_box_outline_blank,
      ),
      findsOneWidget,
    );
  });

  testWidgets('~~üstü çizili~~ gerçekten çizgili render edilir (R-004)',
      (tester) async {
    // R-004 geçersizleşen kaydı üstü çizerek işaretliyor; düz metin olarak
    // çizilirse geçerli kayıttan ayırt edilemez.
    await tester.pumpWidget(wrap(
      const HubMarkdown('~~R-002 geçersiz~~', selectable: false),
    ));

    expect(
      find.byWidgetPredicate((w) {
        if (w is! RichText) return false;
        var struck = false;
        w.text.visitChildren((span) {
          if (span is TextSpan &&
              span.style?.decoration == TextDecoration.lineThrough) {
            struck = true;
          }
          return !struck;
        });
        return struck;
      }),
      findsOneWidget,
    );
  });

  testWidgets('kod bloğu çizilir', (tester) async {
    await tester.pumpWidget(wrap(const HubMarkdown('''
Komut:

```bash
flutter analyze
```
''')));

    expect(find.textContaining('flutter analyze'), findsOneWidget);
  });

  testWidgets('bağlantıya dokunma yukarı iletilir', (tester) async {
    String? tapped;
    await tester.pumpWidget(wrap(
      HubMarkdown(
        '[tasarım](artifacts/reference/flutter-app-design.md)',
        onTapLink: (text, href, title) => tapped = href,
      ),
    ));

    await tester.tap(find.textContaining('tasarım'));
    await tester.pumpAndSettle();

    expect(tapped, 'artifacts/reference/flutter-app-design.md');
  });

  testWidgets('koyu temada da sorunsuz çizilir', (tester) async {
    await tester.pumpWidget(wrap(
      const HubMarkdown('# Başlık\n\n`kod`\n\n> alıntı'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    ));

    expect(find.textContaining('Başlık'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
