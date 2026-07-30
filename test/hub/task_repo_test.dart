import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/hub/task_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

({TaskRepo repo, FakeAdapter adapter}) buildRepo(
  ResponseBody Function(RequestOptions options, String? body) handler,
) {
  final adapter = FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;
  return (
    repo: TaskRepo(ContentsApi(dio, owner: 'afgover', repo: 'takip')),
    adapter: adapter,
  );
}

void main() {
  group('R-001 — app yalnızca inbox\'a yazar', () {
    test('writeToInbox yolu her zaman hub/tasks/inbox/ altına kurar', () async {
      final built = buildRepo(
        (_, __) => jsonResponse({
          'content': {'sha': 'yeni'}
        }),
      );

      await built.repo.writeToInbox(
        '2026-07-30-market-listesi.md',
        content: '---\nid: pending\n---\n',
        commitMessage: 'task(pending): inbox\'a eklendi (app)',
      );

      expect(
        built.adapter.requests.single.path,
        '/repos/afgover/takip/contents/hub/tasks/inbox/'
        '2026-07-30-market-listesi.md',
      );
    });

    test('dosya adı yerine yol verilirse reddedilir', () {
      final built = buildRepo((_, __) => jsonResponse({}));

      expect(
        () => built.repo.writeToInbox(
          '../sessions/kacak.md',
          content: 'x',
          commitMessage: 'm',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(built.adapter.requests, isEmpty);
    });
  });

  test('listPending inbox ve active\'i birleştirir', () async {
    final built = buildRepo((options, __) {
      final isInbox = options.path.endsWith('inbox');
      return jsonResponse([
        {
          'name': isInbox ? 'a.md' : 'b.md',
          'path': '${options.path}/x.md',
          'sha': isInbox ? 'aaa' : 'bbb',
          'type': 'file',
        },
      ]);
    });

    final entries = await built.repo.listPending();

    expect(entries.map((e) => e.name), ['a.md', 'b.md']);
    expect(
      built.adapter.requests.map((r) => r.path.split('/').last),
      ['inbox', 'active'],
    );
  });

  test('boş inbox hata değil, boş liste verir', () async {
    final built = buildRepo(
      (_, __) => jsonResponse({'message': 'Not Found'}, status: 404),
    );

    expect(await built.repo.listPending(), isEmpty);
    expect(await built.repo.listDone(), isEmpty);
  });

  test('gönderilen içerik base64 sonrası bozulmadan çözülür', () async {
    final built = buildRepo(
      (_, __) => jsonResponse({
        'content': {'sha': 'yeni'}
      }),
    );
    const body = '---\ntitle: "Şeker ığdır öğün"\n---\n\n# Başlık\n';

    await built.repo.writeToInbox(
      '2026-07-30-test.md',
      content: body,
      commitMessage: 'm',
    );

    final sent = jsonDecode(built.adapter.bodies.single!) as Map;
    expect(utf8.decode(base64.decode(sent['content'] as String)), body);
  });
}
