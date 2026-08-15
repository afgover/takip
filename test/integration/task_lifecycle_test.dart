import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/features/add_task/add_task_screen.dart';
import 'package:takip/features/pending/pending_screen.dart';
import 'package:takip/github/client.dart';
import 'package:takip/hub/frontmatter.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/all_tasks.dart';
import 'package:takip/hub/hub_watcher.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/outbox.dart';
import 'package:takip/hub/task_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

import '../helpers/test_app.dart';

/// Bellekte duran, GitHub Contents API gibi davranan bir hub.
///
/// Agent tarafı gerçek agent'ın yaptığını yapar: dosyayı klasörden klasöre
/// taşır (SYSTEM.md §4) ve her değişiklikte commit sha'sı ilerler — app'in
/// yoklaması (B-024) bunu görüp listeleri tazeler.
class FakeHub {
  final Map<String, String> files = {};
  int _commit = 0;

  String get headSha => 'commit-$_commit';

  void seedTaskFolders() {
    // Gerçek hub'da klasörler README ile var olur.
    for (final dir in [Hub.inboxDir, Hub.activeDir, Hub.doneDir]) {
      files['$dir/README.md'] = '# klasör';
    }
    _commit++;
  }

  /// Agent'ın görev taşıması: eski yolu sil, yeni yola yaz (SYSTEM.md §4).
  void agentMove(String from, String to, {String Function(String)? edit}) {
    final content = files.remove(from)!;
    files[to] = edit?.call(content) ?? content;
    _commit++;
  }

  FakeAdapter get adapter => FakeAdapter((options, body) {
        if (options.path.endsWith('/commits')) {
          return jsonResponse([
            {'sha': headSha}
          ]);
        }

        final path = Uri.decodeFull(options.path.split('/contents/').last);

        switch (options.method) {
          case 'GET':
            final file = files[path];
            if (file != null) {
              return jsonResponse({
                'path': path,
                'sha': 'sha-${file.hashCode}',
                'encoding': 'base64',
                'content': base64.encode(utf8.encode(file)),
              });
            }
            final children = files.keys.where((k) => k.startsWith('$path/'));
            if (children.isEmpty) {
              return jsonResponse({'message': 'Not Found'}, status: 404);
            }
            return jsonResponse([
              for (final key in children)
                {
                  'name': key.substring(path.length + 1),
                  'path': key,
                  'sha': 'sha-${files[key].hashCode}',
                  'type': 'file',
                }
            ]);

          case 'PUT':
            final sent = jsonDecode(body!) as Map<String, dynamic>;
            if (files.containsKey(path) && sent['sha'] == null) {
              return jsonResponse(
                {'message': 'Invalid request. "sha" wasn\'t supplied.'},
                status: 422,
              );
            }
            files[path] =
                utf8.decode(base64.decode(sent['content'] as String));
            _commit++;
            return jsonResponse({
              'content': {'sha': 'sha-${files[path].hashCode}'}
            });

          default:
            return jsonResponse({'message': 'desteklenmiyor'}, status: 400);
        }
      });
}

class FakeHubConfigNotifier extends HubConfigNotifier {
  @override
  Future<HubConfig?> build() async =>
      const HubConfig(owner: 'afgover', repo: 'takip', token: 't');
}

void main() {
  late FakeHub hub;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    hub = FakeHub()..seedTaskFolders();

    final dio = buildGithubDio((_) => 't')..httpClientAdapter = hub.adapter;
    container = ProviderContainer(
      overrides: [
        hubConfigProvider.overrideWith(FakeHubConfigNotifier.new),
        githubDioProvider.overrideWithValue(dio),
      ],
    );
    await container.read(hubConfigProvider.future);
  });

  tearDown(() => container.dispose());

  Widget wrap(Widget child) => UncontrolledProviderScope(
        container: container,
        child: testApp(child),
      );

  /// Ekranı oturt — **`pumpAndSettle` yerine** (B-130).
  ///
  /// `pumpAndSettle`, ekranda çizilmiş **hiçbir animasyon kalmayana** kadar
  /// kare pompalar. Bu uygulamada o koşul hiç sağlanmayabiliyor: yükleme ve
  /// gönderim göstergeleri (`CircularProgressIndicator`) **sonsuz** döner.
  /// Böyle bir gösterge ekrandayken `pumpAndSettle` kendi 10 dakikalık
  /// sınırına kadar döner ve test zaman aşımıyla düşer — bu dosyadaki iki test
  /// tam olarak buradan kırılıyordu.
  ///
  /// Bunun yerine **sınırlı** sayıda kare pompalanıyor ve araya `runAsync`
  /// giriyor: sahte saat ilerlesin (zamanlayıcılar ateşlensin) ve gerçek async
  /// iş (dio, `SharedPreferences`) da ilerlesin. İkisinden biri eksik olduğunda
  /// ekran hiç tazelenmiyor.
  Future<void> settle(WidgetTester tester, {int frames = 12}) async {
    for (var i = 0; i < frames; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Yoklamayı koştur **ve listenin yeniden hesaplanmasını bekle**.
  ///
  /// `pumpAndSettle` yetmiyor: yalnız kare pompalar, gerçek async işi
  /// sürmez. `activeRepoPendingTasksProvider` ise cihazdaki kopyayı okuyor, yani
  /// `SharedPreferences` üzerinden bir platform kanalına gidiyor. Beklemeden
  /// doğrulama yapmak testi **yarışa** sokuyordu: 10 koşumda 2'si kırılıyordu
  /// ve kırılan koşum "liste tazelenmedi" diye bir hata gösteriyordu — oysa
  /// hata testin kendisindeydi. Yarı yarıya yalan söyleyen bir test, kırık
  /// testten kötüdür (L-045).
  Future<void> pollAndSettle(WidgetTester tester) async {
    await tester.runAsync(() async {
      await container.read(hubWatcherProvider.notifier).checkNow();

      // **Hesabı burada yeniden başlat.** Ekran çizilirken provider'ın gövdesi
      // testin *sahte zaman* zonunda çalışmaya başlıyor; gerçek async işe
      // (yerel kopya + ağ) dayandığı için orada hiç bitmiyor. Geçersiz kılmak
      // o hesabı atar, `runAsync` içindeki okuma gerçek zonda yeniden başlatır.
      container.invalidate(activeRepoPendingTasksProvider);

      // Bekleme `.future` ile değil **durumla**: `.future`, sahte zonda
      // başlayıp hiç bitmeyen ilk hesabın completer'ına bağlı kalıyor ve
      // yeni hesap bitse bile dönmüyordu. Durum ise her yeniden hesapta
      // güncelleniyor.
      for (var i = 0; i < 200; i++) {
        final state = container.read(activeRepoPendingTasksProvider);
        if (!state.isLoading) return;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      fail('bekleyenler listesi 4 saniyede hesaplanmadı');
    });
    await settle(tester);
  }

  /// Gönder düğmesine bas ve gönderim **bitene kadar** bekle.
  ///
  /// Bekleme sabit bir süreye değil **durumun kendisine** bağlı: gönderim
  /// sürerken düğmedeki gösterge dönüyor, kaybolduğu an iş bitmiştir. Sabit
  /// süre beklemek testi makinenin hızına bağlar (L-045'in yarıştan çıkan
  /// dersi).
  Future<void> submitAndSettle(WidgetTester tester) async {
    await tester.tap(find.byKey(AddTaskScreen.submitKey));
    await tester.pump(); // _busy = true — gönderim başladı

    for (var i = 0; i < 300; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      // `pump()` **süreyle** çağrılıyor: süresiz pompalama sahte saati hiç
      // ilerletmez ve gönderim yolundaki zamanlayıcılar hiç ateşlenmez.
      await tester.pump(const Duration(milliseconds: 10));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
    }
    fail('gönderim 3 saniyede bitmedi — gösterge hâlâ dönüyor');
  }

  testWidgets('görev app\'ten eklenir, agent tamamlar, app\'te görünür',
      (tester) async {
    // ---- 1. Kullanıcı app'ten görev ekler --------------------------------
    await tester.pumpWidget(wrap(const AddTaskScreen()));
    await tester.enterText(
      find.byKey(AddTaskScreen.titleFieldKey),
      'Market listesi',
    );
    await tester.enterText(
      find.byKey(AddTaskScreen.descriptionFieldKey),
      'Süt, ekmek, yumurta.',
    );
    await submitAndSettle(tester);

    final written = hub.files.entries
        .firstWhere((e) => e.key.endsWith('-market-listesi.md'));
    expect(written.key, startsWith(Hub.inboxDir));

    // Yazılan dosya sözleşmeye uygun mu?
    final fm = Frontmatter.parse(written.value);
    expect(fm.str('id'), 'pending');
    expect(fm.str('created_by'), 'user');
    expect(fm.str('title'), 'Market listesi');
    expect(fm.body, contains('Süt, ekmek, yumurta.'));

    final taskPath = written.key;

    // ---- 2. App'te "Yeni" olarak görünür ---------------------------------
    await tester.pumpWidget(wrap(const PendingScreen()));
    await pollAndSettle(tester);

    expect(find.text('Market listesi'), findsOneWidget);
    expect(find.text('Yeni'), findsOneWidget);

    // ---- 3. Agent görevi ele alır: inbox → active, ID atar ---------------
    hub.agentMove(
      taskPath,
      taskPath.replaceFirst(Hub.inboxDir, Hub.activeDir),
      edit: (content) => content
          .replaceFirst('id: pending', 'id: T-002')
          .replaceFirst('session: none', 'session: S-2026-07-30-deneme'),
    );

    await pollAndSettle(tester);

    expect(find.text('Ele alınıyor'), findsOneWidget,
        reason: 'yoklama değişikliği görüp listeyi tazelemeli');

    // ---- 4. Agent tamamlar: active → done, sonuç yazar -------------------
    hub.agentMove(
      taskPath.replaceFirst(Hub.inboxDir, Hub.activeDir),
      taskPath.replaceFirst(Hub.inboxDir, Hub.doneDir),
      edit: (content) =>
          content.replaceFirst('result: none', 'result: "Liste hazırlandı"'),
    );

    await pollAndSettle(tester);

    // ---- 5. Bekleyenlerden düşer, tamamlananlarda görünür ----------------
    expect(find.text('Market listesi'), findsNothing);
    expect(find.text('Bekleyen görev yok'), findsOneWidget);

    final done = (await tester.runAsync(
      () => container.read(doneTasksProvider.future),
    ))!;
    expect(done.single.fileName, endsWith('-market-listesi.md'));
    expect(done.single.status, TaskStatus.done);

    final detail = (await tester.runAsync(
      () => container.read(taskDetailProvider(done.single).future),
    ))!;
    expect(detail.id, 'T-002');
    expect(detail.result, 'Liste hazırlandı');
    expect(detail.hasResult, isTrue);
    expect(detail.session, 'S-2026-07-30-deneme');
  });

  testWidgets('ağ yokken eklenen görev, bağlantı gelince kendiliğinden gider',
      (tester) async {
    // Ağı kes: her istek bağlantı hatası.
    var online = false;
    final dio = buildGithubDio((_) => 't')
      ..httpClientAdapter = FakeAdapter((options, body) {
        if (!online) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'ağ yok',
          );
        }
        return hub.adapter.handler(options, body);
      });

    container.dispose();
    container = ProviderContainer(
      overrides: [
        hubConfigProvider.overrideWith(FakeHubConfigNotifier.new),
        githubDioProvider.overrideWithValue(dio),
      ],
    );
    await tester.runAsync(() => container.read(hubConfigProvider.future));

    await tester.pumpWidget(wrap(const AddTaskScreen()));
    await tester.enterText(
      find.byKey(AddTaskScreen.titleFieldKey),
      'Fatura ödemesi',
    );
    await submitAndSettle(tester);

    expect(find.textContaining('kuyruğa alındı'), findsOneWidget);
    expect(hub.files.keys.where((k) => k.contains('fatura')), isEmpty);

    // Bağlantı gelir; yoklamanın başarılı kontrolü kuyruğu boşaltır.
    online = true;
    await tester.runAsync(
      () => container.read(outboxProvider.notifier).flush(),
    );

    expect(
      hub.files.keys.where((k) => k.contains('fatura-odemesi')),
      hasLength(1),
    );
    expect(container.read(outboxProvider).valueOrNull, isEmpty);
  });
}
