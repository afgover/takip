import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/core/errors.dart';
import 'package:takip/features/settings/connection_screen.dart';
import 'package:takip/features/settings/settings_screen.dart';
import 'package:takip/github/client.dart';
import 'package:takip/hub/hub_access.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/hub_watcher.dart';
import 'package:takip/hub/settings.dart';

class FakeHubConfigNotifier extends HubConfigNotifier {
  FakeHubConfigNotifier([this.config = const HubConfig(
    owner: 'afgover',
    repo: 'takip',
    token: 'eski-token',
  )]);

  HubConfig? config;
  final List<HubConfig> saved = [];
  int clears = 0;

  @override
  Future<HubConfig?> build() async => config;

  @override
  Future<void> save(HubConfig next) async {
    saved.add(next);
    config = next;
    state = AsyncData(next);
  }

  @override
  Future<void> clear() async {
    clears++;
    config = null;
    state = const AsyncData(null);
  }
}

/// Yoklamayı gerçek ağa çıkarmadan sabit tut.
class QuietWatcher extends HubWatcher {
  @override
  HubStatus build() => const HubStatus();

  @override
  void start() {}

  @override
  Future<void> checkNow() async {}
}

({Widget widget, FakeHubConfigNotifier config, List<HubConfig> verified})
    build({
  Future<void> Function(HubConfig)? verifier,
  Widget home = const SettingsScreen(),
}) {
  final notifier = FakeHubConfigNotifier();
  final verified = <HubConfig>[];

  return (
    widget: ProviderScope(
      overrides: [
        hubConfigProvider.overrideWith(() => notifier),
        hubWatcherProvider.overrideWith(QuietWatcher.new),
        hubAccessVerifierProvider.overrideWithValue((candidate) async {
          verified.add(candidate);
          if (verifier != null) await verifier(candidate);
        }),
      ],
      child: MaterialApp(home: home),
    ),
    config: notifier,
    verified: verified,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('bağlı repo gösterilir', (tester) async {
    await tester.pumpWidget(build().widget);
    await tester.pumpAndSettle();

    expect(find.text('afgover/takip'), findsOneWidget);
  });

  testWidgets('yoklama aralığı değiştirilip diske yazılır (B-051)',
      (tester) async {
    await tester.pumpWidget(build().widget);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<Duration>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 dakika').last);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(AppSettings.pollIntervalKey), 300);
  });

  test('diskteki aralık yüklenince geçerli olur', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({AppSettings.pollIntervalKey: 60});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // İlk okuma varsayılanı verir; disk okuması bir sonraki mikro görevde.
    expect(container.read(appSettingsProvider).pollInterval,
        const Duration(seconds: 45));

    await Future<void>.delayed(Duration.zero);
    expect(container.read(pollIntervalProvider), const Duration(minutes: 1));
  });

  test('tanınmayan aralık değeri yok sayılır', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({AppSettings.pollIntervalKey: 7});

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appSettingsProvider);

    await Future<void>.delayed(Duration.zero);
    expect(container.read(pollIntervalProvider), const Duration(seconds: 45));
  });

  testWidgets('sıfırlama önce onay ister', (tester) async {
    final built = build();
    await tester.pumpWidget(built.widget);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SettingsScreen.resetKey));
    await tester.pumpAndSettle();

    expect(find.text('Bağlantı sıfırlansın mı?'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(built.config.clears, 0);

    await tester.tap(find.byKey(SettingsScreen.resetKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sıfırla'));
    await tester.pumpAndSettle();

    expect(built.config.clears, 1);
  });

  group('bağlantı düzenleme', () {
    testWidgets('doğrulama geçmeden kaydedilmez', (tester) async {
      final built = build(
        home: const ConnectionScreen(),
        verifier: (_) async => throw const HubAuthError('Token geçersiz.'),
      );
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(ConnectionScreen.tokenFieldKey),
        'yeni-token',
      );
      await tester.tap(find.byKey(ConnectionScreen.submitKey));
      await tester.pumpAndSettle();

      expect(find.byKey(ConnectionScreen.errorKey), findsOneWidget);
      expect(built.config.saved, isEmpty,
          reason: 'çalışan kurulum bozulmamalı');
    });

    testWidgets('token boş bırakılırsa mevcut token korunur', (tester) async {
      final built = build(home: const ConnectionScreen());
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(ConnectionScreen.repoFieldKey),
        'afgover/baska-repo',
      );
      await tester.tap(find.byKey(ConnectionScreen.submitKey));
      await tester.pumpAndSettle();

      expect(built.verified.single.token, 'eski-token');
      expect(built.config.saved.single.repo, 'baska-repo');
    });

    testWidgets('yeni token doğrulanıp kaydedilir', (tester) async {
      final built = build(home: const ConnectionScreen());
      await tester.pumpWidget(built.widget);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(ConnectionScreen.tokenFieldKey),
        '  yeni-token  ',
      );
      await tester.tap(find.byKey(ConnectionScreen.submitKey));
      await tester.pumpAndSettle();

      expect(built.verified.single.token, 'yeni-token');
      expect(built.config.saved.single.token, 'yeni-token');
    });
  });

  testWidgets('önbellek temizlenince ETag kayıtları gider', (tester) async {
    final cache = EtagCache();
    cache.write('GET /x', '"e1"', const []);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        hubConfigProvider.overrideWith(FakeHubConfigNotifier.new),
        hubWatcherProvider.overrideWith(QuietWatcher.new),
        etagCacheProvider.overrideWithValue(cache),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SettingsScreen.clearCacheKey));
    await tester.pumpAndSettle();

    expect(cache.length, 0);
    expect(find.text('Önbellek temizlendi.'), findsOneWidget);
  });
}
