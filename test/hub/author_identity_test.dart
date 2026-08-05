import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/hub/frontmatter.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/models/task_draft.dart';

/// Kimlik alanları (sözleşme 1.15, çoklu kullanıcı — Katman 1).
void main() {
  group('author alanı', () {
    test('görev taslağı kimliği yazar', () {
      final draft = TaskDraft.create(title: 'iş', author: 'afgover');
      expect(Frontmatter.parse(draft.content).str('author'), 'afgover');
    });

    test('kimlik bilinmiyorsa alan hiç yazılmaz', () {
      // Tek kullanıcılı dönemin hâli. Boş string yazmak "kimliği yok" ile
      // "kimliği boş" arasındaki farkı silerdi.
      final draft = TaskDraft.create(title: 'iş');
      expect(draft.content, isNot(contains('author:')));
    });

    test('seçimden üretilen kayıt ve not da kimliği taşır', () {
      final task = TaskDraft.fromSelection(
        quote: 'alıntı',
        sourcePath: 'hub/BACKLOG.md',
        kind: 'gorev',
        mark: TaskMark.highlight,
        note: 'şunu yap',
        author: 'afgover',
      );
      final note = TaskDraft.note(
        quote: 'alıntı',
        sourcePath: 'hub/BACKLOG.md',
        author: 'afgover',
      );

      expect(Frontmatter.parse(task.content).str('author'), 'afgover');
      expect(Frontmatter.parse(note.content).str('author'), 'afgover');
    });

    test('waiting bildirimleri de kimliği taşır', () {
      final task = HubTask(
        id: 'T-001',
        title: 'iş',
        createdBy: 'agent',
        created: '',
        updated: '',
        priority: 'normal',
        category: 'gorev',
        tags: const [],
        session: 'none',
        result: 'none',
        status: TaskStatus.waiting,
        path: '${Hub.waitingDir}/2026-08-06-x.md',
      );

      expect(
        Frontmatter.parse(TaskDraft.waitingDone(task, author: 'afgover').content)
            .str('author'),
        'afgover',
      );
      expect(
        Frontmatter.parse(TaskDraft.waitingAnswer(task,
                selected: const ['Evet'], author: 'afgover')
            .content).str('author'),
        'afgover',
      );
    });

    test('kayıt geri okunduğunda author ve for ayrıştırılır', () {
      final parsed = HubTask.parse(
        path: '${Hub.waitingDir}/2026-08-06-x.md',
        content: '---\nid: T-020\ntitle: "Soru"\n'
            'author: afgover\nfor: mehmet\n---\n\ngövde\n',
        status: TaskStatus.waiting,
      );

      expect(parsed.author, 'afgover');
      expect(parsed.waitingFor, 'mehmet');
    });
  });

  group('waitsFor — kimi bekliyor', () {
    HubTask waiting({String? forWhom}) => HubTask(
          id: 'T-001',
          title: 'iş',
          createdBy: 'agent',
          created: '',
          updated: '',
          priority: 'normal',
          category: 'gorev',
          tags: const [],
          session: 'none',
          result: 'none',
          status: TaskStatus.waiting,
          path: '${Hub.waitingDir}/2026-08-06-x.md',
          waitingFor: forWhom,
        );

    test('for yazılmamışsa herkesi bekler', () {
      // Tek kullanıcılı dönemde yazılmış her görev böyle; onları kimsenin
      // görmediği bir kuyruğa düşürmek sistemin en işe yarar parçasını
      // sessizce boşaltırdı.
      expect(waiting().waitsFor('afgover'), isTrue);
      expect(waiting().waitsFor('mehmet'), isTrue);
      expect(waiting().waitsFor(null), isTrue);
    });

    test('for yazılıysa yalnız o kişiyi bekler', () {
      expect(waiting(forWhom: 'mehmet').waitsFor('mehmet'), isTrue);
      expect(waiting(forWhom: 'mehmet').waitsFor('afgover'), isFalse);
    });

    test('kendi kimliğimiz bilinmiyorsa ayrım yapılmaz', () {
      // Kimliği okunamamış bir kurulumda herkesi "başkasını bekliyor" diye
      // göstermek, bütün bekleyen işleri gizlerdi.
      expect(waiting(forWhom: 'mehmet').waitsFor(null), isTrue);
    });
  });

  group('notes/<login>/ (R-001 korunuyor)', () {
    test('kimlik varsa not kendi klasörüne yazılır', () {
      expect(
        HubFolder.notes.pathFor('2026-08-06-x.md', login: 'afgover'),
        '${Hub.notesDir}/afgover/2026-08-06-x.md',
      );
    });

    test('kimlik yoksa düz yazılır (v1.15 öncesi biçim)', () {
      expect(
        HubFolder.notes.pathFor('2026-08-06-x.md'),
        '${Hub.notesDir}/2026-08-06-x.md',
      );
    });

    test('görevler bölünmez — inbox ortak iş kuyruğu', () {
      expect(
        HubFolder.inbox.pathFor('2026-08-06-x.md', login: 'afgover'),
        '${Hub.inboxDir}/afgover/2026-08-06-x.md',
        reason: 'yol üreticisi genel; bölmeme kararı çağıranda '
            '(TaskDraft görevlerde authorLogin taşımaz)',
      );
      // Asıl garanti burada: görev taslağı alt klasör bilgisi taşımıyor.
      expect(TaskDraft.create(title: 'iş', author: 'afgover').authorLogin,
          isNull);
      expect(
        TaskDraft.note(quote: 'a', sourcePath: 'p', author: 'afgover')
            .authorLogin,
        'afgover',
      );
    });

    test('kullanıcı adı yol dışına çıkamaz', () {
      // R-001'in özü: app yol vermiyor, **ad** veriyor. Ad yol parçasına
      // dönüşmeden önce temizleniyor, yoksa `../` ile hub'ın herhangi bir
      // yerine yazılabilirdi.
      expect(sanitizeLogin('../../gizli'), 'gizli');
      expect(sanitizeLogin('a/b'), 'ab');
      expect(sanitizeLogin('..'), isNull);
      expect(sanitizeLogin(''), isNull);
      expect(sanitizeLogin(null), isNull);
      expect(sanitizeLogin('afgover'), 'afgover');
      expect(sanitizeLogin('bir-kullanici-2'), 'bir-kullanici-2');

      expect(
        HubFolder.notes.pathFor('x.md', login: '../../../etc'),
        '${Hub.notesDir}/etc/x.md',
      );
    });

    test('not taslağı kuyrukta sahibini korur', () {
      // Çevrimdışı alınmış bir not, bağlantı gelince yine **kendi** sahibinin
      // klasörüne gitmeli.
      final draft =
          TaskDraft.note(quote: 'a', sourcePath: 'p', author: 'afgover');
      final restored = TaskDraft.fromJson(draft.toJson());

      expect(restored.authorLogin, 'afgover');
      expect(restored.forRepo('a/b').authorLogin, 'afgover');
      expect(restored.withFileName('y.md').authorLogin, 'afgover');
    });
  });
}
