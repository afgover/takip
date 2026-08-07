import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/annotations.dart';
import 'package:takip/hub/hub_language.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/models/task_draft.dart';

/// Hub dili (sözleşme 1.19).
///
/// Dil cihazın tercihi değil **hub'ın özelliği**: kurulurken seçilir, sözleşme
/// ve arayüz onu izler, o andan sonra üretilen kayıtlar da o dilde yazılır.
void main() {
  group('dil okuma', () {
    test('SYSTEM.md\'deki alandan okunur', () {
      expect(languageCodeIn('**Hub dili:** en\n'), 'en');
      expect(HubLanguage.parse(languageCodeIn('**Hub dili:** en')),
          HubLanguage.en);
    });

    test('alan yoksa tr varsayılır', () {
      // Alan eklenmeden önceki bütün hub'ların gerçek durumu bu. Bilinmeyeni
      // İngilizce saymak, mevcut Türkçe hub'ları bir anda yanlış dile geçirirdi.
      expect(languageCodeIn('**Sözleşme sürümü:** 1.19'), isNull);
      expect(HubLanguage.parse(null), HubLanguage.tr);
      expect(HubLanguage.parse('de'), HubLanguage.tr);
    });

    test('bu reponun kendi sözleşmesi dilini ilan ediyor', () {
      // Ana kopya kendi kuralına uymalı: 1.19 alanı zorunlu kıldı.
      final system = File('hub/SYSTEM.md').readAsStringSync();
      expect(languageCodeIn(system), 'tr');
    });
  });

  group('kayıt dili', () {
    test('gövde başlıkları hub diline göre yazılır', () {
      final tr = TaskDraft.create(title: 'iş', description: 'yap');
      final en = TaskDraft.create(
        title: 'work',
        description: 'do it',
        lang: HubLanguage.en,
      );

      expect(tr.content, contains('## İstek'));
      expect(tr.content, contains('## Notlar'));
      expect(en.content, contains('## Request'));
      expect(en.content, contains('## Notes'));
      expect(en.content, isNot(contains('## İstek')));
    });

    test('seçimden üretilen kayıtta dört başlık da çevrilir', () {
      final en = TaskDraft.fromSelection(
        quote: 'quoted text',
        sourcePath: 'hub/BACKLOG.md',
        kind: 'gorev',
        mark: TaskMark.highlight,
        note: 'do this',
        lang: HubLanguage.en,
      );

      for (final heading in ['## Request', '## Where', '## Quote', '## Notes']) {
        expect(en.content, contains(heading));
      }
    });

    test('notta da dil izlenir', () {
      final en = TaskDraft.note(
        quote: 'quoted',
        sourcePath: 'hub/BACKLOG.md',
        note: 'remember',
        lang: HubLanguage.en,
      );
      expect(en.content, contains('## Where'));
      expect(en.content, contains('## Quote'));
    });

    test('frontmatter alan adları dilden bağımsız İngilizce kalır', () {
      // Sözleşme kuralı: anahtarlar her zaman İngilizce, çeviriden etkilenmez.
      final tr = TaskDraft.create(title: 'iş');
      for (final key in ['id:', 'title:', 'created_by:', 'priority:']) {
        expect(tr.content, contains(key));
      }
    });
  });

  group('ayrıştırıcı bütün dilleri tanır', () {
    // Hub'ın ilan ettiği dille sınırlamak yanlış olurdu: dil alanı eklenmeden
    // önce yazılmış kayıtlar, elle düzenlenmiş dosyalar ve dili sonradan
    // değiştirilmiş hub'lar var.
    test('Türkçe başlıklı gövdeden not okunur', () {
      expect(noteTextFrom('# x\n\n## İstek\nşunu yap\n\n## Notlar\n'),
          'şunu yap');
    });

    test('İngilizce başlıklı gövdeden de okunur', () {
      expect(noteTextFrom('# x\n\n## Request\ndo this\n\n## Notes\n'),
          'do this');
    });

    test('dili değişmiş hub\'da eski kayıt hâlâ okunur', () {
      // Asıl senaryo: hub İngilizce'ye geçti ama Türkçe yazılmış kayıtlar
      // duruyor. Dar bir ayrıştırıcı onları sessizce boş gösterirdi.
      final eski = TaskDraft.fromSelection(
        quote: 'alıntı',
        sourcePath: 'p',
        kind: 'gorev',
        mark: TaskMark.highlight,
        note: 'eski not',
      );
      final yeni = TaskDraft.fromSelection(
        quote: 'quote',
        sourcePath: 'p',
        kind: 'gorev',
        mark: TaskMark.highlight,
        note: 'new note',
        lang: HubLanguage.en,
      );

      expect(noteTextFrom(_body(eski.content)), 'eski not');
      expect(noteTextFrom(_body(yeni.content)), 'new note');
    });
  });
}

/// Frontmatter'ı atıp gövdeyi verir — `noteTextFrom` gövde bekliyor.
String _body(String fileContent) {
  final parts = fileContent.split('---\n');
  return parts.length > 2 ? parts.sublist(2).join('---\n') : fileContent;
}
