import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../hub/hub_config.dart';
import 'client.dart';

/// Commit geçmişi — yoklamanın değişiklik sinyali (B-024) ve ileride aktivite
/// akışının veri kaynağı (B-045).
///
/// TODO(B-045): mesajları SYSTEM.md §8 öneklerine göre ayrıştırıp insan diline
/// çevir ("task(T-003): active → done" → "Agent T-003'ü tamamladı").
class CommitsApi {
  CommitsApi(this._dio, {required this.owner, required this.repo});

  final Dio _dio;
  final String owner;
  final String repo;

  /// Reponun son commit sha'sı; repo hiç commit almamışsa null.
  ///
  /// Yoklamanın tamamı bu tek isteğe dayanır: klasörleri ayrı ayrı taramak
  /// yerine "hub'da herhangi bir şey değişti mi?" sorusu tek çağrıyla
  /// sorulur. Değişiklik yoksa yanıt ETag sayesinde 304'tür.
  Future<String?> headSha() async {
    final res = await sendGithub(
      () => _dio.get<dynamic>(
        '/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}'
        '/commits',
        queryParameters: const {'per_page': 1},
      ),
    );

    // Önbellekten gelen yanıt burada **cevap sayılmaz**: soru "hub değişti mi"
    // ve elimizdeki eski sürümü geri okumak bu soruyu yanıtlamaz. Ağ yokken
    // içerik ekranlarının önbellekten beslenmesi doğru (B-046), ama yoklamanın
    // "her şey yolunda" sanması yanlış olurdu — kullanıcı çevrimdışı olduğunu
    // hiç öğrenemezdi.
    if (res.extra[servedFromCacheFlag] == true) {
      throw const HubNetworkError('Ağ bağlantısı yok.');
    }

    final data = res.data;
    if (data is! List) {
      throw const HubUnexpectedError('Commit listesi beklenmedik biçimde.');
    }
    if (data.isEmpty) return null;

    final sha = (data.first as Map)['sha'];
    return sha is String ? sha : null;
  }

  /// Son commit'ler — aktivite akışının kaynağı (B-045).
  Future<List<CommitInfo>> recent({int limit = 50}) async {
    final res = await sendGithub(
      () => _dio.get<dynamic>(
        '/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}'
        '/commits',
        queryParameters: {'per_page': limit},
      ),
    );

    final data = res.data;
    if (data is! List) {
      throw const HubUnexpectedError('Commit listesi beklenmedik biçimde.');
    }

    return data.whereType<Map>().map(CommitInfo.fromJson).toList();
  }
}

class CommitInfo {
  const CommitInfo({required this.sha, required this.message, this.date});

  factory CommitInfo.fromJson(Map<dynamic, dynamic> json) {
    final commit = json['commit'];
    final author = commit is Map ? commit['author'] : null;
    final raw = author is Map ? author['date'] : null;

    return CommitInfo(
      sha: json['sha'] as String? ?? '',
      message: (commit is Map ? commit['message'] as String? : null) ?? '',
      date: raw is String ? DateTime.tryParse(raw)?.toLocal() : null,
    );
  }

  final String sha;
  final String message;
  final DateTime? date;
}

final commitsApiProvider = Provider<CommitsApi>((ref) {
  final config = ref.watch(hubConfigProvider).value;
  if (config == null) {
    throw StateError('Hub yapılandırılmadı — önce onboarding tamamlanmalı.');
  }
  return CommitsApi(
    ref.watch(githubDioProvider),
    owner: config.owner,
    repo: config.repo,
  );
});
