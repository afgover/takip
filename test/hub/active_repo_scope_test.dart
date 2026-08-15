import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/github/trees_api.dart';
import 'package:takip/hub/all_tasks.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/models/task_draft.dart';
import 'package:takip/hub/offline_store.dart';
import 'package:takip/hub/outbox.dart';

/// Bekleyenler listesinin **kapsamı**: aktif repo, hepsi değil.
///
/// Liste bir dönem bütün bağlı repoları birleştiriyordu (B-067). Ölçülen
/// sonuç şuydu: kullanıcı üç projenin işini tek listede görüyor, ama görev
/// eklerken hedefi seçmiyor — görev sessizce o an aktif olan repoya gidiyor.
/// Yani gösterilen kapsam ile yazılan kapsam farklıydı ve fark, bir projenin
/// agent'ı başka projelerin işlerini kuyruğunda bulana kadar görünmüyordu.
///
/// Test kapsamı **iki repoyla** ölçüyor: tek repoyla kurulan bir test,
/// birleştirmenin geri geldiğini de geçerdi.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Bir reponun cihazdaki kopyasına tek görev koyar.
  Future<void> seed(String slug, String fileName, String title) async {
    final path = '${Hub.inboxDir}/$fileName';
    final store = OfflineStore(slug);
    await store.writeTree([
      TreeEntry(path: path, sha: 'sha-$path', isFile: true, size: 10),
    ]);
    await store.writeDoc(
      path,
      StoredDoc(
        sha: 'sha-$path',
        content: '---\n'
            'id: pending\n'
            'title: "$title"\n'
            'priority: high\n'
            'category: gorev\n'
            '---\n\n'
            '# $title\n',
      ),
    );
  }

  void connectBoth({required String active}) {
    FlutterSecureStorage.setMockInitialValues({
      HubConnectionsStore.listKey: jsonEncode([
        {'owner': 'a', 'repo': 'bir', 'token': 't1'},
        {'owner': 'b', 'repo': 'iki', 'token': 't2'},
      ]),
      HubConnectionsStore.activeKey: active,
    });
  }

  Future<ProviderContainer> boot() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(hubConnectionsProvider.future);
    return container;
  }

  test('liste yalnız aktif reponun işlerini gösterir', () async {
    await seed('a/bir', '2026-08-15-a-gorevi.md', 'A görevi');
    await seed('b/iki', '2026-08-15-b-gorevi.md', 'B görevi');
    connectBoth(active: 'a/bir');

    final container = await boot();
    final tasks =
        await container.read(activeRepoPendingTasksProvider.future);

    expect(tasks.map((t) => t.title), ['A görevi']);
    expect(tasks.single.repoSlug, 'a/bir');
  });

  test('repo değişince liste öbür repoya geçer', () async {
    await seed('a/bir', '2026-08-15-a-gorevi.md', 'A görevi');
    await seed('b/iki', '2026-08-15-b-gorevi.md', 'B görevi');
    connectBoth(active: 'a/bir');

    final container = await boot();
    expect(
      (await container.read(activeRepoPendingTasksProvider.future))
          .map((t) => t.title),
      ['A görevi'],
    );

    await container.read(hubConnectionsProvider.notifier).setActive('b/iki');

    // Öbür reponun işi **kaybolmuş** değil, kapsam dışında kalmıştı: repo
    // değişince görünür oluyor.
    expect(
      (await container.read(activeRepoPendingTasksProvider.future))
          .map((t) => t.title),
      ['B görevi'],
    );
  });

  test('kuyruk da aktif repoya daralır, damgasız taslak aktife sayılır',
      () async {
    // Kuyruk daralmasaydı, başka projeye yazılmayı bekleyen bir taslak bu
    // reponun listesinin tepesinde görünürdü — düzeltilen karışıklığın
    // kuyruk tarafından geri getirilmesi.
    TaskDraft draft(String title, [String? slug]) {
      final d = TaskDraft.create(title: title);
      return slug == null ? d : d.forRepo(slug);
    }

    SharedPreferences.setMockInitialValues({
      'outbox': [
        jsonEncode(draft('A taslağı', 'a/bir').toJson()),
        jsonEncode(draft('B taslağı', 'b/iki').toJson()),
        jsonEncode(draft('Damgasız').toJson()),
      ],
    });
    connectBoth(active: 'a/bir');

    final container = await boot();
    await container.read(outboxProvider.future);

    expect(
      container.read(queuedForActiveRepoProvider).map((d) => d.title),
      ['A taslağı', 'Damgasız'],
    );
  });

  test('filtre seçenekleri de aktif repodan türer', () async {
    await seed('a/bir', '2026-08-15-a-gorevi.md', 'A görevi');
    await seed('b/iki', '2026-08-15-b-gorevi.md', 'B görevi');
    connectBoth(active: 'a/bir');

    final container = await boot();
    await container.read(activeRepoPendingTasksProvider.future);

    // Menüde repo boyutu yok; kalan iki boyut listede gerçekten geçen
    // değerlerden türüyor.
    final facets = container.read(taskFacetsProvider);
    expect(facets.priorities, ['high']);
    expect(facets.categories, ['gorev']);
  });
}
