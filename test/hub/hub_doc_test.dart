import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/models/hub_doc.dart';

void main() {
  group('HubDoc.fromDatedPath', () {
    test('oturum yolunda başlık klasörden okunur', () {
      final doc = HubDoc.fromDatedPath(
        'hub/sessions/2026-07-30-hub-tasima/session.md',
      );

      expect(doc.title, 'Hub tasima');
      expect(doc.date, DateTime(2026, 7, 30));
    });

    test('artifact yolunda başlık dosyadan okunur', () {
      final doc = HubDoc.fromDatedPath(
        'hub/artifacts/S-2026-07-30-x/2026-07-30-github-arastirmasi.md',
      );

      expect(doc.title, 'Github arastirmasi');
      expect(doc.date, DateTime(2026, 7, 30));
    });

    test('tarihsiz ad da okunabilir kalır', () {
      final doc = HubDoc.fromDatedPath(
        'hub/artifacts/reference/flutter-app-design.md',
      );

      expect(doc.title, 'Flutter app design');
      expect(doc.date, isNull);
    });

    test('aynı yol ve sha eşit sayılır (provider anahtarı)', () {
      final a = HubDoc.fromDatedPath('hub/x/2026-07-30-a.md', sha: 's1');
      final b = HubDoc.fromDatedPath('hub/x/2026-07-30-a.md', sha: 's1');
      final c = HubDoc.fromDatedPath('hub/x/2026-07-30-a.md', sha: 's2');

      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('KnowledgeEntry.parseFile', () {
    const sample = '''
# Kurallar (rules)

Giriş paragrafı — kayıt değildir.

---

## R-001 — App'in yazma alanı tek: tasks/inbox/
- **Tarih:** 2026-07-30
- **Kaynak:** Aşama 0 tasarım oturumu
- **Açıklama:** Uygulama yalnızca inbox'a yazar.

## ~~R-002 — Token yalnızca hub'a scope'lanır~~
- **Tarih:** 2026-07-30 (geçersiz: K-012)
- **Kaynak:** Aşama 0
- **Açıklama:** ~~Token asla kod repolarına erişemez.~~ Artık R-005 geçerli.
''';

    test('kayıtları ID, başlık ve alanlarıyla ayırır', () {
      final entries = KnowledgeEntry.parseFile(sample);

      expect(entries, hasLength(2));
      expect(entries.first.id, 'R-001');
      expect(entries.first.title, "App'in yazma alanı tek: tasks/inbox/");
      expect(entries.first.date, '2026-07-30');
      expect(entries.first.source, 'Aşama 0 tasarım oturumu');
      expect(entries.first.body, contains('yalnızca inbox'));
    });

    test('giriş paragrafı kayıt sayılmaz', () {
      expect(
        KnowledgeEntry.parseFile(sample).map((e) => e.id),
        ['R-001', 'R-002'],
      );
    });

    test('üstü çizili başlık geçersiz kayıt olarak işaretlenir (R-004)', () {
      final invalid = KnowledgeEntry.parseFile(sample).last;

      expect(invalid.isInvalidated, isTrue);
      expect(invalid.id, 'R-002', reason: 'ID tildelerden arındırılmalı');
      expect(invalid.title, contains('Token yalnızca'));
      expect(KnowledgeEntry.parseFile(sample).first.isInvalidated, isFalse);
    });
  });

  group('gerçek bilgi tabanı dosyaları', () {
    test('üç dosyanın kayıtları da ayrıştırılabiliyor', () {
      for (final name in ['rules', 'skills', 'lessons']) {
        final file = File('hub/knowledge/$name.md');
        final entries = KnowledgeEntry.parseFile(file.readAsStringSync());

        expect(entries, isNotEmpty, reason: name);
        for (final entry in entries) {
          expect(entry.id, matches(RegExp(r'^[A-Z]{1,2}-\d+$')),
              reason: '$name: "${entry.title}" kaydının ID biçimi bozuk');
          expect(entry.title, isNotEmpty, reason: name);
          expect(entry.date, isNotNull,
              reason: '$name: ${entry.id} tarihi okunamadı');
        }
      }
    });

    test('geçersiz kılınmış kural gerçekten işaretli geliyor', () {
      final entries = KnowledgeEntry.parseFile(
        File('hub/knowledge/rules.md').readAsStringSync(),
      );
      final r002 = entries.firstWhere((e) => e.id == 'R-002');

      expect(r002.isInvalidated, isTrue);
    });
  });
}
