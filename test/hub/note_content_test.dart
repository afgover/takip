import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/common/selection_record.dart';
import 'package:takip/hub/annotations.dart';
import 'package:takip/hub/frontmatter.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/models/task_draft.dart';

import '../helpers/test_app.dart';

/// İşarete dokununca açılan kart, kullanıcının **kendi yazdığını**
/// göstermeli. Alıntıyı zaten belgede görüyor; kart onu tekrar edip notu
/// atlıyordu.
void main() {
  group('noteTextFrom', () {
    test('notun gövdesinden kullanıcı metnini çıkarır', () {
      // Gerçek dosyanın kendisinden üretiliyor: biçim değişirse test düşer.
      final draft = TaskDraft.note(
        quote: 'Impeller rendering backend',
        sourcePath: 'hub/sessions/x/session.md',
        note: 'Buna sonra bakayım.',
        repoSlug: 'afgover/takip',
        section: 'Özet',
      );

      final body = Frontmatter.parse(draft.content).body;
      expect(noteTextFrom(body), 'Buna sonra bakayım.');
    });

    test('görevin gövdesinde `## İstek` altındakini çıkarır', () {
      final draft = TaskDraft.fromSelection(
        quote: 'bir alıntı',
        sourcePath: 'hub/BACKLOG.md',
        kind: 'duzeltme',
        mark: TaskMark.underline,
        note: 'Burası yanlış, şöyle olmalı.',
      );

      final body = Frontmatter.parse(draft.content).body;
      expect(noteTextFrom(body), 'Burası yanlış, şöyle olmalı.');
    });

    test('not girilmemişse null döner — kart boş satır göstermesin', () {
      final draft = TaskDraft.note(
        quote: 'x',
        sourcePath: 'hub/BACKLOG.md',
      );
      expect(noteTextFrom(Frontmatter.parse(draft.content).body), isNull);
    });

    test('tanınmayan gövdede çökmez', () {
      expect(noteTextFrom(''), isNull);
      expect(noteTextFrom('## Nerede\n- **Dosya:** `x`'), isNull);
      expect(noteTextFrom('düz metin'), 'düz metin');
    });
  });

  testWidgets('kart notun içeriğini gösteriyor', (tester) async {
    const annotation = Annotation(
      quote: 'Impeller rendering backend',
      mark: TaskMark.comment,
      title: 'Impeller rendering backend',
      category: 'not',
      path: 'hub/notes/2026-08-03-impeller.md',
      sourcePath: 'hub/sessions/x/session.md',
      note: 'Buna sonra bakayım.',
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: testApp(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => openAnnotationCard(
                context,
                annotation: annotation,
                container: container,
                messenger: ScaffoldMessenger.of(context),
              ),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    expect(find.byKey(annotationNoteKey), findsOneWidget);
    expect(find.text('Buna sonra bakayım.'), findsOneWidget);
    // Alıntı da bağlam olarak duruyor.
    expect(find.text('Impeller rendering backend'), findsOneWidget);
    expect(find.text('Notu sil'), findsOneWidget);
  });

  testWidgets('notu olmayan işarette not satırı hiç çizilmiyor',
      (tester) async {
    const annotation = Annotation(
      quote: 'bir alıntı',
      mark: TaskMark.highlight,
      title: 'bir alıntı',
      category: 'yorum',
      path: 'hub/tasks/inbox/2026-08-03-x.md',
      sourcePath: 'hub/BACKLOG.md',
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: testApp(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => openAnnotationCard(
                context,
                annotation: annotation,
                container: container,
                messenger: ScaffoldMessenger.of(context),
              ),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    expect(find.byKey(annotationNoteKey), findsNothing);
    expect(find.text('İşareti sil'), findsOneWidget);
  });
}
