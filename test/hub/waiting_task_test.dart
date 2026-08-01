import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/hub/frontmatter.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/models/task_draft.dart';
import 'package:takip/hub/task_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

HubTask waitingTask({
  String id = 'T-007',
  String title = 'Fine-grained token üret',
}) =>
    HubTask(
      id: id,
      title: title,
      createdBy: 'agent',
      created: '2026-08-01T06:00:00Z',
      updated: '2026-08-01T06:00:00Z',
      priority: 'high',
      category: 'gorev',
      tags: const [],
      session: 'S-2026-08-01-x',
      result: 'none',
      status: TaskStatus.waiting,
      path: '${Hub.waitingDir}/2026-08-01-token-uret.md',
      body: '# Token\n\n## Notlar\nBeklenen: token üretilip uygulamaya girilmesi.\n',
    );

({TaskRepo repo, FakeAdapter adapter}) buildRepo() {
  final adapter = FakeAdapter((options, _) => jsonResponse({
        'content': {'sha': 'yeni'}
      }));
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;
  return (
    repo: TaskRepo(ContentsApi(dio, owner: 'afgover', repo: 'takip')),
    adapter: adapter,
  );
}

void main() {
  group('TaskStatus.waiting', () {
    test('yol klasörden tanınır', () {
      expect(
        TaskStatus.fromPath('${Hub.waitingDir}/2026-08-01-x.md'),
        TaskStatus.waiting,
      );
      expect(TaskStatus.waiting.needsUser, isTrue);
      expect(TaskStatus.active.needsUser, isFalse);
      expect(TaskStatus.inbox.needsUser, isFalse);
      expect(TaskStatus.done.needsUser, isFalse);
    });

    test('waiting yolu inbox/active/done ile karışmaz', () {
      expect(TaskStatus.fromPath('${Hub.inboxDir}/a.md'), TaskStatus.inbox);
      expect(TaskStatus.fromPath('${Hub.activeDir}/a.md'), TaskStatus.active);
      expect(TaskStatus.fromPath('${Hub.doneDir}/a.md'), TaskStatus.done);
    });
  });

  group('"Yaptım" bildirimi', () {
    test('sözleşmeye uygun bir görev üretir ve asıl göreve işaret eder', () {
      final draft = withClock(
        Clock.fixed(DateTime.utc(2026, 8, 1, 10)),
        () => TaskDraft.waitingDone(waitingTask()),
      );

      final fm = Frontmatter.parse(draft.content);
      expect(fm.str('id'), 'pending', reason: 'ID\'yi agent atar');
      expect(fm.str('created_by'), 'user');
      expect(fm.str('title'), 'Fine-grained token üret — yapıldı');
      expect(fm.list('tags'), contains('waiting-done'));

      // Agent'ın hangi görevi kapatacağını bilmesi için yol ve ID gövdede.
      expect(fm.body, contains('${Hub.waitingDir}/2026-08-01-token-uret.md'));
      expect(fm.body, contains('T-007'));

      expect(draft.commitMessage, "task(pending): inbox'a eklendi (app)");
      expect(draft.fileName, startsWith('2026-08-01-'));
    });

    test('önceliği ve kategoriyi asıl görevden devralır', () {
      final draft = TaskDraft.waitingDone(waitingTask());
      final fm = Frontmatter.parse(draft.content);
      expect(fm.str('priority'), 'high');
      expect(fm.str('category'), 'gorev');
    });

    test('başlıksız görevde ID başlığa düşer', () {
      final draft = TaskDraft.waitingDone(waitingTask(title: '   '));
      expect(Frontmatter.parse(draft.content).str('title'), 'T-007 — yapıldı');
    });

    test('bildirim YALNIZCA inbox\'a yazılır (R-001)', () async {
      final built = buildRepo();

      await built.repo.reportWaitingDone(waitingTask());

      expect(built.adapter.requests, hasLength(1));
      final request = built.adapter.requests.single;
      expect(request.method, 'PUT');
      expect(
        Uri.decodeComponent(request.uri.path),
        contains(Hub.inboxDir),
        reason: 'app asıl görevi taşımaz, yalnız haber verir',
      );
      expect(
        Uri.decodeComponent(request.uri.path),
        isNot(contains(Hub.waitingDir)),
      );
      expect(Uri.decodeComponent(request.uri.path), isNot(contains(Hub.doneDir)));
    });

    test('gönderilen içerik sözleşme dosyası olarak geri okunabilir', () async {
      final built = buildRepo();
      await built.repo.reportWaitingDone(waitingTask());

      final sent = jsonDecode(built.adapter.bodies.single!) as Map;
      final decoded = utf8.decode(base64.decode(sent['content'] as String));
      final parsed = HubTask.parse(
        path: '${Hub.inboxDir}/x.md',
        content: decoded,
        status: TaskStatus.inbox,
      );

      expect(parsed.isPending, isTrue);
      expect(parsed.createdBy, 'user');
      expect(parsed.tags, contains('waiting-done'));
    });
  });
}
