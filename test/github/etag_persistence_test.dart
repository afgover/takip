import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/github/client.dart';

import 'contents_api_test.dart' show FakeAdapter, jsonResponse;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('önbellek diske yazılıp geri okunur (B-046)', () async {
    final store = EtagCacheStore('etag_cache');
    final cache = EtagCache(onChanged: () {});

    cache.write('GET https://api.github.com/x', '"e1"', [
      {'sha': 'commit-1'}
    ]);
    await store.save(cache);

    final restored = EtagCache();
    await store.restore(restored);

    expect(restored.etagOf('GET https://api.github.com/x'), '"e1"');
    expect(restored.dataOf('GET https://api.github.com/x'), [
      {'sha': 'commit-1'}
    ]);
  });

  test('bozuk kayıt uygulamayı kilitlemez, temizlenir', () async {
    SharedPreferences.setMockInitialValues({'etag_cache': 'bu json değil'});
    final store = EtagCacheStore('etag_cache');
    final cache = EtagCache();

    await store.restore(cache);

    expect(cache.length, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('etag_cache'), isNull);
  });

  test('kayıt sayısı sınırlanır', () async {
    final cache = EtagCache();
    for (var i = 0; i < EtagCache.maxPersistedEntries + 20; i++) {
      cache.write('GET /$i', '"e$i"', {'i': i});
    }

    expect(cache.toJson(), hasLength(EtagCache.maxPersistedEntries));
    // En son yazılanlar korunur.
    expect(cache.toJson().keys.first, contains('/99'));
  });

  test('açılışta önbellek doluysa istek If-None-Match ile gider', () async {
    final store = EtagCacheStore('etag_cache');
    final warm = EtagCache();
    warm.write('GET https://api.github.com/repos/a/b/commits', '"e1"', const []);
    await store.save(warm);

    // Uygulama yeniden açıldı: yeni önbellek diskten dolduruluyor.
    final cache = EtagCache();
    await store.restore(cache);

    final adapter = FakeAdapter((_, __) => ResponseBody.fromString('', 304));
    final dio = buildGithubDio((_) => 't', cache: cache)
      ..httpClientAdapter = adapter;

    final res = await dio.get<dynamic>('/repos/a/b/commits');

    expect(adapter.requests.single.headers['If-None-Match'], '"e1"');
    expect(res.extra[notModifiedFlag], isTrue);
  });

  group('ağ yokken önbellekten gösterim', () {
    test('son bilinen içerik döner ve bayat olduğu işaretlenir', () async {
      final cache = EtagCache();
      var online = true;
      final dio = buildGithubDio((_) => 't', cache: cache)
        ..httpClientAdapter = FakeAdapter((options, _) {
          if (!online) {
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'ağ yok',
            );
          }
          return jsonResponse(
            [
              {'sha': 'commit-1'}
            ],
            headers: {
              'etag': ['"e1"']
            },
          );
        });

      await dio.get<dynamic>('/repos/a/b/commits');
      online = false;
      final offline = await dio.get<dynamic>('/repos/a/b/commits');

      expect(offline.data, [
        {'sha': 'commit-1'}
      ]);
      expect(offline.extra[servedFromCacheFlag], isTrue);
    });

    test('önbellekte yoksa hata yutulmaz', () async {
      final dio = buildGithubDio((_) => 't', cache: EtagCache())
        ..httpClientAdapter = FakeAdapter(
          (options, _) => throw DioException.connectionError(
            requestOptions: options,
            reason: 'ağ yok',
          ),
        );

      expect(
        () => dio.get<dynamic>('/repos/a/b/commits'),
        throwsA(isA<DioException>()),
      );
    });

    test('sunucu hatası önbellekle gizlenmez', () async {
      // 401/500 gibi yanıtlar "ağ yok" değildir; bayat içerik göstermek
      // sorunu saklamak olurdu.
      final cache = EtagCache();
      var fail = false;
      final dio = buildGithubDio((_) => 't', cache: cache)
        ..httpClientAdapter = FakeAdapter((options, _) => fail
            ? jsonResponse({'message': 'Bad credentials'}, status: 401)
            : jsonResponse(const [], headers: {
                'etag': ['"e1"']
              }));

      await dio.get<dynamic>('/repos/a/b/commits');
      fail = true;

      expect(
        () => dio.get<dynamic>('/repos/a/b/commits'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
