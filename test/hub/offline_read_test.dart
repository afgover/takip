import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/github/trees_api.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/offline_store.dart';
import 'package:takip/hub/task_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter;

/// Çevrimdışıyken görev **açılabiliyor** mu (T-012).
///
/// Şikâyet somuttu: liste görünüyor, göreve tıklayınca "bağlantı yok" çıkıyor.
/// Sebebi de somut — liste yerel kopyadan çiziliyordu (B-057), okuma yolları
/// ağa gidiyordu. Senkron dosyaları zaten indirmişti; eksik olan indirme
/// değil, **okuma yoluydu**.
///
/// Testin ağı **kasten kırık**: her istek atarsa, geçen bir test tek bir şey
/// kanıtlar — o yolda ağa hiç çıkılmadı. "Yerel kopyayı tercih ediyor" demek
/// ölçmeden söylenirse, ağın sessizce devreye girdiği bir sürümde de doğru
/// görünür.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  TaskRepo offlineRepo(OfflineStore store) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
      ..httpClientAdapter = FakeAdapter((options, _) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'test: ağ yok',
        );
      });
    return TaskRepo(
      ContentsApi(dio, owner: 'afgover', repo: 'takip'),
      store: store,
    );
  }

  Future<OfflineStore> storeWith(Map<String, String> docs) async {
    final store = OfflineStore('afgover/takip');
    await store.writeTree([
      for (final path in docs.keys)
        TreeEntry(path: path, sha: 'sha-$path', isFile: true, size: 10),
    ]);
    for (final entry in docs.entries) {
      await store.writeDoc(
        entry.key,
        StoredDoc(sha: 'sha-${entry.key}', content: entry.value),
      );
    }
    return store;
  }

  const taskFile = '''
---
id: T-050
title: "Çevrimdışı okunacak görev"
created_by: agent
priority: high
category: gorev
---

# Çevrimdışı okunacak görev

## İstek
Gövde de yerel kopyadan gelmeli.
''';

  test('ağ yokken bekleyenler listelenir', () async {
    final store = await storeWith({
      'hub/tasks/waiting/2026-08-10-bir-is.md': taskFile,
      'hub/tasks/inbox/2026-08-10-baska-is.md': taskFile,
      // Görev olmayan dosya listeye karışmamalı.
      'hub/SYSTEM.md': '# sözleşme\n',
    });

    final tasks = await offlineRepo(store).listPending();

    expect(tasks.map((t) => t.fileName), [
      '2026-08-10-bir-is.md', // waiting önce (K-022)
      '2026-08-10-baska-is.md',
    ]);
  });

  test('ağ yokken görevin gövdesi açılır — asıl şikâyet buydu', () async {
    const path = 'hub/tasks/waiting/2026-08-10-bir-is.md';
    final store = await storeWith({path: taskFile});

    final repo = offlineRepo(store);
    final summary = (await repo.listPending()).single;
    final task = await repo.read(summary);

    expect(task.title, 'Çevrimdışı okunacak görev');
    expect(task.body, contains('Gövde de yerel kopyadan gelmeli'));
    expect(task.priority, 'high');
  });

  test('ağ yokken tamamlananlar da açılır', () async {
    // Kullanıcı bunu bildirmedi ama aynı kusurdu: `listDone` da ağa gidiyordu.
    // Bildirilen tek örneği düzeltip aynı sınıftaki diğerini bırakmak, hatayı
    // "şikâyet gelene kadar" ertelemek olurdu.
    final store = await storeWith({
      'hub/tasks/done/2026-08-01-biten-is.md': taskFile,
    });

    final done = await offlineRepo(store).listDone();

    expect(done, hasLength(1));
    expect(done.single.status, TaskStatus.done);
  });

  test('yerel kopya yoksa ağa düşülür (davranış değişmedi)', () async {
    // Kopyanın hiç olmadığı durum gerçek: ilk açılış, senkron bitmeden.
    // Orada eski davranış korunmalı — yoksa yeni kurulumda liste boş görünürdü,
    // ki bu "bağlantı yok" demekten daha kötü: hata değil, **yanlış cevap**.
    final store = OfflineStore('afgover/takip'); // ağaç yazılmadı

    await expectLater(
      offlineRepo(store).listPending(),
      throwsA(isA<Object>()),
    );
  });
}
