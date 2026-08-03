import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/common/hub_markdown.dart';
import 'package:takip/hub/annotations.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/models/task_draft.dart';
import 'package:takip/hub/frontmatter.dart';

Annotation ann(String quote, TaskMark mark) => Annotation(
      quote: quote,
      mark: mark,
      title: quote,
      category: 'yorum',
      path: 'hub/tasks/inbox/x.md',
    );

/// Görünmez işaret karakterleri — kaynaktaki yerlerini sınamak için.
const hlOpen = '';
const hlClose = '';
const ulOpen = '';
const ulClose = '';

void main() {
  group('markAnnotations', () {
    test('alıntıyı bulup işaret karakterleriyle sarar', () {
      final out = markAnnotations(
        'Bu bir cümledir ve içinde alıntı vardır.',
        [ann('alıntı', TaskMark.highlight)],
      );
      expect(out, contains('alıntı$hlClose'));
      expect(out, contains(hlOpen));
    });

    test('altı çizili ayrı işaret kullanır', () {
      final out = markAnnotations('yanlış olan yer', [
        ann('yanlış', TaskMark.underline),
      ]);
      expect(out, contains('yanlış$ulClose'));
      expect(out, contains(ulOpen));
      expect(out, isNot(contains(hlOpen)));
    });

    test('alıntı bulunamazsa belge olduğu gibi kalır', () {
      const source = 'Belge sonradan değişmiş olabilir.';
      expect(markAnnotations(source, [ann('artık yok', TaskMark.highlight)]),
          source);
    });

    test('kayıt yoksa dokunmaz', () {
      expect(markAnnotations('metin', const []), 'metin');
    });

    test('uzun alıntı önce işaretlenir, kısası onu bozmaz', () {
      // "kırmızı altı çizili" ve "kırmızı" birlikte varken kısası önce
      // işaretlenseydi uzun alıntı artık bulunamazdı.
      final out = markAnnotations('burada kırmızı altı çizili yazıyor', [
        ann('kırmızı', TaskMark.highlight),
        ann('kırmızı altı çizili', TaskMark.underline),
      ]);
      expect(out, contains('kırmızı altı çizili$ulClose'));
      expect(out.split(ulOpen).length - 1, 1);
    });

    test('birden çok bağımsız alıntı ayrı ayrı işaretlenir', () {
      final out = markAnnotations('bir ve iki', [
        ann('bir', TaskMark.highlight),
        ann('iki', TaskMark.underline),
      ]);
      expect(out, contains('bir$hlClose'));
      expect(out, contains('iki$ulClose'));
    });

    test('boş alıntı yok sayılır', () {
      expect(markAnnotations('metin', [ann('   ', TaskMark.highlight)]),
          'metin');
    });
  });

  group('isContractStale', () {
    test('eski sürüm geride sayılır', () {
      expect(isContractStale('1.3'), isTrue);
      expect(isContractStale('1.7'), isTrue);
      expect(isContractStale('0.9'), isTrue);
    });

    test('güncel ve ileri sürümler geride sayılmaz', () {
      expect(isContractStale('1.8'), isFalse);
      expect(isContractStale('1.9'), isFalse);
      expect(isContractStale('2.0'), isFalse);
    });

    test('karşılaştırma sayısal — 1.10, 1.9\'dan yenidir', () {
      // Metin karşılaştırması olsaydı "1.10" < "1.9" çıkardı.
      expect(isContractStale('1.10'), isFalse);
    });
  });

  group('TaskDraft.fromSelection', () {
    test('sözleşme 1.5 alanlarını yazar', () {
      final draft = TaskDraft.fromSelection(
        quote: 'işaretlenen cümle',
        sourcePath: 'hub/sessions/2026-08-01-x/session.md',
        kind: 'duzeltme',
        mark: TaskMark.underline,
        note: 'burası yanlış',
        priority: 'high',
      );

      final fm = Frontmatter.parse(draft.content);
      expect(fm.str('id'), 'pending');
      expect(fm.str('created_by'), 'user');
      expect(fm.str('category'), 'duzeltme');
      expect(fm.str('priority'), 'high');
      expect(fm.str('source'), 'hub/sessions/2026-08-01-x/session.md');
      expect(fm.str('quote'), 'işaretlenen cümle');
      expect(fm.str('mark'), 'underline');
      expect(fm.list('tags'), contains('secim'));
      expect(fm.body, contains('burası yanlış'));
      expect(fm.body, contains('işaretlenen cümle'));
    });

    test('başlık uzun alıntıda kısaltılır', () {
      final long = 'kelime ' * 30;
      final draft = TaskDraft.fromSelection(
        quote: long,
        sourcePath: 'hub/x.md',
        kind: 'yorum',
        mark: TaskMark.highlight,
      );
      final title = Frontmatter.parse(draft.content).str('title')!;
      expect(title.length, lessThanOrEqualTo(62));
      expect(title, endsWith('…'));
    });

    test('not girilmezse gövde bunu açıkça söyler', () {
      final draft = TaskDraft.fromSelection(
        quote: 'x',
        sourcePath: 'hub/x.md',
        kind: 'yorum',
        mark: TaskMark.highlight,
      );
      expect(Frontmatter.parse(draft.content).body, contains('(not girilmedi)'));
    });

    test('okunan görev dosyası aynı alanları geri verir', () {
      final draft = TaskDraft.fromSelection(
        quote: 'alıntı',
        sourcePath: 'hub/a.md',
        kind: 'tartisma',
        mark: TaskMark.highlight,
      );
      final task = HubTask.parse(
        path: 'hub/tasks/inbox/x.md',
        content: draft.content,
        status: TaskStatus.inbox,
      );

      expect(task.source, 'hub/a.md');
      expect(task.quote, 'alıntı');
      expect(task.mark, TaskMark.highlight);
      expect(task.isAnnotation, isTrue);
    });

    test('bağlam alanı olmayan görev işaret kaydı sayılmaz', () {
      final draft = TaskDraft.create(title: 'Normal görev');
      final task = HubTask.parse(
        path: 'hub/tasks/inbox/x.md',
        content: draft.content,
        status: TaskStatus.inbox,
      );

      expect(task.isAnnotation, isFalse);
      expect(task.source, isNull);
      // Sözleşme: bu alanlar normal görevlerde hiç yazılmaz.
      expect(draft.content, isNot(contains('source:')));
      expect(draft.content, isNot(contains('quote:')));
      expect(draft.content, isNot(contains('mark:')));
    });
  });

  group('çizilmiş metin ↔ ham markdown eşleşmesi (L-023)', () {
    test('kalın yazı içindeki seçim işaretlenir', () {
      // Kullanıcı ekranda "canlıya alınmasıyla" görüyor; kaynakta yıldızlar var.
      const source = 'Financer bir sunucuda **canlıya alınmasıyla** bitti.';
      final out = markAnnotations(
        source,
        [ann('canlıya alınmasıyla', TaskMark.underline)],
      );
      expect(out, contains(ulOpen));
      expect(out, contains(ulClose));
    });

    test('satır sarmasını aşan seçim işaretlenir', () {
      // Seçimde tek boşluk var, kaynakta satır sonu.
      const source = 'Uzun bir cümlenin\nikinci satıra taşan kısmı.';
      final out = markAnnotations(
        source,
        [ann('cümlenin ikinci satıra', TaskMark.highlight)],
      );
      expect(out, contains(hlOpen));
    });

    test('kod işareti içeren seçim işaretlenir', () {
      const source = 'Sorun `nginx.conf` dosyasındaydı.';
      final out = markAnnotations(
        source,
        [ann('nginx.conf dosyasındaydı', TaskMark.highlight)],
      );
      expect(out, contains(hlOpen));
    });

    test('birebir eşleşme varken izdüşüme düşülmez', () {
      const source = 'düz bir cümle';
      final out = markAnnotations(source, [ann('düz bir', TaskMark.highlight)]);
      expect(out, contains('düz bir$hlClose'));
      expect(out, startsWith(hlOpen));
      expect(out, contains('cümle'));
    });

    test('gerçekten olmayan metin yine bulunamaz', () {
      const source = 'Belge sonradan değişmiş olabilir.';
      expect(
        markAnnotations(source, [ann('bambaşka bir cümle', TaskMark.highlight)]),
        source,
      );
    });
  });

  group('akış ve üçüncü renk', () {
    // Kaynak metne **yalnız işaretin kendisi** gömülüyor; gerisi olduğu gibi
    // kalıyor. Önceki sürüm satırı kelime kelime kutuluyordu (L-030) — o
    // yaklaşım `**kalın**` içeren satırlarda uygulanamadığı için gerçek hub
    // metinlerinde hemen hiç devreye girmiyordu ve terk edildi. Satır akışını
    // artık çizim katmanı koruyor (bkz. hub_markdown_test.dart).
    test('işaret dışındaki metne dokunulmaz', () {
      final out = markAnnotations(
        'bir iki uc dort bes',
        [ann('iki uc', TaskMark.highlight)],
      );
      expect(out, 'bir ${hlOpen}0\u001Fiki uc$hlClose dort bes');
    });

    test('kalın yazı içeren satırda da işaretlenir', () {
      // Asıl hub metinleri böyle; eski çözüm tam da burada devre dışı
      // kalıyordu.
      final out = markAnnotations(
        'bir **kalın** iki uc dort',
        [ann('iki uc', TaskMark.highlight)],
      );
      expect(out, contains('\uE000'));
      expect(out, contains('**kalın**'), reason: 'vurgu bozulmamalı');
    });

    test('liste imi korunur', () {
      final out = markAnnotations(
        '- bir iki uc',
        [ann('iki', TaskMark.comment)],
      );
      expect(out, startsWith('- '));
      expect(out, contains('\uE004'));
    });

    test('yorum kendi işaretini kullanır', () {
      final out = markAnnotations('bir iki', [ann('iki', TaskMark.comment)]);
      expect(out, contains('\uE004'));
      expect(out, isNot(contains('\uE000')));
      expect(out, isNot(contains('\uE002')));
    });
  });
}
