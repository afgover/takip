import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takip/core/errors.dart';
import 'package:takip/features/common/token_scope_warning_dialog.dart';
import 'package:takip/features/onboarding/onboarding_screen.dart';
import 'package:takip/hub/hub_access.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/token_scope.dart';

import '../helpers/test_app.dart';

/// Secure storage yerine bellek: widget testinde platform kanalı yok.
class FakeHubConfigNotifier extends HubConfigNotifier {
  final List<HubConfig> saved = [];

  @override
  Future<HubConfig?> build() async => null;

  @override
  Future<void> save(HubConfig config) async {
    saved.add(config);
    state = AsyncData(config);
  }
}

({Widget widget, FakeHubConfigNotifier config, List<HubConfig> verified})
    buildScreen({
  Future<HubAccess> Function(HubConfig)? verifier,
}) {
  final notifier = FakeHubConfigNotifier();
  final verified = <HubConfig>[];

  return (
    widget: ProviderScope(
      overrides: [
        hubConfigProvider.overrideWith(() => notifier),
        hubAccessVerifierProvider.overrideWithValue((candidate) async {
          verified.add(candidate);
          return verifier == null
              ? const HubAccess()
              : await verifier(candidate);
        }),
      ],
      child: testApp(const OnboardingScreen()),
    ),
    config: notifier,
    verified: verified,
  );
}

Future<void> enterToken(WidgetTester tester, String token) =>
    tester.enterText(find.byKey(OnboardingScreen.tokenFieldKey), token);

void main() {
  testWidgets('repo alanı varsayılanla gelir', (tester) async {
    await tester.pumpWidget(buildScreen().widget);

    final field = tester.widget<TextFormField>(
      find.byKey(OnboardingScreen.repoFieldKey),
    );
    expect(field.controller?.text, 'afgover/takip');
  });

  testWidgets('token boşken doğrulama isteği atılmaz', (tester) async {
    final built = buildScreen();
    await tester.pumpWidget(built.widget);

    await tester.tap(find.byKey(OnboardingScreen.submitButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Token gerekli'), findsOneWidget);
    expect(built.verified, isEmpty);
    expect(built.config.saved, isEmpty);
  });

  testWidgets('bozuk repo biçimi uyarı verir', (tester) async {
    final built = buildScreen();
    await tester.pumpWidget(built.widget);

    await tester.enterText(find.byKey(OnboardingScreen.repoFieldKey), 'takip');
    await enterToken(tester, 'ghp_x');
    await tester.tap(find.byKey(OnboardingScreen.submitButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('owner/ad biçiminde girin'), findsOneWidget);
    expect(built.verified, isEmpty);
  });

  testWidgets('doğrulama geçince token kaydedilir', (tester) async {
    final built = buildScreen();
    await tester.pumpWidget(built.widget);

    await tester.enterText(
      find.byKey(OnboardingScreen.repoFieldKey),
      'https://github.com/afgover/takip',
    );
    await enterToken(tester, '  ghp_gizli  ');
    await tester.tap(find.byKey(OnboardingScreen.submitButtonKey));
    await tester.pumpAndSettle();

    expect(built.verified, hasLength(1));
    expect(built.verified.single.owner, 'afgover');
    expect(built.verified.single.repo, 'takip');
    expect(built.verified.single.token, 'ghp_gizli',
        reason: 'kopyalanan token\'ın kenar boşlukları temizlenmeli');
    expect(built.config.saved.single.slug, 'afgover/takip');
    expect(find.byKey(OnboardingScreen.errorKey), findsNothing);
  });

  testWidgets('doğrulama başarısızsa token kaydedilmez ve sebep gösterilir',
      (tester) async {
    final built = buildScreen(
      verifier: (_) async => throw const HubAuthError(
        'Token geçersiz veya süresi dolmuş.',
      ),
    );
    await tester.pumpWidget(built.widget);

    await enterToken(tester, 'ghp_yanlis');
    await tester.tap(find.byKey(OnboardingScreen.submitButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(OnboardingScreen.errorKey), findsOneWidget);
    expect(find.textContaining('Token geçersiz'), findsOneWidget);
    expect(built.config.saved, isEmpty, reason: 'geçersiz token diske yazılmaz');
  });

  testWidgets('doğrulama sürerken buton kilitlenir, ikinci istek gitmez',
      (tester) async {
    final gate = Completer<HubAccess>();
    final built = buildScreen(verifier: (_) => gate.future);
    await tester.pumpWidget(built.widget);

    await enterToken(tester, 'ghp_x');
    await tester.tap(find.byKey(OnboardingScreen.submitButtonKey));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(OnboardingScreen.submitButtonKey));
    await tester.pump();
    expect(built.verified, hasLength(1));

    gate.complete(const HubAccess());
    await tester.pumpAndSettle();
    expect(built.config.saved, hasLength(1));
  });

  testWidgets('hata sonrası yeniden denenince eski hata temizlenir',
      (tester) async {
    var attempt = 0;
    final built = buildScreen(
      verifier: (_) async {
        attempt++;
        if (attempt == 1) throw const HubNetworkError('Ağ bağlantısı yok.');
        return const HubAccess();
      },
    );
    await tester.pumpWidget(built.widget);

    await enterToken(tester, 'ghp_x');
    await tester.tap(find.byKey(OnboardingScreen.submitButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(OnboardingScreen.errorKey), findsOneWidget);

    await tester.tap(find.byKey(OnboardingScreen.submitButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(OnboardingScreen.errorKey), findsNothing);
    expect(built.config.saved, hasLength(1));
  });

  group('geniş kapsamlı token uyarısı (B-092)', () {
    const wide = TokenScopeWarning(
      title: 'Bu token gereğinden geniş',
      body: 'repo scope\'u bütün repolara erişim verir.',
      scopes: ['repo'],
    );

    testWidgets('uyarı hata kutusu değil, onay kutusu', (tester) async {
      final built = buildScreen(
          verifier: (_) async => const HubAccess(scopeWarning: wide));
      await tester.pumpWidget(built.widget);

      await enterToken(tester, 'ghp_genis');
      await tester.tap(find.byKey(OnboardingScreen.submitButtonKey));
      await tester.pumpAndSettle();

      expect(find.byKey(tokenScopeDialogKey), findsOneWidget);
      expect(find.byKey(OnboardingScreen.errorKey), findsNothing);
      expect(built.config.saved, isEmpty, reason: 'karar verilmeden yazılmaz');
    });

    testWidgets('vazgeçilirse token kaydedilmez ve formda kalınır',
        (tester) async {
      final built = buildScreen(
          verifier: (_) async => const HubAccess(scopeWarning: wide));
      await tester.pumpWidget(built.widget);

      await enterToken(tester, 'ghp_genis');
      await tester.tap(find.byKey(OnboardingScreen.submitButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(tokenScopeCancelKey));
      await tester.pumpAndSettle();

      expect(built.config.saved, isEmpty);
      // Buton yeniden basılabilir olmalı: kullanıcı dar token yapıştıracak.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(OnboardingScreen.tokenFieldKey), findsOneWidget);
    });

    testWidgets('kullanıcı ısrar ederse bağlanır — uyarı engel değil',
        (tester) async {
      final built = buildScreen(
          verifier: (_) async => const HubAccess(scopeWarning: wide));
      await tester.pumpWidget(built.widget);

      await enterToken(tester, 'ghp_genis');
      await tester.tap(find.byKey(OnboardingScreen.submitButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(tokenScopeContinueKey));
      await tester.pumpAndSettle();

      expect(built.config.saved, hasLength(1));
      expect(built.config.saved.single.token, 'ghp_genis');
    });
  });

  testWidgets('token varsayılan olarak gizli, düğmeyle görünür olur',
      (tester) async {
    await tester.pumpWidget(buildScreen().widget);

    EditableText tokenField() => tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(OnboardingScreen.tokenFieldKey),
            matching: find.byType(EditableText),
          ),
        );

    expect(tokenField().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(tokenField().obscureText, isFalse);
  });
}
