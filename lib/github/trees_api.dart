import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../hub/hub_config.dart';
import 'client.dart';

/// Ağaçtaki tek kayıt.
class TreeEntry {
  const TreeEntry({
    required this.path,
    required this.sha,
    required this.isFile,
    this.size,
  });

  final String path;
  final String sha;
  final bool isFile;
  final int? size;

  String get name => path.split('/').last;
}

/// Git Trees API — reponun tüm yollarını **tek istekte** verir.
///
/// Tarayıcı (Faz 4) altı kategoriyi de aynı ağaçtan çıkarır. Alternatif,
/// her klasör için ayrı `contents` isteği atmaktı: `sessions/` içindeki her
/// oturum, `artifacts/` içindeki her klasör... yani kayıt sayısıyla büyüyen
/// istek sayısı. Ağaç isteği sabit bir tanedir ve ETag'lendiği için
/// değişiklik yokken limitten düşmez (B-024, SK-002).
class TreesApi {
  TreesApi(this._dio, {required this.owner, required this.repo});

  final Dio _dio;
  final String owner;
  final String repo;

  Future<List<TreeEntry>> recursive({String ref = 'HEAD'}) async {
    final res = await sendGithub(
      () => _dio.get<dynamic>(
        '/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}'
        '/git/trees/${Uri.encodeComponent(ref)}',
        queryParameters: const {'recursive': '1'},
      ),
    );

    final data = res.data;
    if (data is! Map || data['tree'] is! List) {
      throw const HubUnexpectedError('Ağaç yanıtı beklenmedik biçimde.');
    }

    // GitHub çok büyük repolarda ağacı kırpar. Hub bu boyuta ulaşmaz ama
    // sessizce eksik liste göstermektense belli edelim.
    if (data['truncated'] == true) {
      throw const HubUnexpectedError(
        'Repo ağacı çok büyük olduğu için eksik geldi.',
      );
    }

    return (data['tree'] as List)
        .whereType<Map>()
        .map((e) => TreeEntry(
              path: e['path'] as String,
              sha: e['sha'] as String,
              isFile: e['type'] == 'blob',
              size: e['size'] as int?,
            ))
        .toList();
  }
}

final treesApiProvider = Provider<TreesApi>((ref) {
  final config = ref.watch(hubConfigProvider).value;
  if (config == null) {
    throw StateError('Hub yapılandırılmadı — önce onboarding tamamlanmalı.');
  }
  return TreesApi(
    ref.watch(githubDioProvider),
    owner: config.owner,
    repo: config.repo,
  );
});
