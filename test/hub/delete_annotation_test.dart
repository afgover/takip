import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/hub/task_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

({TaskRepo repo, FakeAdapter adapter}) buildRepo({required bool exists}) {
  final adapter = FakeAdapter((options, _) {
    if (options.method == 'GET') {
      if (!exists) return jsonResponse({'message': 'Not Found'}, status: 404);
      return jsonResponse({
        'path': '${Hub.inboxDir}/2026-08-03-x.md',
        'sha': 'sha1',
        'content': base64.encode(utf8.encode('---\nid: pending\n---\n')),
        'encoding': 'base64',
      });
    }
    return jsonResponse({'commit': {'sha': 'yeni'}});
  });
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;
  return (
    repo: TaskRepo(ContentsApi(dio, owner: 'afgover', repo: 'takip')),
    adapter: adapter,
  );
}

void main() {
  test('inbox\'taki kayıt silinir', () async {
    final t = buildRepo(exists: true);

    expect(await t.repo.deleteFromInbox('2026-08-03-x.md'), isTrue);

    final deletes = t.adapter.requests.where((r) => r.method == 'DELETE');
    expect(deletes, hasLength(1));
    expect(
      Uri.decodeComponent(deletes.single.uri.path),
      contains(Hub.inboxDir),
    );
  });

  test('agent almışsa dosya inbox\'ta yok — silme denenmez', () async {
    final t = buildRepo(exists: false);

    expect(await t.repo.deleteFromInbox('2026-08-03-x.md'), isFalse,
        reason: 'ele alınmış iş sessizce yok edilmemeli');
    expect(t.adapter.requests.any((r) => r.method == 'DELETE'), isFalse);
  });

  test('yol verilirse reddedilir (R-001 yapısal kapısı)', () async {
    final t = buildRepo(exists: true);

    expect(
      () => t.repo.deleteFromInbox('../active/2026-08-03-x.md'),
      throwsA(isA<ArgumentError>()),
    );
    expect(t.adapter.requests, isEmpty);
  });
}
