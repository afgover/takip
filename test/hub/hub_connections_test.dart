import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/hub_connections.dart';

HubConfig conn(String slug, {String token = 't', String? label}) {
  final parsed = HubConfig.parseRepo(slug)!;
  return HubConfig(
    owner: parsed.owner,
    repo: parsed.repo,
    token: token,
    label: label,
  );
}

String encoded(List<HubConfig> connections) =>
    jsonEncode([for (final c in connections) c.toJson()]);

ProviderContainer boot() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('HubConfig', () {
    test('JSON round-trip ad alanını korur', () {
      final original = conn('afgover/takip', token: 'gizli', label: 'Takip');
      final restored = HubConfig.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.slug, 'afgover/takip');
      expect(restored.token, 'gizli');
      expect(restored.label, 'Takip');
    });

    test('ad verilmemişse görünen isim slug olur', () {
      expect(conn('afgover/takip').displayName, 'afgover/takip');
      expect(conn('afgover/takip', label: 'Takip').displayName, 'Takip');
      // Yalnızca boşluktan ibaret ad, ad sayılmaz.
      expect(conn('afgover/takip', label: '   ').displayName, 'afgover/takip');
    });
  });

  group('HubConnectionsState', () {
    test('aktif kayıt yoksa ilk bağlantıya düşülür', () {
      final state = HubConnectionsState(
        connections: [conn('a/bir'), conn('b/iki')],
        activeSlug: 'silinmis/repo',
      );
      // Elde çalışan bağlantı varken kullanıcı onboarding'e atılmamalı.
      expect(state.active?.slug, 'a/bir');
    });

    test('liste boşsa aktif yoktur', () {
      expect(const HubConnectionsState().active, isNull);
      expect(const HubConnectionsState().isEmpty, isTrue);
    });
  });

  group('depolama', () {
    test('T-003 öncesi tek bağlantı göç eder ve eski anahtarlar silinir',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        HubConnectionsStore.legacyOwnerKey: 'afgover',
        HubConnectionsStore.legacyRepoKey: 'takip',
        HubConnectionsStore.legacyTokenKey: 'eski-token',
      });

      const store = HubConnectionsStore();
      final state = await store.load();

      expect(state.length, 1);
      expect(state.active?.slug, 'afgover/takip');
      expect(state.active?.token, 'eski-token',
          reason: 'göç sonrası kullanıcı token\'ı yeniden girmek zorunda '
              'kalmamalı');

      // Yeni biçim yazılmış, eskiler temizlenmiş olmalı.
      const raw = FlutterSecureStorage();
      expect(await raw.read(key: HubConnectionsStore.listKey), isNotNull);
      expect(await raw.read(key: HubConnectionsStore.legacyTokenKey), isNull);

      // İkinci okuma göç yolundan geçmeden aynı sonucu vermeli.
      expect((await store.load()).active?.slug, 'afgover/takip');
    });

    test('kayıt yoksa boş durum döner', () async {
      expect((await const HubConnectionsStore().load()).isEmpty, isTrue);
    });

    test('bozuk JSON bağlantıyı silmez, boş durum döner', () async {
      FlutterSecureStorage.setMockInitialValues({
        HubConnectionsStore.listKey: 'bu json değil',
      });
      expect((await const HubConnectionsStore().load()).isEmpty, isTrue);
    });

    test('listedeki bozuk kayıt diğerlerini düşürmez', () async {
      FlutterSecureStorage.setMockInitialValues({
        HubConnectionsStore.listKey: jsonEncode([
          {'owner': 'a', 'repo': 'bir', 'token': 't'},
          {'owner': 'eksik-token'},
        ]),
      });

      final state = await const HubConnectionsStore().load();
      expect(state.length, 1);
      expect(state.connections.single.slug, 'a/bir');
    });
  });

  group('HubConnections', () {
    test('ilk bağlantı eklenince aktif olur', () async {
      final container = boot();
      await container.read(hubConnectionsProvider.future);

      await container
          .read(hubConnectionsProvider.notifier)
          .upsertAndActivate(conn('afgover/takip'));

      final state = container.read(hubConnectionsProvider).value!;
      expect(state.length, 1);
      expect(state.active?.slug, 'afgover/takip');
      // hubConfigProvider aktif bağlantıyı yayınlar.
      expect(await container.read(hubConfigProvider.future), isNotNull);
    });

    test('aynı repo ikinci kez eklenince kopya oluşmaz, token yenilenir',
        () async {
      final container = boot();
      await container.read(hubConnectionsProvider.future);
      final notifier = container.read(hubConnectionsProvider.notifier);

      await notifier.upsertAndActivate(conn('a/bir', token: 'eski', label: 'Bir'));
      await notifier.upsertAndActivate(conn('a/bir', token: 'yeni'));

      final state = container.read(hubConnectionsProvider).value!;
      expect(state.length, 1, reason: 'aynı repo iki kayıt oluşturmamalı');
      expect(state.active?.token, 'yeni');
      expect(state.active?.label, 'Bir',
          reason: 'ad girilmediyse önceki ad korunmalı');
    });

    test('ikinci repo eklenince aktif olur, ilki listede kalır', () async {
      final container = boot();
      await container.read(hubConnectionsProvider.future);
      final notifier = container.read(hubConnectionsProvider.notifier);

      await notifier.upsertAndActivate(conn('a/bir'));
      await notifier.upsertAndActivate(conn('b/iki'));

      final state = container.read(hubConnectionsProvider).value!;
      expect(state.connections.map((c) => c.slug), ['a/bir', 'b/iki']);
      expect(state.active?.slug, 'b/iki');
    });

    test('setActive aktif repoyu değiştirir, bilinmeyen slug yok sayılır',
        () async {
      final container = boot();
      await container.read(hubConnectionsProvider.future);
      final notifier = container.read(hubConnectionsProvider.notifier);

      await notifier.upsertAndActivate(conn('a/bir'));
      await notifier.upsertAndActivate(conn('b/iki'));

      await notifier.setActive('a/bir');
      expect(container.read(hubConnectionsProvider).value!.active?.slug, 'a/bir');

      await notifier.setActive('yok/olan');
      expect(container.read(hubConnectionsProvider).value!.active?.slug, 'a/bir');
    });

    test('aktif repo silinince sıradaki aktif olur', () async {
      final container = boot();
      await container.read(hubConnectionsProvider.future);
      final notifier = container.read(hubConnectionsProvider.notifier);

      await notifier.upsertAndActivate(conn('a/bir'));
      await notifier.upsertAndActivate(conn('b/iki'));
      await notifier.remove('b/iki');

      final state = container.read(hubConnectionsProvider).value!;
      expect(state.length, 1);
      expect(state.active?.slug, 'a/bir');
    });

    test('son repo silinince onboarding\'e dönülür', () async {
      final container = boot();
      await container.read(hubConnectionsProvider.future);
      final notifier = container.read(hubConnectionsProvider.notifier);

      await notifier.upsertAndActivate(conn('a/bir'));
      await notifier.remove('a/bir');

      expect(container.read(hubConnectionsProvider).value!.isEmpty, isTrue);
      expect(await container.read(hubConfigProvider.future), isNull);
    });

    test('bağlantılar diske yazılır ve yeniden okunur', () async {
      final first = boot();
      await first.read(hubConnectionsProvider.future);
      await first
          .read(hubConnectionsProvider.notifier)
          .upsertAndActivate(conn('a/bir', label: 'Bir'));
      await first
          .read(hubConnectionsProvider.notifier)
          .upsertAndActivate(conn('b/iki'));
      await first.read(hubConnectionsProvider.notifier).setActive('a/bir');

      // Uygulama kapanıp açılmış gibi: yeni container, aynı depo.
      final second = boot();
      final state = await second.read(hubConnectionsProvider.future);

      expect(state.connections.map((c) => c.slug), ['a/bir', 'b/iki']);
      expect(state.active?.slug, 'a/bir', reason: 'aktif seçim de kalıcı olmalı');
      expect(state.active?.label, 'Bir');
    });

    test('removeAll her şeyi siler', () async {
      final container = boot();
      await container.read(hubConnectionsProvider.future);
      final notifier = container.read(hubConnectionsProvider.notifier);

      await notifier.upsertAndActivate(conn('a/bir'));
      await notifier.removeAll();

      expect(container.read(hubConnectionsProvider).value!.isEmpty, isTrue);
      expect(
        await const FlutterSecureStorage().read(key: HubConnectionsStore.listKey),
        isNull,
      );
    });
  });
}
