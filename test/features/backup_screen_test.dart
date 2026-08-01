import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/settings/backup_screen.dart';
import 'package:takip/hub/hub_connections.dart';

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
      child: MaterialApp(home: home),
    );

/// Yedekleme ekranı uzun bir liste; varsayılan test ekranında alt alanlar hiç
/// oluşturulmuyor ve `enterText` "widget yok" diye patlıyor. Ekranı yükseltmek,
/// her etkileşimden önce kaydırmaktan hem kısa hem okunur.
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
    // Panoya yazma platform kanalına iner; testte yutuyoruz.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  group('yedekleme ekranı', () {
    testWidgets('dışa aktarılan metin token içermez', (tester) async {
      useTallScreen(tester);
      final container = await seed([row('a/bir', 'gizli-token-123')]);
      await tester.pumpWidget(wrap(container, const BackupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(BackupScreen.exportPassKey), 'parolam123');
      await tester.tap(find.byKey(BackupScreen.exportButtonKey));
      await tester.pumpAndSettle();

      expect(find.byKey(BackupScreen.exportResultKey), findsOneWidget);
      final shown = tester
          .widget<SelectableText>(
            find.descendant(
              of: find.byKey(BackupScreen.exportResultKey),
              matching: find.byType(SelectableText),
            ),
          )
          .data!;
      expect(shown, isNot(contains('gizli-token-123')));
      expect(shown, startsWith('takip-backup-v1.'));
    });

    testWidgets('kısa parola reddedilir', (tester) async {
      useTallScreen(tester);
      final container = await seed([row('a/bir', 't')]);
      await tester.pumpWidget(wrap(container, const BackupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(BackupScreen.exportPassKey), '123');
      await tester.tap(find.byKey(BackupScreen.exportButtonKey));
      await tester.pumpAndSettle();

      expect(find.byKey(BackupScreen.exportResultKey), findsNothing);
      expect(find.textContaining('en az 6'), findsOneWidget);
    });

    testWidgets('yedek yanlış parolayla geri yüklenmez', (tester) async {
      useTallScreen(tester);
      final container = await seed([row('a/bir', 'tok')]);
      await tester.pumpWidget(wrap(container, const BackupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(BackupScreen.exportPassKey), 'dogruparola');
      await tester.tap(find.byKey(BackupScreen.exportButtonKey));
      await tester.pumpAndSettle();
      final backup = tester
          .widget<SelectableText>(
            find.descendant(
              of: find.byKey(BackupScreen.exportResultKey),
              matching: find.byType(SelectableText),
            ),
          )
          .data!;

      await tester.enterText(find.byKey(BackupScreen.importTextKey), backup);
      await tester.enterText(
          find.byKey(BackupScreen.importPassKey), 'yanlisparola');
      await tester.tap(find.byKey(BackupScreen.importButtonKey));
      await tester.pumpAndSettle();

      expect(find.textContaining('Parola yanlış'), findsOneWidget);
    });

    testWidgets('yedek geri yüklenince bağlantılar listeye eklenir',
        (tester) async {
      useTallScreen(tester);
      // Önce iki repolu bir kaptan yedek al.
      final source = await seed([
        row('a/bir', 'tok-1', label: 'Bir'),
        row('b/iki', 'tok-2'),
      ]);
      await tester.pumpWidget(wrap(source, const BackupScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(BackupScreen.exportPassKey), 'parolam123');
      await tester.tap(find.byKey(BackupScreen.exportButtonKey));
      await tester.pumpAndSettle();
      final backup = tester
          .widget<SelectableText>(
            find.descendant(
              of: find.byKey(BackupScreen.exportResultKey),
              matching: find.byType(SelectableText),
            ),
          )
          .data!;

      // Sonra boş bir cihaz taklidine geri yükle.
      final target = await seed(const []);
      await tester.pumpWidget(wrap(target, const BackupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(BackupScreen.importTextKey), backup);
      await tester.enterText(
          find.byKey(BackupScreen.importPassKey), 'parolam123');
      await tester.tap(find.byKey(BackupScreen.importButtonKey));
      await tester.pumpAndSettle();

      final restored = target.read(hubConnectionsProvider).value!;
      expect(restored.connections.map((c) => c.slug), ['a/bir', 'b/iki']);
      expect(restored.bySlug('a/bir')?.token, 'tok-1');
      expect(restored.bySlug('a/bir')?.label, 'Bir');
    });
  });
}
