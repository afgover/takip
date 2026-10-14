import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/all_tasks.dart';
import 'package:takip/hub/models/task.dart';

TaskSummary task(
  String name,
  TaskStatus status, {
  String? waitingFor,
  String? author,
  String? assignee,
  String? createdBy,
}) =>
    TaskSummary.fromEntry(
      path: 'hub/tasks/${status.name}/$name',
      name: name,
      sha: 'sha-$name',
      status: status,
    )!
        .withContext(
      waitingFor: waitingFor,
      author: author,
      assignee: assignee,
      createdBy: createdBy,
    );

void main() {
  const me = 'afgover';

  group('TaskView.allows', () {
    test('Bana: beni ya da herkesi bekleyen iş ve bana atanmış aktif iş', () {
      final mine = TaskView.mine;
      expect(mine.allows(task('2026-10-15-a.md', TaskStatus.waiting), me), isTrue,
          reason: 'for yoksa herkesi bekler');
      expect(
          mine.allows(task('2026-10-15-b.md', TaskStatus.waiting, waitingFor: me), me),
          isTrue);
      expect(
          mine.allows(
              task('2026-10-15-c.md', TaskStatus.waiting, waitingFor: 'fatih'), me),
          isFalse);
      expect(
          mine.allows(task('2026-10-15-d.md', TaskStatus.active, assignee: me), me),
          isTrue);
      expect(
          mine.allows(
              task('2026-10-15-e.md', TaskStatus.active, assignee: 'fatih'), me),
          isFalse);
      expect(mine.allows(task('2026-10-15-f.md', TaskStatus.inbox), me), isFalse,
          reason: 'gelen kutusu henüz kimsenin değil');
    });

    test('Açtıklarım yalnız yazarı ben olanı alır; yazar bilinmiyorsa almaz', () {
      final authored = TaskView.authored;
      expect(
          authored.allows(task('2026-10-15-a.md', TaskStatus.inbox, author: me), me),
          isTrue);
      expect(
          authored.allows(
              task('2026-10-15-b.md', TaskStatus.inbox, author: 'fatih'), me),
          isFalse);
      expect(authored.allows(task('2026-10-15-c.md', TaskStatus.inbox), me), isFalse);
      expect(
          authored.allows(task('2026-10-15-d.md', TaskStatus.inbox, author: me), null),
          isFalse,
          reason: 'kim olduğumu bilmeden "benim" denemez');
    });

    test('Ajanlar created_by: agent olanı alır; Ekip hepsini', () {
      final byAgent =
          task('2026-10-15-a.md', TaskStatus.waiting, createdBy: 'agent');
      final byUser = task('2026-10-15-b.md', TaskStatus.inbox, createdBy: 'user');
      expect(TaskView.agents.allows(byAgent, me), isTrue);
      expect(TaskView.agents.allows(byUser, me), isFalse);
      expect(TaskView.team.allows(byAgent, me), isTrue);
      expect(TaskView.team.allows(byUser, null), isTrue);
    });
  });

  group('sectionsByHolder', () {
    test('tek kişilik listede bölüm yok (tek, adsız bölüm)', () {
      final tasks = [
        task('2026-10-15-a.md', TaskStatus.active, assignee: me, author: me),
        task('2026-10-15-b.md', TaskStatus.waiting),
        task('2026-10-15-c.md', TaskStatus.inbox, author: me),
      ];
      final sections = sectionsByHolder(tasks, me);
      expect(sections, hasLength(1));
      expect(sections.single.person, isNull);
      expect(sections.single.tasks, tasks);
    });

    test('iki kişide işin sahibine göre bölünür: önce ben, en sonda sahipsiz', () {
      final a = task('2026-10-15-a.md', TaskStatus.waiting, waitingFor: 'zeynep');
      final b = task('2026-10-15-b.md', TaskStatus.active, assignee: me);
      final c = task('2026-10-15-c.md', TaskStatus.inbox, author: 'fatih');
      final d = task('2026-10-15-d.md', TaskStatus.waiting, waitingFor: 'fatih');
      final sections = sectionsByHolder([a, b, c, d], me);

      expect(sections.map((s) => s.person), [me, 'fatih', 'zeynep', null]);
      expect(sections[0].tasks, [b]);
      expect(sections[1].tasks, [d]);
      expect(sections[2].tasks, [a]);
      expect(sections[3].tasks, [c], reason: 'gelen kutusu kimsenin değil');
    });
  });
}
