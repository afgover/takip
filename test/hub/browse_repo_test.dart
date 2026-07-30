import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/errors.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/github/trees_api.dart';
import 'package:takip/hub/browse_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

const _paths = [
  'README.md',
  'lib/main.dart',
  'hub/SYSTEM.md',
  'hub/BACKLOG.md',
  'hub/sessions/2026-07-28-altyapi/session.md',
  'hub/sessions/2026-07-30-hub-tasima/session.md',
  'hub/artifacts/README.md',
  'hub/artifacts/reference/flutter-app-design.md',
  'hub/artifacts/S-2026-07-30-x/2026-07-30-rapor.md',
  'hub/tasks/inbox/README.md',
  'hub/knowledge/rules.md',
];

({BrowseRepo repo, FakeAdapter adapter}) boot({
  Map<String, String> files = const {},
  bool truncated = false,
}) {
  final adapter = FakeAdapter((options, _) {
    if (options.path.contains('/git/trees/')) {
      return jsonResponse({
        'sha': 'tree-sha',
        'truncated': truncated,
        'tree': [
          for (final path in _paths)
            {'path': path, 'sha': 'sha-$path', 'type': 'blob'},
          {'path': 'hub/sessions', 'sha': 'sha-dir', 'type': 'tree'},
        ],
      });
    }

    final path = Uri.decodeFull(options.path.split('/contents/').last);
    final content = files[path];
    if (content == null) {
      return jsonResponse({'message': 'Not Found'}, status: 404);
    }
    return jsonResponse({
      'path': path,
      'sha': 'sha1',
      'encoding': 'base64',
      'content': base64.encode(utf8.encode(content)),
    });
  });

  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;

  return (
    repo: BrowseRepo(
      TreesApi(dio, owner: 'afgover', repo: 'takip'),
      ContentsApi(dio, owner: 'afgover', repo: 'takip'),
    ),
    adapter: adapter,
  );
}

void main() {
  test('oturumlar tek ağaç isteğiyle, yeniden eskiye listelenir', () async {
    final built = boot();

    final sessions = await built.repo.sessions();

    expect(sessions.map((d) => d.title), ['Hub tasima', 'Altyapi']);
    expect(built.adapter.requests, hasLength(1),
        reason: 'klasör klasör gezilmemeli');
  });

  test('artifact listesi README ve kod dosyalarını almaz', () async {
    final built = boot();

    final artifacts = await built.repo.artifacts();

    expect(
      artifacts.map((d) => d.path),
      containsAll([
        'hub/artifacts/reference/flutter-app-design.md',
        'hub/artifacts/S-2026-07-30-x/2026-07-30-rapor.md',
      ]),
    );
    expect(artifacts.map((d) => d.path), isNot(contains('hub/artifacts/README.md')));
    expect(artifacts.map((d) => d.path), isNot(contains('lib/main.dart')));
  });

  test('artifact başlığı ve türü frontmatter\'dan tamamlanır', () async {
    final built = boot(files: {
      'hub/artifacts/reference/flutter-app-design.md':
          '---\nid: A-1\ntype: design\ntitle: "Flutter uygulama tasarımı"\n---\n\ngövde',
      'hub/artifacts/S-2026-07-30-x/2026-07-30-rapor.md':
          '---\nid: A-2\ntype: report\ntitle: "İzin modeli araştırması"\n---\n\ngövde',
    });

    final artifacts = await built.repo.artifactsWithMetadata();

    expect(
      artifacts.map((d) => d.title),
      containsAll(['Flutter uygulama tasarımı', 'İzin modeli araştırması']),
    );
    expect(artifacts.map((d) => d.subtitle), containsAll(['design', 'report']));
  });

  test('okunamayan artifact listeden düşmez', () async {
    // Yalnız biri okunabiliyor; diğeri 404.
    final built = boot(files: {
      'hub/artifacts/reference/flutter-app-design.md':
          '---\ntype: design\ntitle: "Tasarım"\n---\n\ngövde',
    });

    final artifacts = await built.repo.artifactsWithMetadata();

    expect(artifacts, hasLength(2));
    expect(artifacts.where((d) => d.subtitle == null), hasLength(1));
  });

  test('bilgi tabanı dosyası kayıtlara ayrılır', () async {
    final built = boot(files: {
      'hub/knowledge/rules.md': '# Kurallar\n\n## R-001 — Bir kural\n'
          '- **Tarih:** 2026-07-30\n- **Açıklama:** metin\n',
    });

    final entries = await built.repo.knowledge(KnowledgeFile.rules);

    expect(entries.single.id, 'R-001');
    expect(entries.single.title, 'Bir kural');
  });

  test('ağaç kırpılmışsa sessizce eksik liste gösterilmez', () async {
    final built = boot(truncated: true);

    expect(built.repo.sessions(), throwsA(isA<HubUnexpectedError>()));
  });
}
