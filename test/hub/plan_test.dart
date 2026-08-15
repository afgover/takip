import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/plan.dart';

/// Görev ağacı ayrıştırıcısı (sözleşme 1.25 §14).
void main() {
  const source = '''
# PLAN.md — Görev Ağacı

Serbest açıklama metni; ilk plana kadar olan kısım atlanır.

## P-002 — İkinci plan
- **Tarih:** 2026-08-13
- **Kaynak:** S-2026-08-13-durum-ozeti
- **Durum:** tamamlandi

- [x] P-002.1 — Tek adım · ✅ 2026-08-13

## P-001 — Birinci plan
- **Tarih:** 2026-08-12
- **Kaynak:** S-2026-08-12-x
- **Durum:** acik
- **İlgili:** B-097, SEC-010

- [x] P-001.1 — Biten adım · ✅ 2026-08-12
- [ ] P-001.2 — Açık adım
  - [x] P-001.2.1 — Biten alt adım · ✅ 2026-08-12
  - [ ] P-001.2.2 — Açık alt adım
- [ ] ~~P-001.3 — Vazgeçilen adım~~ · ⨯ **İptal (2026-08-13):** gereksizdi
''';

  group('parsePlans', () {
    test('planları dosyadaki sırayla ayırır', () {
      final plans = parsePlans(source);
      expect(plans.map((p) => p.id), ['P-002', 'P-001']);
      expect(plans.first.title, 'İkinci plan');
    });

    test('alan satırlarını okur', () {
      final plan = parsePlans(source).last;
      expect(plan.field('Tarih'), '2026-08-12');
      expect(plan.field('Kaynak'), 'S-2026-08-12-x');
      expect(plan.field('İlgili'), 'B-097, SEC-010');
    });

    test('durumu iki dilde de tanır', () {
      expect(parsePlans(source).last.status, PlanStatus.acik);
      expect(parsePlans(source).first.status, PlanStatus.tamamlandi);
      expect(
        parsePlans('## P-003 — x\n- **Status:** completed\n').single.status,
        PlanStatus.tamamlandi,
      );
    });

    test('alanı olmayan plan açık sayılır', () {
      // Eksik alan yüzünden bir planı sessizce arşive itmek, ağacın tek işine
      // (yarım kalanı göstermek) aykırı.
      expect(parsePlans('## P-004 — alansız\n').single.status, PlanStatus.acik);
    });

    test('adım durumlarını ayırır', () {
      final steps = parsePlans(source).last.steps;
      expect(steps.map((s) => s.id), [
        'P-001.1',
        'P-001.2',
        'P-001.2.1',
        'P-001.2.2',
        'P-001.3',
      ]);
      expect(steps[0].state, PlanStepState.done);
      expect(steps[1].state, PlanStepState.open);
      expect(steps[4].state, PlanStepState.cancelled);
    });

    test('girinti ağaç derinliğine çevrilir', () {
      final steps = parsePlans(source).last.steps;
      expect(steps[1].depth, 0);
      expect(steps[2].depth, 1);
      expect(steps[3].depth, 1);
    });

    test('iptal edilen adımın başlığı çizgiden arınır, nedeni kalır', () {
      final step = parsePlans(source).last.steps[4];
      expect(step.title, 'Vazgeçilen adım');
      expect(step.note, contains('gereksizdi'));
    });

    test('· ayracından sonrası nota gider', () {
      final step = parsePlans(source).last.steps.first;
      expect(step.title, 'Biten adım');
      expect(step.note, '✅ 2026-08-12');
    });

    test('iptal sayısı ilerleme paydasına girmez', () {
      // 5 adımın biri iptal: "2/4" doğru, "2/5" ilerlemeyi olduğundan az
      // gösterirdi.
      final plan = parsePlans(source).last;
      expect(plan.doneCount, 2);
      expect(plan.plannedCount, 4);
    });

    test('sarılmış adım satırı öncekine eklenir, ayrı adım sayılmaz', () {
      final plan = parsePlans('''
## P-005 — sarma
- [ ] P-005.1 — çok uzun bir adım başlığı
      ikinci satıra sarmış
- [ ] P-005.2 — ikinci adım
''').single;
      expect(plan.steps.length, 2);
      expect(plan.steps.first.title, contains('ikinci satıra sarmış'));
    });

    test('ayraç satır sonundaysa not alt satırdan toplanır (B-133)', () {
      // Hatanın kendisi: `·` satır sonunda kalınca tarih başlığın içine
      // gömülüyordu — ekran çiziliyor, test geçiyor, yalnız tarih yanlış yerde.
      final step = parsePlans('''
## P-001 — x
- [x] P-001.1 — Düzeltme yapıldı ·
      ✅ 2026-08-13; iki test iyileşti
''').single.steps.single;

      expect(step.title, 'Düzeltme yapıldı');
      expect(step.note, '✅ 2026-08-13; iki test iyileşti');
    });

    test('ayraç ilk kez devam satırında geçiyorsa yakalanır (B-133)', () {
      final step = parsePlans('''
## P-001 — x
- [x] P-001.1 — Uzun bir adım başlığı burada
      bölünüyor · ✅ 2026-08-13
''').single.steps.single;

      expect(step.title, 'Uzun bir adım başlığı burada bölünüyor');
      expect(step.note, '✅ 2026-08-13');
    });

    test('not birden çok satıra yayılabilir', () {
      final step = parsePlans('''
## P-001 — x
- [x] P-001.1 — Adım · ✅ 2026-08-13;
      ilk devam
      ikinci devam
''').single.steps.single;

      expect(step.title, 'Adım');
      expect(step.note, '✅ 2026-08-13; ilk devam ikinci devam');
    });

    test('ayraçsız sarkan satır hâlâ başlığa gider', () {
      final step = parsePlans('''
## P-001 — x
- [ ] P-001.1 — Başlığın ilk parçası
      ikinci parçası
''').single.steps.single;

      expect(step.title, 'Başlığın ilk parçası ikinci parçası');
      expect(step.note, isNull);
    });

    test('gerçek PLAN.md: tarihli hiçbir adımda tarih başlıkta kalmıyor', () {
      // Ölçüt kaba ama tam olarak bu hatayı kuruyor: ✅ işareti nota aittir,
      // başlıkta görünüyorsa devam satırı yanlış yere eklenmiştir.
      final plans = parsePlans(File('hub/PLAN.md').readAsStringSync());
      for (final plan in plans) {
        for (final step in plan.steps) {
          expect(
            step.title,
            isNot(contains('✅')),
            reason: '${step.id} — tamamlanma işareti başlığa sızmış',
          );
        }
      }
    });

    test('Türetilmiş alanı okunur, iki dilde de (sözleşme 1.26)', () {
      for (final line in [
        '- **Türetilmiş:** true',
        '- **Turetilmis:** true',
        '- **Derived:** true',
        '- **Türetilmiş:** evet',
      ]) {
        final plan = parsePlans('## P-001 — x\n$line\n').single;
        expect(plan.reconstructed, isTrue, reason: line);
      }
    });

    test('alanı olmayan plan türetilmiş sayılmaz (R-008)', () {
      // 1.26 öncesi yazılmış planların hepsi önceden yazılmıştı; yeni alanın
      // yokluğu "bilinmiyor" değil, "hayır" demek.
      final plan = parsePlans('## P-001 — x\n- **Durum:** tamamlandi\n').single;
      expect(plan.reconstructed, isFalse);
    });

    test('Türetilmiş: false türetilmiş saymaz', () {
      final plan = parsePlans('## P-001 — x\n- **Türetilmiş:** false\n').single;
      expect(plan.reconstructed, isFalse);
    });

    test('gerçek PLAN.md: türetilmiş planlar kapalı doğmuş', () {
      // Sözleşme §14: geriye dönük plan `Durum: tamamlandi` (ya da `iptal`)
      // ile yazılır — açık bir plan geriye dönük olamaz.
      final plans = parsePlans(File('hub/PLAN.md').readAsStringSync());
      final derived = plans.where((p) => p.reconstructed).toList();

      expect(derived, isNotEmpty, reason: 'ağaçta türetilmiş plan bulunmalı');
      for (final plan in derived) {
        expect(
          plan.status,
          isNot(PlanStatus.acik),
          reason: '${plan.id} türetilmiş ama açık görünüyor',
        );
        expect(
          plan.field('kaynak') ?? plan.field('source'),
          isNotNull,
          reason: '${plan.id} türetilmiş ama Kaynak alanı yok',
        );
      }
    });

    test('boş dosya boş liste verir', () {
      expect(parsePlans(''), isEmpty);
    });
  });
}
