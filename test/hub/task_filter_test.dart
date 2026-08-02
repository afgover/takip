import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/all_tasks.dart';
import 'package:takip/hub/models/task.dart';

TaskSummary task({
  String repo = 'a/bir',
  String? priority = 'normal',
  String? category = 'gorev',
  TaskStatus status = TaskStatus.inbox,
}) =>
    TaskSummary(
      path: 'hub/tasks/inbox/2026-08-02-x.md',
      fileName: '2026-08-02-x.md',
      sha: 'sha',
      status: status,
      date: DateTime.utc(2026, 8, 2),
      title: 'X',
      repoSlug: repo,
      repoLabel: repo,
      priority: priority,
      category: category,
    );

void main() {
  test('boş filtre her şeyi geçirir', () {
    expect(const TaskFilter().allows(task()), isTrue);
    expect(const TaskFilter().isEmpty, isTrue);
  });

  test('repo filtresi yalnız seçili repoyu geçirir', () {
    const f = TaskFilter(repos: {'a/bir'});
    expect(f.allows(task(repo: 'a/bir')), isTrue);
    expect(f.allows(task(repo: 'b/iki')), isFalse);
  });

  test('öncelik ve kategori birlikte daraltır', () {
    const f = TaskFilter(priorities: {'high'}, categories: {'hata'});
    expect(f.allows(task(priority: 'high', category: 'hata')), isTrue);
    expect(f.allows(task(priority: 'high', category: 'gorev')), isFalse);
    expect(f.allows(task(priority: 'low', category: 'hata')), isFalse);
  });

  test('etiketi bilinmeyen görev filtreye takılmaz', () {
    // Yerel kopya inmeden öncelik/kategori okunamıyor; bu görevi gizlemek
    // onu kaybetmek olurdu.
    const f = TaskFilter(priorities: {'urgent'}, categories: {'hata'});
    expect(f.allows(task(priority: null, category: null)), isTrue);
  });

  test('toggle aynı değeri ekler ve çıkarır', () {
    const empty = TaskFilter();
    final withRepo = empty.toggled(repo: 'a/bir');
    expect(withRepo.repos, {'a/bir'});
    expect(withRepo.toggled(repo: 'a/bir').repos, isEmpty);
  });

  test('activeCount kaç boyutun daraltıldığını sayar', () {
    expect(const TaskFilter().activeCount, 0);
    expect(const TaskFilter(repos: {'a/bir'}).activeCount, 1);
    expect(
      const TaskFilter(repos: {'a/bir'}, priorities: {'high'}).activeCount,
      2,
    );
  });

  test('TaskSummary kimliği repoyu da içerir', () {
    // Aynı yol iki farklı hub'da bulunabilir; bunlar aynı görev değildir.
    expect(task(repo: 'a/bir') == task(repo: 'b/iki'), isFalse);
    expect(task(repo: 'a/bir') == task(repo: 'a/bir'), isTrue);
  });

  test('isTaskPath dört durum klasörünü tanır', () {
    expect(isTaskPath('hub/tasks/inbox/x.md'), isTrue);
    expect(isTaskPath('hub/tasks/active/x.md'), isTrue);
    expect(isTaskPath('hub/tasks/waiting/x.md'), isTrue);
    expect(isTaskPath('hub/tasks/done/x.md'), isTrue);
    expect(isTaskPath('hub/sessions/x/session.md'), isFalse);
  });
}
