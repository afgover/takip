import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'merkez_api.dart';

/// Parola saklanmaz, yalnız Merkez'in verdiği belirteç (R-005).
const merkezTokenKey = 'merkez_token';

final merkezDioProvider = Provider<Dio>((ref) => MerkezApi.buildDio());

final merkezApiProvider =
    Provider<MerkezApi>((ref) => MerkezApi(ref.watch(merkezDioProvider)));

/// Oturum: null = bağlı değil.
final merkezTokenProvider =
    AsyncNotifierProvider<MerkezTokenNotifier, String?>(MerkezTokenNotifier.new);

class MerkezTokenNotifier extends AsyncNotifier<String?> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> build() => _storage.read(key: merkezTokenKey);

  Future<void> login(String password) async {
    final token = await ref.read(merkezApiProvider).login(password);
    await _storage.write(key: merkezTokenKey, value: token);
    state = AsyncData(token);
  }

  Future<void> logout() async {
    await _storage.delete(key: merkezTokenKey);
    state = const AsyncData(null);
  }
}

/// `/today`. Belirteç reddedilirse oturum kapanır, ekran giriş formuna döner.
final merkezTodayProvider = FutureProvider<TodayData?>((ref) async {
  final token = await ref.watch(merkezTokenProvider.future);
  if (token == null) return null;
  try {
    return await ref.read(merkezApiProvider).today(token);
  } on MerkezError catch (e) {
    if (e.kind == MerkezErrorKind.unauthorized) {
      await ref.read(merkezTokenProvider.notifier).logout();
      return null;
    }
    rethrow;
  }
});
