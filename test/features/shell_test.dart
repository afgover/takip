import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/common/repo_switcher.dart';
import 'package:takip/features/shell.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/all_tasks.dart';
import 'package:takip/merkez/merkez_api.dart';
import 'package:takip/merkez/merkez_providers.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      HubConnectionsStore.listKey: jsonEncode([
        {'owner': 'afgover', 'repo': 'takip', 'token': 't'},
      ]),
    });
  });

  testWidgets('repo şeridi durum çubuğunun altına girmez', (tester) async {
    // Çentikli/durum çubuklu bir cihaz taklidi: üstte 48 piksel sistem alanı.
    const topInset = 48.0;

    // Test yerleşimle ilgili; görev listesi sabitlenmezse ekran gerçek ağ
    // isteği açıyor ve testin sonunda askıda zamanlayıcı kalıyor.
    final container = ProviderContainer(
      overrides: [
        activeRepoPendingTasksProvider.overrideWith((ref) async => const <TaskSummary>[]),
      ],
    );
    addTearDown(container.dispose);
    await container.read(hubConnectionsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testApp(
          MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(top: topInset),
            ),
            child: const AppShell(),
          ),
        ),
      ),
    );
    await tester.pump();

    final bar = find.byKey(RepoSwitcher.barKey);
    expect(bar, findsOneWidget);

    // Şerit sistem alanının altında başlamalı. Bu doğrulanmazsa repo adı
    // saatin ve pil ikonunun üzerine biner — gerçek cihazda görülene kadar
    // fark edilmeyen türden bir hata (L-017).
    expect(
      tester.getTopLeft(bar).dy,
      greaterThanOrEqualTo(topInset),
      reason: 'kabuk üst güvenli alanı bırakmıyor',
    );
  });

  testWidgets('sekme değişimi ekleme ekranındaki yazıyı öldürmez (T-022)',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        activeRepoPendingTasksProvider
            .overrideWith((ref) async => const <TaskSummary>[]),
      ],
    );
    addTearDown(container.dispose);
    await container.read(hubConnectionsProvider.future);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: testApp(const AppShell()),
    ));
    await tester.pumpAndSettle();

    // Ekle sekmesine geç, yaz.
    await tester.tap(find.byIcon(Icons.add_task));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'Sekme geçişinde yaşayacak yazı');

    // Başka sekmeye bakıp geri dön — `_screens[_index]` bu noktada ekranı
    // yok edip yazıyı kaybediyordu.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_task));
    await tester.pumpAndSettle();

    expect(find.text('Sekme geçişinde yaşayacak yazı'), findsOneWidget);
  });

  group('Bugün sekmesi', () {
    Future<void> pumpShell(WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          activeRepoPendingTasksProvider
              .overrideWith((ref) async => const <TaskSummary>[]),
          // Oturum varken gerçek ağ isteği açılmasın.
          merkezTodayProvider.overrideWith(
            (ref) async => TodayData.fromJson(const {}),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(hubConnectionsProvider.future);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: testApp(const AppShell()),
      ));
      await tester.pumpAndSettle();
    }

    int selected(WidgetTester tester) =>
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    testWidgets('Merkez oturumu yoksa ana ekran Bekleyenler kalır', (tester) async {
      await pumpShell(tester);
      expect(selected(tester), AppShell.pendingTabIndex);
    });

    testWidgets('Merkez oturumu varsa açılışta Bugün, sonra seçim korunur', (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        HubConnectionsStore.listKey: jsonEncode([
          {'owner': 'afgover', 'repo': 'takip', 'token': 't'},
        ]),
        merkezTokenKey: 'jwt',
      });
      await pumpShell(tester);
      expect(selected(tester), AppShell.todayTabIndex);

      await tester.tap(find.text('Ayarlar'));
      await tester.pumpAndSettle();
      expect(selected(tester), AppShell.settingsTabIndex);
    });
  });
}
