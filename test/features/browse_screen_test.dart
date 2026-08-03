import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/browse/activity_screen.dart';
import 'package:takip/features/browse/browse_screen.dart';
import 'package:takip/features/browse/doc_list_screen.dart';
import 'package:takip/features/browse/document_screen.dart';
import 'package:takip/features/browse/knowledge_screen.dart';
import 'package:takip/hub/browse_repo.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/models/activity.dart';
import 'package:takip/hub/models/hub_doc.dart';

class FakeHubConfigNotifier extends HubConfigNotifier {
  @override
  Future<HubConfig?> build() async =>
      const HubConfig(owner: 'afgover', repo: 'takip', token: 't');
}

Widget app(Widget home, {List<Override> overrides = const []}) => ProviderScope(
      overrides: [
        hubConfigProvider.overrideWith(FakeHubConfigNotifier.new),
        ...overrides,
      ],
      child: MaterialApp(home: home),
    );

void main() {
  testWidgets('kategori ekranı sözleşmedeki başlıkları gösterir (B-040)',
      (tester) async {
    // Varsayılan test ekranına yedi kart sığmıyor; grid görünmeyeni çizmez.
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(const BrowseScreen()));

    for (final title in [
      'Security',
      'Tamamlananlar',
      'Oturumlar',
      'Raporlar & Planlar',
      'Bilgi tabanı',
      'Yol haritası',
      'Aktivite',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('oturum listesinden belgeye geçilir (B-041)', (tester) async {
    await tester.pumpWidget(app(
      DocListScreen(
        title: 'Oturumlar',
        provider: sessionsProvider,
        emptyTitle: 'Oturum kaydı yok',
      ),
      overrides: [
        sessionsProvider.overrideWith((ref) async => [
              HubDoc.fromDatedPath(
                'hub/sessions/2026-07-30-hub-tasima/session.md',
                sha: 's1',
              ),
            ]),
        docContentProvider.overrideWith(
          (ref, path) async => '---\nid: S-2026-07-30-hub-tasima\n'
              'status: closed\ntopics: [kurulum]\n---\n\n'
              '# Oturum\n\n## Özet\nHer şey taşındı.',
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Hub tasima'), findsOneWidget);

    await tester.tap(find.text('Hub tasima'));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentScreen), findsOneWidget);
    expect(find.textContaining('Her şey taşındı.'), findsOneWidget);
    // Frontmatter rozet olarak özetleniyor.
    expect(find.text('status: closed'), findsOneWidget);
    expect(find.text('kurulum'), findsOneWidget);
  });

  testWidgets('artifact listesi türe göre süzülür (B-042)', (tester) async {
    await tester.pumpWidget(app(
      DocListScreen(
        title: 'Raporlar & Planlar',
        provider: artifactsProvider,
        emptyTitle: 'yok',
        showTypeFilter: true,
      ),
      overrides: [
        artifactsProvider.overrideWith((ref) async => [
              HubDoc.fromDatedPath('hub/artifacts/reference/tasarim.md')
                  .copyWith(title: 'Tasarım', subtitle: 'design'),
              HubDoc.fromDatedPath('hub/artifacts/x/2026-07-30-rapor.md')
                  .copyWith(title: 'Araştırma', subtitle: 'report'),
            ]),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tasarım'), findsOneWidget);
    expect(find.text('Araştırma'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'design'));
    await tester.pumpAndSettle();

    expect(find.text('Tasarım'), findsOneWidget);
    expect(find.text('Araştırma'), findsNothing);
  });

  testWidgets('geçersiz kılınan kural üstü çizili gösterilir (B-043)',
      (tester) async {
    await tester.pumpWidget(app(
      const KnowledgeScreen(),
      overrides: [
        knowledgeProvider.overrideWith((ref, file) async => const [
              KnowledgeEntry(
                id: 'R-001',
                title: 'Geçerli kural',
                body: 'metin',
                isInvalidated: false,
                date: '2026-07-30',
              ),
              KnowledgeEntry(
                id: 'R-002',
                title: 'Eski kural',
                body: 'metin',
                isInvalidated: true,
              ),
            ]),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('R-001'), findsOneWidget);
    expect(find.text('geçersiz kayıt'), findsOneWidget);

    final struck = tester.widget<Text>(find.text('Eski kural'));
    expect(struck.style?.decoration, TextDecoration.lineThrough);

    final valid = tester.widget<Text>(find.text('Geçerli kural'));
    expect(valid.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  testWidgets('aktivite akışı varsayılanda kod commit\'lerini gizler (B-045)',
      (tester) async {
    await tester.pumpWidget(app(
      const ActivityScreen(),
      overrides: [
        activityProvider.overrideWith((ref) async => [
              ActivityEntry.fromCommit(
                message: 'task(T-002): active → done',
                sha: 'a',
              ),
              ActivityEntry.fromCommit(
                message: 'feat(B-023): Contents API katmanı',
                sha: 'b',
              ),
            ]),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('T-002 tamamlandı'), findsOneWidget);
    expect(find.textContaining('Contents API katmanı'), findsNothing);

    await tester.tap(find.byKey(ActivityScreen.codeToggleKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('Contents API katmanı'), findsOneWidget);
  });
}
