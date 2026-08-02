import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/github/client.dart';
import 'package:takip/hub/browse_repo.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/hub_sync.dart';
import 'package:takip/hub/offline_store.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

/// Sahte hub: yol → içerik. SHA içerikten türetilir, böylece içerik
/// değişince SHA de değişir (gerçek git davranışı).
class FakeRemote {
  FakeRemote(this.files);

  Map<String, String> files;
  int treeRequests = 0;
  final downloaded = <String>[];
  bool offline = false;

  static String shaOf(String content) =>
      content.hashCode.toUnsigned(32).toRadixString(16);

  ResponseBody handle(RequestOptions options, String? _) {
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'ağ yok',
      );
    }

    final path = options.uri.path;
    if (path.contains('/git/trees/')) {
      treeRequests++;
      return jsonResponse({
        'truncated': false,
        'tree': [
          for (final entry in files.entries)
            {
              'path': entry.key,
              'sha': shaOf(entry.value),
              'type': 'blob',
              'size': entry.value.length,
            },
        ],
      });
    }

    final marker = '/contents/';
    final index = path.indexOf(marker);
    if (index >= 0) {
      final filePath = Uri.decodeComponent(path.substring(index + marker.length));
      final content = files[filePath];
      if (content == null) return jsonResponse({'message': 'Not Found'}, status: 404);
      downloaded.add(filePath);
      return jsonResponse({
        'path': filePath,
        'sha': shaOf(content),
        'content': base64.encode(utf8.encode(content)),
        'encoding': 'base64',
      });
    }

    return jsonResponse({'message': 'beklenmeyen istek: $path'}, status: 500);
  }
}

Future<({ProviderContainer container, FakeRemote remote})> boot(
  Map<String, String> files,
) async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({
    HubConnectionsStore.listKey: jsonEncode([
      {'owner': 'afgover', 'repo': 'takip', 'token': 't'},
    ]),
  });

  final remote = FakeRemote(files);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = FakeAdapter(remote.handle);

  // Senkron artık API'lerini paylaşılan istemciden kendi kuruyor (her repo
  // için ayrı owner/repo), o yüzden override edilen şey istemcinin kendisi.
  final container = ProviderContainer(
    overrides: [githubDioProvider.overrideWithValue(dio)],
  );
  addTearDown(container.dispose);
  await container.read(hubConnectionsProvider.future);
  // Türetilmiş aktif bağlantı da çözülmeli: API sağlayıcıları onu izliyor.
  await container.read(hubConfigProvider.future);
  return (container: container, remote: remote);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hub = {
    'hub/BACKLOG.md': '# Backlog',
    'hub/SYSTEM.md': '# Sözleşme',
    'hub/sessions/2026-08-01-x/session.md': '# Oturum',
    'lib/main.dart': 'void main() {}', // kod indirilmemeli
    'hub/logo.png': 'binary', // markdown olmayan indirilmemeli
  };

  test('ilk senkron hub markdown dosyalarını indirir, kodu indirmez', () async {
    final t = await boot(hub);
    await t.container.read(hubSyncProvider.notifier).syncNow();

    expect(t.remote.downloaded, hasLength(3));
    expect(t.remote.downloaded, isNot(contains('lib/main.dart')));
    expect(t.remote.downloaded, isNot(contains('hub/logo.png')));

    final status = t.container.read(hubSyncProvider);
    expect(status.docCount, 3);
    expect(status.syncing, isFalse);
    expect(status.error, isNull);
    expect(status.hasOfflineCopy, isTrue);
  });

  test('değişmeyen dosya ikinci senkronda yeniden indirilmez', () async {
    final t = await boot(hub);
    final notifier = t.container.read(hubSyncProvider.notifier);

    await notifier.syncNow();
    t.remote.downloaded.clear();
    await notifier.syncNow();

    expect(t.remote.downloaded, isEmpty,
        reason: 'SHA değişmediyse indirmenin anlamı yok');
    // Ağaç yine de sorulur — değişiklik ancak böyle görülür.
    expect(t.remote.treeRequests, 2);
  });

  test('yalnızca değişen dosya yeniden indirilir', () async {
    final t = await boot(hub);
    final notifier = t.container.read(hubSyncProvider.notifier);
    await notifier.syncNow();
    t.remote.downloaded.clear();

    t.remote.files = {...hub, 'hub/BACKLOG.md': '# Backlog (guncellendi)'};
    await notifier.syncNow();

    expect(t.remote.downloaded, ['hub/BACKLOG.md']);

    final store = t.container.read(offlineStoreProvider)!;
    expect((await store.readDoc('hub/BACKLOG.md'))?.content,
        '# Backlog (guncellendi)');
  });

  test('hub\'dan silinen dosya yerel kopyadan da düşer', () async {
    final t = await boot(hub);
    final notifier = t.container.read(hubSyncProvider.notifier);
    await notifier.syncNow();

    final store = t.container.read(offlineStoreProvider)!;
    expect(await store.readDoc('hub/SYSTEM.md'), isNotNull);

    t.remote.files = {...hub}..remove('hub/SYSTEM.md');
    await notifier.syncNow();

    expect(await store.readDoc('hub/SYSTEM.md'), isNull,
        reason: 'hub\'da olmayan belge listede kalmamalı');
    expect(t.container.read(hubSyncProvider).docCount, 2);
  });

  test('ağ yokken var olan kopya bozulmaz', () async {
    final t = await boot(hub);
    final notifier = t.container.read(hubSyncProvider.notifier);
    await notifier.syncNow();

    t.remote.offline = true;
    await notifier.syncNow();

    final status = t.container.read(hubSyncProvider);
    expect(status.error, isNotNull);
    expect(status.docCount, 3, reason: 'elde olan kopya silinmemeli');

    final store = t.container.read(offlineStoreProvider)!;
    expect((await store.readDoc('hub/BACKLOG.md'))?.content, '# Backlog');
  });

  test('tarayıcı yerel kopyadan okur, ağa gitmez', () async {
    final t = await boot(hub);
    await t.container.read(hubSyncProvider.notifier).syncNow();

    t.remote.offline = true; // bundan sonra her istek patlar
    final browse = t.container.read(browseRepoProvider);

    expect(await browse.readDoc('hub/BACKLOG.md'), '# Backlog');
    final sessions = await browse.sessions();
    expect(sessions.map((d) => d.path),
        ['hub/sessions/2026-08-01-x/session.md']);
  });

  test('yerel kopya silinince sayaç sıfırlanır', () async {
    final t = await boot(hub);
    final notifier = t.container.read(hubSyncProvider.notifier);
    await notifier.syncNow();

    await notifier.clearOfflineCopy();

    final status = t.container.read(hubSyncProvider);
    expect(status.docCount, 0);
    expect(status.hasOfflineCopy, isFalse);
    expect(status.syncedAt, isNull);
    expect(
      await t.container.read(offlineStoreProvider)!.readDoc('hub/BACKLOG.md'),
      isNull,
    );
  });

  test('kopya repo başına ayrı tutulur', () async {
    final t = await boot(hub);
    await t.container.read(hubSyncProvider.notifier).syncNow();

    // Aynı cihazda ikinci repo: onun deposu boş olmalı.
    const other = OfflineStore('afgover/baska');
    expect(await other.readDoc('hub/BACKLOG.md'), isNull);
    expect(await other.readTree(), isNull);

    // İlk reponunki yerinde duruyor.
    final mine = t.container.read(offlineStoreProvider)!;
    expect(await mine.readDoc('hub/BACKLOG.md'), isNotNull);
  });

  test('bir reponun kopyası silinince diğeri etkilenmez', () async {
    final t = await boot(hub);
    await t.container.read(hubSyncProvider.notifier).syncNow();

    const other = OfflineStore('afgover/baska');
    await other.writeDoc(
      'hub/BACKLOG.md',
      const StoredDoc(sha: 'x', content: 'öteki repo'),
    );

    await t.container.read(hubSyncProvider.notifier).clearOfflineCopy();

    expect((await other.readDoc('hub/BACKLOG.md'))?.content, 'öteki repo');
  });

  test('üst üste çağrılan senkron tek kez koşar', () async {
    final t = await boot(hub);
    final notifier = t.container.read(hubSyncProvider.notifier);

    await Future.wait([notifier.syncNow(), notifier.syncNow()]);

    expect(t.remote.treeRequests, 1);
    expect(t.remote.downloaded, hasLength(3));
  });
}
