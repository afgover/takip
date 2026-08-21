import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takip/hub/reported_waiting.dart';

const _slug = 'afgover/takip';
const _other = 'afgover/financer_takip';
const _path = 'hub/tasks/waiting/2026-08-06-release-imza-anahtari.md';

ProviderContainer boot() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('işaretlenen bekleme diske yazılır ve yeniden okunur', () async {
    final first = boot();
    await first.read(reportedWaitingProvider.future);
    await first.read(reportedWaitingProvider.notifier).mark(_slug, _path);

    // Uygulama kapanıp açılmış gibi: yeni container, aynı disk. Kusur tam
    // buradaydı — bilgi widget durumundaydı ve ekran kapanınca ölüyordu.
    final second = boot();
    final record = await second.read(reportedWaitingProvider.future);
    expect(record, contains(ReportedWaiting.keyFor(_slug, _path)));
  });

  test('anahtar repoyu içerir: aynı yol iki hub\'da ayrı kayıttır', () async {
    final c = boot();
    await c.read(reportedWaitingProvider.future);
    await c.read(reportedWaitingProvider.notifier).mark(_slug, _path);

    final record = c.read(reportedWaitingProvider).requireValue;
    expect(record, contains(ReportedWaiting.keyFor(_slug, _path)));
    // Yol hub-göreli; repo olmasa biri diğerinin düğmesini kilitlerdi (L-045).
    expect(record, isNot(contains(ReportedWaiting.keyFor(_other, _path))));
  });

  test('bozuk kayıt düğmeyi kilitlemez', () async {
    SharedPreferences.setMockInitialValues({'reported-waiting': 'düz metin'});
    final c = boot();
    expect(await c.read(reportedWaitingProvider.future), isEmpty);
  });

  group('temizleme — hub\'da olmayan kayıt düşer', () {
    test('görev waiting\'ten çıkınca kayıt silinir', () async {
      final c = boot();
      await c.read(reportedWaitingProvider.future);
      await c.read(reportedWaitingProvider.notifier).mark(_slug, _path);

      // Agent bildirimi işledi: dosya artık `waiting/`te değil.
      await c
          .read(reportedWaitingProvider.notifier)
          .pruneMissing(_slug, {'hub/tasks/done/2026-08-06-release.md'});

      expect(c.read(reportedWaitingProvider).requireValue, isEmpty);
    });

    test('hub\'da duran görevin kaydı korunur', () async {
      final c = boot();
      await c.read(reportedWaitingProvider.future);
      await c.read(reportedWaitingProvider.notifier).mark(_slug, _path);

      await c.read(reportedWaitingProvider.notifier).pruneMissing(_slug, {_path});

      expect(
        c.read(reportedWaitingProvider).requireValue,
        contains(ReportedWaiting.keyFor(_slug, _path)),
      );
    });

    test('başka reponun kaydına dokunulmaz', () async {
      final c = boot();
      await c.read(reportedWaitingProvider.future);
      final notifier = c.read(reportedWaitingProvider.notifier);
      await notifier.mark(_slug, _path);
      await notifier.mark(_other, _path);

      // Bu çağrı yalnız **bir** reponun ağacını ölçtü; diğeri hakkında hiçbir
      // şey bilmiyor. Bilmediğini silmek, mükerrer bildirim yolunu yeniden
      // açardı.
      await notifier.pruneMissing(_slug, const {});

      final record = c.read(reportedWaitingProvider).requireValue;
      expect(record, isNot(contains(ReportedWaiting.keyFor(_slug, _path))));
      expect(record, contains(ReportedWaiting.keyFor(_other, _path)));
    });

    test('temizlik diske de yansır', () async {
      final c = boot();
      await c.read(reportedWaitingProvider.future);
      await c.read(reportedWaitingProvider.notifier).mark(_slug, _path);
      await c.read(reportedWaitingProvider.notifier).pruneMissing(_slug, const {});

      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('reported-waiting')!), isEmpty);
    });
  });

  group('üç ayrı cevap: evet / hayır / bilinmiyor', () {
    // "Bilmiyorum" ile "hayır" ayrı tutuluyor: kayıt yüklenirken düğmeyi açık
    // bırakmak, tam olarak önlenmek istenen mükerrer bildirimi davet ederdi.
    test('yüklenirken bilinmiyor', () {
      expect(
        reportedStateOf(const AsyncLoading(), _slug, _path),
        ReportedState.unknown,
      );
    });

    test('kayıt okunamazsa hayır — kullanıcı engellenmez', () {
      expect(
        reportedStateOf(
            AsyncError(Exception('bozuk'), StackTrace.empty), _slug, _path),
        ReportedState.no,
      );
    });

    test('kayıt varsa evet, yoksa hayır', () {
      const data = AsyncData<Map<String, String>>(
          {'$_slug|$_path': '2026-08-21T09:00:00Z'});
      expect(reportedStateOf(data, _slug, _path), ReportedState.yes);
      expect(reportedStateOf(data, _slug, 'başka/yol.md'), ReportedState.no);
    });
  });
}
