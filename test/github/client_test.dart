import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/github/client.dart';

import 'contents_api_test.dart' show FakeAdapter, jsonResponse;

void main() {
  group('ETag doğrulama önbelleği (B-024)', () {
    test('ilk GET etag\'i saklar, ikincisi If-None-Match gönderir', () async {
      final cache = EtagCache();
      final adapter = FakeAdapter(
        (_, __) => jsonResponse(
          [
            {'sha': 'commit-1'}
          ],
          headers: {
            'etag': ['"abc"']
          },
        ),
      );
      final dio = buildGithubDio(() => 't', cache: cache)
        ..httpClientAdapter = adapter;

      await dio.get<dynamic>('/repos/a/b/commits');
      await dio.get<dynamic>('/repos/a/b/commits');

      expect(adapter.requests.first.headers.containsKey('If-None-Match'),
          isFalse);
      expect(adapter.requests.last.headers['If-None-Match'], '"abc"');
    });

    test('304 gelince gövde önbellekten döner ve işaretlenir', () async {
      final cache = EtagCache();
      var call = 0;
      final adapter = FakeAdapter((_, __) {
        call++;
        if (call == 1) {
          return jsonResponse(
            [
              {'sha': 'commit-1'}
            ],
            headers: {
              'etag': ['"abc"']
            },
          );
        }
        return ResponseBody.fromString('', 304);
      });
      final dio = buildGithubDio(() => 't', cache: cache)
        ..httpClientAdapter = adapter;

      await dio.get<dynamic>('/repos/a/b/commits');
      final second = await dio.get<dynamic>('/repos/a/b/commits');

      expect(second.statusCode, 200);
      expect(second.data, [
        {'sha': 'commit-1'}
      ]);
      expect(second.extra[notModifiedFlag], isTrue);
    });

    test('yazma sonrası yeni içerik gelir (bayat veri gösterilmez)', () async {
      final cache = EtagCache();
      var call = 0;
      final adapter = FakeAdapter((_, __) {
        call++;
        return jsonResponse(
          [
            {'sha': 'commit-$call'}
          ],
          headers: {
            'etag': ['"etag-$call"']
          },
        );
      });
      final dio = buildGithubDio(() => 't', cache: cache)
        ..httpClientAdapter = adapter;

      await dio.get<dynamic>('/repos/a/b/commits');
      // Sunucu değişikliği görünce 200 + yeni etag döner; önbellek güncellenir.
      final second = await dio.get<dynamic>('/repos/a/b/commits');

      expect(second.data, [
        {'sha': 'commit-2'}
      ]);
      expect(second.extra[notModifiedFlag], isNull);
      expect(cache.etagOf('GET https://api.github.com/repos/a/b/commits'),
          '"etag-2"');
    });

    test('farklı yollar birbirinin etag\'ini kullanmaz', () async {
      final cache = EtagCache();
      final adapter = FakeAdapter(
        (options, __) => jsonResponse(
          const [],
          headers: {
            'etag': ['"${options.path}"']
          },
        ),
      );
      final dio = buildGithubDio(() => 't', cache: cache)
        ..httpClientAdapter = adapter;

      await dio.get<dynamic>('/repos/a/b/contents/hub');
      await dio.get<dynamic>('/repos/a/b/commits');

      expect(cache.length, 2);
      expect(adapter.requests.last.headers.containsKey('If-None-Match'),
          isFalse);
    });

    test('GET olmayan istekler önbelleğe girmez', () async {
      final cache = EtagCache();
      final adapter = FakeAdapter(
        (_, __) => jsonResponse(
          {'content': <String, dynamic>{}},
          headers: {
            'etag': ['"x"']
          },
        ),
      );
      final dio = buildGithubDio(() => 't', cache: cache)
        ..httpClientAdapter = adapter;

      await dio.put<dynamic>('/repos/a/b/contents/x.md', data: {'a': 1});

      expect(cache.length, 0);
    });

    test('önbellek temizlendikten sonra gelen 304 hataya çevrilir', () async {
      // Sunucu bizim göndermediğimiz bir etag'e 304 dönemez; yine de olursa
      // sessizce boş veri göstermek yerine hata verilir.
      final cache = EtagCache();
      final dio = buildGithubDio(() => 't', cache: cache)
        ..httpClientAdapter =
            FakeAdapter((_, __) => ResponseBody.fromString('', 304));

      await expectLater(
        dio.get<dynamic>('/repos/a/b/commits'),
        throwsA(isA<DioException>()),
      );
    });

    test('önbellek verilmezse If-None-Match eklenmez', () async {
      final adapter = FakeAdapter((_, __) => jsonResponse(const []));
      final dio = buildGithubDio(() => 't')..httpClientAdapter = adapter;

      await dio.get<dynamic>('/repos/a/b/commits');
      await dio.get<dynamic>('/repos/a/b/commits');

      expect(
        adapter.requests.every((r) => !r.headers.containsKey('If-None-Match')),
        isTrue,
      );
    });
  });
}
