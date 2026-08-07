import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/settings/connection_screen.dart';
import 'package:takip/hub/hub_access.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/hub_watcher.dart';

import '../helpers/test_app.dart';

Map<String, dynamic> row(String slug, String token, {String? label}) => {
      'owner': slug.split('/').first,
      'repo': slug.split('/').last,
      'token': token,
      if (label != null) 'label': label,
    };

/// Diskte verilen bağlantılarla açılmış bir kap.
Future<ProviderContainer> seed(
  List<Map<String, dynamic>> connections, {
  List<Override> overrides = const [],
}) async {
  FlutterSecureStorage.setMockInitialValues(
    connections.isEmpty
        ? {}
        : {HubConnectionsStore.listKey: jsonEncode(connections)},
  );
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  await container.read(hubConnectionsProvider.future);
  return container;
}

Widget wrap(ProviderContainer container, Widget home) =>
    UncontrolledProviderScope(
      container: container,
      child: testApp(home),
    );

/// Uzun formlarda varsayılan test ekranı alt alanları hiç oluşturmuyor ve
/// `enterText` "widget yok" diye patlıyor. Ekranı yükseltmek, her etkileşimden
/// önce kaydırmaktan hem kısa hem okunur.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('token yeniden kullanımı', () {
    testWidgets('mevcut token seçilince token alanı zorunlu olmaz',
        (tester) async {
      useTallScreen(tester);
      final verified = <HubConfig>[];
      final container = await seed(
        [row('a/bir', 'ortak-token', label: 'Bir')],
        overrides: [
          hubAccessVerifierProvider.overrideWithValue((candidate) async {
            verified.add(candidate);
            return const HubAccess();
          }),
        ],
      );

      await tester.pumpWidget(
        wrap(container, const ConnectionScreen(mode: ConnectionMode.add)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(ConnectionScreen.repoFieldKey), 'a/yeni');

      // Token alanı boş; bunun yerine mevcut bağlantının token'ı seçiliyor.
      final dropdown = find.byKey(ConnectionScreen.reuseTokenKey);
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Bir token'ını kullan").last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ConnectionScreen.submitKey));
      await tester.pumpAndSettle();
      container.read(hubWatcherProvider.notifier).stop();

      // Doğrulama yine çalışmalı — yeniden kullanım güvenliği gevşetmiyor.
      expect(verified, hasLength(1));
      expect(verified.single.slug, 'a/yeni');
      expect(verified.single.token, 'ortak-token');

      final state = container.read(hubConnectionsProvider).value!;
      expect(state.connections.map((c) => c.slug), ['a/bir', 'a/yeni']);
      expect(state.bySlug('a/yeni')?.token, 'ortak-token');
    });

    testWidgets('token seçilmediyse ve yazılmadıysa uyarı verir',
        (tester) async {
      useTallScreen(tester);
      final verified = <HubConfig>[];
      final container = await seed(
        [row('a/bir', 'ortak-token')],
        overrides: [
          hubAccessVerifierProvider.overrideWithValue((candidate) async {
            verified.add(candidate);
            return const HubAccess();
          }),
        ],
      );

      await tester.pumpWidget(
        wrap(container, const ConnectionScreen(mode: ConnectionMode.add)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(ConnectionScreen.repoFieldKey), 'a/yeni');
      await tester.tap(find.byKey(ConnectionScreen.submitKey));
      await tester.pumpAndSettle();

      expect(find.text('Token gerekli'), findsOneWidget);
      expect(verified, isEmpty);
    });
  });
}
