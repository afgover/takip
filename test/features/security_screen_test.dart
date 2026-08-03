import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/browse/browse_screen.dart';
import 'package:takip/features/browse/security_screen.dart';
import 'package:takip/hub/browse_repo.dart';
import 'package:takip/hub/models/hub_doc.dart';

/// Güvenlik logunun ekranı. Kayıtlar `SYSTEM.md` §12 biçiminde.
///
/// Ayrıştırma testleri **gerçek `hub/SECURITY.md`** üzerinden koşuyor: elle
/// yazılmış bir örnek, dosyanın biçimi değişince sessizce eskir ve ekran
/// bozulurken test yeşil kalırdı.
void main() {
  final real = KnowledgeEntry.parseFile(
    File('hub/SECURITY.md').readAsStringSync(),
  );

  group('gerçek SECURITY.md', () {
    test('kayıtlara ayrılıyor ve hepsi bir tür taşıyor', () {
      expect(real, isNotEmpty);
      for (final entry in real) {
        expect(entry.id, startsWith('SEC-'), reason: entry.title);
        expect(securityKindOf(entry), isNotNull,
            reason: '${entry.id} — Tür alanı sözleşmedeki değerlerden olmalı');
      }
    });

    test('açık kayıtlar tanınıyor', () {
      expect(real.where(isSecurityOpen), isNotEmpty,
          reason: 'dosyada en az bir açık kayıt var');
    });

    test('sır sızmıyor — token benzeri değer yok', () {
      // §12: kayıt neyin korunduğunu anlatır, korunan şeyin kendisini değil.
      final text = File('hub/SECURITY.md').readAsStringSync();
      expect(text, isNot(matches(RegExp(r'gh[pousr]_[A-Za-z0-9]{20,}'))));
      expect(text, isNot(matches(RegExp(r'github_pat_[A-Za-z0-9_]{20,}'))));
    });
  });

  group('alan okuma', () {
    KnowledgeEntry entryOf(String body) =>
        KnowledgeEntry.parseFile('## SEC-009 — başlık\n$body').single;

    test('tür ve durum okunuyor', () {
      final entry = entryOf('- **Tür:** acik\n- **Durum:** acik\n');
      expect(securityKindOf(entry), SecurityKind.acik);
      expect(isSecurityOpen(entry), isTrue);
    });

    test('durum alanı yoksa açık sayılmaz', () {
      // Alanı olmayan eski kayıtlar ekranı yanlış yere uyarıyla doldurmasın.
      expect(isSecurityOpen(entryOf('- **Tür:** onlem\n')), isFalse);
    });

    test('geçersizleşen kayıt açık sayılmaz (R-004)', () {
      final entry = KnowledgeEntry.parseFile(
        '## ~~SEC-010 — geçersiz~~\n- **Tür:** acik\n- **Durum:** acik\n',
      ).single;
      expect(entry.isInvalidated, isTrue);
      expect(isSecurityOpen(entry), isFalse);
    });

    test('tanınmayan tür null döner, ekran çökmez', () {
      expect(securityKindOf(entryOf('- **Tür:** bilinmeyen\n')), isNull);
    });
  });

  Widget wrap(List<KnowledgeEntry> entries) => ProviderScope(
        overrides: [
          securityProvider.overrideWith((ref) async => entries),
        ],
        child: const MaterialApp(home: SecurityScreen()),
      );

  testWidgets('açık kayıtlar listenin başına alınır', (tester) async {
    final entries = KnowledgeEntry.parseFile('''
## SEC-001 — kapali olan
- **Tür:** onlem
- **Durum:** kapali

## SEC-002 — acik olan
- **Tür:** acik
- **Durum:** acik
''');

    await tester.pumpWidget(wrap(entries));
    await tester.pumpAndSettle();

    // Kapanmamış iş görünür olmalı; kronolojik sıra onu aşağı gömerdi.
    final titles = tester
        .widgetList<ExpansionTile>(find.byType(ExpansionTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, ['acik olan', 'kapali olan']);
    expect(find.text('1 açık kayıt'), findsOneWidget);
  });

  testWidgets('türe göre filtreleniyor', (tester) async {
    await tester.pumpWidget(wrap(real));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('security-filter-yapilacak')));
    await tester.pumpAndSettle();

    final shown = tester.widgetList<ExpansionTile>(find.byType(ExpansionTile));
    expect(shown, isNotEmpty);
    for (final tile in shown) {
      final title = (tile.title as Text).data;
      final entry = real.firstWhere((e) => e.title == title);
      expect(securityKindOf(entry), SecurityKind.yapilacak);
    }
  });

  testWidgets('tarayıcıda Security var, Bekleyen görevler yok',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: BrowseScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Security'), findsOneWidget);
    // Alt menüde kendi sekmesi var; aynı ekrana iki kapı olmamalı.
    expect(find.text('Bekleyen görevler'), findsNothing);
  });
}
