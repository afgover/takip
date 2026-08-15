import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/github/repo_scope_api.dart';

import 'contents_api_test.dart' show FakeAdapter, jsonResponse;

Dio buildDio(FakeAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.github.com'))
      ..httpClientAdapter = adapter;

void main() {
  group('lastPageOfLinkHeader', () {
    test('rel="last" sayfa numarasını okur', () {
      const header =
          '<https://api.github.com/user/repos?per_page=1&page=2>; rel="next", '
          '<https://api.github.com/user/repos?per_page=1&page=7>; rel="last"';

      expect(lastPageOfLinkHeader(header), 7);
    });

    test('sıra değişse de doğru bağlantıyı seçer', () {
      // `last` başta, `next` sonra: parçaların sırası GitHub'ın garantisi
      // değil, o yüzden konuma değil `rel` değerine bakılıyor.
      const header =
          '<https://api.github.com/user/repos?page=42>; rel="last", '
          '<https://api.github.com/user/repos?page=2>; rel="next"';

      expect(lastPageOfLinkHeader(header), 42);
    });

    test('yalnız next varsa null — "son sayfa" bilgisi yok', () {
      const header = '<https://api.github.com/user/repos?page=2>; rel="next"';

      expect(lastPageOfLinkHeader(header), isNull);
    });

    test('boş, null ve bozuk başlık null döner', () {
      expect(lastPageOfLinkHeader(null), isNull);
      expect(lastPageOfLinkHeader(''), isNull);
      expect(lastPageOfLinkHeader('lastik'), isNull);
      expect(lastPageOfLinkHeader('<bozuk; rel="last"'), isNull);
      expect(lastPageOfLinkHeader('<https://x/y?page=0>; rel="last"'), isNull);
    });
  });

  group('readVisibleRepoCount', () {
    test('sayfalama başlığından toplamı okur, gövdeyi indirmez', () async {
      final adapter = FakeAdapter(
        (_, __) => jsonResponse(
          [
            {'full_name': 'afgover/takip'},
          ],
          headers: {
            'link': [
              '<https://api.github.com/user/repos?per_page=1&page=12>; '
                  'rel="last"',
            ],
          },
        ),
      );

      expect(await readVisibleRepoCount(buildDio(adapter)), 12);

      // Tek istek ve tek kayıtlık sayfa: 12 repoluk gövde inmiyor.
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.path, '/user/repos');
      expect(adapter.requests.single.queryParameters['per_page'], 1);
    });

    test('süzgeç parametresi göndermiyor — ölçülen istek sadeydi', () async {
      // T-006 sade `GET /user/repos` ile ölçüldü. `visibility`/`affiliation`
      // eklemek sonucun kapsamını değiştirebilir, yani bu katmanı dayandığı
      // ölçümün dışına çıkarırdı.
      final adapter = FakeAdapter((_, __) => jsonResponse(<Object>[]));

      await readVisibleRepoCount(buildDio(adapter));

      expect(
        adapter.requests.single.queryParameters.keys,
        ['per_page'],
      );
    });

    test('Link başlığı yoksa gövdedeki kayıt sayılır', () async {
      final adapter = FakeAdapter(
        (_, __) => jsonResponse([
          {'full_name': 'afgover/takip'},
        ]),
      );

      expect(await readVisibleRepoCount(buildDio(adapter)), 1);
    });

    test('boş gövde 0 döner — "hiç repo görmüyor" ölçülmüş bir sonuçtur',
        () async {
      final adapter = FakeAdapter((_, __) => jsonResponse(<Object>[]));

      expect(await readVisibleRepoCount(buildDio(adapter)), 0);
    });

    test('hata null döner, 0 değil (bilinmeyen veriye çevrilmez)', () async {
      for (final status in [401, 403, 404, 500]) {
        final adapter = FakeAdapter(
          (_, __) => jsonResponse({'message': 'yok'}, status: status),
        );

        expect(
          await readVisibleRepoCount(buildDio(adapter)),
          isNull,
          reason: '$status için "bilinmiyor" bekleniyordu',
        );
      }
    });

    test('beklenmedik gövde null döner', () async {
      final adapter = FakeAdapter((_, __) => jsonResponse({'toplam': 3}));

      expect(await readVisibleRepoCount(buildDio(adapter)), isNull);
    });
  });
}
