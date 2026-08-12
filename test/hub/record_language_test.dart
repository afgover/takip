import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/browse/security_screen.dart';
import 'package:takip/hub/hub_language.dart';
import 'package:takip/hub/models/hub_doc.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/models/task_draft.dart';

/// Hub dili **yazılan kayda** da geçiyor mu (sözleşme 1.19).
///
/// Arayüzün İngilizce olması yetmiyor: "akabinde oluşturulacak içerik de o
/// dilde devam eder" kuralının karşılığı, uygulamanın hub'a yazdığı dosyanın
/// kendisi. Bu ayrı bir yol — arayüz `L`'den, kayıt `HubLanguage`'dan gelir —
/// ve biri çalışıp diğeri çalışmadığında hiçbir hata çıkmaz: İngilizce bir
/// hub'da sessizce Türkçe kayıtlar birikir.
void main() {
  final task = HubTask(
    id: 'T-001',
    title: 'Bir iş',
    createdBy: 'agent',
    created: '2026-08-08T10:00:00Z',
    updated: '2026-08-08T10:00:00Z',
    priority: 'normal',
    category: 'gorev',
    tags: const [],
    session: 'none',
    result: 'none',
    status: TaskStatus.waiting,
    path: 'hub/tasks/waiting/x.md',
    body: '',
  );

  group('waiting bildirimleri hub dilini izler', () {
    test('İngilizce hub İngilizce kayıt üretir', () {
      final done = TaskDraft.waitingDone(task, lang: HubLanguage.en);

      expect(done.title, contains('done'));
      expect(done.content, contains('## Request'));
      expect(done.content, contains('## Notes'));
      expect(done.content, isNot(contains('## İstek')));
    });

    test('Türkçe varsayılan korunuyor', () {
      final done = TaskDraft.waitingDone(task);

      expect(done.title, contains('yapıldı'));
      expect(done.content, contains('## İstek'));
    });

    test('cevapta seçim ve açıklama alan adları da çevriliyor', () {
      final answer = TaskDraft.waitingAnswer(
        task,
        selected: const ['Evet'],
        note: 'kısa not',
        lang: HubLanguage.en,
      );

      expect(answer.content, contains('- **Choice:** Evet'));
      expect(answer.content, contains('- **Explanation:** kısa not'));
      // Kullanıcının **yazdığı** metin çevrilmiyor: seçenek metni agent'ın
      // sorduğu sorudan geliyor, not da kullanıcının kendi cümlesi.
      expect(answer.content, contains('Evet'));
    });

    test('bildirim hedef repoyu kendisi söyler (sözleşme 1.24)', () {
      // Yol hub-göreli, ID hub başına: ikisi de hub'ı tanımlamıyor. Yanlış
      // yere düşen bildirim ancak bu satırla teşhis edilir (L-009, L-045).
      final done =
          TaskDraft.waitingDone(task, repoSlug: 'afgover/goverco_takip');
      expect(done.content, contains('- **Repo:** `afgover/goverco_takip`'));
      expect(done.repoSlug, 'afgover/goverco_takip');

      final answer = TaskDraft.waitingAnswer(task,
          selected: const ['Evet'], repoSlug: 'afgover/goverco_takip');
      expect(answer.content, contains('- **Repo:** `afgover/goverco_takip`'));

      // Repo bilinmiyorsa satır hiç yazılmaz — boş bir alan "kimliksiz" diye
      // bir şey uydururdu (L-040'ın aynı ilkesi).
      expect(TaskDraft.waitingDone(task).content, isNot(contains('**Repo:**')));
    });

    test('seçim yapılmadıysa bunu hub dilinde söyler', () {
      final answer = TaskDraft.waitingAnswer(
        task,
        selected: const [],
        lang: HubLanguage.en,
      );

      expect(answer.content, contains('(no choice)'));
    });
  });

  group('uygulama İngilizce sözleşmeyi okuyabiliyor (B-116)', () {
    // Gerçek dosyaya karşı koşuyor, uydurma bir metne değil: İngilizce bir hub
    // kendi `hub/SYSTEM.md`'sine bu dosyanın **içeriğini** koyacak. Ayrıştırıcı
    // başlıkları tanımazsa hub sessizce `tr` görünür — hata vermez, yalnız
    // arayüz yanlış dilde çizilir ve kayıtlar yanlış dilde yazılır.
    final english = File('hub/SYSTEM.en.md').readAsStringSync();
    final turkish = File('hub/SYSTEM.md').readAsStringSync();

    test('İngilizce başlıktan dil okunuyor', () {
      expect(languageCodeIn(english), 'en');
      expect(HubLanguage.parse(languageCodeIn(english)), HubLanguage.en);
    });

    test('Türkçe başlık aynen çalışmaya devam ediyor', () {
      expect(languageCodeIn(turkish), 'tr');
    });

    test('alan hiç yoksa tr varsayılıyor', () {
      expect(languageCodeIn('# bir belge\n'), isNull);
      expect(HubLanguage.parse(null), HubLanguage.tr);
    });
  });

  group('güvenlik kaydı iki dilde de okunuyor', () {
    KnowledgeEntry entry(String body) => KnowledgeEntry(
          id: 'SEC-001',
          title: 'x',
          body: body,
          date: null,
          isInvalidated: false,
        );

    test('Türkçe alan adları', () {
      final e = entry('- **Tür:** acik\n- **Durum:** acik\n');

      expect(securityKindOf(e), SecurityKind.acik);
      expect(isSecurityOpen(e), isTrue);
    });

    test('İngilizce alan adları', () {
      final e = entry('- **Type:** hole\n- **Status:** open\n');

      expect(securityKindOf(e), SecurityKind.acik);
      expect(isSecurityOpen(e), isTrue);
    });

    // Ayrıştırıcı geniş, yazan dar (L-019 ile aynı doktrin): dili değişmiş bir
    // hub'da eski kayıtlar okunamaz hâle gelmemeli.
    test('dili değişen hub eski kayıtlarını okumaya devam eder', () {
      final old = entry('- **Tür:** onlem\n- **Durum:** kapali\n');

      expect(securityKindOf(old), SecurityKind.onlem);
      expect(isSecurityOpen(old), isFalse);
    });
  });
}
