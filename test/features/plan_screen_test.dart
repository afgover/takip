import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/browse/browse_screen.dart';
import 'package:takip/features/browse/plan_screen.dart';
import 'package:takip/hub/plan.dart';

import '../helpers/test_app.dart';

/// Görev ağacı ekranı (sözleşme 1.25 §14).
///
/// Ayrıştırma **gerçek `hub/PLAN.md`** üzerinden de sınanıyor —
/// `security_screen_test` ile aynı gerekçe: elle yazılmış bir örnek, dosyanın
/// biçimi değişince sessizce eskir ve ekran bozulurken test yeşil kalır.
void main() {
  final real = parsePlans(File('hub/PLAN.md').readAsStringSync());

  group('gerçek PLAN.md', () {
    test('planlara ayrılıyor ve zorunlu alanları taşıyor', () {
      expect(real, isNotEmpty);
      for (final plan in real) {
        expect(plan.id, startsWith('P-'), reason: plan.title);
        expect(plan.field('Tarih'), isNotNull, reason: '${plan.id} — Tarih');
        expect(plan.field('Kaynak'), isNotNull, reason: '${plan.id} — Kaynak');
        expect(plan.field('Durum'), isNotNull, reason: '${plan.id} — Durum');
        expect(plan.steps, isNotEmpty, reason: '${plan.id} — adımsız plan');
      }
    });

    test('her adım plan numarasının altında numaralı', () {
      for (final plan in real) {
        for (final step in plan.steps) {
          expect(step.id, startsWith('${plan.id}.'),
              reason: '${plan.id}: "${step.title}"');
        }
      }
    });

    test('iptal edilen her adım gerekçe taşır (§14/2)', () {
      for (final plan in real) {
        for (final step in plan.steps) {
          if (step.state != PlanStepState.cancelled) continue;
          expect(step.note, isNotNull, reason: '${step.id} — nedensiz iptal');
        }
      }
    });
  });

  Widget wrap(List<Plan> plans) => ProviderScope(
        overrides: [planProvider.overrideWith((ref) async => plans)],
        child: testApp(const PlanScreen()),
      );

  const twoPlans = '''
## P-002 — Biten plan
- **Tarih:** 2026-08-12
- **Kaynak:** S-x
- **Durum:** tamamlandi

- [x] P-002.1 — Biten adım · ✅ 2026-08-12

## P-001 — Açık plan
- **Tarih:** 2026-08-13
- **Kaynak:** S-y
- **Durum:** acik

- [x] P-001.1 — Biten adım
- [ ] P-001.2 — Kalan adım
- [ ] ~~P-001.3 — Vazgeçilen~~ · ⨯ **İptal:** gerek kalmadı
''';

  testWidgets('varsayılan filtre açık planları gösterir', (tester) async {
    await tester.pumpWidget(wrap(parsePlans(twoPlans)));
    await tester.pumpAndSettle();

    // Ağacın işi yarım kalanı görünür kılmak; biten planlar varsayılan
    // görünümde öne çıkmamalı.
    expect(find.text('Açık plan'), findsOneWidget);
    expect(find.text('Biten plan'), findsNothing);
  });

  testWidgets('filtre kaldırılınca tümü gelir, açık olan üstte',
      (tester) async {
    await tester.pumpWidget(wrap(parsePlans(twoPlans)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('plan-filter-all')));
    await tester.pumpAndSettle();

    final titles = tester
        .widgetList<ExpansionTile>(find.byType(ExpansionTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, ['Açık plan', 'Biten plan']);
  });

  testWidgets('açık plan kendiliğinden açık, adımları görünür',
      (tester) async {
    await tester.pumpWidget(wrap(parsePlans(twoPlans)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kalan adım'), findsOneWidget);
    expect(find.textContaining('Vazgeçilen'), findsOneWidget);
  });

  testWidgets('ilerleme sayısı iptali paydaya katmaz', (tester) async {
    await tester.pumpWidget(wrap(parsePlans(twoPlans)));
    await tester.pumpAndSettle();

    // Üç adımın biri iptal: 1/2.
    expect(find.text('1/2 adım'), findsOneWidget);
  });

  testWidgets('türetilmiş plan ayrı etiketle işaretleniyor (1.26)',
      (tester) async {
    // Önceden yazılmış plan bir karardır, türetilmiş olan bir kayıt; ikisini
    // aynı göstermek hub'ın geçmişini olduğundan planlı gösterirdi.
    const derived = '''
## P-010 — Türetilmiş plan
- **Durum:** tamamlandi
- **Türetilmiş:** true

- [x] P-010.1 — adım · ✅ 2026-08-15
''';

    await tester.pumpWidget(wrap(parsePlans(derived)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plan-filter-all')));
    await tester.pumpAndSettle();

    expect(find.text('türetilmiş'), findsOneWidget);
  });
  testWidgets('önceden yazılmış planda etiket çıkmıyor', (tester) async {
    await tester.pumpWidget(wrap(parsePlans(twoPlans)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plan-filter-all')));
    await tester.pumpAndSettle();

    expect(find.text('türetilmiş'), findsNothing);
  });
  testWidgets('PLAN.md yoksa boş durum — hata değil (§14/6)', (tester) async {
    await tester.pumpWidget(wrap(const []));
    await tester.pumpAndSettle();

    expect(find.text('Görev ağacı boş'), findsOneWidget);
  });

  testWidgets('tarayıcıda görev ağacı kartı var', (tester) async {
    await tester.pumpWidget(ProviderScope(child: testApp(const BrowseScreen())));
    await tester.pumpAndSettle();

    // Kart ızgarada aşağıda kalıyor; test penceresinde görünür hâle getirmek
    // için kaydırılıyor.
    await tester.scrollUntilVisible(find.text('Görev ağacı'), 200);
    expect(find.text('Görev ağacı'), findsOneWidget);
    expect(find.text('PLAN.md'), findsOneWidget);
  });
}
