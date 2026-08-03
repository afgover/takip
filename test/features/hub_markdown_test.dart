import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/common/hub_markdown.dart';
import 'package:takip/hub/annotations.dart';
import 'package:takip/hub/models/task.dart';

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

  // --- İşaretler ---------------------------------------------------------
  //
  // Buradaki asıl test **yükseklik** testi. Kullanıcının şikâyeti "işaretli
  // kelimeden sonrası alt satıra kayıyor"du; rengin doğru olması yetmiyor,
  // metnin akışı işaretsiz hâliyle birebir aynı kalmalı.

  /// İşaretli ve işaretsiz aynı metnin kapladığı yükseklik.
  Future<(double plain, double marked)> heights(
    WidgetTester tester,
    String text,
    List<Annotation> annotations,
  ) async {
    Future<double> measure(List<Annotation> anns) async {
      await tester.pumpWidget(wrap(SizedBox(
        width: 300,
        child: HubMarkdown(text, annotations: anns, selectable: false),
      )));
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(HubMarkdown)).height;
    }

    return (await measure(const []), await measure(annotations));
  }

  testWidgets('işaret satır akışını bozmuyor', (tester) async {
    const text = 'Bir iki uc dort bes alti yedi sekiz dokuz on onbir oniki '
        'onuc ondort onbes onalti onyedi onsekiz ondokuz yirmi yirmibir.';

    final (plain, marked) = await heights(tester, text, [
      annotationOf('bes alti', TaskMark.highlight),
    ]);

    expect(marked, plain,
        reason: 'işaretli metin işaretsizle aynı satır sayısında olmalı');
  });

  testWidgets('işaret kalın/kod içeren satırda da akışı bozmuyor',
      (tester) async {
    // Gerçek hub metinleri düz nesir değil; `**kalın**` ve `` `kod` `` dolu.
    // Önceki çözüm yalnız düz nesirde çalıştığı için cihazda hiç işe
    // yaramamıştı (L-032).
    const text = 'Sozlesme **v1.8** ile `mark: comment` alani geldi ve bu '
        'sayede yorumlar sari isaretten ayrilabiliyor artik tamamen.';

    final (plain, marked) = await heights(tester, text, [
      annotationOf('geldi ve', TaskMark.underline),
    ]);

    expect(marked, plain);
  });

  testWidgets('üç işaret de kendi rengiyle tek metin akışında çizilir',
      (tester) async {
    await tester.pumpWidget(wrap(SizedBox(
      width: 300,
      child: HubMarkdown(
        'Bir iki uc dort bes alti yedi sekiz dokuz on onbir oniki onuc.',
        selectable: false,
        annotations: [
          annotationOf('iki', TaskMark.highlight),
          annotationOf('bes', TaskMark.underline),
          annotationOf('dokuz', TaskMark.comment),
        ],
      ),
    )));
    await tester.pumpAndSettle();

    final styles = <TextStyle>[];
    void walk(InlineSpan span) {
      if (span is TextSpan) {
        if (span.style != null) styles.add(span.style!);
        span.children?.forEach(walk);
      }
    }
    final texts = tester.widgetList<RichText>(find.byType(RichText)).toList();
    for (final rt in texts) {
      walk(rt.text);
    }

    // Paragrafın tamamı **tek** bir RichText: işaret ayrı bir kutu değil,
    // aynı metin akışının parçası. Bozulmanın kaynağı buydu.
    expect(texts, hasLength(1));

    expect(styles.where((s) => s.backgroundColor == const Color(0xFFFFE082)),
        hasLength(1), reason: 'sarı işaret');
    expect(styles.where((s) => s.backgroundColor == const Color(0xFFA5D6A7)),
        hasLength(1), reason: 'yeşil yorum — sarıdan ayrı olmalı');
    expect(styles.where((s) => s.decoration == TextDecoration.underline),
        hasLength(1), reason: 'kırmızı altı çizili');
  });

  testWidgets('işarete dokunma SelectionArea altında da ulaşıyor',
      (tester) async {
    // İşaret artık kendi widget'ı değil, metin akışındaki bir `TextSpan`.
    // Dokunma `TapGestureRecognizer` ile geliyor ve belgeler her yerde
    // `SelectionArea` içinde çiziliyor; seçim katmanının dokunmayı yutmadığı
    // burada sınanıyor — `onTap`'i elle çağırmak bunu göstermezdi.
    Annotation? tapped;
    final annotation = annotationOf('ikinci', TaskMark.highlight);

    await tester.pumpWidget(wrap(SelectionArea(
      child: HubMarkdown(
        'Bir ikinci ucuncu dort.',
        selectable: false,
        annotations: [annotation],
        onTapAnnotation: (a) => tapped = a,
      ),
    )));
    await tester.pumpAndSettle();

    final finder = find.byType(RichText).first;
    final paragraph = tester.renderObject(finder) as RenderParagraph;
    final at = paragraph.text.toPlainText().indexOf('ikinci');
    final box = paragraph
        .getBoxesForSelection(
            TextSelection(baseOffset: at, extentOffset: at + 'ikinci'.length))
        .first;

    await tester.tapAt(box.toRect().center + tester.getTopLeft(finder));
    await tester.pumpAndSettle();

    expect(tapped?.quote, 'ikinci');
  });
}

Annotation annotationOf(String quote, TaskMark mark) => Annotation(
      quote: quote,
      mark: mark,
      title: quote,
      category: 'yorum',
      path: 'hub/tasks/inbox/2026-08-03-x.md',
    );
