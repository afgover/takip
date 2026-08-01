import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/hub/models/task.dart';
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

  test('listPending üç klasörü birleştirir; bekleyenler önde, sonra yeniden '
      'eskiye', () async {
    // Her klasör tek görev döndürüyor. `waiting` en ESKİ tarihi taşıyor:
    // tarihe göre sıralansa sona düşerdi — öne gelmesi sıralamanın durumu
    // önceliklendirdiğini kanıtlıyor (K-022).
    const byDir = {
      'inbox': ('2026-07-28-eski-gorev.md', 'aaa'),
      'active': ('2026-07-30-yeni-gorev.md', 'bbb'),
      'waiting': ('2026-07-20-token-uret.md', 'ccc'),
    };

    final built = buildRepo((options, __) {
      final dir = options.path.split('/').last;
      final entry = byDir[dir];
      if (entry == null) return jsonResponse(const []);
      return jsonResponse([
        {
          'name': entry.$1,
          'path': '${options.path}/${entry.$1}',
          'sha': entry.$2,
          'type': 'file',
        },
      ]);
    });

    final tasks = await built.repo.listPending();

    expect(tasks.map((e) => e.title), ['Token uret', 'Yeni gorev', 'Eski gorev']);
    expect(
      tasks.map((e) => e.status),
      [TaskStatus.waiting, TaskStatus.active, TaskStatus.inbox],
    );
    expect(
      built.adapter.requests.map((r) => r.path.split('/').last).toSet(),
      {'inbox', 'active', 'waiting'},
    );
  });

  test('görev olmayan dosyalar listeye girmez', () async {
    final built = buildRepo((options, __) => jsonResponse([
          {
            'name': 'README.md',
            'path': '${options.path}/README.md',
            'sha': 'a',
            'type': 'file'
          },
          {
            'name': '_template.md',
            'path': '${options.path}/_template.md',
            'sha': 'b',
            'type': 'file'
          },
          {
            'name': 'notlar.txt',
            'path': '${options.path}/notlar.txt',
            'sha': 'c',
            'type': 'file'
          },
          {
            'name': 'arsiv-2025',
            'path': '${options.path}/arsiv-2025',
            'sha': 'd',
            'type': 'dir'
          },
          {
            'name': '2026-07-30-gercek-gorev.md',
            'path': '${options.path}/2026-07-30-gercek-gorev.md',
            'sha': 'e',
            'type': 'file'
          },
        ]));

    final tasks = await built.repo.listDone();

    expect(tasks.map((e) => e.fileName), ['2026-07-30-gercek-gorev.md']);
  });

  test('read frontmatter\'ı modele çevirir', () async {
    const content = '''
---
id: T-001
title: "Market listesi"
created_by: user
priority: high
category: gorev
tags: [ev]
result: "Alındı"
---

# Market listesi

## İstek
Süt al.
''';
    final built = buildRepo(
      (_, __) => jsonResponse({
        'path': 'hub/tasks/done/2026-07-30-market.md',
        'sha': 'sha1',
        'encoding': 'base64',
        'content': base64.encode(utf8.encode(content)),
      }),
    );

    final summary = TaskSummary.fromEntry(
      path: 'hub/tasks/done/2026-07-30-market.md',
      name: '2026-07-30-market.md',
      sha: 'sha1',
      status: TaskStatus.done,
    )!;
    final task = await built.repo.read(summary);

    expect(task.id, 'T-001');
    expect(task.title, 'Market listesi');
    expect(task.priority, 'high');
    expect(task.tags, ['ev']);
    expect(task.status, TaskStatus.done);
    expect(task.hasResult, isTrue);
    expect(task.isPending, isFalse);
    expect(task.body, contains('Süt al.'));
    expect(task.sha, 'sha1');
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
