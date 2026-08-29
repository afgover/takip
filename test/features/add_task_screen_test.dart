import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/add_task/add_task_screen.dart';
import 'package:takip/hub/frontmatter.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/task_repo.dart';
import 'package:takip/github/client.dart';
import 'package:takip/github/contents_api.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

import '../helpers/test_app.dart';

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
      child: testApp(AddTaskScreen()),
    ),
    adapter: adapter,
  );
}

/// İki bağlantılı kurulum: hedef repo seçicisi ancak burada anlamlı.
///
/// `taskRepoProvider` **bilerek** sabitlenmiyor; ekran hedefi kendi seçtiği
/// için asıl ölçülen şey isteğin hangi repoya gittiği. Sahte depo konsaydı
/// test, hedefin doğru seçildiğini değil yalnızca bir istek atıldığını
/// ölçerdi.
({Widget widget, FakeAdapter adapter}) buildMultiRepoScreen({
  ResponseBody Function(RequestOptions options, String? body)? handler,
}) {
  FlutterSecureStorage.setMockInitialValues({
    HubConnectionsStore.listKey: jsonEncode([
      {'owner': 'a', 'repo': 'bir', 'token': 't1'},
      {'owner': 'b', 'repo': 'iki', 'token': 't2'},
    ]),
    HubConnectionsStore.activeKey: 'a/bir',
  });

  final adapter = FakeAdapter(
    handler ??
        (_, __) => jsonResponse({
              'content': {'sha': 'yeni-sha'}
            }),
  );
  final dio = buildGithubDio((_) => 't')..httpClientAdapter = adapter;

  return (
    widget: ProviderScope(
      overrides: [githubDioProvider.overrideWithValue(dio)],
      child: testApp(AddTaskScreen()),
    ),
    adapter: adapter,
  );
}

Future<void> chooseTarget(WidgetTester tester, String displayName) async {
  await tester.tap(find.byKey(AddTaskScreen.targetRepoFieldKey));
  await tester.pumpAndSettle();
  // `.last`: seçili değer düğmenin kendisinde de yazıyor; açılan listedeki
  // kopya sonuncusu.
  await tester.tap(find.text(displayName).last);
  await tester.pumpAndSettle();
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Güvenli depo da sıfırlanıyor: sahte değerler statik ve testler arasında
    // kalıcı. Sıfırlanmazsa "tek bağlantı" varsayan bir test, kendinden önce
    // koşan çok bağlantılı bir testin kurduğu düzeni görür ve sıraya bağlı
    // olarak kırılır.
    FlutterSecureStorage.setMockInitialValues({});
  });

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

  testWidgets('ağ yokken görev kuyruğa alınır, kaybolmaz', (tester) async {
    final built = buildScreen(
      handler: (options, _) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'ağ yok',
      ),
    );
    await tester.pumpWidget(built.widget);

    await fillAndSubmit(tester);

    expect(find.textContaining('kuyruğa alındı'), findsOneWidget);
    final titleField = tester.widget<TextFormField>(
      find.byKey(AddTaskScreen.titleFieldKey),
    );
    expect(titleField.controller?.text, isEmpty, reason: 'iş kaybolmadı');

    final prefs = await SharedPreferences.getInstance();
    final queued = prefs.getStringList('outbox')!;
    expect(queued, hasLength(1));
    expect(
      jsonDecode(queued.single)['fileName'],
      endsWith('-market-listesi.md'),
    );
  });

  testWidgets('yetki hatası kuyruğa alınmaz — beklemekle düzelmez',
      (tester) async {
    final built = buildScreen(
      handler: (_, __) =>
          jsonResponse({'message': 'Bad credentials'}, status: 401),
    );
    await tester.pumpWidget(built.widget);

    await fillAndSubmit(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('outbox'), anyOf(isNull, isEmpty));
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

  /// Görevin **hangi hub'a** gittiği ekranda görünür ve seçilebilir olmalı.
  ///
  /// Önceki hâlde hedef, başka bir ekranın durumundan (repo şeridi) türüyordu
  /// ve bu ekranda hiçbir yerde yazmıyordu. Yanlış projeye düşen görev sessiz
  /// bir hatadır: kullanıcı görmez, yalnız o projenin agent'ı yabancı bir iş
  /// bulur (L-045'in aynı ailesinden).
  group('hedef repo', () {
    testWidgets('tek bağlantı varken seçici çizilmez', (tester) async {
      // Seçeneksiz bir seçici, karar veriliyormuş izlenimi verir; hedefi
      // zaten üstteki repo şeridi söylüyor.
      final built = buildScreen();
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      expect(find.byKey(AddTaskScreen.targetRepoFieldKey), findsNothing);
    });

    testWidgets('iki bağlantı varken seçici aktif repoyla gelir',
        (tester) async {
      final built = buildMultiRepoScreen();
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<String>>(
        find.byKey(AddTaskScreen.targetRepoFieldKey),
      );
      expect(dropdown.value, 'a/bir');
    });

    testWidgets('seçilen repoya yazılır, aktif repoya değil', (tester) async {
      final built = buildMultiRepoScreen();
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      await chooseTarget(tester, 'b/iki');
      await fillAndSubmit(tester);

      final request = built.adapter.requests.single;
      expect(request.method, 'PUT');
      expect(
        request.path,
        startsWith('/repos/b/iki/contents/hub/tasks/inbox/'),
        reason: 'aktif repo a/bir; görev seçilen repoya gitmeli',
      );
    });

    testWidgets('ağ yokken kuyruğa giren taslak seçilen repoyu taşır',
        (tester) async {
      // Damga taslak **üretilirken** basılıyor. Kuyruğa girerken basılsaydı
      // (T-003'ün ilk hâli) hedef "kuyruğa alındığı andaki aktif repo" olurdu
      // ve kullanıcının seçtiği repo yolda kaybolurdu.
      final built = buildMultiRepoScreen(
        handler: (options, _) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'ağ yok',
        ),
      );
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      await chooseTarget(tester, 'b/iki');
      await fillAndSubmit(tester);

      expect(find.textContaining('kuyruğa alındı'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      final queued = prefs.getStringList('outbox')!;
      expect(jsonDecode(queued.single)['repoSlug'], 'b/iki');
    });
  });

  group('taslak kalıcılığı (T-022)', () {
    testWidgets('yazılan metin diske iner ve yeniden kurulan ekrana geri gelir',
        (tester) async {
      final built = buildScreen();
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(AddTaskScreen.titleFieldKey), 'Yarım kalan başlık');
      await tester.enterText(find.byKey(AddTaskScreen.descriptionFieldKey),
          'Uzun uzun yazılmış açıklama.');
      await tester.pump();

      // Süreç ölümü taklidi: ekran tamamen atılıp sıfırdan kuruluyor.
      // (SharedPreferences sahtesi bellekte yaşadığı için "disk" duruyor.)
      await tester.pumpWidget(const SizedBox());
      final built2 = buildScreen();
      await tester.pumpWidget(built2.widget);
      await tester.pumpAndSettle();

      expect(find.text('Yarım kalan başlık'), findsOneWidget);
      expect(find.text('Uzun uzun yazılmış açıklama.'), findsOneWidget);
    });

    testWidgets('gönderim taslağı da temizler — geri gelmez', (tester) async {
      final built = buildScreen();
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();
      await fillAndSubmit(tester);

      await tester.pumpWidget(const SizedBox());
      final built2 = buildScreen();
      await tester.pumpWidget(built2.widget);
      await tester.pumpAndSettle();

      expect(find.text('Market listesi'), findsNothing);
    });
  });
}
