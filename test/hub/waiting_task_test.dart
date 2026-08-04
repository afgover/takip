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

  group('seçenekli bekleme (sözleşme 1.12)', () {
    HubTask question({List<String> options = const ['Evet', 'Hayır'],
        bool multi = false, TaskStatus status = TaskStatus.waiting}) {
      final base = waitingTask();
      return HubTask(
        id: base.id,
        title: base.title,
        createdBy: base.createdBy,
        created: base.created,
        updated: base.updated,
        priority: base.priority,
        category: base.category,
        tags: base.tags,
        session: base.session,
        result: base.result,
        status: status,
        path: base.path,
        body: base.body,
        options: options,
        multi: multi,
      );
    }

    test('options/multi frontmatter\'dan okunur', () {
      final parsed = HubTask.parse(
        path: '${Hub.waitingDir}/2026-08-04-x.md',
        content: '---\nid: T-009\ntitle: "Soru"\n'
            'options: ["Evet", "Hayır"]\nmulti: "true"\n---\n\ngövde\n',
        status: TaskStatus.waiting,
      );

      expect(parsed.options, ['Evet', 'Hayır']);
      expect(parsed.multi, isTrue);
      expect(parsed.isQuestion, isTrue);
    });

    test('seçeneksiz görev soru değildir — 1.11 davranışı korunur', () {
      expect(waitingTask().isQuestion, isFalse);
      expect(waitingTask().options, isEmpty);
      expect(waitingTask().multi, isFalse);
    });

    test('soru yalnız waiting/\'te sorulur', () {
      // Başka klasördeki bir dosyada options bulunsa bile o iş kullanıcıyı
      // beklemiyordur; cevap düğmesi çıkmamalı.
      expect(question(status: TaskStatus.active).isQuestion, isFalse);
      expect(question(status: TaskStatus.inbox).isQuestion, isFalse);
    });

    test('cevap sözleşmeye uygun bildirim üretir', () {
      final draft = withClock(
        Clock.fixed(DateTime.utc(2026, 8, 4, 10)),
        () => TaskDraft.waitingAnswer(
          question(),
          selected: const ['Evet'],
          note: 'yarın yaparım',
        ),
      );

      final fm = Frontmatter.parse(draft.content);
      expect(fm.str('id'), 'pending');
      expect(fm.str('created_by'), 'user');
      expect(fm.str('title'), 'Fine-grained token üret — cevaplandı');
      expect(fm.list('tags'), contains('waiting-answer'));
      expect(fm.body, contains('**Seçim:** Evet'));
      expect(fm.body, contains('**Açıklama:** yarın yaparım'));
      // Agent hangi görevin cevaplandığını bilmeli.
      expect(fm.body, contains('${Hub.waitingDir}/2026-08-01-token-uret.md'));
      expect(fm.body, contains('T-007'));
    });

    test('çoklu seçim tek satırda birleşir', () {
      final draft = TaskDraft.waitingAnswer(
        question(multi: true),
        selected: const ['Evet', 'Hayır'],
      );
      expect(Frontmatter.parse(draft.content).body,
          contains('**Seçim:** Evet · Hayır'));
    });

    test('açıklama boşsa satır hiç yazılmaz', () {
      final draft = TaskDraft.waitingAnswer(question(), selected: const ['Evet']);
      expect(Frontmatter.parse(draft.content).body,
          isNot(contains('Açıklama')));
    });

    test('cevap geri okunabilir bir sözleşme dosyasıdır', () {
      final draft = TaskDraft.waitingAnswer(question(), selected: const ['Evet']);
      final parsed = HubTask.parse(
        path: '${Hub.inboxDir}/x.md',
        content: draft.content,
        status: TaskStatus.inbox,
      );
      expect(parsed.isPending, isTrue);
      expect(parsed.tags, contains('waiting-answer'));
    });

    test('options yazan görev dosyası aynen geri okunur (round-trip)', () {
      final content = question(multi: true).toFileContent();
      final parsed = HubTask.parse(
        path: '${Hub.waitingDir}/x.md',
        content: content,
        status: TaskStatus.waiting,
      );
      expect(parsed.options, ['Evet', 'Hayır']);
      expect(parsed.multi, isTrue);
    });
  });
}
