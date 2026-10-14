import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/features/add_task/add_task_screen.dart';
import 'package:takip/features/share/shared_text.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/hub/task_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;
import '../helpers/test_app.dart';

class _Shared extends SharedTextNotifier {
  _Shared(this.initial);
  final SharedText initial;

  @override
  SharedText? build() => initial;
}

Widget _form(SharedText shared) {
  final adapter = FakeAdapter((_, __) => jsonResponse({
        'content': {'sha': 'yeni'}
      }));
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;
  return ProviderScope(
    overrides: [
      taskRepoProvider.overrideWithValue(
          TaskRepo(ContentsApi(dio, owner: 'afgover', repo: 'takip'))),
      sharedTextProvider.overrideWith(() => _Shared(shared)),
    ],
    child: testApp(AddTaskScreen()),
  );
}

String _field(WidgetTester tester, int i) =>
    tester.widgetList<EditableText>(find.byType(EditableText)).elementAt(i).controller.text;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('mergeShared', () {
    test('boş formda ilk dolu satır başlık, metnin tamamı açıklama', () {
      final r = mergeShared(
        title: '',
        description: '',
        shared: SharedText(text: '\n  Fatura ödenecek \nSon gün cuma'),
      );
      expect(r.title, 'Fatura ödenecek');
      expect(r.description, 'Fatura ödenecek \nSon gün cuma');
      expect(r.appended, isFalse);
    });

    test('tek kısa satır yalnız başlık olur', () {
      final r = mergeShared(
          title: '', description: '', shared: SharedText(text: 'Market'));
      expect(r.title, 'Market');
      expect(r.description, '');
    });

    test('konu satırı varsa başlık odur', () {
      final r = mergeShared(
        title: '',
        description: '',
        shared: SharedText(text: 'gövde metni', subject: 'Toplantı notu'),
      );
      expect(r.title, 'Toplantı notu');
      expect(r.description, 'gövde metni');
    });

    test('uzun satır başlıkta kısalır, açıklama tam kalır', () {
      final long = 'a' * 200;
      final r = mergeShared(
          title: '', description: '', shared: SharedText(text: long));
      expect(r.title.length, sharedTitleMax);
      expect(r.title.endsWith('…'), isTrue);
      expect(r.description, long);
    });

    test('formda yazılmış metin silinmez, paylaşım açıklamanın sonuna eklenir',
        () {
      final r = mergeShared(
        title: 'Yarım iş',
        description: 'ilk not',
        shared: SharedText(text: 'gelen mesaj'),
      );
      expect(r.title, 'Yarım iş');
      expect(r.description, 'ilk not\n\ngelen mesaj');
      expect(r.appended, isTrue);
    });
  });

  group('platform kanalı', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(shareChannel, null));

    test('açılışta bekleyen metni alır; sonradan gelen paylaşımı da alır',
        () async {
      var replies = <Map<String, String>?>[
        {'text': 'ilk paylaşım'},
        {'text': 'ikinci', 'subject': 'Konu'},
      ];
      messenger.setMockMethodCallHandler(shareChannel, (call) async {
        expect(call.method, 'takeSharedText');
        return replies.isEmpty ? null : replies.removeAt(0);
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(sharedTextProvider);
      await Future<void>.delayed(Duration.zero);
      final first = container.read(sharedTextProvider)!;
      expect(first.text, 'ilk paylaşım');

      // Uygulama açıkken yeni paylaşım: Android "sharedTextAvailable" der.
      await messenger.handlePlatformMessage(
        shareChannel.name,
        shareChannel.codec
            .encodeMethodCall(const MethodCall('sharedTextAvailable')),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);
      final second = container.read(sharedTextProvider)!;
      expect(second.subject, 'Konu');
      expect(second.seq, greaterThan(first.seq));
    });
  });

  group('Ekle formu', () {
    testWidgets('paylaşılan metin boş formu doldurur ve bunu söyler',
        (tester) async {
      await tester.pumpWidget(_form(SharedText(text: 'Kira\nAyın beşinde')));
      await tester.pumpAndSettle();

      expect(_field(tester, 0), 'Kira');
      expect(_field(tester, 1), 'Kira\nAyın beşinde');
      expect(find.textContaining('forma yerleştirildi'), findsOneWidget);
    });

    testWidgets('yarım kalmış taslağı ezmez, sonuna ekler', (tester) async {
      SharedPreferences.setMockInitialValues({
        'add_task_draft_v1':
            jsonEncode({'title': 'Yarım iş', 'description': 'ilk not'}),
      });
      await tester.pumpWidget(_form(SharedText(text: 'gelen mesaj')));
      await tester.pumpAndSettle();

      expect(_field(tester, 0), 'Yarım iş');
      expect(_field(tester, 1), 'ilk not\n\ngelen mesaj');
      expect(find.textContaining('sonuna eklendi'), findsOneWidget);
    });
  });
}
