import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/core/errors.dart';
import 'package:takip/features/common/hub_error_view.dart';
import 'package:takip/features/common/hub_status_banner.dart';
import 'package:takip/github/client.dart';
import 'package:takip/github/commits_api.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/hub_watcher.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

class FakeHubConfigNotifier extends HubConfigNotifier {
  @override
  Future<HubConfig?> build() async =>
      const HubConfig(owner: 'afgover', repo: 'takip', token: 't');
}

class FakeWatcher extends HubWatcher {
  FakeWatcher(this._initial);
  final HubStatus _initial;

  @override
  HubStatus build() => _initial;

  @override
  Future<void> checkNow() async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('describeHubError — her hata için yapılabilecek bir şey (B-050)', () {
    test('ağ hatası kuyruğu hatırlatır, ayarlara yollamaz', () {
      final detail = describeHubError(const HubNetworkError('x'));

      expect(detail.headline, 'Bağlantı yok');
      expect(detail.message, contains('kuyrukta bekler'));
      expect(detail.suggestsSettings, isFalse);
    });

    test('token hatası izinleri söyler ve ayarlara yollar', () {
      final detail = describeHubError(const HubAuthError('Token geçersiz.'));

      expect(detail.headline, 'Token kabul edilmedi');
      expect(detail.message, contains('Contents: Read and write'));
      expect(detail.suggestsSettings, isTrue);
    });

    test('rate limit kalan süreyi söyler', () {
      final now = DateTime(2026, 7, 30, 12);
      final detail = describeHubError(
        HubRateLimitError('x', resetAt: now.add(const Duration(minutes: 12))),
        now: now,
      );

      expect(detail.headline, 'İstek limiti doldu');
      expect(detail.message, contains('12 dakika'));
    });

    test('reset zamanı geçmişse "birazdan" denir', () {
      final now = DateTime(2026, 7, 30, 12);
      final detail = describeHubError(
        HubRateLimitError('x', resetAt: now.subtract(const Duration(hours: 1))),
        now: now,
      );

      expect(detail.message, contains('Birazdan'));
    });

    test('bilinmeyen hata da anlaşılır biçimde sunulur', () {
      final detail = describeHubError(StateError('bir şey'));

      expect(detail.headline, 'Beklenmeyen hata');
      expect(detail.message, contains('bir şey'));
    });
  });

  testWidgets('token hatasında ayarlar düğmesi çıkar', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HubErrorView(
          error: const HubAuthError('Token geçersiz.'),
          onOpenSettings: () => opened = true,
          onRetry: () {},
        ),
      ),
    ));

    expect(find.text('Token kabul edilmedi'), findsOneWidget);
    await tester.tap(find.text('Bağlantı ayarları'));
    expect(opened, isTrue);
  });

  testWidgets('ağ hatasında ayarlar düğmesi çıkmaz', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HubErrorView(
          error: const HubNetworkError('yok'),
          onOpenSettings: () {},
          onRetry: () {},
        ),
      ),
    ));

    expect(find.text('Bağlantı ayarları'), findsNothing);
    expect(find.text('Yeniden dene'), findsOneWidget);
  });

  group('durum şeridi', () {
    Widget banner({
      required HubStatus status,
      VoidCallback? onOpenSettings,
    }) =>
        ProviderScope(
          overrides: [
            hubConfigProvider.overrideWith(FakeHubConfigNotifier.new),
            hubWatcherProvider.overrideWith(() => FakeWatcher(status)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HubStatusBanner(onOpenSettings: onOpenSettings),
            ),
          ),
        );

    testWidgets('sorun yokken görünmez', (tester) async {
      await tester.pumpWidget(banner(status: const HubStatus()));
      await tester.pumpAndSettle();

      expect(find.byKey(HubStatusBanner.bannerKey), findsNothing);
    });

    testWidgets('hata varsa başlığı ve çıkış yolunu gösterir', (tester) async {
      var opened = false;
      await tester.pumpWidget(banner(
        status: const HubStatus(error: HubAuthError('Token geçersiz.')),
        onOpenSettings: () => opened = true,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(HubStatusBanner.bannerKey), findsOneWidget);
      expect(find.text('Token kabul edilmedi'), findsOneWidget);

      await tester.tap(find.text('Ayarlar'));
      expect(opened, isTrue);
    });

    testWidgets('ağ hatasında yeniden dene sunar', (tester) async {
      await tester.pumpWidget(banner(
        status: const HubStatus(error: HubNetworkError('yok')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bağlantı yok'), findsOneWidget);
      expect(find.text('Yeniden dene'), findsOneWidget);
    });
  });

  test('önbellekten gelen commit yanıtı "değişmedi" sayılmaz', () async {
    // B-046 ile ağ yokken GET'ler önbellekten dönüyor. Yoklama bunu cevap
    // sayarsa kullanıcı çevrimdışı olduğunu hiç öğrenemez.
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

    final api = CommitsApi(dio, owner: 'afgover', repo: 'takip');
    expect(await api.headSha(), 'commit-1');

    online = false;
    expect(() => api.headSha(), throwsA(isA<HubNetworkError>()));
  });
}
