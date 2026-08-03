import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/common/selection_record.dart';
import 'package:takip/hub/models/task.dart';

void main() {
  testWidgets('yorum kutusu yazılan notu geri döndürür', (tester) async {
    SelectionRequest? result;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await openCommentBox(
                    context,
                    quote: 'işaretlenen cümle',
                  );
                },
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    // Kutu açıldı ve alıntıyı gösteriyor.
    expect(find.text('Yorum ekle'), findsOneWidget);
    expect(find.text('işaretlenen cümle'), findsOneWidget);

    await tester.enterText(find.byKey(commentFieldKey), 'buraya dikkat');
    await tester.tap(find.byKey(commentSubmitKey));
    await tester.pumpAndSettle();

    expect(result, isNotNull, reason: 'kutu seçimi döndürmeli');
    expect(result!.note, 'buraya dikkat');
    expect(result!.kind, RecordKind.yorum);
    // Yorum sarıdan ayrı bir renkte olmalı; aynı sarı olursa kullanıcı
    // "işaretledim" ile "not düştüm"ü ekranda ayırt edemiyor.
    expect(result!.mark, TaskMark.comment);
  });

  testWidgets('vazgeçilince null döner', (tester) async {
    SelectionRequest? result;
    var completed = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await openCommentBox(context, quote: 'x');
                  completed = true;
                },
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
  });
}
