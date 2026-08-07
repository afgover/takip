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

  testWidgets('menünün eylemleri anahtarlarıyla tanımlı', (tester) async {
    await pumpDoc(tester);

    // Eylemler artık **anahtarla** bulunuyor, metinle değil (sözleşme 1.18):
    // etiket dile göre değişiyor ve metni kimlik saymak menüyü seçili dile
    // bağımlı kılardı. Anahtarların sabitliği bu testin konusu; etiketlerin
    // doğruluğu `language_switch_test`'in.
    expect(AnnotatedDocument.highlightKey, const Key('selection-highlight'));
    expect(AnnotatedDocument.underlineKey, const Key('selection-underline'));
    expect(AnnotatedDocument.bookmarkKey, const Key('selection-bookmark'));
    expect(AnnotatedDocument.noteKey, const Key('selection-note'));
    expect(AnnotatedDocument.taskKey, const Key('selection-task'));
    expect(AnnotatedDocument.copyKey, const Key('selection-copy'));
  });

  testWidgets('seçim yokken menü boş kalır', (tester) async {
    await pumpDoc(tester);
    // Hiçbir seçim yapılmadan menü açılırsa eylem sunulmamalı: seçim
    // olmadan işaretlenecek ya da alıntılanacak bir şey yok.
    expect(find.byKey(AnnotatedDocument.highlightKey), findsNothing);
    expect(find.byKey(AnnotatedDocument.taskKey), findsNothing);
  });
}
