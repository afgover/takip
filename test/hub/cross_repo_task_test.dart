import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/github/client.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/task_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

/// Bekleyenler artık **bütün repoların** işlerini birlikte gösteriyor. O
/// listeden bir göreve dokunulduğunda görev, aktif repodan değil **kendi**
/// reposundan okunmalı; yoksa aktif repoda o dosya bulunmadığı için ekranda
/// "bulunamadı" çıkıyor — kullanıcının financer görevlerinde gördüğü buydu.
void main() {
  late FakeAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      HubConnectionsStore.listKey: jsonEncode([
        {'owner': 'afgover', 'repo': 'takip', 'token': 'token-takip'},
        {'owner': 'afgover', 'repo': 'financer_takip', 'token': 'token-fin'},
      ]),
      // Aktif repo takip; financer görevine dokunulacak.
      HubConnectionsStore.activeKey: 'afgover/takip',
    });

    adapter = FakeAdapter((options, _) {
      return jsonResponse({
        'path': Uri.decodeFull(options.path.split('/contents/').last),
        'sha': 'sha1',
        'encoding': 'base64',
        'content': base64.encode(utf8.encode(
          '---\nid: T-009\ntitle: financer görevi\n---\n\n# İçerik\n',
        )),
      });
    });

    // Gerçek `githubDioProvider` kullanılıyor, yalnız taşıma katmanı
    // değiştiriliyor: token'ı isteğin yoluna göre seçen interceptor da
    // testin kapsamına girsin — asıl doğrulanan o.
    container = ProviderContainer();
    container.read(githubDioProvider).httpClientAdapter = adapter;
  });

  tearDown(() => container.dispose());

  TaskSummary summaryIn(String? slug) => TaskSummary(
        path: '${Hub.waitingDir}/2026-08-03-yedek-al.md',
        fileName: '2026-08-03-yedek-al.md',
        sha: 'sha1',
        status: TaskStatus.waiting,
        date: DateTime.parse('2026-08-03'),
        title: 'Yedek al',
        repoSlug: slug,
      );

  test('görev kendi reposundan okunur, aktif repodan değil', () async {
    // Bağlantılar yüklensin.
    await container.read(hubConnectionsProvider.future);

    final task = await container
        .read(taskDetailProvider(summaryIn('afgover/financer_takip')).future);

    expect(task.title, 'financer görevi');

    final request = adapter.requests.single;
    expect(
      request.uri.path,
      contains('/repos/afgover/financer_takip/contents/'),
      reason: 'aktif repo takip olsa da istek financer_takip\'e gitmeli',
    );
    expect(
      request.headers['Authorization'],
      contains('token-fin'),
      reason: 'her repo kendi tokeniyle okunur (L-019)',
    );
  });

  test('repo bilgisi olmayan görev aktif repodan okunur', () async {
    await container.read(hubConnectionsProvider.future);

    await container.read(taskDetailProvider(summaryIn(null)).future);

    expect(
      adapter.requests.single.uri.path,
      contains('/repos/afgover/takip/contents/'),
    );
  });
}
