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

({Widget widget, FakeAdapter adapter}) buildScreen(String path) {
  final adapter = FakeAdapter((options, _) {
    if (options.method == 'GET') {
      return jsonResponse({
        'path': path,
        'sha': 'sha1',
        'content': base64.encode(utf8.encode(_taskFile)),
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
      child: MaterialApp(home: TaskDetailScreen(summary: summaryFor(path))),
    ),
    adapter: adapter,
  );
}

Finder get doneButton => find.byKey(const Key('waiting-done-button'));

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
}
