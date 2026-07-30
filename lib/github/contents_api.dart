import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../hub/hub_config.dart';
import 'client.dart';

/// Contents API sarmalayıcısı — dosya okuma/yazma/silme, SHA yönetimi.
///
/// Bu sınıf hub sözleşmesini bilmez: kendisine verilen yolu yazar, "hangi
/// klasöre yazmak serbest" sorusu üst katmanın (hub/) işidir — R-001 kısıtı
/// orada uygulanır (bkz. `hub/task_repo.dart`).
///
/// Yazma modeli: GitHub'da güncelleme optimistic-lock'ludur. Var olan bir
/// dosyayı yazarken elimizdeki [sha] gönderilir; dosya bu arada değiştiyse
/// GitHub 409/422 döner ve çağıran yeniden okuyup dener (B-033).
class ContentsApi {
  ContentsApi(this._dio, {required this.owner, required this.repo});

  final Dio _dio;
  final String owner;
  final String repo;

  /// Dizindeki kayıtlar. Yol yoksa **boş liste** döner: git'te boş dizin
  /// diye bir şey olmadığından "içi boşalmış dizin" ile "hiç olmayan dizin"
  /// API'de aynı şekilde (404) görünür; ikisi de kullanıcı için "kayıt yok"
  /// demektir. (L-005)
  Future<List<RepoEntry>> listDir(String dir) async {
    final Response<dynamic> res;
    try {
      res = await _send(() => _dio.get<dynamic>(_url(dir)));
    } on HubNotFoundError {
      return const [];
    }

    final data = res.data;
    if (data is! List) {
      throw HubUnexpectedError('Dizin bekleniyordu, dosya geldi: $dir');
    }
    return data
        .whereType<Map>()
        .map((e) => RepoEntry.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Yol repoda var mı? Yetki hataları yukarı geçer — "yok" ile "göremiyorum"
  /// karıştırılmaz (onboarding doğrulaması buna dayanır, B-022).
  Future<bool> pathExists(String path) async {
    try {
      await _send(() => _dio.get<dynamic>(_url(path)));
      return true;
    } on HubNotFoundError {
      return false;
    }
  }

  /// Tek dosyanın içeriği (base64 çözülmüş) ve sha'sı.
  Future<RepoFile> getFile(String path) async {
    final res = await _send(() => _dio.get<dynamic>(_url(path)));
    final data = res.data;
    if (data is! Map) {
      throw HubUnexpectedError('Dosya bekleniyordu, dizin geldi: $path');
    }
    return RepoFile.fromJson(data.cast<String, dynamic>());
  }

  /// Dosyayı oluşturur ya da günceller; **yeni sha**'yı döner.
  ///
  /// [sha] yalnızca güncellemede verilir (yeni dosyada null). Var olan bir
  /// dosyaya sha'sız yazmak GitHub tarafında 422'dir ve [HubConflictError]'a
  /// çevrilir.
  Future<String> putFile(
    String path,
    String content, {
    String? sha,
    required String commitMessage,
  }) async {
    final res = await _send(
      () => _dio.put<dynamic>(
        _url(path),
        data: {
          'message': commitMessage,
          'content': base64.encode(utf8.encode(content)),
          if (sha != null) 'sha': sha,
        },
      ),
    );

    final newSha = (res.data as Map?)?['content']?['sha'];
    if (newSha is! String) {
      throw const HubUnexpectedError('Yazma yanıtında sha yok.');
    }
    return newSha;
  }

  /// Dosyayı siler. Taşıma (inbox → active) = hedefe [putFile] + kaynakta
  /// [deleteFile]; sözleşmede iki ayrı commit olarak geçer (SYSTEM.md §4).
  Future<void> deleteFile(
    String path, {
    required String sha,
    required String commitMessage,
  }) async {
    await _send(
      () => _dio.delete<dynamic>(
        _url(path),
        data: {'message': commitMessage, 'sha': sha},
      ),
    );
  }

  /// `/repos/{owner}/{repo}/contents/{path}` — segmentler ayrı ayrı encode
  /// edilir ki yoldaki `/` ayraç olarak kalsın.
  String _url(String path) {
    final clean = path.split('/').where((s) => s.isNotEmpty);
    final encoded = clean.map(Uri.encodeComponent).join('/');
    return '/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}'
        '/contents/$encoded';
  }

  /// Tüm çağrılar buradan geçer: dışarı yalnızca [HubError] sızar.
  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw mapGithubError(e);
    }
  }
}

/// Dizin listesindeki tek kayıt (dosya ya da alt dizin).
class RepoEntry {
  const RepoEntry({
    required this.name,
    required this.path,
    required this.sha,
    this.isDirectory = false,
  });

  factory RepoEntry.fromJson(Map<String, dynamic> json) => RepoEntry(
        name: json['name'] as String,
        path: json['path'] as String,
        sha: json['sha'] as String,
        isDirectory: json['type'] == 'dir',
      );

  final String name;
  final String path;
  final String sha;
  final bool isDirectory;
}

class RepoFile {
  const RepoFile({
    required this.path,
    required this.sha,
    required this.content,
  });

  factory RepoFile.fromJson(Map<String, dynamic> json) {
    final encoding = json['encoding'];
    // 1 MB üstü dosyalarda GitHub içeriği göndermez (encoding: "none").
    // Hub dosyaları küçüktür; yine de sessizce boş içerik dönmeyelim.
    if (encoding != 'base64') {
      throw HubUnexpectedError(
        'Dosya Contents API ile okunamıyor (encoding: $encoding): '
        '${json['path']}',
      );
    }
    // GitHub base64'ü satırlara bölerek gönderir; boşluklar temizlenmeli.
    final raw = (json['content'] as String).replaceAll(RegExp(r'\s'), '');
    return RepoFile(
      path: json['path'] as String,
      sha: json['sha'] as String,
      content: utf8.decode(base64.decode(raw)),
    );
  }

  final String path;
  final String sha;
  final String content; // çözülmüş (base64 değil)
}

/// Onboarding tamamlanmadan okunmaz; ekranlar config null iken onboarding
/// gösterir (bkz. `app.dart`).
final contentsApiProvider = Provider<ContentsApi>((ref) {
  final config = ref.watch(hubConfigProvider).value;
  if (config == null) {
    throw StateError('Hub yapılandırılmadı — önce onboarding tamamlanmalı.');
  }
  return ContentsApi(
    ref.watch(githubDioProvider),
    owner: config.owner,
    repo: config.repo,
  );
});
