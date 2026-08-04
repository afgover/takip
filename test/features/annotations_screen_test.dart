import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/browse/annotations_screen.dart';
import 'package:takip/features/browse/document_screen.dart';
import 'package:takip/hub/annotations.dart';
import 'package:takip/hub/browse_repo.dart';
import 'package:takip/hub/models/task.dart';

AnnotationEntry entry({
  required String quote,
  required TaskMark mark,
  String source = 'hub/sessions/2026-08-04-x/session.md',
  String repoSlug = 'afgover/takip',
  String repoLabel = 'takip',
  String? note,
}) =>
    AnnotationEntry(
      annotation: Annotation(
        quote: quote,
        mark: mark,
        title: quote,
        category: 'not',
        path: 'hub/notes/2026-08-04-$quote.md',
        sourcePath: source,
        repoSlug: repoSlug,
        note: note,
      ),
      repoLabel: repoLabel,
    );

Widget app(List<AnnotationEntry> entries, {List<Override> extra = const []}) =>
    ProviderScope(
      overrides: [
        allAnnotationsProvider.overrideWith((ref) async => entries),
        ...extra,
      ],
      child: const MaterialApp(home: AnnotationsScreen()),
    );

void main() {
  testWidgets('bütün repolardaki işaretler tek listede', (tester) async {
    await tester.pumpWidget(app([
      entry(quote: 'birinci', mark: TaskMark.bookmark),
      entry(
        quote: 'ikinci',
        mark: TaskMark.underline,
        repoSlug: 'afgover/financer_takip',
        repoLabel: 'Financer',
      ),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('birinci'), findsOneWidget);
    expect(find.text('ikinci'), findsOneWidget);
    expect(find.text('Financer'), findsOneWidget);
  });

  testWidgets('renge göre süzülür', (tester) async {
    await tester.pumpWidget(app([
      entry(quote: 'yer imi', mark: TaskMark.bookmark),
      entry(quote: 'kırmızı', mark: TaskMark.underline),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AnnotationsScreen.filterKey(TaskMark.bookmark)));
    await tester.pumpAndSettle();

    expect(find.text('yer imi'), findsOneWidget);
    expect(find.text('kırmızı'), findsNothing);
  });

  testWidgets('listede geçmeyen renk için süzgeç gösterilmez', (tester) async {
    // Boş sonuç veren bir düğme sunmamak (B-068'deki kural).
    await tester.pumpWidget(app([entry(quote: 'a', mark: TaskMark.bookmark)]));
    await tester.pumpAndSettle();

    expect(find.byKey(AnnotationsScreen.filterKey(TaskMark.bookmark)),
        findsOneWidget);
    expect(find.byKey(AnnotationsScreen.filterKey(TaskMark.comment)),
        findsNothing);
  });

  testWidgets('dokununca kaydın KENDİ reposundaki belge açılır', (tester) async {
    // L-031: çok kaynaklı listeden açılan yol da çok kaynaklı olmalı; aktif
    // repoya bakılsaydı başka repodaki işaret "bulunamadı" derdi.
    final reads = <({String? repoSlug, String path})>[];

    await tester.pumpWidget(app(
      [
        entry(
          quote: 'başka repodaki not',
          mark: TaskMark.bookmark,
          source: 'hub/BACKLOG.md',
          repoSlug: 'afgover/financer_takip',
          repoLabel: 'Financer',
        ),
      ],
      extra: [
        docContentForProvider.overrideWith((ref, key) async {
          reads.add(key);
          return '# Belge\n\nbaşka repodaki not burada.';
        }),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('başka repodaki not'));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentScreen), findsOneWidget);
    expect(reads.single.repoSlug, 'afgover/financer_takip');
    expect(reads.single.path, 'hub/BACKLOG.md');
  });

  testWidgets('notun metni kartta görünür', (tester) async {
    await tester.pumpWidget(app([
      entry(quote: 'alıntı', mark: TaskMark.comment, note: 'buna sonra bak'),
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
}
