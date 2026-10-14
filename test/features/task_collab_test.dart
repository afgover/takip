import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/pending/task_collab.dart';
import 'package:takip/features/pending/task_detail_screen.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/hub/all_tasks.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/models/task_event.dart';
import 'package:takip/hub/task_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;
import '../helpers/test_app.dart';

class _Login extends HubConfigNotifier {
  @override
  Future<HubConfig?> build() async =>
      const HubConfig(owner: 'afgover', repo: 'takip', token: 't', login: 'afgover');
}

const _path = 'hub/tasks/active/2026-10-15-kira-odemesi.md';

TaskSummary get _summary => TaskSummary.fromEntry(
      path: _path,
      name: '2026-10-15-kira-odemesi.md',
      sha: 'sha',
      status: TaskStatus.active,
    )!;

HubTask _task({String? assignee = 'fatih', String body = ''}) => HubTask(
      id: 'T-040',
      title: 'Kira ödemesi',
      createdBy: 'user',
      created: '2026-10-15T09:00:00Z',
      updated: '2026-10-15T09:00:00Z',
      priority: 'high',
      category: 'gorev',
      tags: const [],
      session: 'none',
      result: 'none',
      status: TaskStatus.active,
      path: _path,
      assignee: assignee,
      body: body,
    );

/// Gönderilen dosyaların içerikleri (PUT gövdesinden).
final sent = <String>[];

Widget _screen(HubTask task, {List<TaskEvent> events = const []}) {
  final adapter = FakeAdapter((options, body) {
    if (options.method == 'PUT' && body != null) {
      sent.add(utf8.decode(base64.decode(
          (jsonDecode(body) as Map<String, dynamic>)['content'] as String)));
    }
    return jsonResponse({
      'content': {'sha': 'yeni'}
    });
  });
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;
  return ProviderScope(
    overrides: [
      hubConfigProvider.overrideWith(_Login.new),
      taskRepoProvider.overrideWithValue(
          TaskRepo(ContentsApi(dio, owner: 'afgover', repo: 'takip'))),
      taskDetailProvider.overrideWith((ref, _) async => task),
      taskEventsProvider.overrideWith((ref, _) async => events),
      activeRepoPendingTasksProvider.overrideWith((ref) async => const []),
    ],
    child: testApp(TaskDetailScreen(summary: _summary)),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sent.clear();
  });

  testWidgets('işlenmiş ve bekleyen yorumlar akışta; belgede ikinci kez yok',
      (tester) async {
    await tester.pumpWidget(_screen(
      _task(body: '# Kira ödemesi\n\n## İstek\nÖde.\n\n## Yorumlar\n\n'
          '### [2026-10-15 11:05] @fatih\nIBAN değişti.\n'),
      events: const [
        TaskEvent(
          kind: TaskEventKind.comment,
          target: '2026-10-15-kira-odemesi.md',
          path: 'hub/tasks/inbox/x.md',
          author: 'zeynep',
          created: '2026-10-15T12:00:00Z',
          text: 'Yarın öderim.',
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Yorumlar (2)'), findsOneWidget);
    expect(find.text('IBAN değişti.'), findsOneWidget,
        reason: 'belgedeki bölüm çıkarıldı, yorum yalnız akışta');
    expect(find.text('Yarın öderim.'), findsOneWidget);
    expect(find.textContaining('işlenmeyi bekliyor'), findsOneWidget);
  });

  testWidgets('yorum yazmak inbox\'a olay dosyası gönderir', (tester) async {
    await tester.pumpWidget(_screen(_task()));
    await tester.pumpAndSettle();
    expect(find.text('Henüz yorum yok.'), findsOneWidget);

    await tester.ensureVisible(find.byKey(TaskThread.sendKey));
    await tester.enterText(find.byKey(TaskThread.inputKey), 'Dekont ekte');
    await tester.pump();
    await tester.tap(find.byKey(TaskThread.sendKey));
    await tester.pumpAndSettle();

    expect(sent, hasLength(1));
    final e = TaskEvent.parse('hub/tasks/inbox/y.md', sent.single)!;
    expect(e.kind, TaskEventKind.comment);
    expect(e.target, '2026-10-15-kira-odemesi.md');
    expect(e.author, 'afgover');
    expect(e.text, 'Dekont ekte');
    expect(find.text('Yorum gönderildi.'), findsOneWidget);
  });

  testWidgets('başkasının işini üstlenmek atama olayı gönderir', (tester) async {
    await tester.pumpWidget(_screen(_task(assignee: 'fatih')));
    await tester.pumpAndSettle();

    expect(find.text('Sorumlu: @fatih'), findsOneWidget);
    await tester.tap(find.byKey(TaskOwnerRow.takeOverKey));
    await tester.pumpAndSettle();

    final e = TaskEvent.parse('hub/tasks/inbox/z.md', sent.single)!;
    expect(e.kind, TaskEventKind.assign);
    expect(e.assignee, 'afgover');
    expect(find.textContaining('@afgover için atama gönderildi'), findsOneWidget);
  });

  testWidgets('bekleyen atama sorumluyu değiştirir; üstlenen bensem düğme yok',
      (tester) async {
    await tester.pumpWidget(_screen(
      _task(assignee: 'fatih'),
      events: const [
        TaskEvent(
          kind: TaskEventKind.assign,
          target: '2026-10-15-kira-odemesi.md',
          path: 'hub/tasks/inbox/a.md',
          created: '2026-10-15T12:00:00Z',
          assignee: 'afgover',
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sorumlu: @afgover'), findsOneWidget);
    expect(find.textContaining('işlenmeyi bekliyor'), findsOneWidget);
    expect(find.byKey(TaskOwnerRow.takeOverKey), findsNothing);
  });

  testWidgets('Ata: geçersiz ad reddedilir, geçerli ad gönderilir',
      (tester) async {
    await tester.pumpWidget(_screen(_task(assignee: null)));
    await tester.pumpAndSettle();
    expect(find.text('Sorumlu yok'), findsOneWidget);

    await tester.tap(find.byKey(TaskOwnerRow.assignKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'bad name!');
    await tester.tap(find.widgetWithText(FilledButton, 'Ata'));
    await tester.pumpAndSettle();
    expect(find.text('Geçerli bir GitHub kullanıcı adı yaz.'), findsOneWidget);
    expect(sent, isEmpty);

    await tester.enterText(find.byType(TextField).last, '@zeynep');
    await tester.tap(find.widgetWithText(FilledButton, 'Ata'));
    await tester.pumpAndSettle();
    final e = TaskEvent.parse('hub/tasks/inbox/z.md', sent.single)!;
    expect(e.assignee, 'zeynep');
  });
}
