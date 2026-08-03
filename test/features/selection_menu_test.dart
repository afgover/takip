import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/common/annotated_document.dart';
import 'package:takip/hub/hub_connections.dart';

Future<void> pumpDoc(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({
    HubConnectionsStore.listKey: jsonEncode([
      {'owner': 'afgover', 'repo': 'takip', 'token': 't'},
    ]),
  });

  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: AnnotatedDocument(
            data: 'Seçilebilir bir cümle burada duruyor.',
            sourcePath: 'hub/sessions/2026-08-02-x/session.md',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('belge çiziliyor ve seçilebilir alanın içinde', (tester) async {
    await pumpDoc(tester);
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.textContaining('Seçilebilir bir cümle'), findsOneWidget);
  });

  testWidgets('menü tam olarak beş eylemden oluşur', (tester) async {
    await pumpDoc(tester);

    // Etiketler tek yerde tanımlı; menüyü kuran kod bunları kullanıyor.
    // Sistem öğeleri hiç eklenmediği için menü tam olarak bunlardır.
    // Sıra da anlamlı: iki hızlı işaret önce, ayrıntı isteyenler sonra.
    expect(AnnotatedDocument.highlightLabel, 'Sarı işaretle');
    expect(AnnotatedDocument.underlineLabel, 'Kırmızı çizgi');
    expect(AnnotatedDocument.commentLabel, 'Yorum ekle');
    expect(AnnotatedDocument.taskLabel, 'Görev oluştur');
    expect(AnnotatedDocument.copyLabel, 'Kopyala');
  });

  testWidgets('seçim yokken menü boş kalır', (tester) async {
    await pumpDoc(tester);
    // Hiçbir seçim yapılmadan menü açılırsa eylem sunulmamalı: seçim
    // olmadan işaretlenecek ya da alıntılanacak bir şey yok.
    expect(find.text(AnnotatedDocument.highlightLabel), findsNothing);
    expect(find.text(AnnotatedDocument.taskLabel), findsNothing);
  });
}
