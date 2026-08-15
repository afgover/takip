import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/settings/settings_screen.dart';
import 'package:takip/hub/hub_access.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/hub_watcher.dart';

import '../helpers/test_app.dart';
import 'settings_screen_test.dart' show FakeHubConfigNotifier, QuietWatcher;

/// Ayarlar'daki "Token kapsamı" satırı (B-103, P-003.4).
///
/// Ölçüm sonuçlarının **ayrı** gösterildiğini kuruyor: "ölçülemedi" ile
/// "fazla erişim yok" aynı kutuya düşerse kontrol sessizce yalan söyler.
Widget build({
  required Future<int?> Function(HubConfig) measure,
  List<HubConfig> connections = const [],
  String token = 'github_pat_x',
}) {
  final config = HubConfig(owner: 'afgover', repo: 'takip', token: token);

  return ProviderScope(
    overrides: [
      hubConfigProvider.overrideWith(() => FakeHubConfigNotifier(config)),
      hubWatcherProvider.overrideWith(QuietWatcher.new),
      hubConnectionsProvider.overrideWith(
        () => _FakeConnections(
          connections.isEmpty ? [config] : connections,
        ),
      ),
      tokenScopeMeasureProvider.overrideWithValue(measure),
    ],
    child: testApp(const SettingsScreen()),
  );
}

class _FakeConnections extends HubConnections {
  _FakeConnections(this.list);

  final List<HubConfig> list;

  @override
  Future<HubConnectionsState> build() async =>
      HubConnectionsState(connections: list, activeSlug: list.first.slug);
}

Future<void> tapTile(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('settings-token-scope')),
    200,
  );
  await tester.tap(find.byKey(const Key('settings-token-scope')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ölçmeden önce hiçbir sonuç iddia etmiyor', (tester) async {
    var calls = 0;
    await tester.pumpWidget(build(measure: (_) async {
      calls++;
      return 1;
    }));
    await tester.pumpAndSettle();

    expect(find.text('Token kapsamı'), findsOneWidget);
    expect(find.text("Token'ın kaç repo gördüğünü ölç"), findsOneWidget);
    expect(calls, 0, reason: 'ölçüm ekran açılınca kendiliğinden koşmamalı');
  });

  testWidgets('fazla erişim bulunursa sayılar doğru sırayla yazılıyor',
      (tester) async {
    // Sayıların **sırası** ayrıca sınanıyor: iki yer tutucu da `int` olduğu
    // için yer değiştirseler analiz de derleyici de sessiz kalır; yalnız
    // çıkan metin yakalar.
    await tester.pumpWidget(build(measure: (_) async => 9));
    await tester.pumpAndSettle();
    await tapTile(tester);

    expect(find.textContaining('9 repo görüyor'), findsOneWidget);
    expect(find.textContaining('ihtiyaç 1'), findsOneWidget);
  });

  testWidgets('fazla erişim yoksa "yok" diyor, sayıları gösteriyor',
      (tester) async {
    await tester.pumpWidget(build(measure: (_) async => 1));
    await tester.pumpAndSettle();
    await tapTile(tester);

    expect(find.textContaining('1 repo görüyor'), findsOneWidget);
    expect(find.textContaining('ihtiyaç 1'), findsOneWidget);
    expect(find.textContaining('Fazla erişim görünmüyor'), findsOneWidget);
  });

  testWidgets('ölçülemedi, "temiz" ile aynı kutuya girmiyor', (tester) async {
    await tester.pumpWidget(build(measure: (_) async => null));
    await tester.pumpAndSettle();
    await tapTile(tester);

    expect(find.textContaining('Ölçülemedi'), findsOneWidget);
    expect(find.textContaining('Fazla erişim görünmüyor'), findsNothing);
  });

  testWidgets('iki hub aynı token\'ı paylaşıyorsa ihtiyaç 2 (B-056)',
      (tester) async {
    // Yanlış alarmın önlendiği yer: iki hub'a aynı token verilmişse token'ın
    // 2 repo görmesi beklenen durumdur, uyarı çıkmamalı.
    const token = 'github_pat_paylasilan';
    await tester.pumpWidget(
      build(
        token: token,
        connections: const [
          HubConfig(owner: 'afgover', repo: 'takip', token: token),
          HubConfig(owner: 'afgover', repo: 'financer_takip', token: token),
        ],
        measure: (_) async => 2,
      ),
    );
    await tester.pumpAndSettle();
    await tapTile(tester);

    expect(find.textContaining('ihtiyaç 2'), findsOneWidget);
    expect(find.textContaining('Fazla erişim görünmüyor'), findsOneWidget);
  });

  testWidgets('klasik token için istek harcanmıyor, uyarı önekten çıkıyor',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      build(
        token: 'ghp_klasik',
        measure: (_) async {
          calls++;
          return 3;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tapTile(tester);

    expect(calls, 0);
    expect(find.textContaining('gereğinden geniş'), findsOneWidget);
  });

  testWidgets('uyarıdan sonra dokunmak ayrıntıyı açıyor', (tester) async {
    await tester.pumpWidget(build(measure: (_) async => 9));
    await tester.pumpAndSettle();
    await tapTile(tester);

    // İkinci dokunuş yeniden ölçmez, ne bulunduğunu anlatır.
    await tapTile(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Only select repositories'), findsOneWidget);
  });
}
