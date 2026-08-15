import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/errors.dart';
import 'package:takip/features/pending/pending_screen.dart';
import 'package:takip/features/pending/task_detail_screen.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/models/task_draft.dart';
import 'package:takip/hub/all_tasks.dart';
import 'package:takip/hub/task_repo.dart';

import '../helpers/test_app.dart';

class FakeHubConfigNotifier extends HubConfigNotifier {
  @override
  Future<HubConfig?> build() async =>
      const HubConfig(owner: 'afgover', repo: 'takip', token: 't');
}

TaskSummary summary(String name, TaskStatus status) => TaskSummary.fromEntry(
      path: 'hub/tasks/${status.name}/$name',
      name: name,
      sha: 'sha-$name',
      status: status,
    )!;

Widget buildApp({
  required Override tasksOverride,
  List<Override> extra = const [],
}) =>
    ProviderScope(
      overrides: [
        hubConfigProvider.overrideWith(FakeHubConfigNotifier.new),
        tasksOverride,
        ...extra,
      ],
      child: testApp(PendingScreen()),
    );

void main() {
  // Kuyruk diskte durduğu için testler birbirinin kalıntısını görmemeli.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('yüklenirken göstergeyi çizer', (tester) async {
    await tester.pumpWidget(buildApp(
      tasksOverride: activeRepoPendingTasksProvider.overrideWith(
        (ref) => Future<List<TaskSummary>>.delayed(
          const Duration(seconds: 1),
          () => const [],
        ),
      ),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('görev yoksa açıklayıcı boş durum gösterir', (tester) async {
    await tester.pumpWidget(buildApp(
      tasksOverride: activeRepoPendingTasksProvider.overrideWith((ref) async => const []),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bekleyen görev yok'), findsOneWidget);
    expect(find.byKey(PendingScreen.listKey), findsNothing);
  });

  testWidgets('görevleri durum rozetiyle listeler', (tester) async {
    await tester.pumpWidget(buildApp(
      tasksOverride: activeRepoPendingTasksProvider.overrideWith((ref) async => [
            summary('2026-07-30-market-listesi.md', TaskStatus.active),
            summary('2026-07-28-fatura-odemesi.md', TaskStatus.inbox),
          ]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Market listesi'), findsOneWidget);
    expect(find.text('Fatura odemesi'), findsOneWidget);
    expect(find.text('Ele alınıyor'), findsOneWidget);
    expect(find.text('Yeni'), findsOneWidget);
    // Tarih dosya adından okunuyor (dosya indirilmeden).
    expect(find.text('30.07.2026'), findsOneWidget);
  });

  testWidgets('kuyrukta bekleyen görevler listenin başında gösterilir',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'outbox': [
        jsonEncode(
          withClock(
            Clock.fixed(DateTime.utc(2026, 7, 30)),
            () => TaskDraft.create(title: 'Gönderilemeyen görev'),
          ).toJson(),
        ),
      ],
    });

    await tester.pumpWidget(buildApp(
      tasksOverride: activeRepoPendingTasksProvider.overrideWith((ref) async => [
            summary('2026-07-30-market-listesi.md', TaskStatus.inbox),
          ]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Gönderilecek'), findsOneWidget);
    expect(find.text('Bağlantı gelince gönderilecek'), findsOneWidget);

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(
      (tiles.first.title! as Text).data,
      'Gönderilemeyen görev',
      reason: 'kuyruktakiler en üstte',
    );
  });

  testWidgets('hub boş ama kuyruk doluysa boş durum gösterilmez',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'outbox': [
        jsonEncode(
          withClock(
            Clock.fixed(DateTime.utc(2026, 7, 30)),
            () => TaskDraft.create(title: 'Bekleyen'),
          ).toJson(),
        ),
      ],
    });

    await tester.pumpWidget(buildApp(
      tasksOverride: activeRepoPendingTasksProvider.overrideWith((ref) async => const []),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bekleyen görev yok'), findsNothing);
    expect(find.text('Bekleyen'), findsOneWidget);
  });

  testWidgets('hata durumunda sebep ve yeniden dene çıkar', (tester) async {
    var calls = 0;
    await tester.pumpWidget(buildApp(
      tasksOverride: activeRepoPendingTasksProvider.overrideWith((ref) async {
        calls++;
        if (calls == 1) throw const HubNetworkError('Ağ bağlantısı yok.');
        return const [];
      }),
    ));
    await tester.pumpAndSettle();

    // B-050: ham mesaj yerine başlık + ne yapılabileceği gösteriliyor.
    expect(find.text('Bağlantı yok'), findsOneWidget);
    expect(find.textContaining('kuyrukta bekler'), findsOneWidget);

    await tester.tap(find.text('Yeniden dene'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Bekleyen görev yok'), findsOneWidget);
  });

  testWidgets('göreve dokununca detay ekranı açılır ve içerik indirilir',
      (tester) async {
    final item = summary('2026-07-30-market-listesi.md', TaskStatus.inbox);
    var detailFetches = 0;

    await tester.pumpWidget(buildApp(
      tasksOverride: activeRepoPendingTasksProvider.overrideWith((ref) async => [item]),
      extra: [
        taskDetailProvider.overrideWith((ref, arg) async {
          detailFetches++;
          return HubTask.parse(
            path: arg.path,
            status: arg.status,
            content: '---\nid: T-004\ntitle: "Market listesi"\n'
                'category: gorev\npriority: high\n---\n\n'
                '## İstek\nSüt, ekmek.\n',
          );
        }),
      ],
    ));
    await tester.pumpAndSettle();

    expect(detailFetches, 0, reason: 'liste içerik indirmemeli');

    await tester.tap(find.text('Market listesi'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailScreen), findsOneWidget);
    expect(detailFetches, 1);
    expect(find.textContaining('Süt, ekmek.'), findsOneWidget);
    expect(find.text('gorev'), findsOneWidget);
    expect(find.text('high'), findsOneWidget);
  });

  testWidgets('agent ID atamamışsa detayda belirtilir', (tester) async {
    final item = summary('2026-07-30-yeni-gorev.md', TaskStatus.inbox);

    await tester.pumpWidget(buildApp(
      tasksOverride: activeRepoPendingTasksProvider.overrideWith((ref) async => [item]),
      extra: [
        taskDetailProvider.overrideWith((ref, arg) async => HubTask.parse(
              path: arg.path,
              status: arg.status,
              content: '---\nid: pending\ntitle: "Yeni görev"\n---\n\ngövde',
            )),
      ],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yeni gorev'));
    await tester.pumpAndSettle();

    expect(find.text('agent henüz ele almadı'), findsOneWidget);
  });
}
