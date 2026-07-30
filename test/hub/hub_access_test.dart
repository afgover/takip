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
    test('hub kökü görünüyorsa geçer ve tek istek atar', () async {
      final built = buildApi(
        (_, __) => jsonResponse([
          {
            'name': 'SYSTEM.md',
            'path': 'hub/SYSTEM.md',
            'sha': 'a',
            'type': 'file',
          },
        ]),
      );

      await checkHubAccess(built.api, candidate);

      expect(built.adapter.requests, hasLength(1));
      expect(
        built.adapter.requests.single.path,
        '/repos/afgover/takip/contents/hub',
      );
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
    final dio = buildGithubDio(() => 'aday-token')
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
