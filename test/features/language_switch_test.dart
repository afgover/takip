import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/browse/browse_screen.dart';

import '../helpers/test_app.dart';

/// Dil seçeneğinin **gerçekten** çalıştığının kanıtı (sözleşme 1.18).
///
/// Altyapıyı kurup "İngilizce eklendi" demek, bu hafta üç kez hata yaptığım
/// kalıbın aynısı olurdu (L-035, L-039, L-040): iddia edilen ama ölçülmeyen
/// davranış. Aynı ekran iki dilde çizilip karşılaştırılıyor.
void main() {
  testWidgets('aynı ekran seçilen dile göre çiziliyor', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> pump(Locale locale) async {
      await tester.pumpWidget(ProviderScope(
        child: testApp(const BrowseScreen(), locale: locale),
      ));
      await tester.pumpAndSettle();
    }

    await pump(const Locale('tr'));
    expect(find.text('Tamamlananlar'), findsOneWidget);
    expect(find.text('Hub Tarayıcı'), findsOneWidget);
    expect(find.text('Completed'), findsNothing);

    await pump(const Locale('en'));
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Hub browser'), findsOneWidget);
    expect(find.text('Tamamlananlar'), findsNothing);
  });

  testWidgets('desteklenmeyen dil İngilizce\'ye düşer', (tester) async {
    // Cihazı Almanca olan biri boş ekran değil, anlaşılır bir dil görmeli.
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(
      child: testApp(const BrowseScreen(), locale: const Locale('de')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
  });
}
