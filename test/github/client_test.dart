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
      final dio = buildGithubDio((_) => 't', cache: cache)
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
      final dio = buildGithubDio((_) => 't', cache: cache)
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
      final dio = buildGithubDio((_) => 't', cache: cache)
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
      final dio = buildGithubDio((_) => 't', cache: cache)
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
      final dio = buildGithubDio((_) => 't', cache: cache)
        ..httpClientAdapter = adapter;

      await dio.put<dynamic>('/repos/a/b/contents/x.md', data: {'a': 1});

      expect(cache.length, 0);
    });

    test('önbellek temizlendikten sonra gelen 304 hataya çevrilir', () async {
      // Sunucu bizim göndermediğimiz bir etag'e 304 dönemez; yine de olursa
      // sessizce boş veri göstermek yerine hata verilir.
      final cache = EtagCache();
      final dio = buildGithubDio((_) => 't', cache: cache)
        ..httpClientAdapter =
            FakeAdapter((_, __) => ResponseBody.fromString('', 304));

      await expectLater(
        dio.get<dynamic>('/repos/a/b/commits'),
        throwsA(isA<DioException>()),
      );
    });

    test('önbellek verilmezse If-None-Match eklenmez', () async {
      final adapter = FakeAdapter((_, __) => jsonResponse(const []));
      final dio = buildGithubDio((_) => 't')..httpClientAdapter = adapter;

      await dio.get<dynamic>('/repos/a/b/commits');
      await dio.get<dynamic>('/repos/a/b/commits');

      expect(
        adapter.requests.every((r) => !r.headers.containsKey('If-None-Match')),
        isTrue,
      );
    });
  });
  group('token isteğin gittiği repoya bağlanır (L-019)', () {
    test('githubSlugOf yolu ayrıştırır', () {
      expect(githubSlugOf('/repos/afgover/takip/commits'), 'afgover/takip');
      expect(
        githubSlugOf('/repos/afgover/financer_takip/contents/hub'),
        'afgover/financer_takip',
      );
      // Yüzde-kodlanmış segmentler çözülür.
      expect(githubSlugOf('/repos/af%2Dgover/a%2Eb'), 'af-gover/a.b');
      // Repo yolu olmayan istekler eşleşmez.
      expect(githubSlugOf('/user'), isNull);
      expect(githubSlugOf('/repos/afgover'), isNull);
      expect(githubSlugOf(''), isNull);
    });

    test('her repo kendi token\'ıyla çağrılır, aktif olan hangisiyse olsun',
        () async {
      final tokens = <String, String>{
        'afgover/takip': 'token-takip',
        'afgover/financer_takip': 'token-financer',
      };
      final seen = <String, String?>{};

      final adapter = FakeAdapter((options, _) {
        seen[options.path] = options.headers['Authorization'] as String?;
        return jsonResponse(const []);
      });
      // Gerçekteki kurulumun aynısı: token, isteğin yolundan seçiliyor.
      final dio = buildGithubDio(
        (options) => tokens[githubSlugOf(options.path)],
      )..httpClientAdapter = adapter;

      await dio.get<dynamic>('/repos/afgover/takip/commits');
      await dio.get<dynamic>('/repos/afgover/financer_takip/commits');

      expect(seen['/repos/afgover/takip/commits'], 'Bearer token-takip');
      expect(
        seen['/repos/afgover/financer_takip/commits'],
        'Bearer token-financer',
        reason: 'adres bir repoya, token başka repoya ait olamaz',
      );
    });

    test('eşleşme yoksa token gönderilmez', () async {
      final adapter = FakeAdapter((options, _) => jsonResponse(const []));
      final dio = buildGithubDio((options) => null)
        ..httpClientAdapter = adapter;

      await dio.get<dynamic>('/repos/afgover/takip/commits');

      expect(adapter.requests.single.headers['Authorization'], isNull);
    });
  });
}
