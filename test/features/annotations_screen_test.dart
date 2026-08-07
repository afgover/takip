import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/browse/annotations_screen.dart';
import 'package:takip/features/browse/document_screen.dart';
import 'package:takip/hub/annotations.dart';
import 'package:takip/hub/browse_repo.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/models/task.dart';

import '../helpers/test_app.dart';

class FakeHubConfigNotifier extends HubConfigNotifier {
  FakeHubConfigNotifier(this.config);

  final HubConfig? config;

  @override
  Future<HubConfig?> build() async => config;
}

Annotation annotation({
  required String quote,
  required TaskMark mark,
  String source = 'hub/sessions/2026-08-04-x/session.md',
  String repoSlug = 'afgover/takip',
  String? note,
}) =>
    Annotation(
      quote: quote,
      mark: mark,
      title: quote,
      category: 'not',
      path: 'hub/notes/2026-08-04-$quote.md',
      sourcePath: source,
      repoSlug: repoSlug,
      note: note,
    );

Widget app(
  List<Annotation> entries, {
  List<Override> extra = const [],
  HubConfig? active = const HubConfig(
    owner: 'afgover',
    repo: 'takip',
    token: 't',
    label: 'Takip',
  ),
}) =>
    ProviderScope(
      overrides: [
        repoAnnotationsProvider.overrideWith((ref) async => entries),
        hubConfigProvider.overrideWith(() => FakeHubConfigNotifier(active)),
        ...extra,
      ],
      child: testApp(AnnotationsScreen()),
    );

void main() {
  testWidgets('aktif repodaki işaretler listelenir', (tester) async {
    await tester.pumpWidget(app([
      annotation(quote: 'birinci', mark: TaskMark.bookmark),
      annotation(quote: 'ikinci', mark: TaskMark.underline),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('birinci'), findsOneWidget);
    expect(find.text('ikinci'), findsOneWidget);
  });

  testWidgets('hangi reponun listesi olduğu başlıkta yazar', (tester) async {
    // Liste tek repoya ait; hangisi olduğu görünmezse kullanıcı eksik bir
    // listeyi tam sanar (sözleşme 1.13).
    await tester.pumpWidget(app([
      annotation(quote: 'birinci', mark: TaskMark.bookmark),
    ]));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(AnnotationsScreen.repoLabelKey)).data,
      'Takip',
    );
  });

  testWidgets('renge göre süzülür', (tester) async {
    await tester.pumpWidget(app([
      annotation(quote: 'yer imi', mark: TaskMark.bookmark),
      annotation(quote: 'kırmızı', mark: TaskMark.underline),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AnnotationsScreen.filterKey(TaskMark.bookmark)));
    await tester.pumpAndSettle();

    expect(find.text('yer imi'), findsOneWidget);
    expect(find.text('kırmızı'), findsNothing);
  });

  testWidgets('listede geçmeyen renk için süzgeç gösterilmez', (tester) async {
    // Boş sonuç veren bir düğme sunmamak (B-068'deki kural).
    await tester
        .pumpWidget(app([annotation(quote: 'a', mark: TaskMark.bookmark)]));
    await tester.pumpAndSettle();

    expect(find.byKey(AnnotationsScreen.filterKey(TaskMark.bookmark)),
        findsOneWidget);
    expect(find.byKey(AnnotationsScreen.filterKey(TaskMark.comment)),
        findsNothing);
  });

  testWidgets('dokununca belge kaydın kendi reposundan okunur', (tester) async {
    // Hedef, "listedeki her şey aktif repodandır" varsayımına değil kaydın
    // kendi `repoSlug`'ına dayanıyor (L-031).
    final reads = <({String? repoSlug, String path})>[];

    await tester.pumpWidget(app(
      [
        annotation(
          quote: 'backlog\'daki not',
          mark: TaskMark.bookmark,
          source: 'hub/BACKLOG.md',
        ),
      ],
      extra: [
        docContentForProvider.overrideWith((ref, key) async {
          reads.add(key);
          return '# Belge\n\nbacklog\'daki not burada.';
        }),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('backlog\'daki not'));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentScreen), findsOneWidget);
    expect(reads.single.repoSlug, 'afgover/takip');
    expect(reads.single.path, 'hub/BACKLOG.md');
  });

  testWidgets('notun metni kartta görünür', (tester) async {
    await tester.pumpWidget(app([
      annotation(quote: 'alıntı', mark: TaskMark.comment, note: 'buna sonra bak'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('buna sonra bak'), findsOneWidget);
  });

  testWidgets('hiç işaret yokken ne yapılacağını söyler', (tester) async {
    await tester.pumpWidget(app(const []));
    await tester.pumpAndSettle();

    expect(find.text('Henüz işaret yok'), findsOneWidget);
    expect(find.textContaining('yer imi'), findsOneWidget);
  });

  testWidgets('bağlantı yokken başlık şeridi çizilmez', (tester) async {
    await tester.pumpWidget(app(const [], active: null));
    await tester.pumpAndSettle();

    expect(find.byKey(AnnotationsScreen.repoLabelKey), findsNothing);
    expect(find.text('İşaretler'), findsOneWidget);
  });
}
