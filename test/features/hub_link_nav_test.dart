import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/browse/document_screen.dart';
import 'package:takip/features/common/annotated_document.dart';
import 'package:takip/features/common/hub_link_nav.dart';
import 'package:takip/hub/browse_repo.dart';

import '../helpers/test_app.dart';

/// Belgeler arası geçiş (sözleşme 1.25 §15) — uygulama tarafı.
void main() {
  const backlog = '''
# BACKLOG.md

- [x] B-096 · bir madde
- [ ] B-097 · [SEC-010](SECURITY.md#SEC-010) ile ilgili madde
''';

  const security = '''
# SECURITY.md

## SEC-001 — ilk kayıt
gövde

## SEC-010 — aranan kayıt
gövde
''';

  Widget wrap(Widget home) => ProviderScope(
        overrides: [
          docContentProvider.overrideWith((ref, path) async =>
              path.endsWith('SECURITY.md') ? security : backlog),
        ],
        child: testApp(home),
      );

  testWidgets('hub içi bağlantıya dokununca hedef belge açılır',
      (tester) async {
    await tester.pumpWidget(wrap(const DocumentScreen(
      path: 'hub/BACKLOG.md',
      title: 'Backlog',
    )));
    await tester.pumpAndSettle();

    // Markdown içindeki bağlantı metnine dokunmak yerine geçiş doğrudan
    // sınanıyor: `flutter_markdown` bağlantıyı `TextSpan` olarak çiziyor ve
    // widget testinde span'a dokunmak metnin sarma konumuna bağlı olurdu.
    final context = tester.element(find.byType(AnnotatedDocument).first);
    openHubLink(
      context,
      href: 'SECURITY.md#SEC-010',
      fromPath: 'hub/BACKLOG.md',
    );
    await tester.pumpAndSettle();

    // Yeni ekranın başlığı dosya adı (gövdedeki `# SECURITY.md` başlığıyla
    // karışmasın diye AppBar'da aranıyor).
    expect(find.widgetWithText(AppBar, 'SECURITY.md'), findsOneWidget);
    expect(find.textContaining('aranan kayıt'), findsOneWidget);
  });

  testWidgets('çapa belgeyi ikiye bölüyor — kaydırma hedefi oluşuyor',
      (tester) async {
    await tester.pumpWidget(wrap(const DocumentScreen(
      path: 'hub/SECURITY.md',
      title: 'Güvenlik',
      anchor: 'SEC-010',
    )));
    await tester.pumpAndSettle();

    // Çapa bulunduğunda gövde iki parça hâlinde çiziliyor; parçaların arasına
    // konan işaret kaydırmanın hedefi oluyor.
    expect(find.byType(AnnotatedDocument), findsNWidgets(2));
  });

  testWidgets('bulunamayan çapa belgeyi baştan açar, hata vermez',
      (tester) async {
    await tester.pumpWidget(wrap(const DocumentScreen(
      path: 'hub/SECURITY.md',
      title: 'Güvenlik',
      anchor: 'SEC-999',
    )));
    await tester.pumpAndSettle();

    expect(find.byType(AnnotatedDocument), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub dışı bağlantı açılmaz, kullanıcıya söylenir',
      (tester) async {
    await tester.pumpWidget(wrap(const DocumentScreen(
      path: 'hub/BACKLOG.md',
      title: 'Backlog',
    )));
    await tester.pumpAndSettle();

    openHubLink(
      tester.element(find.byType(AnnotatedDocument).first),
      href: 'https://github.com/afgover/takip',
      fromPath: 'hub/BACKLOG.md',
    );
    await tester.pumpAndSettle();

    // Sessizce hiçbir şey yapmayan bir dokunuş, uygulamanın donduğunu
    // düşündürür.
    expect(find.textContaining('hub dışına'), findsOneWidget);
    expect(find.text('Backlog'), findsOneWidget); // ekran değişmedi
  });
}
