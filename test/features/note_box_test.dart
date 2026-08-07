import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/features/common/selection_record.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('not kutusu yazılan notu geri döndürür', (tester) async {
    String? result;

    await tester.pumpWidget(
      ProviderScope(
        child: testApp(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await openNoteBox(
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
    expect(find.text('Not ekle'), findsOneWidget);
    expect(find.text('işaretlenen cümle'), findsOneWidget);

    await tester.enterText(find.byKey(noteFieldKey), 'buraya dikkat');
    await tester.tap(find.byKey(noteSubmitKey));
    await tester.pumpAndSettle();

    expect(result, 'buraya dikkat');
  });

  testWidgets('vazgeçilince null döner', (tester) async {
    String? result;
    var completed = false;

    await tester.pumpWidget(
      ProviderScope(
        child: testApp(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await openNoteBox(context, quote: 'x');
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
