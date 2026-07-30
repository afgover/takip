import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/utils.dart';

void main() {
  group('slugify — SYSTEM.md dosya adı kuralı', () {
    test('Türkçe karakterleri sadeleştirir', () {
      expect(slugify('Şeker ığdır öğün ÇİÇEK'), 'seker-igdir-ogun-cicek');
    });

    test('noktalama ve fazla boşluk tek tireye iner', () {
      expect(slugify('Market listesi:  süt, ekmek!'), 'market-listesi-sut-ekmek');
    });

    test('baştaki ve sondaki tireler atılır', () {
      expect(slugify('  --Deneme--  '), 'deneme');
    });
  });

  test('taskFileName sözleşme biçimini üretir', () {
    final name = taskFileName(DateTime.utc(2026, 7, 30, 14, 5), 'Görev Adı');
    expect(name, '2026-07-30-gorev-adi.md');
  });

  test('isoNow saniye hassasiyetinde UTC verir', () {
    expect(isoNow(), matches(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'));
  });
}
