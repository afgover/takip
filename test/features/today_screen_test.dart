import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/today/today_screen.dart';
import 'package:takip/merkez/merkez_providers.dart';

import '../helpers/test_app.dart';

class _Server implements HttpClientAdapter {
  _Server(this.today);

  Map<String, dynamic> today;
  (int, Object?) answerResponse = (201, {'path': 'p'});
  (int, Object?) loginResponse = (200, {'accessToken': 'jwt'});
  int todayStatus = 200;
  (int, Object?) commandsResponse = (200, {'catalog': [], 'recent': []});
  (int, Object?) runResponse = (201, {'id': 'c1'});
  final answers = <Map<String, dynamic>>[];
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    paths.add(options.path);
    String? body;
    if (stream != null) {
      body = utf8.decode((await stream.toList()).expand((c) => c).toList());
    }
    late (int, Object?) out;
    if (options.path == '/auth/login') {
      out = loginResponse;
    } else if (options.path == '/today') {
      out = (todayStatus, today);
    } else if (options.path == '/commands') {
      out = commandsResponse;
    } else if (options.path.startsWith('/commands/')) {
      out = runResponse;
    } else {
      answers.add(jsonDecode(body!) as Map<String, dynamic>);
      out = answerResponse;
    }
    return ResponseBody.fromString(jsonEncode(out.$2), out.$1, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _sample({bool answered = false}) => {
      'totals': {
        'pendingDecisions': 1,
        'withOptions': 1,
        'awaitingAgent': answered ? 1 : 0,
        'parked': 1,
      },
      'failedHubs': <String>[],
      'hubs': [
        {
          'slug': 'Copilot_takip',
          'project': 'CoPilot',
          'status': 'aktif',
          'inboxCount': 0,
          'waiting': [
            {
              'taskId': 'T-7',
              'title': 'Hangisi?',
              'priority': 'high',
              'due': '2026-11-01',
              'overdue': true,
              'awaitingAgent': answered,
              'options': ['Evet', 'Hayır'],
            },
          ],
        },
        {
          'slug': 'taskr_takip',
          'project': 'taskr',
          'status': 'beklemede',
          'inboxCount': 0,
          'waiting': [
            {'taskId': 'T-1', 'title': 'Park', 'options': null},
          ],
        },
      ],
    };

Future<_Server> _pump(WidgetTester tester, _Server server) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://m.test'))
    ..httpClientAdapter = server;
  await tester.pumpWidget(ProviderScope(
    overrides: [merkezDioProvider.overrideWithValue(dio)],
    child: testApp(const Scaffold(body: TodayScreen())),
  ));
  await tester.pumpAndSettle();
  return server;
}

void main() {
  void signedIn() =>
      FlutterSecureStorage.setMockInitialValues({merkezTokenKey: 'jwt'});

  testWidgets('oturum yoksa giriş formu, istek gitmez', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final server = await _pump(tester, _Server(_sample()));
    expect(find.text('Bağlan'), findsOneWidget);
    expect(server.paths, isEmpty);
  });

  testWidgets('giriş belirteci saklar, parolayı saklamaz, listeyi açar', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await _pump(tester, _Server(_sample()));
    await tester.enterText(find.byType(TextField), 'gizli');
    await tester.tap(find.text('Bağlan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hangisi?'), findsOneWidget);
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: merkezTokenKey), 'jwt');
    expect((await storage.readAll()).values, isNot(contains('gizli')));
  });

  testWidgets('yanlış parola formda kalır ve hatayı gösterir', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final server = _Server(_sample())..loginResponse = (401, {});
    await _pump(tester, server);
    await tester.enterText(find.byType(TextField), 'yanlis');
    await tester.tap(find.text('Bağlan'));
    await tester.pumpAndSettle();
    expect(find.text('Parola kabul edilmedi.'), findsOneWidget);
    expect(await const FlutterSecureStorage().read(key: merkezTokenKey), isNull);
  });

  testWidgets('özet, öncelik sırası ve beklemedeki bölüm', (tester) async {
    signedIn();
    await _pump(tester, _Server(_sample()));
    expect(find.text('1 bekleyen karar, 1 seçenekli'), findsOneWidget);
    expect(find.text('CoPilot (1)'), findsOneWidget);
    expect(find.text('Son tarih geçti: 2026-11-01'), findsOneWidget);
    expect(find.text('Beklemedeki projeler (1)'), findsOneWidget);
    expect(find.textContaining('Park'), findsNothing);
  });

  testWidgets('seçenek tek dokunuşla gitmez; onayla cevap yazılır', (tester) async {
    signedIn();
    final server = await _pump(tester, _Server(_sample()));
    await tester.tap(find.text('Evet'));
    await tester.pumpAndSettle();
    expect(server.answers, isEmpty);
    expect(find.text('Seçim: Evet'), findsOneWidget);

    server.today = _sample(answered: true);
    await tester.enterText(find.byType(TextField), 'tamam');
    await tester.tap(find.text('Gönder'));
    await tester.pumpAndSettle();

    expect(server.answers.single, {'option': 'Evet', 'text': 'tamam'});
    expect(server.paths, contains('/hubs/Copilot_takip/tasks/T-7/answer'));
    expect(find.text("Cevap hub'a yazıldı."), findsOneWidget);
    expect(find.text('Cevaplandı, ajan bekleniyor'), findsOneWidget);
    expect(find.text('Evet'), findsNothing);
  });

  testWidgets('seçeneksiz cevapta boş metin gönderilmez', (tester) async {
    signedIn();
    final server = await _pump(tester, _Server(_sample()));
    await tester.tap(find.text('Cevap yaz').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gönder'));
    await tester.pumpAndSettle();
    expect(server.answers, isEmpty);
    expect(find.text('Bir cevap yaz.'), findsOneWidget);
  });

  testWidgets('çelişen cevap sunucunun mesajıyla gösterilir, liste yenilenir', (tester) async {
    signedIn();
    final server = await _pump(tester, _Server(_sample()));
    server.answerResponse = (409, {'message': 'Çelişen cevap'});
    server.paths.clear();
    await tester.tap(find.text('Hayır'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gönder'));
    await tester.pumpAndSettle();
    expect(find.text('Çelişen cevap'), findsOneWidget);
    expect(find.text('Gönder'), findsOneWidget);
    expect(server.paths, contains('/today'));
  });

  testWidgets('süresi dolan belirteç giriş formuna döner', (tester) async {
    signedIn();
    final server = _Server(_sample())..todayStatus = 401;
    await _pump(tester, server);
    expect(find.text('Bağlan'), findsOneWidget);
    expect(await const FlutterSecureStorage().read(key: merkezTokenKey), isNull);
  });

  testWidgets('sunucu hatasında yeniden dene', (tester) async {
    signedIn();
    final server = _Server(_sample())..todayStatus = 502;
    await _pump(tester, server);
    expect(find.text('Merkez bir hata döndürdü. Yeniden dene.'), findsOneWidget);
    server.todayStatus = 200;
    await tester.tap(find.text('Yeniden dene'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hangisi?'), findsOneWidget);
  });

  testWidgets('İngilizce dilde de çizilir', (tester) async {
    signedIn();
    final dio = Dio(BaseOptions(baseUrl: 'https://m.test'))
      ..httpClientAdapter = _Server(_sample());
    await tester.pumpWidget(ProviderScope(
      overrides: [merkezDioProvider.overrideWithValue(dio)],
      child: testApp(const Scaffold(body: TodayScreen()), locale: const Locale('en')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('1 pending decisions, 1 with options'), findsOneWidget);
  });

  group('Çalıştır', () {
    const name = 'goverco.harcamalari-cikar';
    Map<String, dynamic> list(List<Map<String, dynamic>> recent) => {
          'catalog': [
            {
              'name': name,
              'title': {'tr': 'Harcamaları çıkar', 'en': 'Extract expenses'},
              'hub': 'goverco_takip',
            },
          ],
          'recent': recent,
        };

    testWidgets('katalog boşsa bölüm görünmez', (tester) async {
      signedIn();
      await _pump(tester, _Server(_sample()));
      expect(find.text('Çalıştır'), findsNothing);
    });

    testWidgets('dokunmak işi başlatmaz; vazgeçince istek gitmez', (tester) async {
      signedIn();
      final server = _Server(_sample())..commandsResponse = (200, list(const []));
      await _pump(tester, server);
      await tester.tap(find.text('Çalıştır'));
      await tester.pumpAndSettle();
      expect(server.paths, isNot(contains('/commands/$name/run')));
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(server.paths, isNot(contains('/commands/$name/run')));
    });

    testWidgets('onayla kuyruğa alınır, durum yenilenir', (tester) async {
      signedIn();
      final server = _Server(_sample())..commandsResponse = (200, list(const []));
      await _pump(tester, server);
      await tester.tap(find.text('Çalıştır'));
      await tester.pumpAndSettle();
      server.commandsResponse = (200, list([{'type': name, 'status': 'queued'}]));
      await tester.tap(find.widgetWithText(FilledButton, 'Çalıştır').last);
      await tester.pumpAndSettle();
      expect(server.paths, contains('/commands/$name/run'));
      expect(find.text('İş kuyruğa alındı. Mac mini alınca başlar.'), findsOneWidget);
      expect(find.text('Kuyrukta, Mac mini bekleniyor'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.ancestor(
          of: find.text('Çalıştır'), matching: find.byWidgetPredicate((w) => w is FilledButton)));
      expect(button.onPressed, isNull);
    });

    testWidgets('son çalışma durumu gösterilir, en yeni kazanır', (tester) async {
      signedIn();
      final server = _Server(_sample())
        ..commandsResponse = (200, list([
          {'type': name, 'status': 'failed'},
          {'type': name, 'status': 'done'},
          {'type': 'wake-agent', 'status': 'queued'},
        ]));
      await _pump(tester, server);
      expect(find.text('Son çalışma başarısız'), findsOneWidget);
    });

    testWidgets('komut listesi hatası bekleyen kararları düşürmez', (tester) async {
      signedIn();
      final server = _Server(_sample())..commandsResponse = (500, {});
      await _pump(tester, server);
      expect(find.textContaining('Hangisi?'), findsOneWidget);
    });

    testWidgets('kuyruktaki iş için 409 mesajı gösterilir', (tester) async {
      signedIn();
      final server = _Server(_sample())
        ..commandsResponse = (200, list(const []))
        ..runResponse = (409, {'message': 'Bu komut zaten kuyrukta'});
      await _pump(tester, server);
      await tester.tap(find.text('Çalıştır'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Çalıştır').last);
      await tester.pumpAndSettle();
      expect(find.text('Bu komut zaten kuyrukta'), findsOneWidget);
    });

    testWidgets('İngilizce başlık', (tester) async {
      signedIn();
      final server = _Server(_sample())..commandsResponse = (200, list(const []));
      final dio = Dio(BaseOptions(baseUrl: 'https://m.test'))..httpClientAdapter = server;
      await tester.pumpWidget(ProviderScope(
        overrides: [merkezDioProvider.overrideWithValue(dio)],
        child: testApp(const Scaffold(body: TodayScreen()), locale: const Locale('en')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Extract expenses'), findsOneWidget);
      expect(find.text('Run'), findsOneWidget);
    });
  });
}
