import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/errors.dart';
import 'package:takip/github/contents_api.dart';

/// Dio'nun HTTP katmanını değiştiren sahte adaptör: istekleri kaydeder,
/// yanıtı test belirler. Ağ gerekmez.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options, String? body) handler;
  final List<RequestOptions> requests = [];
  final List<String?> bodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    String? body;
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      body = utf8.decode(chunks.expand((c) => c).toList());
    }
    requests.add(options);
    bodies.add(body);
    return handler(options, body);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(
  Object? data, {
  int status = 200,
  Map<String, List<String>> headers = const {},
}) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    );

/// Verilen yanıtı döndüren bir ContentsApi + adaptör çifti kurar.
({ContentsApi api, FakeAdapter adapter}) buildApi(
  ResponseBody Function(RequestOptions options, String? body) handler,
) {
  final adapter = FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;
  return (
    api: ContentsApi(dio, owner: 'afgover', repo: 'takip'),
    adapter: adapter,
  );
}

String b64(String s) => base64.encode(utf8.encode(s));

void main() {
  group('listDir', () {
    test('dizin kayıtlarını ad/sha/tip ile döner', () async {
      final built = buildApi(
        (_, __) => jsonResponse([
          {
            'name': '2026-07-30-market.md',
            'path': 'hub/tasks/inbox/2026-07-30-market.md',
            'sha': 'aaa',
            'type': 'file',
          },
          {
            'name': 'arsiv-2025',
            'path': 'hub/tasks/inbox/arsiv-2025',
            'sha': 'bbb',
            'type': 'dir',
          },
        ]),
      );

      final entries = await built.api.listDir('hub/tasks/inbox');

      expect(entries, hasLength(2));
      expect(entries.first.name, '2026-07-30-market.md');
      expect(entries.first.sha, 'aaa');
      expect(entries.first.isDirectory, isFalse);
      expect(entries.last.isDirectory, isTrue);
      expect(
        built.adapter.requests.single.path,
        '/repos/afgover/takip/contents/hub/tasks/inbox',
      );
    });

    test('404 boş listeye çevrilir — git\'te boş dizin yoktur (L-005)',
        () async {
      final built = buildApi(
        (_, __) => jsonResponse({'message': 'Not Found'}, status: 404),
      );

      expect(await built.api.listDir('hub/tasks/active'), isEmpty);
    });

    test('yol bir dosyaysa hata verir', () async {
      final built = buildApi(
        (_, __) => jsonResponse({'name': 'x.md', 'type': 'file'}),
      );

      expect(
        () => built.api.listDir('hub/BACKLOG.md'),
        throwsA(isA<HubUnexpectedError>()),
      );
    });
  });

  group('getFile', () {
    test('satırlara bölünmüş base64 içeriği çözer', () async {
      // GitHub base64'ü 60 karakterde bir satır sonuyla gönderir.
      final encoded = '${b64('# Görev\n\nTürkçe içerik.')}\n';
      final built = buildApi(
        (_, __) => jsonResponse({
          'path': 'hub/tasks/inbox/a.md',
          'sha': 'ccc',
          'encoding': 'base64',
          'content': encoded,
        }),
      );

      final file = await built.api.getFile('hub/tasks/inbox/a.md');

      expect(file.content, '# Görev\n\nTürkçe içerik.');
      expect(file.sha, 'ccc');
    });

    test('1 MB üstü dosyada (encoding: none) sessizce boş dönmez', () async {
      final built = buildApi(
        (_, __) => jsonResponse({
          'path': 'hub/buyuk.md',
          'sha': 'ddd',
          'encoding': 'none',
          'content': '',
        }),
      );

      expect(
        () => built.api.getFile('hub/buyuk.md'),
        throwsA(isA<HubUnexpectedError>()),
      );
    });
  });

  group('putFile', () {
    test('yeni dosyada sha göndermez, yeni sha\'yı döner', () async {
      final built = buildApi(
        (_, __) => jsonResponse({
          'content': {'sha': 'yeni-sha'}
        }),
      );

      final sha = await built.api.putFile(
        'hub/tasks/inbox/a.md',
        'içerik',
        commitMessage: 'task(pending): inbox\'a eklendi (app)',
      );

      expect(sha, 'yeni-sha');
      final sent = jsonDecode(built.adapter.bodies.single!) as Map;
      expect(sent.containsKey('sha'), isFalse);
      expect(utf8.decode(base64.decode(sent['content'] as String)), 'içerik');
      expect(sent['message'], 'task(pending): inbox\'a eklendi (app)');
      expect(built.adapter.requests.single.method, 'PUT');
    });

    test('güncellemede sha gönderir', () async {
      final built = buildApi(
        (_, __) => jsonResponse({
          'content': {'sha': 'v2'}
        }),
      );

      await built.api.putFile(
        'hub/tasks/inbox/a.md',
        'yeni',
        sha: 'v1',
        commitMessage: 'task(T-001): not eklendi',
      );

      expect((jsonDecode(built.adapter.bodies.single!) as Map)['sha'], 'v1');
    });

    test('409 çakışması HubConflictError olur', () async {
      final built = buildApi(
        (_, __) => jsonResponse(
          {'message': 'does not match'},
          status: 409,
        ),
      );

      expect(
        () => built.api.putFile('hub/tasks/inbox/a.md', 'x',
            sha: 'eski', commitMessage: 'm'),
        throwsA(isA<HubConflictError>()),
      );
    });

    test('sha\'sız güncellemede gelen 422 de çakışma sayılır', () async {
      final built = buildApi(
        (_, __) => jsonResponse(
          {'message': 'Invalid request. "sha" wasn\'t supplied.'},
          status: 422,
        ),
      );

      expect(
        () => built.api
            .putFile('hub/tasks/inbox/a.md', 'x', commitMessage: 'm'),
        throwsA(isA<HubConflictError>()),
      );
    });
  });

  test('deleteFile sha ve mesajı gövdede gönderir', () async {
    final built = buildApi((_, __) => jsonResponse({'commit': {}}));

    await built.api.deleteFile(
      'hub/tasks/inbox/a.md',
      sha: 'aaa',
      commitMessage: 'task(T-001): inbox → active',
    );

    final sent = jsonDecode(built.adapter.bodies.single!) as Map;
    expect(sent['sha'], 'aaa');
    expect(sent['message'], 'task(T-001): inbox → active');
    expect(built.adapter.requests.single.method, 'DELETE');
  });

  group('hata eşleme', () {
    test('401 → HubAuthError', () async {
      final built = buildApi(
        (_, __) => jsonResponse({'message': 'Bad credentials'}, status: 401),
      );

      expect(
        () => built.api.getFile('hub/BACKLOG.md'),
        throwsA(isA<HubAuthError>()),
      );
    });

    test('kalan istek 0 iken 403 → HubRateLimitError (reset zamanıyla)',
        () async {
      final built = buildApi(
        (_, __) => jsonResponse(
          {'message': 'API rate limit exceeded'},
          status: 403,
          headers: {
            'x-ratelimit-remaining': ['0'],
            'x-ratelimit-reset': ['1790000000'],
          },
        ),
      );

      await expectLater(
        built.api.getFile('hub/BACKLOG.md'),
        throwsA(
          isA<HubRateLimitError>().having(
            (e) => e.resetAt,
            'resetAt',
            DateTime.fromMillisecondsSinceEpoch(1790000000 * 1000, isUtc: true),
          ),
        ),
      );
    });

    test('limit dolu değilken 403 → yetki hatası', () async {
      final built = buildApi(
        (_, __) => jsonResponse(
          {'message': 'Resource not accessible by personal access token'},
          status: 403,
          headers: {
            'x-ratelimit-remaining': ['4999'],
          },
        ),
      );

      expect(
        () => built.api.getFile('hub/BACKLOG.md'),
        throwsA(isA<HubAuthError>()),
      );
    });

    test('404 → HubNotFoundError (listeleme dışında)', () async {
      final built = buildApi(
        (_, __) => jsonResponse({'message': 'Not Found'}, status: 404),
      );

      expect(
        () => built.api.getFile('hub/yok.md'),
        throwsA(isA<HubNotFoundError>()),
      );
    });

    test('500 → HubUnexpectedError, durum kodunu taşır', () async {
      final built = buildApi(
        (_, __) => jsonResponse({'message': 'Server Error'}, status: 500),
      );

      await expectLater(
        built.api.getFile('hub/BACKLOG.md'),
        throwsA(
          isA<HubUnexpectedError>()
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('ağ hatası → HubNetworkError', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = _ThrowingAdapter();
      final api = ContentsApi(dio, owner: 'afgover', repo: 'takip');

      expect(
        () => api.getFile('hub/BACKLOG.md'),
        throwsA(isA<HubNetworkError>()),
      );
    });
  });

  test('yol segmentleri ayrı ayrı encode edilir, / ayraç kalır', () async {
    final built = buildApi(
      (_, __) => jsonResponse({
        'path': 'p',
        'sha': 's',
        'encoding': 'base64',
        'content': b64('x'),
      }),
    );

    await built.api.getFile('hub/tasks/inbox/ödev listesi.md');

    expect(
      built.adapter.requests.single.path,
      '/repos/afgover/takip/contents/hub/tasks/inbox/%C3%B6dev%20listesi.md',
    );
  });
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'ağ yok',
    );
  }

  @override
  void close({bool force = false}) {}
}
