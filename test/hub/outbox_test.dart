import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:takip/github/contents_api.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/hub_connections.dart';
import 'package:takip/hub/models/task_draft.dart';
import 'package:takip/hub/outbox.dart';
import 'package:takip/hub/task_repo.dart';

import '../github/contents_api_test.dart' show FakeAdapter, jsonResponse;

TaskDraft draft(String title) => withClock(
      Clock.fixed(DateTime.utc(2026, 7, 30, 10)),
      () => TaskDraft.create(title: title),
    );

({ProviderContainer container, FakeAdapter adapter}) boot(
  ResponseBody Function(RequestOptions options, String? body) handler,
) {
  final adapter = FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;
  final container = ProviderContainer(
    overrides: [
      taskRepoProvider.overrideWithValue(
        TaskRepo(ContentsApi(dio, owner: 'afgover', repo: 'takip')),
      ),
    ],
  );
  return (container: container, adapter: adapter);
}

ResponseBody ok(RequestOptions _, String? __) => jsonResponse({
      'content': {'sha': 'yeni'}
    });

ResponseBody offline(RequestOptions options, String? _) =>
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'ağ yok',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('kuyruk diske yazılır ve yeniden okunur', () async {
    final first = boot(ok);
    addTearDown(first.container.dispose);

    await first.container.read(outboxProvider.future);
    await first.container.read(outboxProvider.notifier).add(draft('Market'));

    // Uygulama kapanıp açılmış gibi: yeni container, aynı disk.
    final second = boot(ok);
    addTearDown(second.container.dispose);
    final restored = await second.container.read(outboxProvider.future);

    expect(restored, hasLength(1));
    expect(restored.single.title, 'Market');
  });

  test('flush kuyruğu gönderir ve boşaltır', () async {
    final t = boot(ok);
    addTearDown(t.container.dispose);

    await t.container.read(outboxProvider.future);
    final outbox = t.container.read(outboxProvider.notifier);
    await outbox.add(draft('Market'));
    await outbox.add(draft('Fatura'));

    await outbox.flush();

    expect(t.container.read(outboxProvider).valueOrNull, isEmpty);
    expect(t.adapter.requests, hasLength(2));
    expect(t.adapter.requests.first.method, 'PUT');

    final sent = jsonDecode(t.adapter.bodies.first!) as Map;
    expect(sent['message'], "task(pending): inbox'a eklendi (app)");
  });

  test('ağ hâlâ yoksa kuyruk korunur', () async {
    final t = boot(offline);
    addTearDown(t.container.dispose);

    await t.container.read(outboxProvider.future);
    final outbox = t.container.read(outboxProvider.notifier);
    await outbox.add(draft('Market'));

    await outbox.flush();

    expect(t.container.read(outboxProvider).valueOrNull, hasLength(1));
  });

  test('ağ yoksa kalan taslaklar için boşuna istek atılmaz', () async {
    final t = boot(offline);
    addTearDown(t.container.dispose);

    await t.container.read(outboxProvider.future);
    final outbox = t.container.read(outboxProvider.notifier);
    await outbox.add(draft('Market'));
    await outbox.add(draft('Fatura'));
    await outbox.add(draft('Rapor'));

    await outbox.flush();

    expect(t.adapter.requests, hasLength(1),
        reason: 'ilk denemede ağ yoksa diğerleri denenmez');
    expect(t.container.read(outboxProvider).valueOrNull, hasLength(3));
  });

  test('kalıcı hata diğer taslakları engellemez', () async {
    var call = 0;
    final t = boot((options, _) {
      call++;
      // İlk taslak yetki hatası alıyor, ikincisi gidiyor.
      return call == 1
          ? jsonResponse({'message': 'Bad credentials'}, status: 401)
          : jsonResponse({
              'content': {'sha': 'yeni'}
            });
    });
    addTearDown(t.container.dispose);

    await t.container.read(outboxProvider.future);
    final outbox = t.container.read(outboxProvider.notifier);
    await outbox.add(draft('Market'));
    await outbox.add(draft('Fatura'));

    await outbox.flush();

    final left = t.container.read(outboxProvider).valueOrNull!;
    expect(left, hasLength(1));
    expect(left.single.title, 'Market');
    expect(t.adapter.requests, hasLength(2));
  });

  test('bozuk kayıt kuyruğu kilitlemez', () async {
    SharedPreferences.setMockInitialValues({
      'outbox': ['bu json değil', jsonEncode(draft('Market').toJson())],
    });

    final t = boot(ok);
    addTearDown(t.container.dispose);

    final loaded = await t.container.read(outboxProvider.future);
    expect(loaded, hasLength(1));
    expect(loaded.single.title, 'Market');
  });

  test('kuyruk boşken flush istek atmaz', () async {
    final t = boot(ok);
    addTearDown(t.container.dispose);

    await t.container.read(outboxProvider.future);
    await t.container.read(outboxProvider.notifier).flush();

    expect(t.adapter.requests, isEmpty);
  });

  test('taslak tek tek kaldırılabilir', () async {
    final t = boot(ok);
    addTearDown(t.container.dispose);

    await t.container.read(outboxProvider.future);
    final outbox = t.container.read(outboxProvider.notifier);
    final market = draft('Market');
    await outbox.add(market);
    await outbox.add(draft('Fatura'));

    await outbox.remove(market.fileName);

    final left = t.container.read(outboxProvider).valueOrNull!;
    expect(left.map((d) => d.title), ['Fatura']);
  });

  group('çoklu repo (T-003)', () {
    /// Aktif bağlantısı kurulu bir kap; `sent` aktif olmayan repolara giden
    /// gönderimleri kaydeder (ağa çıkılmaz).
    Future<
        ({
          ProviderContainer container,
          FakeAdapter adapter,
          List<({String slug, String title})> sent,
        })> bootWithRepos(
      List<String> slugs, {
      ResponseBody Function(RequestOptions, String?) handler = ok,
    }) async {
      FlutterSecureStorage.setMockInitialValues({});
      final sent = <({String slug, String title})>[];
      final adapter = FakeAdapter(handler);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = adapter;

      final container = ProviderContainer(
        overrides: [
          // Aktif repoya giden yol (paylaşılan depo).
          taskRepoProvider.overrideWithValue(
            TaskRepo(ContentsApi(dio, owner: 'a', repo: 'bir')),
          ),
          // Aktif olmayan repoya giden yol.
          draftSenderProvider.overrideWithValue(
            (target, draft) async =>
                sent.add((slug: target.slug, title: draft.title)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hubConnectionsProvider.future);
      final notifier = container.read(hubConnectionsProvider.notifier);
      for (final slug in slugs) {
        final parsed = HubConfig.parseRepo(slug)!;
        await notifier.upsertAndActivate(
          HubConfig(owner: parsed.owner, repo: parsed.repo, token: 't'),
        );
      }
      // Uygulamada `app.dart` kabuğu çizmeden önce bunu çözüyor; kuyruk da
      // aktif bağlantıyı senkron okuduğu için testte aynısını yapıyoruz.
      await container.read(hubConfigProvider.future);
      await container.read(outboxProvider.future);
      return (container: container, adapter: adapter, sent: sent);
    }

    test('kuyruğa alınan taslak o anki aktif repoyla damgalanır', () async {
      final t = await bootWithRepos(['a/bir', 'b/iki']);

      await t.container.read(outboxProvider.notifier).add(draft('Market'));

      final queued = t.container.read(outboxProvider).valueOrNull!;
      expect(queued.single.repoSlug, 'b/iki');
    });

    test('damgalı taslağın damgası ezilmez (S-2026-08-12)', () async {
      // Bekleyen-görev bildirimi ekranda görevin kendi reposuyla damgalanıp
      // geliyor; add() koşulsuz yeniden damgalasaydı ağ hatasında kuyruğa
      // giren her bildirim aktif repoya yönlenirdi. Üç bildirim tam bu yoldan
      // financer_takip'e düştü — bu test o hatanın kendisi.
      final t = await bootWithRepos(['a/bir', 'b/iki']); // aktif: b/iki

      await t.container
          .read(outboxProvider.notifier)
          .add(draft('Bildirim').forRepo('a/bir'));

      final queued = t.container.read(outboxProvider).valueOrNull!;
      expect(queued.single.repoSlug, 'a/bir',
          reason: 'aktif repo (b/iki) damgayı ezmemeli');

      await t.container.read(outboxProvider.notifier).flush();
      expect(t.sent.map((e) => e.slug), ['a/bir']);
    });

    test('repo değişse bile taslak kendi reposuna gider', () async {
      final t = await bootWithRepos(['a/bir', 'b/iki']);
      final outbox = t.container.read(outboxProvider.notifier);

      // Çevrimdışıyken b/iki'ye görev yazıldı.
      await outbox.add(draft('B görevi'));
      // Sonra kullanıcı a/bir'e geçti ve bağlantı geldi.
      await t.container.read(hubConnectionsProvider.notifier).setActive('a/bir');

      await outbox.flush();

      // Görev aktif repoya (a/bir) değil, yazıldığı repoya gitmeli.
      expect(t.sent.map((e) => e.slug), ['b/iki']);
      expect(t.adapter.requests, isEmpty,
          reason: 'aktif repoya (a/bir) hiçbir şey yazılmamalı');
      expect(t.container.read(outboxProvider).valueOrNull, isEmpty);
    });

    test('damgalı taslak aktif repoya ait olsa da hedefi açıkça belirtilir',
        () async {
      final t = await bootWithRepos(['a/bir']);
      final outbox = t.container.read(outboxProvider.notifier);

      await outbox.add(draft('Market'));
      await outbox.flush();

      // Paylaşılan depo `hubConfigProvider` üzerinden bayat kalabildiği için
      // hedef tahmine bırakılmaz; damga varsa açık gönderim kullanılır.
      expect(t.sent.map((e) => e.slug), ['a/bir']);
      expect(t.container.read(outboxProvider).valueOrNull, isEmpty);
    });

    test('damgasız taslak (T-003 öncesi) paylaşılan depodan gider', () async {
      // Eski sürümden kalmış kayıt: diskte repoSlug alanı yok.
      final legacy = draft('Eski görev').toJson();
      expect(legacy.containsKey('repoSlug'), isFalse);
      SharedPreferences.setMockInitialValues({
        'outbox': [jsonEncode(legacy)],
      });

      final t = await bootWithRepos(['a/bir']);
      await t.container.read(outboxProvider.notifier).flush();

      expect(t.adapter.requests, hasLength(1));
      expect(t.sent, isEmpty);
      expect(t.container.read(outboxProvider).valueOrNull, isEmpty);
    });

    test('reposu kaldırılan taslak kuyrukta kalır, atılmaz', () async {
      final t = await bootWithRepos(['a/bir', 'b/iki']);
      final outbox = t.container.read(outboxProvider.notifier);

      await outbox.add(draft('B görevi')); // b/iki damgalı
      await t.container.read(hubConnectionsProvider.notifier).remove('b/iki');

      await outbox.flush();

      expect(t.sent, isEmpty);
      expect(t.adapter.requests, isEmpty,
          reason: 'silinmiş reponun görevi başka repoya yazılmamalı');
      final left = t.container.read(outboxProvider).valueOrNull!;
      expect(left, hasLength(1),
          reason: 'kullanıcının yazdığı iş sessizce kaybolmamalı');
      expect(left.single.title, 'B görevi');
    });
  });
}
