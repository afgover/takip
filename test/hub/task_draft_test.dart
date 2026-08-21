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

  group('görev hedef hub\'ını kendisi söyler (B-139)', () {
    // Sözleşme 1.24 bunu bildirimler için kuralmıştı; gerekçesi türe bağlı
    // değil. Yol hub-göreli, ID hub başına — ikisi de hub'ı tanımlamıyor ve
    // yanlış hub'a düşen bir görev bildirimlerle **aynı sebepten** teşhis
    // edilemiyordu (L-045).
    TaskDraft withRepo(String? slug) => withClock(
          Clock.fixed(DateTime.utc(2026, 8, 21, 9)),
          () => TaskDraft.create(
            title: 'Deneme',
            description: 'kısa açıklama',
            repoSlug: slug,
          ),
        );

    test('repo verilince gövdede Repo satırı olur', () {
      expect(withRepo('afgover/takip').content,
          contains('- **Repo:** `afgover/takip`'));
    });

    test('satır kullanıcının metnine karışmaz', () {
      final body = withRepo('afgover/takip').content;
      // Açıklama ile Repo satırı arasında boş satır var: `## İstek`
      // kullanıcının yazdığı şeydir, makine okunur olgu onun içine
      // yapışmamalı (T-014'ün ayrımı).
      expect(body, contains('kısa açıklama\n\n- **Repo:**'));
      // Not başlığı yerinde ve Repo satırından sonra.
      expect(body.indexOf('- **Repo:**'),
          lessThan(body.indexOf('## Notlar')));
    });

    test('repo yoksa satır hiç yazılmaz, boş satır da bırakmaz', () {
      final body = withRepo(null).content;
      expect(body, isNot(contains('Repo')));
      expect(body, contains('kısa açıklama\n\n## Notlar'));
    });

    test('gövdedeki satır ile kuyruk damgası aynı kaynaktan gelir', () {
      // İkisi ayrı yerden bassaydı zamanla ayrışır, gövde bir hub'ı kuyruk
      // başka bir hub'ı gösterebilirdi.
      final d = withRepo('afgover/financer_takip');
      expect(d.repoSlug, 'afgover/financer_takip');
      expect(d.content, contains('- **Repo:** `afgover/financer_takip`'));
    });
  });
}
