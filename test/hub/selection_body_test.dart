import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/common/hub_markdown.dart';
import 'package:takip/hub/frontmatter.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/models/task_draft.dart';

void main() {
  group('kaydın "nerede" bilgisi', () {
    test('repo, dosya ve bölüm gövdeye yazılır', () {
      final draft = TaskDraft.fromSelection(
        quote: 'işaretlenen cümle',
        sourcePath: 'hub/sessions/2026-08-03-x/session.md',
        kind: 'gorev',
        mark: TaskMark.highlight,
        note: 'şunu yap',
        section: 'Özet',
        repoSlug: 'afgover/takip',
      );

      final body = Frontmatter.parse(draft.content).body;
      expect(body, contains('## Nerede'));
      expect(body, contains('afgover/takip'));
      expect(body, contains('hub/sessions/2026-08-03-x/session.md'));
      expect(body, contains('**Bölüm:** Özet'));
      expect(body, contains('şunu yap'));
      expect(body, contains('> işaretlenen cümle'));
    });

    test('bilinmeyen alanlar satır olarak hiç yazılmaz', () {
      final draft = TaskDraft.fromSelection(
        quote: 'x',
        sourcePath: 'hub/a.md',
        kind: 'yorum',
        mark: TaskMark.highlight,
      );

      final body = Frontmatter.parse(draft.content).body;
      expect(body, contains('- **Dosya:** `hub/a.md`'));
      expect(body, isNot(contains('**Repo:**')));
      expect(body, isNot(contains('**Bölüm:**')));
    });
  });

  group('sectionOf', () {
    const doc = '''
# Oturum: Bir şey

## Özet
Burada özet var.

## Kayıt
Burada kayıt var ve **kalın** bir yer.
''';

    test('alıntının altında bulunduğu başlığı bulur', () {
      expect(sectionOf(doc, 'Burada özet var'), 'Özet');
      expect(sectionOf(doc, 'Burada kayıt var'), 'Kayıt');
    });

    test('kalın yazı içindeki seçim için de çalışır', () {
      // Seçimde yıldız yok; izdüşüm üzerinden bulunuyor.
      expect(sectionOf(doc, 'kalın bir yer'), 'Kayıt');
    });

    test('başlıktan önceki metinde başlık yoksa null', () {
      expect(sectionOf('düz metin, başlık yok', 'düz metin'), isNull);
    });

    test('bulunamayan alıntı için null', () {
      expect(sectionOf(doc, 'hiç olmayan cümle'), isNull);
    });
  });
}
