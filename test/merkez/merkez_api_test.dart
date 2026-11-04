import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/merkez/merkez_api.dart';

class _Fake implements HttpClientAdapter {
  _Fake(this.status, this.body);

  final int status;
  final Object? body;
  RequestOptions? last;
  String? lastBody;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    last = options;
    if (stream != null) {
      lastBody = utf8.decode((await stream.toList()).expand((c) => c).toList());
    }
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

(MerkezApi, _Fake) _api(int status, Object? body) {
  final fake = _Fake(status, body);
  final dio = Dio(BaseOptions(baseUrl: 'https://m.test'))
    ..httpClientAdapter = fake;
  return (MerkezApi(dio), fake);
}

void main() {
  test('login belirteci döner, parola gövdede', () async {
    final (api, fake) = _api(200, {'accessToken': 'jwt'});
    expect(await api.login('p'), 'jwt');
    expect(fake.last!.path, '/auth/login');
    expect(jsonDecode(fake.lastBody!), {'password': 'p'});
  });

  test('today ayrıştırır, bilinmeyen alanı yok sayar', () async {
    final (api, fake) = _api(200, {
      'lastIndexedAt': '2026-11-04T00:00:00.000Z',
      'failedHubs': ['x_takip'],
      'yeniAlan': 1,
      'totals': {'pendingDecisions': 3, 'withOptions': 1, 'awaitingAgent': 1, 'parked': 2},
      'hubs': [
        {
          'slug': 'a_takip',
          'project': 'A',
          'status': 'aktif',
          'inboxCount': 1,
          'waiting': [
            {
              'taskId': 'T-1',
              'title': 'Karar',
              'priority': 'high',
              'due': '2026-11-01',
              'overdue': true,
              'awaitingAgent': true,
              'options': ['Evet', 'Hayır'],
            },
            {'taskId': null, 'title': 'Eski', 'options': null},
          ],
        },
      ],
    });
    final data = await api.today('jwt');
    expect(fake.last!.headers['Authorization'], 'Bearer jwt');
    expect(data.totals.pendingDecisions, 3);
    expect(data.totals.parked, 2);
    expect(data.failedHubs, ['x_takip']);
    final task = data.hubs.single.waiting.first;
    expect(task.options, ['Evet', 'Hayır']);
    expect(task.overdue, isTrue);
    expect(task.awaitingAgent, isTrue);
    expect(data.hubs.single.waiting.last.taskId, isNull);
    expect(data.hubs.single.waiting.last.options, isEmpty);
    expect(data.hubs.single.isActive, isTrue);
  });

  test('commands: yalnız katalog, durum recent listesinden', () async {
    final (api, fake) = _api(200, {
      'catalog': [
        {'name': 'a.b', 'title': {'tr': 'Tr', 'en': 'En'}},
        {'name': 'c.d', 'title': {}},
      ],
      'recent': [
        {'type': 'a.b', 'status': 'running'},
        {'type': 'a.b', 'status': 'done'},
        {'type': 'wake-agent', 'status': 'queued'},
      ],
    });
    final list = await api.commands('jwt');
    expect(fake.last!.headers['Authorization'], 'Bearer jwt');
    expect(list.map((c) => c.name), ['a.b', 'c.d']);
    expect(list.first.lastStatus, 'running');
    expect(list.first.isActive, isTrue);
    expect(list.last.lastStatus, isNull);
    expect(list.last.titleTr, 'c.d');
  });

  test('runCommand adı kodlar, gövde göndermez', () async {
    final (api, fake) = _api(201, {'id': 'c'});
    await api.runCommand('jwt', 'goverco.harcamalari-cikar');
    expect(fake.last!.path, '/commands/goverco.harcamalari-cikar/run');
    expect(fake.last!.method, 'POST');
    expect(fake.lastBody, isNull);
  });

  test('answer yolu kodlar, boş açıklamayı göndermez', () async {
    final (api, fake) = _api(201, {'path': 'p'});
    await api.answer('jwt', hub: 'Copilot_takip', taskId: 'T-1', option: 'Evet', text: '  ');
    expect(fake.last!.path, '/hubs/Copilot_takip/tasks/T-1/answer');
    expect(fake.last!.headers['Authorization'], 'Bearer jwt');
    expect(jsonDecode(fake.lastBody!), {'option': 'Evet'});
  });

  test('answer yalnız açıklamayı kırpıp gönderir', () async {
    final (api, fake) = _api(201, {});
    await api.answer('jwt', hub: 'a', taskId: 'T-2', text: ' Hayır ');
    expect(jsonDecode(fake.lastBody!), {'text': 'Hayır'});
  });

  test('hata kodları eşlenir, 4xx mesajı korunur', () async {
    Future<MerkezError> err(int status, Object? body) async {
      final (api, _) = _api(status, body);
      try {
        await api.today('t');
      } on MerkezError catch (e) {
        return e;
      }
      fail('hata bekleniyordu');
    }

    expect((await err(401, {})).kind, MerkezErrorKind.unauthorized);
    final conflict = await err(409, {'message': 'Çelişen cevap'});
    expect(conflict.kind, MerkezErrorKind.conflict);
    expect(conflict.serverMessage, 'Çelişen cevap');
    expect((await err(400, {'message': ['liste']})).serverMessage, isNull);
    expect((await err(404, {})).kind, MerkezErrorKind.rejected);
    expect((await err(429, {})).kind, MerkezErrorKind.rateLimited);
    expect((await err(502, {})).kind, MerkezErrorKind.server);
  });

  test('ağ hatası network olur, belirteçsiz yanıt server', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://m.test'))
      ..httpClientAdapter = _Throwing();
    await expectLater(MerkezApi(dio).today('t'),
        throwsA(isA<MerkezError>().having((e) => e.kind, 'kind', MerkezErrorKind.network)));
    final (api, _) = _api(200, {});
    await expectLater(api.login('p'),
        throwsA(isA<MerkezError>().having((e) => e.kind, 'kind', MerkezErrorKind.server)));
  });
}

class _Throwing implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancel) =>
      throw DioException.connectionError(requestOptions: options, reason: 'x');

  @override
  void close({bool force = false}) {}
}
