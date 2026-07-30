import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/add_task/add_task_screen.dart';
import 'package:takip/hub/frontmatter.dart';
import 'package:takip/hub/task_repo.dart';
import 'package:takip/github/contents_api.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

({Widget widget, FakeAdapter adapter}) buildScreen({
  ResponseBody Function(RequestOptions options, String? body)? handler,
}) {
  final adapter = FakeAdapter(
    handler ??
        (_, __) => jsonResponse({
              'content': {'sha': 'yeni-sha'}
            }),
  );
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;
  final repo = TaskRepo(ContentsApi(dio, owner: 'afgover', repo: 'takip'));

  return (
    widget: ProviderScope(
      overrides: [taskRepoProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: AddTaskScreen()),
    ),
    adapter: adapter,
  );
}

Future<void> fillAndSubmit(
  WidgetTester tester, {
  String title = 'Market listesi',
  String description = 'Süt, ekmek.',
}) async {
  await tester.enterText(find.byKey(AddTaskScreen.titleFieldKey), title);
  await tester.enterText(
      find.byKey(AddTaskScreen.descriptionFieldKey), description);
  await tester.tap(find.byKey(AddTaskScreen.submitKey));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('başlık boşken istek atılmaz', (tester) async {
    final built = buildScreen();
    await tester.pumpWidget(built.widget);

    await tester.tap(find.byKey(AddTaskScreen.submitKey));
    await tester.pumpAndSettle();

    expect(find.text('Başlık gerekli'), findsOneWidget);
    expect(built.adapter.requests, isEmpty);
  });

  testWidgets('slug üretmeyen başlık reddedilir', (tester) async {
    final built = buildScreen();
    await tester.pumpWidget(built.widget);

    await tester.enterText(find.byKey(AddTaskScreen.titleFieldKey), '!!! ???');
    await tester.tap(find.byKey(AddTaskScreen.submitKey));
    await tester.pumpAndSettle();

    expect(find.text('Başlık harf ya da rakam içermeli'), findsOneWidget);
    expect(built.adapter.requests, isEmpty);
  });

  testWidgets('görev inbox\'a sözleşme biçiminde yazılır', (tester) async {
    final built = buildScreen();
    await tester.pumpWidget(built.widget);

    await fillAndSubmit(tester);

    final request = built.adapter.requests.single;
    expect(request.method, 'PUT');
    expect(
      request.path,
      startsWith('/repos/afgover/takip/contents/hub/tasks/inbox/'),
    );
    expect(request.path, endsWith('-market-listesi.md'));

    final sent = jsonDecode(built.adapter.bodies.single!) as Map;
    expect(sent['message'], "task(pending): inbox'a eklendi (app)");
    expect(sent.containsKey('sha'), isFalse, reason: 'yeni dosya');

    final fm = Frontmatter.parse(
      utf8.decode(base64.decode(sent['content'] as String)),
    );
    expect(fm.str('id'), 'pending');
    expect(fm.str('created_by'), 'user');
    expect(fm.str('title'), 'Market listesi');
    expect(fm.body, contains('Süt, ekmek.'));
  });

  testWidgets('gönderim sonrası form temizlenir ve bildirim çıkar',
      (tester) async {
    final built = buildScreen();
    await tester.pumpWidget(built.widget);

    await fillAndSubmit(tester);

    expect(find.text('Görev hub\'a gönderildi.'), findsOneWidget);
    final titleField = tester.widget<TextFormField>(
      find.byKey(AddTaskScreen.titleFieldKey),
    );
    expect(titleField.controller?.text, isEmpty);
  });

  testWidgets('hata durumunda sebep gösterilir, form korunur', (tester) async {
    final built = buildScreen(
      handler: (_, __) =>
          jsonResponse({'message': 'Bad credentials'}, status: 401),
    );
    await tester.pumpWidget(built.widget);

    await fillAndSubmit(tester);

    expect(find.textContaining('Token geçersiz'), findsOneWidget);
    final titleField = tester.widget<TextFormField>(
      find.byKey(AddTaskScreen.titleFieldKey),
    );
    expect(titleField.controller?.text, 'Market listesi',
        reason: 'hatada kullanıcının yazdığı kaybolmamalı');
  });

  testWidgets('yeni kategori girilebilir ve sonraki açılışta listede olur',
      (tester) async {
    final built = buildScreen();
    await tester.pumpWidget(built.widget);

    await tester.tap(find.byKey(AddTaskScreen.categoryFieldKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yeni kategori…').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AddTaskScreen.newCategoryFieldKey),
      'alisveris',
    );
    await fillAndSubmit(tester);

    final sent = jsonDecode(built.adapter.bodies.single!) as Map;
    final fm = Frontmatter.parse(
      utf8.decode(base64.decode(sent['content'] as String)),
    );
    expect(fm.str('category'), 'alisveris');

    // K-010: görülen kategori cihazda saklanır, sonraki açılışta listede.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('seen_categories'), contains('alisveris'));
  });

  testWidgets('yeni kategori seçilip adı boş bırakılırsa gönderilmez',
      (tester) async {
    final built = buildScreen();
    await tester.pumpWidget(built.widget);

    await tester.tap(find.byKey(AddTaskScreen.categoryFieldKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yeni kategori…').last);
    await tester.pumpAndSettle();

    await fillAndSubmit(tester);

    expect(find.text('Kategori adı gerekli'), findsOneWidget);
    expect(built.adapter.requests, isEmpty);
  });
}
