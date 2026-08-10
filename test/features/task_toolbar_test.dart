import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/pending/pending_screen.dart';
import 'package:takip/hub/all_tasks.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/models/task.dart';

import '../helpers/test_app.dart';

class FakeHubConfigNotifier extends HubConfigNotifier {
  @override
  Future<HubConfig?> build() async =>
      const HubConfig(owner: 'afgover', repo: 'takip', token: 't');
}

TaskSummary task({
  required String name,
  String repo = 'afgover/takip',
  String? priority = 'normal',
  String? category = 'gorev',
}) =>
    TaskSummary(
      path: 'hub/tasks/inbox/$name',
      fileName: name,
      sha: 'sha-$name',
      status: TaskStatus.inbox,
      date: DateTime.utc(2026, 8, 2),
      title: name.replaceAll('.md', ''),
      repoSlug: repo,
      repoLabel: repo,
      priority: priority,
      category: category,
    );

final _tasks = [
  task(name: 'bir.md', priority: 'high', category: 'gorev'),
  task(name: 'iki.md', priority: 'low', category: 'hata'),
  task(
      name: 'uc.md',
      repo: 'afgover/financer_takip',
      priority: 'high',
      category: 'fikir'),
];

Widget buildApp() => ProviderScope(
      overrides: [
        hubConfigProvider.overrideWith(FakeHubConfigNotifier.new),
        allPendingTasksProvider.overrideWith((ref) async => _tasks),
      ],
      child: testApp(PendingScreen()),
    );

/// Filtre menüleri ve kalıcılık (T-016).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openMenu(WidgetTester tester, String kind) async {
    await tester.tap(find.byKey(TaskToolbar.menuKey(kind)));
    await tester.pumpAndSettle();
  }

  testWidgets('üç filtre menüsü ve sıralama yan yana', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(TaskToolbar.menuKey('repo')), findsOneWidget);
    expect(find.byKey(TaskToolbar.menuKey('category')), findsOneWidget);
    expect(find.byKey(TaskToolbar.menuKey('priority')), findsOneWidget);
    expect(find.byKey(TaskSortButton.buttonKey), findsOneWidget);
  });

  testWidgets('menü açılınca o boyutun seçenekleri listelenir',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await openMenu(tester, 'priority');

    // Anahtarla aranıyor, metinle değil: `high` aynı zamanda görev
    // kartlarındaki etiketlerde de yazıyor ve metin araması menüyü
    // ölçmek yerine ekranın tamamını ölçerdi.
    expect(find.byKey(TaskToolbar.chipKey('priority', 'high')), findsOneWidget);
    expect(find.byKey(TaskToolbar.chipKey('priority', 'low')), findsOneWidget);
    // Yalnız gerçekten görevlerde geçen değerler; olmayan bir seçenek
    // "burada bir şey var" diye yanlış bilgi verirdi.
    expect(find.byKey(TaskToolbar.chipKey('priority', 'urgent')), findsNothing);
  });

  testWidgets('menü seçimde kapanmaz — birden fazla seçilebilir',
      (tester) async {
    // İsteğin asıl noktası buydu: her seçimde menüyü yeniden açtırmamak.
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await openMenu(tester, 'category');
    await tester.tap(find.byKey(TaskToolbar.chipKey('category', 'gorev')));
    await tester.pumpAndSettle();

    expect(find.byKey(TaskToolbar.chipKey('category', 'hata')), findsOneWidget,
        reason: 'menü ilk seçimden sonra kapanmamalı');

    await tester.tap(find.byKey(TaskToolbar.chipKey('category', 'hata')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PendingScreen)),
    );
    expect(container.read(taskFilterProvider).categories, {'gorev', 'hata'});
  });

  testWidgets('seçim listeyi daraltır', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('bir'), findsOneWidget);
    expect(find.text('iki'), findsOneWidget);

    await openMenu(tester, 'priority');
    await tester.tap(find.byKey(TaskToolbar.chipKey('priority', 'high')));
    await tester.pumpAndSettle();
    // Menüyü kapat.
    await tester.tapAt(const Offset(10, 500));
    await tester.pumpAndSettle();

    expect(find.text('bir'), findsOneWidget);
    expect(find.text('iki'), findsNothing);
  });

  testWidgets('sıfırla yalnız bir şey seçiliyken görünür', (tester) async {
    // Hiçbir şey seçili değilken duran bir sıfırlama düğmesi, dokunulunca
    // hiçbir şey yapmayan bir düğmedir.
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.byKey(TaskToolbar.resetKey), findsNothing);

    await openMenu(tester, 'priority');
    await tester.tap(find.byKey(TaskToolbar.chipKey('priority', 'high')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 500));
    await tester.pumpAndSettle();

    expect(find.byKey(TaskToolbar.resetKey), findsOneWidget);
  });

  testWidgets('sıfırla filtreyi ve sıralamayı birlikte temizler',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PendingScreen)),
    );
    container.read(taskFilterProvider.notifier).toggle(priority: 'high');
    container.read(taskOrderProvider.notifier).select(TaskSort.date);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TaskToolbar.resetKey));
    await tester.pumpAndSettle();

    // Yarısı dönen bir sıfırlama, sıfırlama değildir.
    expect(container.read(taskFilterProvider).isEmpty, isTrue);
    expect(container.read(taskOrderProvider).isDefault, isTrue);
    expect(find.byKey(TaskToolbar.resetKey), findsNothing);
  });

  group('kalıcılık', () {
    testWidgets('seçimler diske yazılır', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PendingScreen)),
      );
      container.read(taskFilterProvider.notifier).toggle(category: 'hata');
      container.read(taskOrderProvider.notifier).select(TaskSort.priority);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getString('task_filter'), contains('hata'));
      expect(prefs.getString('task_sort'), 'priority');
    });

    testWidgets('yeniden açılışta geri gelir', (tester) async {
      SharedPreferences.setMockInitialValues({
        'task_filter': '{"repos":[],"priorities":["high"],"categories":[]}',
        'task_sort': 'date',
        'task_sort_ascending': true,
      });

      final container = ProviderContainer(overrides: [
        hubConfigProvider.overrideWith(FakeHubConfigNotifier.new),
      ]);
      addTearDown(container.dispose);

      // İlk okuma senkron varsayılanı verir; disk gelince güncellenir. Liste
      // tercih okunsun diye beklemez — beklerse açılışta bir kare boş görünür.
      // **İkisi de burada okunuyor**: bir sağlayıcı ilk okunduğunda kuruluyor,
      // yani okunmayanın geri yükleme işi hiç başlamaz.
      expect(container.read(taskFilterProvider).isEmpty, isTrue);
      expect(container.read(taskOrderProvider).isDefault, isTrue);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      expect(container.read(taskFilterProvider).priorities, {'high'});
      expect(container.read(taskOrderProvider).sort, TaskSort.date);
      expect(container.read(taskOrderProvider).ascending, isTrue);
    });

    testWidgets('bozuk tercih filtresiz açar, çökertmez', (tester) async {
      // Yanlış bir filtre görevleri **sessizce gizlerdi**; okunamayan tercihte
      // güvenli taraf "her şeyi göster".
      SharedPreferences.setMockInitialValues({'task_filter': 'bu json değil'});

      final container = ProviderContainer(overrides: [
        hubConfigProvider.overrideWith(FakeHubConfigNotifier.new),
      ]);
      addTearDown(container.dispose);

      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(container.read(taskFilterProvider).isEmpty, isTrue);
    });

    testWidgets('tanınmayan sıralama varsayılana düşer', (tester) async {
      SharedPreferences.setMockInitialValues({'task_sort': 'bilinmeyen'});

      final container = ProviderContainer(overrides: [
        hubConfigProvider.overrideWith(FakeHubConfigNotifier.new),
      ]);
      addTearDown(container.dispose);

      container.read(taskOrderProvider);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(container.read(taskOrderProvider).isDefault, isTrue);
    });
  });
}
