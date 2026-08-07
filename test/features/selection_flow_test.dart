import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/features/common/annotated_document.dart';
import 'package:takip/features/common/selection_record.dart';
import 'package:takip/github/client.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/models/task.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

import '../helpers/test_app.dart';

/// Seçimden kayda giden **zincirin tamamı**.
///
/// Parçaların hepsi ayrı ayrı test ediliyordu (menü kuruluyor mu, kutu not
/// döndürüyor mu, depo PUT atıyor mu) ve hepsi geçiyordu; buna rağmen cihazda
/// yorum eklemek hiçbir şey yapmıyordu. Kopukluk parçaların **arasındaydı**,
/// yani hiçbir testin bakmadığı yerde. Bu dosya araya bakıyor: gerçek metin
/// seçiliyor, gerçek menüye dokunuluyor, sahte GitHub'a giden isteğe bakılıyor.
const _doc = 'Birinci cümle burada duruyor. İkinci cümle de var.';
const _sourcePath = 'hub/sessions/2026-08-03-x/session.md';

({Widget widget, FakeAdapter adapter}) buildDoc() {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({
    HubConnectionsStore.listKey: jsonEncode([
      {'owner': 'afgover', 'repo': 'takip', 'token': 't'},
    ]),
  });

  final adapter = FakeAdapter((options, _) {
    // Kayıt listesi (işaretleri türeten okuma) boş dönsün.
    if (options.method == 'GET') {
      return jsonResponse({'message': 'Not Found'}, status: 404);
    }
    return jsonResponse({
      'content': {'path': options.uri.path, 'sha': 'yeni'},
      'commit': {'sha': 'c1'},
    });
  });

  return (
    widget: ProviderScope(
      overrides: [
        githubDioProvider.overrideWith((ref) {
          final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
            ..httpClientAdapter = adapter;
          return dio;
        }),
      ],
      child: testApp(
        const Scaffold(
          body: AnnotatedDocument(data: _doc, sourcePath: _sourcePath),
        ),
      ),
    ),
    adapter: adapter,
  );
}

/// Metnin bir bölümünü gerçekten seçer — `SelectionArea` uzun basıp
/// sürüklemeyle çalışıyor, bu yüzden test de öyle yapıyor.
Future<void> selectText(WidgetTester tester) async {
  final text = find.byType(RichText).first;
  final box = tester.getRect(text);
  final start = Offset(box.left + 4, box.top + box.height / 2);

  final gesture = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 600)); // uzun basış
  await gesture.moveTo(Offset(box.left + 90, start.dy));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('seçim menüsü gerçek seçimde açılıyor', (tester) async {
    final t = buildDoc();
    await tester.pumpWidget(t.widget);
    await tester.pumpAndSettle();

    await selectText(tester);

    expect(
      find.byKey(AnnotatedDocument.noteKey),
      findsOneWidget,
      reason: 'seçim yapıldığında menü açılmalı',
    );
  });

  testWidgets('not `notes/`a yazılır, görev olarak yazılmaz', (tester) async {
    final t = buildDoc();
    await tester.pumpWidget(t.widget);
    await tester.pumpAndSettle();

    await selectText(tester);
    await tester.tap(find.byKey(AnnotatedDocument.noteKey));
    await tester.pumpAndSettle();

    expect(find.byKey(noteFieldKey), findsOneWidget,
        reason: 'not kutusu açılmalı');
    await tester.enterText(find.byKey(noteFieldKey), 'buraya dikkat');
    await tester.tap(find.byKey(noteSubmitKey));
    await tester.pumpAndSettle();

    final puts = t.adapter.requests.where((r) => r.method == 'PUT').toList();
    expect(puts, hasLength(1), reason: 'not hub\'a yazılmalı');

    // Kullanıcının asıl şikâyeti buydu: kendine aldığı not agent'ın iş
    // kuyruğuna düşüyordu. Notun `tasks/` altına **hiç** yazılmaması gerek.
    final path = Uri.decodeFull(puts.single.uri.path);
    expect(path, contains('/${Hub.notesDir}/'));
    expect(path, isNot(contains('/tasks/')),
        reason: 'not görev değil — iş kuyruğuna girmemeli');

    final body = jsonDecode(jsonEncode(puts.single.data)) as Map;
    final content = utf8.decode(base64.decode(body['content'] as String));
    expect(content, contains('mark: comment'),
        reason: 'notun kendi rengi olmalı — sarı işaretten ayrılmalı');
    expect(content, contains('buraya dikkat'));
    expect(content, isNot(contains('priority:')),
        reason: 'notun önceliği/durumu yok — görev şeması taşımamalı');
  });

  testWidgets('notsuz sarı işaret göreve DEĞİL nota gidiyor', (tester) async {
    // Karar değişti: boş seçim iş kuyruğunu doldurmasın. Notsuz hızlı işaret
    // artık `notes/`a düşüyor — belgede işaret olarak kalıyor ama Bekleyen
    // görevler'e girmiyor. Agent'a iş çıkarmak isteyen not yazar (aşağıdaki test).
    final t = buildDoc();
    await tester.pumpWidget(t.widget);
    await tester.pumpAndSettle();

    await selectText(tester);
    await tester.tap(find.byKey(AnnotatedDocument.highlightKey));
    await tester.pumpAndSettle();

    final path = Uri.decodeFull(
        t.adapter.requests.singleWhere((r) => r.method == 'PUT').uri.path);
    expect(path, contains('/${Hub.notesDir}/'));
    expect(path, isNot(contains('/tasks/')),
        reason: 'notsuz işaret iş kuyruğuna girmemeli');
  });

  testWidgets('notsuz işaret tek dokunuşta gider, rengini korur', (tester) async {
    final t = buildDoc();
    await tester.pumpWidget(t.widget);
    await tester.pumpAndSettle();

    await selectText(tester);
    await tester.tap(find.byKey(AnnotatedDocument.highlightKey));
    await tester.pumpAndSettle();

    final puts = t.adapter.requests.where((r) => r.method == 'PUT');
    expect(puts, hasLength(1), reason: 'tek dokunuş, tek gönderim');
    final body = jsonDecode(jsonEncode(puts.single.data)) as Map;
    final content = utf8.decode(base64.decode(body['content'] as String));
    // Nota düştü ama sarı rengini korudu — yeşile (comment) zorlanmadı.
    expect(content, contains('mark: highlight'));
  });

  testWidgets('not yazılınca seçim göreve dönüşür (tasks/inbox)',
      (tester) async {
    final t = buildDoc();
    await tester.pumpWidget(t.widget);
    await tester.pumpAndSettle();

    await selectText(tester);
    await tester.tap(find.byKey(AnnotatedDocument.taskKey));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(SelectionRecordSheet.noteFieldKey), 'şunu düzelt');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SelectionRecordSheet.submitKey));
    await tester.pumpAndSettle();

    final path = Uri.decodeFull(
        t.adapter.requests.singleWhere((r) => r.method == 'PUT').uri.path);
    expect(path, contains('/${Hub.inboxDir}/'),
        reason: 'notlu seçim agent iş kuyruğuna gider');
    final body = jsonDecode(jsonEncode(t.adapter.requests
        .singleWhere((r) => r.method == 'PUT')
        .data)) as Map;
    final content = utf8.decode(base64.decode(body['content'] as String));
    expect(content, contains('şunu düzelt'));
  });

  group('yer imi (sözleşme 1.12, T-008)', () {
    testWidgets('tek dokunuşta `notes/`a mavi işaret yazılır', (tester) async {
      final t = buildDoc();
      await tester.pumpWidget(t.widget);
      await tester.pumpAndSettle();

      await selectText(tester);
      await tester.tap(find.byKey(AnnotatedDocument.bookmarkKey));
      await tester.pumpAndSettle();

      final puts = t.adapter.requests.where((r) => r.method == 'PUT');
      expect(puts, hasLength(1));
      expect(Uri.decodeFull(puts.single.uri.path),
          contains('/${Hub.notesDir}/'));

      final body = jsonDecode(jsonEncode(puts.single.data)) as Map;
      final content = utf8.decode(base64.decode(body['content'] as String));
      expect(content, contains('mark: bookmark'));
    });

    testWidgets('not yazılsa bile göreve dönüşmez', (tester) async {
      // Diğer işaretlerde notlu seçim göreve gider (yukarıdaki test). Yer
      // iminde gitmez: niyet adında — "burayı sonra bulayım" agent'a iş değil.
      final t = buildDoc();
      await tester.pumpWidget(t.widget);
      await tester.pumpAndSettle();

      await selectText(tester);
      await tester.tap(find.byKey(AnnotatedDocument.taskKey));
      await tester.pumpAndSettle();

      await tester.tap(
          find.byKey(SelectionRecordSheet.markKey(TaskMark.bookmark)));
      await tester.enterText(
          find.byKey(SelectionRecordSheet.noteFieldKey), 'sonra oku');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SelectionRecordSheet.submitKey));
      await tester.pumpAndSettle();

      final puts = t.adapter.requests.where((r) => r.method == 'PUT');
      final path = Uri.decodeFull(puts.single.uri.path);
      expect(path, contains('/${Hub.notesDir}/'));
      expect(path, isNot(contains('/tasks/')),
          reason: 'yer imi hiçbir koşulda iş kuyruğuna girmemeli');

      final body = jsonDecode(jsonEncode(puts.single.data)) as Map;
      final content = utf8.decode(base64.decode(body['content'] as String));
      expect(content, contains('mark: bookmark'));
      expect(content, contains('sonra oku'), reason: 'not kaybolmamalı');
    });
  });
}
