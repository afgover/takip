import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/settings/queued_drafts_sheet.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/models/task_draft.dart';
import 'package:takip/hub/outbox.dart';

import '../helpers/test_app.dart';

/// Kuyruk taslakları düzenlenip silinebilir (T-021).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      HubConnectionsStore.listKey: jsonEncode([
        {'owner': 'afgover', 'repo': 'takip', 'token': 't'},
      ]),
    });
  });

  TaskDraft draft({String title = 'Çevrimdışı görev'}) => TaskDraft.create(
        title: title,
        description: 'İlk açıklama.',
        priority: 'high',
        category: 'hata',
        repoSlug: 'afgover/takip',
      );

  Future<ProviderContainer> pumpSheet(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(outboxProvider.notifier).add(draft());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: testApp(const Scaffold(body: QueuedDraftsSheet())),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  test('descriptionFromContent gövdedeki açıklamayı geri çıkarır', () {
    expect(draft().descriptionFromContent, 'İlk açıklama.');
    final bos = TaskDraft.create(title: 'Başlık');
    // Açıklamasız taslakta iskeletin "verilmedi" cümlesi düzenleme alanına
    // sızmamalı — kullanıcı kendi yazmadığı metni düzenlememeli.
    expect(bos.descriptionFromContent, '');
  });

  test('edited() öteki alanları taslağın kendisinden korur', () {
    final e = draft().edited(title: 'Yeni başlık', description: 'Yeni metin');
    expect(e.title, 'Yeni başlık');
    expect(e.descriptionFromContent, 'Yeni metin');
    expect(e.repoSlug, 'afgover/takip');
    expect(e.content, contains('priority: high'));
    expect(e.content, contains('category: hata'));
  });

  testWidgets('silme onay ister; onaylanınca taslak kuyruktan düşer',
      (tester) async {
    final container = await pumpSheet(tester);
    expect(find.text('Çevrimdışı görev'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    // Onaysız hiçbir şey silinmez.
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(container.read(outboxProvider).valueOrNull, hasLength(1));

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil').last);
    await tester.pumpAndSettle();
    expect(container.read(outboxProvider).valueOrNull, isEmpty);
  });

  testWidgets('düzenleme kuyruktaki taslağı yerinde günceller',
      (tester) async {
    final container = await pumpSheet(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.text('Çevrimdışı görev'), 'Düzeltilmiş görev');
    await tester.enterText(find.text('İlk açıklama.'), 'Düzeltilmiş açıklama.');
    await tester.tap(find.text('Düzenle').last);
    await tester.pumpAndSettle();

    final drafts = container.read(outboxProvider).valueOrNull!;
    expect(drafts, hasLength(1));
    expect(drafts.single.title, 'Düzeltilmiş görev');
    expect(drafts.single.descriptionFromContent, 'Düzeltilmiş açıklama.');
    // Öncelik/kategori düzenlemede kaybolmaz.
    expect(drafts.single.content, contains('priority: high'));
  });
}
