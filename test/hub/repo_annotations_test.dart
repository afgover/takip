import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/github/trees_api.dart';
import 'package:takip/hub/annotations.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/models/task.dart';
import 'package:takip/hub/offline_store.dart';

const _takip = HubConfig(owner: 'afgover', repo: 'takip', token: 't');
const _financer = HubConfig(
  owner: 'afgover',
  repo: 'financer_takip',
  token: 't',
  label: 'Financer',
);

/// Yerel kopyaya bir kayıt yazar; `annotationsIn` ağ kullanmaz.
Future<void> put(
  HubConfig connection,
  String path,
  String content,
) async {
  final store = OfflineStore(connection.slug);
  final tree = await store.readTree() ?? const <TreeEntry>[];
  await store.writeDoc(path, StoredDoc(sha: path, content: content));
  await store.writeTree([
    ...tree,
    TreeEntry(path: path, sha: path, isFile: true),
  ]);
}

String record({
  required String mark,
  required String quote,
  String source = 'hub/sessions/2026-08-04-x/session.md',
  String body = 'notun metni',
}) =>
    '---\n'
    'title: "$quote"\n'
    'created_by: user\n'
    'source: $source\n'
    'quote: "$quote"\n'
    'mark: $mark\n'
    '---\n\n'
    '# $quote\n\n'
    '$body\n';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('annotationsIn', () {
    test('görevlerdeki ve notlardaki işaretleri birlikte toplar', () async {
      await put(_takip, '${Hub.notesDir}/2026-08-04-a.md',
          record(mark: 'bookmark', quote: 'yer imi konan cümle'));
      await put(_takip, '${Hub.inboxDir}/2026-08-04-b.md',
          record(mark: 'underline', quote: 'yanlış olan yer'));

      final found = await annotationsIn(_takip);

      expect(found, hasLength(2));
      expect(
        found.map((e) => e.mark),
        containsAll([TaskMark.bookmark, TaskMark.underline]),
      );
    });

    test('her kayıt kendi belgesini taşır', () async {
      await put(
        _takip,
        '${Hub.notesDir}/2026-08-04-a.md',
        record(
          mark: 'bookmark',
          quote: 'alıntı',
          source: 'hub/BACKLOG.md',
        ),
      );

      final entry = (await annotationsIn(_takip)).single;
      // Liste çok belgeli: kayıt hangi belgeye ait olduğunu kendisi bilmeli,
      // yoksa dokununca nereye gidileceği bilinemez.
      expect(entry.sourcePath, 'hub/BACKLOG.md');
      expect(entry.repoSlug, 'afgover/takip');
      expect(entry.note, 'notun metni');
    });

    test('işaret alanları eksik olan kayıt listeye girmez', () async {
      // `source`/`quote`/`mark` üçü birlikte anlamlı (§4). Normal bir görev
      // (seçimden üretilmemiş) burada görünmemeli.
      await put(
        _takip,
        '${Hub.inboxDir}/2026-08-04-duz.md',
        '---\nid: pending\ntitle: "Düz görev"\n---\n\n# Düz görev\n',
      );

      expect(await annotationsIn(_takip), isEmpty);
    });

    test('oturum/artifact dosyaları taranmaz', () async {
      // Yalnız görev ve not dosyaları işaret taşır; bir oturum kaydında
      // "quote:" geçmesi onu işaret yapmaz.
      await put(_takip, '${Hub.sessionsDir}/2026-08-04-x/session.md',
          record(mark: 'highlight', quote: 'oturumdaki metin'));

      expect(await annotationsIn(_takip), isEmpty);
    });

    test('yalnız verilen bağlantı taranır — başka repo sızmaz', () async {
      // Sözleşme 1.13: liste aktif repoya ait. Bu fonksiyon tek bağlantı
      // aldığı için sızıntı yapısal olarak mümkün değil; test bunu sabitliyor.
      await put(_takip, '${Hub.notesDir}/2026-08-04-a.md',
          record(mark: 'bookmark', quote: 'takip işareti'));
      await put(_financer, '${Hub.notesDir}/2026-08-04-b.md',
          record(mark: 'comment', quote: 'financer işareti'));

      final inTakip = await annotationsIn(_takip);
      expect(inTakip.map((a) => a.quote), ['takip işareti']);

      final inFinancer = await annotationsIn(_financer);
      expect(inFinancer.map((a) => a.quote), ['financer işareti']);
    });

    test('yerel kopyası olmayan bağlantı boş döner (çökmez)', () async {
      expect(await annotationsIn(_financer), isEmpty);
    });
  });

  group('sözleşme uyumu', () {
    test('TaskMark değerlerinin hepsi sözleşmede tanımlı', () {
      // Yeni bir işaret türü eklenirken sözleşmeye yazmayı unutmak, K-031'de
      // yaşanan sessiz hatanın aynısı: hiçbir şey hata vermez, yalnız kayıt
      // sözleşmesiz kalır. Liste elle senkron tutulmasın diye dosyadan okunuyor.
      final contract = File('hub/SYSTEM.md').readAsStringSync();
      for (final mark in TaskMark.values) {
        expect(
          contract,
          contains(mark.name),
          reason: '${mark.name} SYSTEM.md\'de geçmiyor',
        );
      }
    });

    test('yer imi göreve dönüşemez, diğerleri dönüşebilir', () {
      expect(TaskMark.bookmark.canBecomeTask, isFalse);
      for (final mark in TaskMark.values.where((m) => m != TaskMark.bookmark)) {
        expect(mark.canBecomeTask, isTrue, reason: mark.name);
      }
    });
  });
}
