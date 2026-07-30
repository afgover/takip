import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Onboarding'de girilen hub bağlantı bilgisi.
/// Token yalnızca secure storage'da durur (R-002: sadece hub'a scope'lu PAT).
class HubConfig {
  const HubConfig({required this.owner, required this.repo, required this.token});

  final String owner;
  final String repo;
  final String token;
}

const _storage = FlutterSecureStorage();
const _kOwner = 'hub_owner';
const _kRepo = 'hub_repo';
const _kToken = 'hub_token';

/// null → onboarding gösterilir.
final hubConfigProvider =
    AsyncNotifierProvider<HubConfigNotifier, HubConfig?>(HubConfigNotifier.new);

class HubConfigNotifier extends AsyncNotifier<HubConfig?> {
  @override
  Future<HubConfig?> build() async {
    final owner = await _storage.read(key: _kOwner);
    final repo = await _storage.read(key: _kRepo);
    final token = await _storage.read(key: _kToken);
    if (owner == null || repo == null || token == null) return null;
    return HubConfig(owner: owner, repo: repo, token: token);
  }

  /// B-022: kaydetmeden önce tek GET ile doğrulama eklenecek.
  Future<void> save(HubConfig config) async {
    await _storage.write(key: _kOwner, value: config.owner);
    await _storage.write(key: _kRepo, value: config.repo);
    await _storage.write(key: _kToken, value: config.token);
    state = AsyncData(config);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
    state = const AsyncData(null);
  }
}
