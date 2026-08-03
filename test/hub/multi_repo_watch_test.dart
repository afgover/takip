import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/github/client.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/hub_sync.dart';
import 'package:takip/hub/hub_watcher.dart';
import 'package:takip/hub/offline_store.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

/// Yoklamanın **bütün bağlantıları** izlemesi.
///
/// Senkron (`HubSync`) baştan beri tüm repoları indiriyor, ama tetikleyicisi
/// yalnız aktif reponun son commit'iydi. Sonuç: aktif olmayan bir repoya
/// yapılan push hiçbir sinyal üretmiyordu — kullanıcı financer'a yazılan
/// güncellemeyi uygulamada göremiyordu. Bekleyenler'i de vuruyordu, çünkü o
/// liste açıkça repolar arası.
/// Tetiklenen senkron arka planda koşuyor; ölçmeden önce bitmesi beklenir.
Future<void> settle() async {
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeAdapter adapter;
  late ProviderContainer container;
  var takipSha = 'takip-1';
  var financerSha = 'fin-1';

  setUp(() {
    takipSha = 'takip-1';
    financerSha = 'fin-1';

    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      HubConnectionsStore.listKey: jsonEncode([
        {'owner': 'afgover', 'repo': 'takip', 'token': 'token-takip'},
        {'owner': 'afgover', 'repo': 'financer_takip', 'token': 'token-fin'},
      ]),
      HubConnectionsStore.activeKey: 'afgover/takip',
    });

    adapter = FakeAdapter((options, _) {
      final path = Uri.decodeFull(options.path);
      final sha = path.contains('financer_takip') ? financerSha : takipSha;
      return jsonResponse([
        {'sha': sha},
      ]);
    });

    container = ProviderContainer();
    container.read(githubDioProvider).httpClientAdapter = adapter;
  });

  tearDown(() => container.dispose());

  test('yoklama her bağlantının başını okur', () async {
    await container.read(hubConnectionsProvider.future);
    await container.read(hubWatcherProvider.notifier).checkNow();

    final heads = container.read(hubWatcherProvider).heads;
    expect(heads['afgover/takip'], 'takip-1');
    expect(
      heads['afgover/financer_takip'],
      'fin-1',
      reason: 'aktif olmayan repo da izlenmeli',
    );
  });

  test('aktif olmayan repodaki değişiklik görülür', () async {
    await container.read(hubConnectionsProvider.future);
    final watcher = container.read(hubWatcherProvider.notifier);
    await watcher.checkNow();

    // Kullanıcı takip'te; financer'a push yapılıyor.
    financerSha = 'fin-2';
    await watcher.checkNow();

    final status = container.read(hubWatcherProvider);
    expect(status.heads['afgover/financer_takip'], 'fin-2');
    expect(
      status.headSha,
      'takip-1',
      reason: 'aktif reponun başı değişmedi — o alan aktif repoyu anlatır',
    );
    expect(
      status.changedSlugs,
      contains('afgover/financer_takip'),
      reason: 'senkronun tetiklenmesi için değişiklik bildirilmeli',
    );
  });

  test('hiçbir şey değişmediyse değişiklik bildirilmez', () async {
    await container.read(hubConnectionsProvider.future);
    final watcher = container.read(hubWatcherProvider.notifier);
    await watcher.checkNow();
    await watcher.checkNow();

    expect(container.read(hubWatcherProvider).changedSlugs, isEmpty);
  });

  test('her bağlantı kendi tokeniyle yoklanır (L-019)', () async {
    await container.read(hubConnectionsProvider.future);
    await container.read(hubWatcherProvider.notifier).checkNow();

    for (final request in adapter.requests) {
      final expected = Uri.decodeFull(request.path).contains('financer_takip')
          ? 'token-fin'
          : 'token-takip';
      expect(request.headers['Authorization'], contains(expected));
    }
  });

  test('aktif olmayan repodaki değişiklik cihazdaki kopyaya iner', () async {
    // Kullanıcının bildirdiği durumun tamamı: takip aktifken financer_takip'e
    // push yapılıyor ve uygulamada hiçbir şey değişmiyordu. Zincirin üç halkası
    // da burada: yoklama → senkron tetiği → cihazdaki kopya.
    var financerDoc = 'eski içerik';

    adapter = FakeAdapter((options, _) {
      final path = Uri.decodeFull(options.path);
      final isFinancer = path.contains('financer_takip');

      if (path.contains('/commits')) {
        return jsonResponse([
          {'sha': isFinancer ? financerSha : takipSha},
        ]);
      }
      if (path.contains('/git/trees/')) {
        return jsonResponse({
          'truncated': false,
          'tree': [
            {
              'path': 'hub/artifacts/reference/guvenlik-durusu.md',
              'sha': isFinancer ? financerSha : 'takip-blob',
              'type': 'blob',
            },
          ],
        });
      }
      return jsonResponse({
        'path': 'hub/artifacts/reference/guvenlik-durusu.md',
        'sha': isFinancer ? financerSha : 'takip-blob',
        'encoding': 'base64',
        'content':
            base64.encode(utf8.encode(isFinancer ? financerDoc : 'takip')),
      });
    });
    container.dispose();
    container = ProviderContainer();
    container.read(githubDioProvider).httpClientAdapter = adapter;

    await container.read(hubConnectionsProvider.future);
    container.read(hubSyncProvider); // dinleyici kurulsun
    final watcher = container.read(hubWatcherProvider.notifier);

    // Senkron **elle çağrılmıyor**: sınanan şey tam olarak yoklamanın onu
    // kendiliğinden tetiklemesi.
    await watcher.checkNow();
    await settle();

    // financer'a push: **aktif repo takip, başı değişmiyor.**
    financerDoc = 'güvenlik duruşu belgesi';
    financerSha = 'fin-2';
    await watcher.checkNow();
    await settle();

    final stored = await OfflineStore('afgover/financer_takip')
        .readDoc('hub/artifacts/reference/guvenlik-durusu.md');
    expect(
      stored?.content,
      'güvenlik duruşu belgesi',
      reason: 'aktif olmayan repodaki güncelleme cihaza inmeli',
    );
  });
}
