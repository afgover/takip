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

  test('filtrenin repo boyutu yok — liste zaten tek repo', () {
    // Repo süzgeci, liste bütün repoları birleştirirken vardı. Liste aktif
    // repoya daralınca menüsü de kalkmıştı; kalan bir seçim, kullanıcının
    // açamayacağı görünmez bir filtre olarak listeyi boşaltabilirdi.
    const f = TaskFilter(priorities: {'high'});
    expect(f.allows(task(repo: 'a/bir', priority: 'high')), isTrue);
    expect(f.allows(task(repo: 'b/iki', priority: 'high')), isTrue);
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
    final withCategory = empty.toggled(category: 'hata');
    expect(withCategory.categories, {'hata'});
    expect(withCategory.toggled(category: 'hata').categories, isEmpty);
  });

  test('activeCount kaç boyutun daraltıldığını sayar', () {
    expect(const TaskFilter().activeCount, 0);
    expect(const TaskFilter(categories: {'hata'}).activeCount, 1);
    expect(
      const TaskFilter(categories: {'hata'}, priorities: {'high'}).activeCount,
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
