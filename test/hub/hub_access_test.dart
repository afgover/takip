import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/errors.dart';
import 'package:takip/github/client.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/hub/hub_access.dart';
import 'package:takip/hub/hub_config.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

const candidate = HubConfig(owner: 'afgover', repo: 'takip', token: 'gizli');

({ContentsApi api, FakeAdapter adapter}) buildApi(
  ResponseBody Function(RequestOptions options, String? body) handler,
) {
  final adapter = FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;
  return (
    api: ContentsApi(dio, owner: candidate.owner, repo: candidate.repo),
    adapter: adapter,
  );
}

void main() {
  group('checkHubAccess', () {
    test('hub kökü okunur, ardından yazma izni yoklanır', () async {
      // İki istek: hub kökünü okuma + içeriksiz yazma denemesi (B-026).
      final built = buildApi((options, __) {
        if (options.method == 'GET') {
          return jsonResponse([
            {
              'name': 'SYSTEM.md',
              'path': 'hub/SYSTEM.md',
              'sha': 'a',
              'type': 'file',
            },
          ]);
        }
        return jsonResponse(
          {'message': 'Invalid request. "content" wasn\'t supplied.'},
          status: 422,
        );
      });

      await checkHubAccess(built.api, candidate);

      expect(built.adapter.requests, hasLength(2));
      expect(
        built.adapter.requests.first.path,
        '/repos/afgover/takip/contents/hub',
      );
      expect(built.adapter.requests.last.method, 'PUT');
    });

    test('404 → repo/token/klasör olasılıklarını birlikte söyler', () async {
      final built = buildApi(
        (_, __) => jsonResponse({'message': 'Not Found'}, status: 404),
      );

      await expectLater(
        checkHubAccess(built.api, candidate),
        throwsA(
          isA<HubNotFoundError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('afgover/takip'),
              contains('Repo adı'),
              contains('token'),
            ),
          ),
        ),
      );
    });

    test('geçersiz token → yetki hatası (yok sayılmaz)', () async {
      final built = buildApi(
        (_, __) => jsonResponse({'message': 'Bad credentials'}, status: 401),
      );

      expect(
        () => checkHubAccess(built.api, candidate),
        throwsA(isA<HubAuthError>()),
      );
    });

    test('ağ yoksa ağ hatası olarak görünür', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = FakeAdapter((options, _) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'ağ yok',
          );
        });

      expect(
        () => checkHubAccess(
          ContentsApi(dio, owner: 'afgover', repo: 'takip'),
          candidate,
        ),
        throwsA(isA<HubNetworkError>()),
      );
    });
  });

  test('doğrulama isteği aday token ile imzalanır', () async {
    // Henüz kaydedilmemiş token'la doğrulama yapılabilmesi B-022'nin şartı.
    final adapter = FakeAdapter((_, __) => jsonResponse(const []));
    final dio = buildGithubDio((_) => 'aday-token')
      ..httpClientAdapter = adapter;

    await ContentsApi(dio, owner: 'afgover', repo: 'takip')
        .pathExists('hub');

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer aday-token',
    );
  });

  group('HubConfig.parseRepo', () {
    test('owner/ad', () {
      expect(HubConfig.parseRepo('afgover/takip')?.owner, 'afgover');
      expect(HubConfig.parseRepo('  afgover/takip  ')?.repo, 'takip');
    });

    test('yapıştırılan GitHub adresi', () {
      expect(HubConfig.parseRepo('https://github.com/afgover/takip')?.repo,
          'takip');
      expect(HubConfig.parseRepo('github.com/afgover/takip.git')?.repo, 'takip');
      expect(HubConfig.parseRepo('https://github.com/afgover/takip/')?.owner,
          'afgover');
    });

    test('bozuk biçimler reddedilir', () {
      for (final bad in ['', 'takip', 'a/b/c', '/takip', 'afgover/', 'a b/c']) {
        expect(HubConfig.parseRepo(bad), isNull, reason: bad);
      }
    });
  });
}
