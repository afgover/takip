import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/errors.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/hub/models/task_draft.dart';
import 'package:takip/hub/task_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

TaskDraft draft(String title) => withClock(
      Clock.fixed(DateTime.utc(2026, 7, 30)),
      () => TaskDraft.create(title: title, description: 'açıklama'),
    );

/// Hub'ı taklit eden basit dosya sistemi: PUT var olan yola yazmaya
/// çalışırsa GitHub gibi çakışma verir.
({TaskRepo repo, FakeAdapter adapter, Map<String, String> files}) boot({
  Map<String, String> initial = const {},
}) {
  final files = {...initial};

  final adapter = FakeAdapter((options, body) {
    final path = Uri.decodeFull(options.path.split('/contents/').last);

    if (options.method == 'GET') {
      final content = files[path];
      if (content == null) {
        return jsonResponse({'message': 'Not Found'}, status: 404);
      }
      return jsonResponse({
        'path': path,
        'sha': 'sha-${content.hashCode}',
        'encoding': 'base64',
        'content': base64.encode(utf8.encode(content)),
      });
    }

    // PUT: sha verilmeden var olan dosyaya yazmak GitHub'da 422'dir.
    final sent = jsonDecode(body!) as Map<String, dynamic>;
    if (files.containsKey(path) && sent['sha'] == null) {
      return jsonResponse(
        {'message': 'Invalid request. "sha" wasn\'t supplied.'},
        status: 422,
      );
    }
    files[path] = utf8.decode(base64.decode(sent['content'] as String));
    return jsonResponse({
      'content': {'sha': 'sha-${files[path].hashCode}'}
    });
  });

  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;

  return (
    repo: TaskRepo(ContentsApi(dio, owner: 'afgover', repo: 'takip')),
    adapter: adapter,
    files: files,
  );
}

void main() {
  test('aynı görev ikinci kez gönderilirse kopya oluşmaz', () async {
    // Gerçek senaryo: yazma başarılı oldu ama yanıt kaybolduğu için outbox
    // aynı taslağı yeniden gönderiyor.
    final t = boot();
    final task = draft('Market listesi');

    final first = await t.repo.send(task);
    final second = await t.repo.send(task);

    expect(t.files.keys, ['hub/tasks/inbox/2026-07-30-market-listesi.md']);
    expect(second.fileName, first.fileName);
  });

  test('aynı gün aynı başlıkla farklı görev, ad sonuna sayı alır', () async {
    final t = boot();

    await t.repo.send(draft('Market listesi'));
    final second = await t.repo.send(
      withClock(
        Clock.fixed(DateTime.utc(2026, 7, 30)),
        () => TaskDraft.create(
          title: 'Market listesi',
          description: 'bambaşka bir iş',
        ),
      ),
    );

    expect(second.fileName, '2026-07-30-market-listesi-2.md');
    expect(t.files, hasLength(2));
    // İlk görevin içeriği korunmalı.
    expect(
      t.files['hub/tasks/inbox/2026-07-30-market-listesi.md'],
      contains('açıklama'),
    );
  });

  test('üçüncü çakışmada numara ilerler', () async {
    final t = boot();
    for (var i = 1; i <= 3; i++) {
      await t.repo.send(
        withClock(
          Clock.fixed(DateTime.utc(2026, 7, 30)),
          () => TaskDraft.create(title: 'Rapor', description: 'sürüm $i'),
        ),
      );
    }

    expect(t.files.keys.map((k) => k.split('/').last).toList()..sort(), [
      '2026-07-30-rapor-2.md',
      '2026-07-30-rapor-3.md',
      '2026-07-30-rapor.md',
    ]);
  });

  test('çakışma çözülemezse anlaşılır hata verir', () async {
    // Beş ad da doluyken pes edilir; sessizce üstüne yazılmaz.
    final files = {
      for (final name in [
        '2026-07-30-rapor.md',
        '2026-07-30-rapor-2.md',
        '2026-07-30-rapor-3.md',
        '2026-07-30-rapor-4.md',
        '2026-07-30-rapor-5.md',
      ])
        'hub/tasks/inbox/$name': 'başka içerik',
    };
    final t = boot(initial: files);

    await expectLater(
      t.repo.send(draft('Rapor')),
      throwsA(isA<HubConflictError>()),
    );
    expect(t.files.values, everyElement('başka içerik'));
  });

  test('çakışma sonrası dosya silinmişse aynı adla yazılır', () async {
    var putCount = 0;
    final files = <String, String>{};

    final adapter = FakeAdapter((options, body) {
      final path = Uri.decodeFull(options.path.split('/contents/').last);
      if (options.method == 'GET') {
        // Çakışmayı okumaya gittiğimizde dosya artık yok (agent taşımış).
        return jsonResponse({'message': 'Not Found'}, status: 404);
      }
      putCount++;
      if (putCount == 1) {
        return jsonResponse(
          {'message': 'Invalid request. "sha" wasn\'t supplied.'},
          status: 422,
        );
      }
      files[path] = 'yazıldı';
      return jsonResponse({
        'content': {'sha': 'sha1'}
      });
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
      ..httpClientAdapter = adapter;
    final repo = TaskRepo(ContentsApi(dio, owner: 'afgover', repo: 'takip'));

    final result = await repo.send(draft('Market listesi'));

    expect(result.fileName, '2026-07-30-market-listesi.md',
        reason: 'gereksiz yere -2 açılmamalı');
    expect(files.keys, ['hub/tasks/inbox/2026-07-30-market-listesi.md']);
  });
}
