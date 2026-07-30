import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/core/errors.dart';
import 'package:takip/github/commits_api.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/hub_watcher.dart';

class FakeCommitsApi extends CommitsApi {
  FakeCommitsApi() : super(Dio(), owner: 'afgover', repo: 'takip');

  int calls = 0;
  String? sha = 'commit-1';
  Object? error;

  /// Yanıtı geciktirmek için (üst üste binen istek testi).
  Completer<String?>? gate;

  @override
  Future<String?> headSha() async {
    calls++;
    if (error != null) throw error!;
    if (gate != null) return gate!.future;
    return sha;
  }
}

class FakeHubConfigNotifier extends HubConfigNotifier {
  FakeHubConfigNotifier(this.config);
  HubConfig? config;

  @override
  Future<HubConfig?> build() async => config;

  void switchTo(HubConfig next) {
    config = next;
    state = AsyncData(next);
  }
}

const _config = HubConfig(owner: 'afgover', repo: 'takip', token: 't');

/// n yoklama aralığı kadar süre.
Duration intervals(int n) => Hub.defaultPollInterval * n;

({ProviderContainer container, FakeCommitsApi api, FakeHubConfigNotifier cfg})
    boot(FakeAsync async, {HubConfig? config}) {
  final api = FakeCommitsApi();
  final notifier = FakeHubConfigNotifier(config ?? _config);
  final container = ProviderContainer(
    overrides: [
      commitsApiProvider.overrideWithValue(api),
      hubConfigProvider.overrideWith(() => notifier),
    ],
  );
  // AsyncNotifier'ın ilk build'i çözülsün.
  container.read(hubConfigProvider);
  async.flushMicrotasks();
  return (container: container, api: api, cfg: notifier);
}

void main() {
  test('start hemen bir kontrol yapar ve aralıkla sürdürür', () {
    fakeAsync((async) {
      final t = boot(async);
      addTearDown(t.container.dispose);

      t.container.read(hubWatcherProvider.notifier).start();
      async.flushMicrotasks();
      expect(t.api.calls, 1, reason: 'ilk kontrol beklenmeden yapılmalı');

      async.elapse(intervals(1));
      expect(t.api.calls, 2);

      async.elapse(intervals(3));
      expect(t.api.calls, 5);
    });
  });

  test('stop sonrası yoklama durur', () {
    fakeAsync((async) {
      final t = boot(async);
      addTearDown(t.container.dispose);
      final watcher = t.container.read(hubWatcherProvider.notifier);

      watcher.start();
      async.flushMicrotasks();
      watcher.stop();
      async.elapse(intervals(5));

      expect(t.api.calls, 1);
      expect(t.container.read(hubWatcherProvider).watching, isFalse);
    });
  });

  test('sha değişince lastChangedAt güncellenir, değişmeyince durur', () {
    fakeAsync((async) {
      final t = boot(async);
      addTearDown(t.container.dispose);

      t.container.read(hubWatcherProvider.notifier).start();
      async.flushMicrotasks();
      final firstChange = t.container.read(hubWatcherProvider).lastChangedAt;
      expect(firstChange, isNotNull);
      expect(t.container.read(hubWatcherProvider).headSha, 'commit-1');

      // Değişiklik yok: sha aynı kalır, lastChangedAt sabit.
      async.elapse(intervals(1));
      expect(t.container.read(hubWatcherProvider).lastChangedAt, firstChange);

      t.api.sha = 'commit-2';
      async.elapse(intervals(1));
      final status = t.container.read(hubWatcherProvider);
      expect(status.headSha, 'commit-2');
      expect(status.lastChangedAt, isNot(firstChange));
    });
  });

  test('yavaş yanıtta istekler üst üste binmez', () {
    fakeAsync((async) {
      final t = boot(async);
      addTearDown(t.container.dispose);
      t.api.gate = Completer<String?>();

      t.container.read(hubWatcherProvider.notifier).start();
      async.flushMicrotasks();
      expect(t.api.calls, 1);

      // İlk istek yanıtlanmadan üç aralık geçse de yeni istek atılmaz.
      async.elapse(intervals(3));
      expect(t.api.calls, 1);

      t.api.gate!.complete('commit-1');
      t.api.gate = null;
      async.flushMicrotasks();

      async.elapse(intervals(1));
      expect(t.api.calls, 2);
    });
  });

  test('token geçersizse yoklama durur (boşuna istek atılmaz)', () {
    fakeAsync((async) {
      final t = boot(async);
      addTearDown(t.container.dispose);
      t.api.error = const HubAuthError('Token geçersiz.');

      t.container.read(hubWatcherProvider.notifier).start();
      async.flushMicrotasks();
      async.elapse(intervals(5));

      expect(t.api.calls, 1);
      final status = t.container.read(hubWatcherProvider);
      expect(status.error, isA<HubAuthError>());
      expect(status.watching, isFalse);
    });
  });

  test('rate limit\'te reset zamanına kadar beklenir', () {
    fakeAsync((async) {
      final t = boot(async);
      addTearDown(t.container.dispose);
      t.api.error = HubRateLimitError(
        'Limit doldu.',
        resetAt: clock.now().add(const Duration(minutes: 5)),
      );

      t.container.read(hubWatcherProvider.notifier).start();
      async.flushMicrotasks();
      expect(t.api.calls, 1);

      // Beş dakika dolmadan yeni istek yok.
      async.elapse(const Duration(minutes: 4));
      expect(t.api.calls, 1);

      t.api.error = null;
      async.elapse(const Duration(minutes: 2));
      expect(t.api.calls, greaterThan(1));
      expect(t.container.read(hubWatcherProvider).error, isNull);
    });
  });

  test('başarılı yoklama önceki hatayı temizler', () {
    fakeAsync((async) {
      final t = boot(async);
      addTearDown(t.container.dispose);
      t.api.error = const HubNetworkError('Ağ yok.');

      t.container.read(hubWatcherProvider.notifier).start();
      async.flushMicrotasks();
      expect(t.container.read(hubWatcherProvider).error, isNotNull);

      t.api.error = null;
      async.elapse(intervals(1));
      expect(t.container.read(hubWatcherProvider).error, isNull);
    });
  });

  test('yapılandırma yokken istek atılmaz', () {
    fakeAsync((async) {
      final api = FakeCommitsApi();
      final container = ProviderContainer(
        overrides: [
          commitsApiProvider.overrideWithValue(api),
          hubConfigProvider.overrideWith(() => FakeHubConfigNotifier(null)),
        ],
      );
      addTearDown(container.dispose);
      container.read(hubConfigProvider);
      async.flushMicrotasks();

      container.read(hubWatcherProvider.notifier).start();
      async.flushMicrotasks();
      async.elapse(intervals(3));

      expect(api.calls, 0);
    });
  });

  test('repo değişince önceki hub\'ın sürümü taşınmaz', () {
    fakeAsync((async) {
      final t = boot(async);
      addTearDown(t.container.dispose);

      t.container.read(hubWatcherProvider.notifier).start();
      async.flushMicrotasks();
      expect(t.container.read(hubWatcherProvider).headSha, 'commit-1');

      t.cfg.switchTo(
        const HubConfig(owner: 'afgover', repo: 'baska', token: 't'),
      );
      t.api.sha = 'commit-1'; // yeni repoda tesadüfen aynı sha olsa bile
      async.elapse(intervals(1));

      final status = t.container.read(hubWatcherProvider);
      expect(status.headSha, 'commit-1');
      expect(status.lastChangedAt, isNotNull,
          reason: 'yeni repo için değişiklik olarak sayılmalı');
    });
  });
}
