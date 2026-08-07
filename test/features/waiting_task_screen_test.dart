import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/features/pending/task_detail_screen.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/task_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

import '../helpers/test_app.dart';

const waitingPath = '${Hub.waitingDir}/2026-08-01-token-uret.md';
const activePath = '${Hub.activeDir}/2026-08-01-baska-is.md';

const _taskFile = '''
---
id: T-007
title: "Fine-grained token üret"
created_by: agent
created: "2026-08-01T06:00:00Z"
updated: "2026-08-01T06:00:00Z"
priority: high
category: gorev
tags: []
session: S-2026-08-01-x
result: none
---

# Fine-grained token üret

## Notlar
Beklenen: token üretilip uygulamaya girilmesi.
''';

TaskSummary summaryFor(String path) => TaskSummary.fromEntry(
      path: path,
      name: path.split('/').last,
      sha: 'sha1',
      status: TaskStatus.fromPath(path)!,
    )!;

/// Seçenekli bekleme (sözleşme 1.12): agent soru soruyor, kullanıcı seçiyor.
const _questionFile = '''
---
id: T-009
title: "Token kapsamı ne olsun?"
created_by: agent
created: "2026-08-04T06:00:00Z"
updated: "2026-08-04T06:00:00Z"
priority: high
category: gorev
tags: []
session: S-2026-08-04-x
result: none
options: ["Fine-grained üreteceğim", "Klasikle devam", "Sonra bakalım"]
---

# Token kapsamı ne olsun?

## Notlar
Beklenen: karar.
''';

/// Aynısı çoklu seçimli.
final _multiQuestionFile =
    _questionFile.replaceFirst('result: none', 'result: none\nmulti: "true"');

({Widget widget, FakeAdapter adapter}) buildScreen(
  String path, {
  String? file,
}) {
  final adapter = FakeAdapter((options, _) {
    if (options.method == 'GET') {
      return jsonResponse({
        'path': path,
        'sha': 'sha1',
        'content': base64.encode(utf8.encode(file ?? _taskFile)),
        'encoding': 'base64',
      });
    }
    return jsonResponse({
      'content': {'sha': 'yeni'}
    });
  });
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;

  return (
    widget: ProviderScope(
      overrides: [
        taskRepoProvider.overrideWithValue(
          TaskRepo(ContentsApi(dio, owner: 'afgover', repo: 'takip')),
        ),
      ],
      child: testApp(TaskDetailScreen(summary: summaryFor(path))),
    ),
    adapter: adapter,
  );
}

Finder get doneButton => find.byKey(const Key('waiting-done-button'));
Finder get answerButton => find.byKey(const Key('waiting-answer-button'));
Finder option(int index) => find.byKey(Key('waiting-option-$index'));

/// Gönderilen bildirimin gövdesi (base64 çözülmüş).
String sentBody(FakeAdapter adapter) {
  final put = adapter.requests.firstWhere((r) => r.method == 'PUT');
  final data = put.data as Map;
  return utf8.decode(base64.decode(data['content'] as String));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('bekleyen görevde şerit ve "Yaptım" düğmesi görünür',
      (tester) async {
    await tester.pumpWidget(buildScreen(waitingPath).widget);
    await tester.pumpAndSettle();

    expect(find.text('Seni bekliyor'), findsOneWidget);
    expect(doneButton, findsOneWidget);
    expect(find.textContaining('Bu iş seni bekliyor'), findsOneWidget);
    // Beklenenin ne olduğu görev notlarından okunuyor.
    expect(find.textContaining('token üretilip'), findsOneWidget);
  });

  testWidgets('bekleyen olmayan görevde düğme yok', (tester) async {
    await tester.pumpWidget(buildScreen(activePath).widget);
    await tester.pumpAndSettle();

    expect(doneButton, findsNothing);
    expect(find.textContaining('Bu iş seni bekliyor'), findsNothing);
  });

  testWidgets('"Yaptım" inbox\'a bildirim yazar, asıl görevi taşımaz',
      (tester) async {
    final built = buildScreen(waitingPath);
    await tester.pumpWidget(built.widget);
    await tester.pumpAndSettle();

    await tester.tap(doneButton);
    await tester.pumpAndSettle();

    final writes = built.adapter.requests.where((r) => r.method == 'PUT');
    expect(writes, hasLength(1));
    expect(Uri.decodeComponent(writes.single.uri.path), contains(Hub.inboxDir));

    // R-001: silme yok, waiting/ dosyasına dokunulmuyor.
    expect(built.adapter.requests.any((r) => r.method == 'DELETE'), isFalse);
    expect(
      built.adapter.requests.any(
        (r) => r.method != 'GET' &&
            Uri.decodeComponent(r.uri.path).contains(Hub.waitingDir),
      ),
      isFalse,
    );

    expect(find.text('Agent\'a bildirildi.'), findsOneWidget);
  });

  testWidgets('bildirimden sonra düğme kapanır (kopya bildirim olmasın)',
      (tester) async {
    final built = buildScreen(waitingPath);
    await tester.pumpWidget(built.widget);
    await tester.pumpAndSettle();

    await tester.tap(doneButton);
    await tester.pumpAndSettle();
    expect(find.text('Bildirildi'), findsOneWidget);

    await tester.tap(doneButton);
    await tester.pumpAndSettle();

    expect(built.adapter.requests.where((r) => r.method == 'PUT'), hasLength(1),
        reason: 'ikinci dokunuş yeni istek atmamalı');
  });

  group('seçenekli bekleme (sözleşme 1.12, T-007)', () {
    testWidgets('seçenekler görünür, "Yaptım" görünmez', (tester) async {
      await tester
          .pumpWidget(buildScreen(waitingPath, file: _questionFile).widget);
      await tester.pumpAndSettle();

      expect(find.text('Fine-grained üreteceğim'), findsOneWidget);
      expect(find.text('Klasikle devam'), findsOneWidget);
      expect(answerButton, findsOneWidget);
      // Agent soru sordu; cevabı "yaptım" değil seçim.
      expect(doneButton, findsNothing);
    });

    testWidgets('seçim yapılmadan gönderilemez', (tester) async {
      final built = buildScreen(waitingPath, file: _questionFile);
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      await tester.tap(answerButton);
      await tester.pumpAndSettle();

      expect(built.adapter.requests.any((r) => r.method == 'PUT'), isFalse);
    });

    testWidgets('tek seçimde ikinci seçenek birincinin yerine geçer',
        (tester) async {
      final built = buildScreen(waitingPath, file: _questionFile);
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      await tester.tap(option(0));
      await tester.pump();
      await tester.tap(option(1));
      await tester.pump();
      await tester.tap(answerButton);
      await tester.pumpAndSettle();

      final body = sentBody(built.adapter);
      expect(body, contains('**Seçim:** Klasikle devam'));
      expect(body, isNot(contains('Fine-grained üreteceğim')));
      expect(body, contains('waiting-answer'));
    });

    testWidgets('multi: true ise birden çok seçilir, sıra listeden gelir',
        (tester) async {
      final built = buildScreen(waitingPath, file: _multiQuestionFile);
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      // Ters sırada dokunuluyor; kayıtta listedeki sıra görünmeli.
      await tester.tap(option(2));
      await tester.pump();
      await tester.tap(option(0));
      await tester.pump();
      await tester.tap(answerButton);
      await tester.pumpAndSettle();

      expect(
        sentBody(built.adapter),
        contains('**Seçim:** Fine-grained üreteceğim · Sonra bakalım'),
      );
    });

    testWidgets('açıklama yazılırsa cevaba eklenir', (tester) async {
      final built = buildScreen(waitingPath, file: _questionFile);
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      await tester.tap(option(0));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('waiting-answer-note')),
        'Hafta içinde üretirim.',
      );
      await tester.tap(answerButton);
      await tester.pumpAndSettle();

      expect(
        sentBody(built.adapter),
        contains('**Açıklama:** Hafta içinde üretirim.'),
      );
    });

    testWidgets('cevaptan sonra soru kapanır', (tester) async {
      final built = buildScreen(waitingPath, file: _questionFile);
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      await tester.tap(option(0));
      await tester.pump();
      await tester.tap(answerButton);
      await tester.pumpAndSettle();
      expect(find.text('Cevaplandı'), findsOneWidget);

      await tester.tap(answerButton);
      await tester.pumpAndSettle();
      expect(
        built.adapter.requests.where((r) => r.method == 'PUT'),
        hasLength(1),
        reason: 'bir görev = bir soru; ikinci cevap gitmemeli',
      );
    });

    testWidgets('cevap inbox\'a yazılır, waiting/ dosyasına dokunulmaz',
        (tester) async {
      final built = buildScreen(waitingPath, file: _questionFile);
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      await tester.tap(option(0));
      await tester.pump();
      await tester.tap(answerButton);
      await tester.pumpAndSettle();

      final writes = built.adapter.requests.where((r) => r.method == 'PUT');
      expect(Uri.decodeComponent(writes.single.uri.path), contains(Hub.inboxDir));
      expect(built.adapter.requests.any((r) => r.method == 'DELETE'), isFalse);
    });

    testWidgets('waiting dışında seçenek olsa da cevap düğmesi çıkmaz',
        (tester) async {
      // options yalnız waiting/'te anlamlı: başka klasördeki iş kullanıcıyı
      // beklemiyordur.
      await tester
          .pumpWidget(buildScreen(activePath, file: _questionFile).widget);
      await tester.pumpAndSettle();

      expect(answerButton, findsNothing);
      expect(doneButton, findsNothing);
    });
  });
}
