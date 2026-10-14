import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/all_tasks.dart';
import 'package:takip/hub/hub_language.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/models/task_draft.dart';
import 'package:takip/hub/models/task_event.dart';

HubTask target() => const HubTask(
      id: 'pending',
      title: 'Kira ödemesi',
      createdBy: 'user',
      created: '2026-10-15T09:00:00Z',
      updated: '2026-10-15T09:00:00Z',
      priority: 'high',
      category: 'gorev',
      tags: [],
      session: 'none',
      result: 'none',
      status: TaskStatus.inbox,
      path: 'hub/tasks/inbox/2026-10-15-kira-odemesi.md',
    );

TaskSummary summary(String name, TaskStatus status) => TaskSummary.fromEntry(
      path: 'hub/tasks/${status.name}/$name',
      name: name,
      sha: 'sha-$name',
      status: status,
    )!;

TaskEvent event(TaskEventKind kind, String target,
        {String created = '2026-10-15T10:00:00Z', String? assignee}) =>
    TaskEvent(
      kind: kind,
      target: target,
      path: 'hub/tasks/inbox/x.md',
      created: created,
      assignee: assignee,
    );

void main() {
  group('TaskEvent.parse', () {
    test('yorum olayı: tür, hedef, yazar ve metin', () {
      final e = TaskEvent.parse('hub/tasks/inbox/2026-10-15-yorum.md', '''---
id: pending
title: "Yorum: Kira ödemesi"
author: fatih
tags: [comment]
target: 2026-10-15-kira-odemesi.md
created: "2026-10-15T11:05:00Z"
---

# Yorum: Kira ödemesi

## Yorum
Ev sahibi IBAN'ı değiştirdi.
''')!;
      expect(e.kind, TaskEventKind.comment);
      expect(e.target, '2026-10-15-kira-odemesi.md');
      expect(e.author, 'fatih');
      expect(e.text, "Ev sahibi IBAN'ı değiştirdi.");
    });

    test('etiketsiz ya da hedefsiz dosya olay sayılmaz', () {
      expect(TaskEvent.parse('p', '---\nid: pending\ntitle: x\ntags: []\n---\n'),
          isNull);
      expect(
          TaskEvent.parse('p', '---\nid: pending\ntitle: x\ntags: [comment]\n---\n'),
          isNull,
          reason: 'hedefsiz olay hiçbir göreve bağlanamaz');
    });
  });

  group('taslaklar kendi yazdıklarını geri okur', () {
    test('yorum taslağı olay olarak ayrışır; hedef dosya adı', () {
      final d = TaskDraft.comment(target(),
          text: '  Yarın öderim  ', author: 'fatih', lang: HubLanguage.tr);
      final e = TaskEvent.parse('hub/tasks/inbox/${d.fileName}', d.content)!;
      expect(e.kind, TaskEventKind.comment);
      expect(e.target, '2026-10-15-kira-odemesi.md');
      expect(e.text, 'Yarın öderim');
      expect(d.title, 'Yorum: Kira ödemesi');
    });

    test('atama taslağı kişiyi taşır; İngilizce hubda İngilizce başlık', () {
      final d = TaskDraft.assign(target(),
          assignee: 'fatih', author: 'afgover', lang: HubLanguage.en);
      final e = TaskEvent.parse('hub/tasks/inbox/${d.fileName}', d.content)!;
      expect(e.kind, TaskEventKind.assign);
      expect(e.assignee, 'fatih');
      expect(d.title, 'Assign: Kira ödemesi → @fatih');
    });

    test('bekleyen soru cevabı da hedefini söyler', () {
      final waiting = HubTask.parse(
        path: 'hub/tasks/waiting/2026-10-15-soru.md',
        content: '---\nid: T-030\ntitle: Soru\noptions: [a, b]\n---\n',
        status: TaskStatus.waiting,
      );
      final d = TaskDraft.waitingAnswer(waiting, selected: ['a']);
      expect(d.content, contains('target: 2026-10-15-soru.md'));
    });
  });

  group('parseComments', () {
    test('işlenmiş yorumlar UTC saat ve yazarla okunur, bölüm sonunda durur', () {
      final c = parseComments('''# Kira ödemesi

## İstek
Öde.

## Yorumlar

### [2026-10-15 11:05] @fatih
IBAN değişti.
Yenisi notlarda.

### [2026-10-15 12:30] @afgover
Tamam.

## Ek
Bu yorum değil.
''');
      expect(c, hasLength(2));
      expect(c[0].author, 'fatih');
      expect(c[0].text, 'IBAN değişti.\nYenisi notlarda.');
      expect(c[0].at, DateTime.utc(2026, 10, 15, 11, 5));
      expect(c[1].text, 'Tamam.');
    });

    test('İngilizce bölüm adı da okunur; bölüm yoksa boş', () {
      expect(parseComments('## Comments\n\n### [2026-10-15 09:00] @x\nhi\n'),
          hasLength(1));
      expect(parseComments('## Notlar\nyorum yok'), isEmpty);
    });
  });

  group('applyEvents', () {
    test('bekleyen yorumlar sayıya eklenir, olaysız görev değişmez', () {
      final tasks = [
        summary('2026-10-15-a.md', TaskStatus.active).withContext(commentCount: 2),
        summary('2026-10-15-b.md', TaskStatus.inbox),
      ];
      final out = applyEvents(tasks, [
        event(TaskEventKind.comment, '2026-10-15-a.md'),
        event(TaskEventKind.comment, '2026-10-15-a.md'),
      ]);
      expect(out[0].commentCount, 4);
      expect(out[1].commentCount, 0);
      expect(out[1].assigneePending, isFalse);
    });

    test('en yeni atama geçerli; inbox görevinde bile iş o kişide', () {
      final out = applyEvents([summary('2026-10-15-a.md', TaskStatus.inbox)], [
        event(TaskEventKind.assign, '2026-10-15-a.md',
            created: '2026-10-15T12:00:00Z', assignee: 'zeynep'),
        event(TaskEventKind.assign, '2026-10-15-a.md',
            created: '2026-10-15T10:00:00Z', assignee: 'fatih'),
      ]);
      expect(out.single.assignee, 'zeynep');
      expect(out.single.assigneePending, isTrue);
      expect(out.single.effectiveAssignee, 'zeynep');
      expect(holderOf(out.single), 'zeynep');
      expect(TaskView.mine.allows(out.single, 'zeynep'), isTrue);
      expect(TaskView.mine.allows(out.single, 'fatih'), isFalse);
    });
  });
}
