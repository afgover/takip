import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/settings/connection_screen.dart';
import 'package:takip/hub/hub_access.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/hub_watcher.dart';

import 'settings_screen_test.dart' show FakeHubConfigNotifier, QuietWatcher;

/// Kimliğin **görünür ve düzenlenebilir** olması (sözleşme 1.15).
///
/// İlk uygulamada kimlik yalnız `/user`'dan okunuyordu ve hiçbir ekranda
/// görünmüyordu. Kullanıcının ilk tepkisi bunu ortaya çıkardı: "author yok,
/// nickname'i bir yerde tanımlamadık". Görünmeyen bir kimlik doğrulanamaz ve
/// otomatik okuma başarısız olduğunda kullanıcının elinde çare kalmaz.
({Widget widget, FakeHubConfigNotifier config}) build({
  HubConfig? initial,
  HubAccess access = const HubAccess(),
}) {
  final notifier = FakeHubConfigNotifier(
    initial ??
        const HubConfig(owner: 'afgover', repo: 'takip', token: 'eski-token'),
  );

  return (
    widget: ProviderScope(
      overrides: [
        hubConfigProvider.overrideWith(() => notifier),
        hubWatcherProvider.overrideWith(QuietWatcher.new),
        hubAccessVerifierProvider.overrideWithValue((_) async => access),
      ],
      child: const MaterialApp(home: ConnectionScreen()),
    ),
    config: notifier,
  );
}

Finder get loginField => find.byKey(ConnectionScreen.loginFieldKey);

void main() {
  testWidgets('kayıtlı kimlik alanda görünür', (tester) async {
    await tester.pumpWidget(build(
      initial: const HubConfig(
        owner: 'afgover',
        repo: 'takip',
        token: 't',
        login: 'afgover',
      ),
    ).widget);
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(loginField).controller?.text,
      'afgover',
    );
  });

  testWidgets('elle yazılan kimlik kaydedilir', (tester) async {
    // `/user` hiçbir şey döndürmese bile kullanıcı kimliğini tanımlayabilmeli.
    final built = build();
    await tester.pumpWidget(built.widget);
    await tester.pumpAndSettle();

    await tester.enterText(loginField, 'mehmet');
    await tester.tap(find.byKey(ConnectionScreen.submitKey));
    await tester.pumpAndSettle();

    expect(built.config.saved.single.login, 'mehmet');
  });

  testWidgets('alan boşsa token\'dan okunan kimlik kullanılır',
      (tester) async {
    final built = build(access: const HubAccess(login: 'afgover'));
    await tester.pumpWidget(built.widget);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ConnectionScreen.submitKey));
    await tester.pumpAndSettle();

    expect(built.config.saved.single.login, 'afgover');
  });

  testWidgets('elle yazılan kimlik otomatiğe üstün gelir', (tester) async {
    // Kullanıcı bilerek başka bir ad yazdıysa, token'dan okunan onu ezmemeli.
    final built = build(access: const HubAccess(login: 'afgover'));
    await tester.pumpWidget(built.widget);
    await tester.pumpAndSettle();

    await tester.enterText(loginField, 'baska-ad');
    await tester.tap(find.byKey(ConnectionScreen.submitKey));
    await tester.pumpAndSettle();

    expect(built.config.saved.single.login, 'baska-ad');
  });

  testWidgets('kimlik hiç bilinmiyorsa alan boş kalır, kayıt yine olur',
      (tester) async {
    // Kimlik isteğe bağlı: bilinmemesi bağlantıyı engellemez.
    final built = build();
    await tester.pumpWidget(built.widget);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ConnectionScreen.submitKey));
    await tester.pumpAndSettle();

    expect(built.config.saved, hasLength(1));
    expect(built.config.saved.single.login, isNull);
  });
}
