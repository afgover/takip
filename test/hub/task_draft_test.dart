import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/frontmatter.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/models/task_draft.dart';

TaskDraft draftAt(DateTime at, {String title = 'Market listesi', String? desc}) =>
    withClock(
      Clock.fixed(at),
      () => TaskDraft.create(
        title: title,
        description: desc ?? 'Süt, ekmek.',
        priority: 'high',
        category: 'gorev',
      ),
    );

void main() {
  final at = DateTime.utc(2026, 7, 30, 14, 5);

  test('dosya adı sözleşme biçiminde', () {
    expect(draftAt(at).fileName, '2026-07-30-market-listesi.md');
    expect(
      draftAt(at, title: 'Şeker & ığdır!').fileName,
      '2026-07-30-seker-igdir.md',
    );
  });

  test('commit mesajı SYSTEM.md §8 önekini taşır', () {
    expect(draftAt(at).commitMessage, "task(pending): inbox'a eklendi (app)");
  });

  test('içerik sözleşme alanlarını ve gövde başlıklarını içerir', () {
    final fm = Frontmatter.parse(draftAt(at).content);

    expect(fm.str('id'), 'pending', reason: 'ID atamak agent\'ın işi');
    expect(fm.str('created_by'), 'user');
    expect(fm.str('title'), 'Market listesi');
    expect(fm.str('priority'), 'high');
    expect(fm.str('category'), 'gorev');
    expect(fm.str('session'), 'none');
    expect(fm.str('result'), 'none');
    expect(fm.list('tags'), isEmpty);
    expect(fm.dateTime('created'), at);

    expect(fm.body, contains('# Market listesi'));
    expect(fm.body, contains('## İstek'));
    expect(fm.body, contains('Süt, ekmek.'));
    expect(fm.body, contains('## Notlar'));
  });

  test('yazılan dosya app tarafından da geri okunabiliyor', () {
    final task = HubTask.parse(
      path: 'hub/tasks/inbox/x.md',
      content: draftAt(at, title: 'Görev: iki nokta "tırnak"').content,
      status: TaskStatus.inbox,
    );

    expect(task.title, 'Görev: iki nokta "tırnak"');
    expect(task.isPending, isTrue);
    expect(task.hasResult, isFalse);
  });

  test('açıklama boşken gövde yine de anlamlı', () {
    final fm = Frontmatter.parse(draftAt(at, desc: '   ').content);
    expect(fm.body, contains('(açıklama girilmedi)'));
  });

  test('json\'a çevrilip geri okunabiliyor (outbox için)', () {
    final draft = draftAt(at);
    final restored = TaskDraft.fromJson(draft.toJson());

    expect(restored.fileName, draft.fileName);
    expect(restored.content, draft.content);
    expect(restored.commitMessage, draft.commitMessage);
    expect(restored.title, draft.title);
    expect(restored.createdAt, draft.createdAt);
  });

  test('withFileName yalnız adı değiştirir', () {
    final draft = draftAt(at);
    final renamed = draft.withFileName('2026-07-30-market-listesi-2.md');

    expect(renamed.fileName, '2026-07-30-market-listesi-2.md');
    expect(renamed.content, draft.content);
  });
}
