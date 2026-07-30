import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/frontmatter.dart';

void main() {
  group('parse', () {
    test('alanları ve gövdeyi ayırır', () {
      final fm = Frontmatter.parse('''
---
id: T-001
title: "Market listesi"
tags: [ev, acil]
---

# Market listesi

## İstek
Süt al.
''');

      expect(fm.fields['id'], 'T-001');
      expect(fm.str('title'), 'Market listesi');
      expect(fm.list('tags'), ['ev', 'acil']);
      expect(fm.body, startsWith('# Market listesi'));
      expect(fm.hasFrontmatter, isTrue);
      expect(fm.isMalformed, isFalse);
    });

    test('CRLF satır sonlarını kaldırır', () {
      final fm = Frontmatter.parse('---\r\nid: T-002\r\n---\r\n\r\n# Başlık\r\n');

      expect(fm.str('id'), 'T-002');
      expect(fm.body, '# Başlık\n');
    });

    test('BOM ile başlayan dosyayı okur', () {
      final fm = Frontmatter.parse('﻿---\nid: T-003\n---\n\ngövde');

      expect(fm.str('id'), 'T-003');
      expect(fm.body, 'gövde');
    });

    test('frontmatter yoksa her şey gövdedir', () {
      final fm = Frontmatter.parse('# Sadece markdown\n\nmetin');

      expect(fm.fields, isEmpty);
      expect(fm.hasFrontmatter, isFalse);
      expect(fm.body, '# Sadece markdown\n\nmetin');
    });

    test('kapanmayan blok gövde sayılır, veri kaybolmaz', () {
      const raw = '---\nid: T-004\nkapanmadı';
      final fm = Frontmatter.parse(raw);

      expect(fm.fields, isEmpty);
      expect(fm.body, raw);
    });

    test('bozuk YAML çökmez; ham içerik korunur', () {
      const raw = '---\ntitle: Market: listesi\n---\n\ngövde';
      final fm = Frontmatter.parse(raw);

      expect(fm.isMalformed, isTrue);
      expect(fm.fields, isEmpty);
      expect(fm.body, raw, reason: 'içerik gizlenmemeli');
    });

    test('boş frontmatter bloğu', () {
      final fm = Frontmatter.parse('---\n---\n\ngövde');

      expect(fm.fields, isEmpty);
      expect(fm.body, 'gövde');
    });

    test('gövdedeki yatay çizgi frontmatter sanılmaz', () {
      final fm = Frontmatter.parse('---\nid: T-005\n---\n\nüst\n\n---\n\nalt');

      expect(fm.str('id'), 'T-005');
      expect(fm.body, 'üst\n\n---\n\nalt');
    });
  });

  group('tipli erişim', () {
    final fm = Frontmatter.parse('''
---
id: T-006
title: "Deneme"
created: 2026-07-30T14:05:00Z
tags: []
tek_etiket: acil
session: none
bos:
sayi: 42
---
''');

    test('str boş alanı null verir', () {
      expect(fm.str('bos'), isNull);
      expect(fm.str('yok'), isNull);
      expect(fm.strOr('yok', 'none'), 'none');
      expect(fm.str('sayi'), '42', reason: 'sayı da metne çevrilir');
    });

    test('list boş/tek/çok değeri normalize eder', () {
      expect(fm.list('tags'), isEmpty);
      expect(fm.list('yok'), isEmpty);
      expect(fm.list('tek_etiket'), ['acil']);
    });

    test('dateTime ISO 8601 okur, bozukta null verir', () {
      expect(fm.dateTime('created'), DateTime.utc(2026, 7, 30, 14, 5));
      expect(fm.dateTime('title'), isNull);
      expect(fm.dateTime('yok'), isNull);
    });
  });

  group('serialize — çıktı her durumda geçerli YAML', () {
    /// Yazılan metnin gerçekten okunabildiğini tek yerden doğrular.
    Frontmatter roundTrip(Map<String, dynamic> fields, {String body = 'gövde'}) =>
        Frontmatter.parse(Frontmatter.of(fields, body: body).serialize());

    test('iki nokta içeren başlık tırnaklanır', () {
      final out = roundTrip({'title': 'Market: süt, ekmek'});
      expect(out.str('title'), 'Market: süt, ekmek');
    });

    test('tırnak ve satır sonu kaçışlanır', () {
      final out = roundTrip({'title': 'O "şey"\nikinci satır'});
      expect(out.str('title'), 'O "şey"\nikinci satır');
    });

    test('bool/sayı gibi görünen metin, metin olarak geri gelir', () {
      final out = roundTrip({'a': 'true', 'b': 'no', 'c': '42', 'd': 'null'});

      expect(out.fields['a'], 'true');
      expect(out.fields['b'], 'no');
      expect(out.fields['c'], '42');
      expect(out.fields['d'], 'null');
    });

    test('Türkçe başlık tırnaksız ve okunur kalır', () {
      final text =
          Frontmatter.of({'title': 'Şeker ığdır öğün'}).serialize();

      expect(text, contains('title: Şeker ığdır öğün'));
      expect(Frontmatter.parse(text).str('title'), 'Şeker ığdır öğün');
    });

    test('liste ve boş liste', () {
      final out = roundTrip({
        'tags': ['ev', 'acil: çok'],
        'bos': <String>[],
      });

      expect(out.list('tags'), ['ev', 'acil: çok']);
      expect(out.list('bos'), isEmpty);
    });

    test('alan sırası korunur (sözleşmedeki sıra)', () {
      final text = Frontmatter.of({
        'id': 'pending',
        'title': 'x',
        'created_by': 'user',
      }).serialize();

      expect(
        text.split('\n').take(4).toList(),
        ['---', 'id: pending', 'title: x', 'created_by: user'],
      );
    });

    test('parse → serialize → parse aynı sonucu verir', () {
      const original = '''
---
id: T-007
title: "Görev: bir deneme"
created_by: user
tags: [a, b]
result: none
---

# Görev

Gövde metni.
''';
      final first = Frontmatter.parse(original);
      final second = Frontmatter.parse(first.serialize());

      expect(second.fields, first.fields);
      expect(second.body, first.body);
      // Gövde de tekrar tekrar boş satır biriktirmemeli.
      expect(first.serialize(), Frontmatter.parse(first.serialize()).serialize());
    });
  });
}
