import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/core/errors.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/hub/hub_access.dart';
import 'package:takip/hub/hub_config.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

const candidate = HubConfig(owner: 'afgover', repo: 'takip', token: 't');

/// Hub kökü okunabiliyor; PUT yanıtını test belirliyor.
({ContentsApi api, FakeAdapter adapter}) boot(
  ResponseBody Function(RequestOptions options, String? body) onPut,
) {
  final adapter = FakeAdapter((options, body) {
    if (options.method == 'GET') {
      return jsonResponse([
        {
          'name': 'SYSTEM.md',
          'path': 'hub/SYSTEM.md',
          'sha': 'a',
          'type': 'file',
        }
      ]);
    }
    return onPut(options, body);
  });

  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;
  return (
    api: ContentsApi(dio, owner: 'afgover', repo: 'takip'),
    adapter: adapter,
  );
}

ResponseBody forbidden({
  String? accepted = 'contents=write',
  String remaining = '4999',
}) =>
    jsonResponse(
      {'message': 'Resource not accessible by personal access token'},
      status: 403,
      headers: {
        'x-ratelimit-remaining': [remaining],
        if (accepted != null) 'x-accepted-github-permissions': [accepted],
      },
    );

/// İzin varken içeriksiz PUT'un aldığı yanıt.
ResponseBody missingContent(RequestOptions _, String? __) => jsonResponse(
      {'message': 'Invalid request. "content" wasn\'t supplied.'},
      status: 422,
    );

void main() {
  group('yazma izni yoklaması (B-026)', () {
    test('403 kesin olumsuzdur; eksik izin adıyla bildirilir', () async {
      final built = boot((_, __) => forbidden());

      await expectLater(
        checkHubAccess(built.api, candidate),
        throwsA(
          isA<HubAuthError>().having(
            (e) => e.message,
            'message',
            allOf(contains('yazamıyor'), contains('contents=write')),
          ),
        ),
      );
    });

    test('başlık yoksa genel izin adı kullanılır', () async {
      final built = boot((_, __) => forbidden(accepted: null));

      await expectLater(
        checkHubAccess(built.api, candidate),
        throwsA(isA<HubAuthError>()),
      );
    });

    test('422 doğrulama hatası "izin yok" sayılmaz', () async {
      // İzin varsa içeriksiz PUT doğrulamada takılır; buradan geçilmeli.
      final built = boot(missingContent);

      await expectLater(checkHubAccess(built.api, candidate), completes);
    });

    test('rate limit 403\'ü izin sorunu sanılmaz', () async {
      final built = boot((_, __) => forbidden(remaining: '0'));

      await expectLater(checkHubAccess(built.api, candidate), completes);
    });

    test('yoklama içerik göndermez — repoda dosya oluşamaz', () async {
      final built = boot(missingContent);
      await checkHubAccess(built.api, candidate);

      final put = built.adapter.requests.firstWhere((r) => r.method == 'PUT');
      final sent = jsonDecode(
        built.adapter.bodies[built.adapter.requests.indexOf(put)]!,
      ) as Map;

      expect(sent.containsKey('content'), isFalse,
          reason: 'içerik olmadan GitHub dosya oluşturamaz');
      expect(sent.containsKey('sha'), isFalse);
      expect(put.path, contains(Hub.inboxDir));
    });

    test('okuma başarısızsa yazma denemesi hiç yapılmaz', () async {
      final adapter = FakeAdapter((options, _) {
        if (options.method == 'GET') {
          return jsonResponse({'message': 'Not Found'}, status: 404);
        }
        return jsonResponse({}, status: 200);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = adapter;

      await expectLater(
        checkHubAccess(
          ContentsApi(dio, owner: 'afgover', repo: 'takip'),
          candidate,
        ),
        throwsA(isA<HubNotFoundError>()),
      );
      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
    });

    test('beklenmedik başarı da "izin yok" sayılmaz', () async {
      final built = boot((_, __) => jsonResponse({'content': {}}));

      await expectLater(checkHubAccess(built.api, candidate), completes);
    });
  });
}
