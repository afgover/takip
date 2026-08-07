import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/common/repo_switcher.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/hub_watcher.dart';

import '../helpers/test_app.dart';

/// Repo geçişi yoklamayı yeniden başlatır (periyodik zamanlayıcı). Test
/// bitmeden durdurulmazsa çerçeve "askıda timer" diye haklı olarak patlar.
void stopWatcher(ProviderContainer container) =>
    container.read(hubWatcherProvider.notifier).stop();

/// Diskte kayıtlı bağlantılarla açılmış bir uygulama taklidi.
Future<ProviderContainer> pumpSwitcher(
  WidgetTester tester,
  List<({String slug, String? label})> repos, {
  String? activeSlug,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    HubConnectionsStore.listKey: jsonEncode([
      for (final r in repos)
        {
          'owner': r.slug.split('/').first,
          'repo': r.slug.split('/').last,
          'token': 't',
          if (r.label != null) 'label': r.label,
        },
    ]),
    if (activeSlug != null) HubConnectionsStore.activeKey: activeSlug,
  });

  final container = ProviderContainer();
  addTearDown(container.dispose);
  await container.read(hubConnectionsProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: testApp(
        const Scaffold(body: Column(children: [RepoSwitcher()])),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('bağlantı yokken şerit görünmez', (tester) async {
    await pumpSwitcher(tester, const []);
    expect(find.byKey(RepoSwitcher.barKey), findsNothing);
  });

  testWidgets('tek repoda ad görünür, sayaç görünmez', (tester) async {
    await pumpSwitcher(tester, const [(slug: 'afgover/takip', label: null)]);

    expect(find.byKey(RepoSwitcher.barKey), findsOneWidget);
    expect(find.text('afgover/takip'), findsOneWidget);
    expect(find.textContaining('repo'), findsNothing,
        reason: 'tek repoda sayaç gürültüden ibaret olurdu');
  });

  testWidgets('ad verilmişse slug yerine ad gösterilir', (tester) async {
    await pumpSwitcher(tester, const [(slug: 'afgover/takip', label: 'Takip')]);

    expect(find.text('Takip'), findsOneWidget);
    expect(find.text('afgover/takip'), findsNothing);
  });

  testWidgets('birden çok repoda sayaç görünür', (tester) async {
    await pumpSwitcher(
      tester,
      const [(slug: 'a/bir', label: null), (slug: 'b/iki', label: null)],
      activeSlug: 'a/bir',
    );

    expect(find.text('a/bir'), findsOneWidget);
    expect(find.text('2 repo'), findsOneWidget);
  });

  testWidgets('şeride dokununca repo listesi açılır', (tester) async {
    await pumpSwitcher(
      tester,
      const [(slug: 'a/bir', label: null), (slug: 'b/iki', label: 'İki')],
      activeSlug: 'a/bir',
    );

    await tester.tap(find.byKey(RepoSwitcher.barKey));
    await tester.pumpAndSettle();

    expect(find.byKey(RepoSwitcher.tileKey('a/bir')), findsOneWidget);
    expect(find.byKey(RepoSwitcher.tileKey('b/iki')), findsOneWidget);
    expect(find.text('Repo ekle'), findsOneWidget);
    expect(find.text('Repoları yönet'), findsOneWidget);
  });

  testWidgets('listeden repo seçilince aktif değişir', (tester) async {
    final container = await pumpSwitcher(
      tester,
      const [(slug: 'a/bir', label: null), (slug: 'b/iki', label: null)],
      activeSlug: 'a/bir',
    );

    await tester.tap(find.byKey(RepoSwitcher.barKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RepoSwitcher.tileKey('b/iki')));
    await tester.pumpAndSettle();
    stopWatcher(container);

    expect(
      container.read(hubConnectionsProvider).value!.active?.slug,
      'b/iki',
    );
    // Şerit yeni repoyu göstermeli.
    expect(find.text('b/iki'), findsOneWidget);
  });

  testWidgets('seçim diske yazılır', (tester) async {
    final container = await pumpSwitcher(
      tester,
      const [(slug: 'a/bir', label: null), (slug: 'b/iki', label: null)],
      activeSlug: 'a/bir',
    );

    await tester.tap(find.byKey(RepoSwitcher.barKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RepoSwitcher.tileKey('b/iki')));
    await tester.pumpAndSettle();
    stopWatcher(container);

    expect(
      await const FlutterSecureStorage().read(key: HubConnectionsStore.activeKey),
      'b/iki',
    );
  });
}
