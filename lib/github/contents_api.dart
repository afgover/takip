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
  Future<bool> pathExists(String path) async => (await probePath(path)).exists;

  /// [pathExists] + yanıtta GitHub'ın bildirdiği OAuth scope'ları (B-092).
  ///
  /// Kapsam bilgisi **fazladan istek olmadan** gelir: `X-OAuth-Scopes` her
  /// kimlikli yanıtta bulunur (klasik token'larda), yani zaten yaptığımız
  /// erişim kontrolünün yanıtından okunur. Yorumu bu katmanın işi değil —
  /// burada yalnız başlığın ham değeri taşınır (`hub/token_scope.dart`).
  ///
  /// Yol yoksa (404) yanıt yine de kimlikliydi; başlık okunabiliyorsa
  /// taşınır.
  Future<PathProbe> probePath(String path) async {
    try {
      final res = await _send(() => _dio.get<dynamic>(_url(path)));
      return PathProbe(exists: true, oauthScopes: _scopesOf(res));
    } on HubNotFoundError {
      return const PathProbe(exists: false);
    }
  }

  static String? _scopesOf(Response<dynamic> res) =>
      res.headers.value('x-oauth-scopes');

  /// Token'ın yazma izni **kesin olarak yok mu**? Varsa/bilinmiyorsa null,
  /// yoksa eksik iznin adı döner (B-026).
  ///
  /// GitHub'da bir token'ın izinlerini soracak bir uç nokta yok:
  /// `GET /repos` yanıtındaki `permissions`, token'ın kapsamını değil
  /// kullanıcının rolünü yansıtır. Geriye tek güvenilir sinyal kalıyor:
  /// yazma denemesine gelen 403.
  ///
  /// Deneme **içeriksiz** bir PUT'tur. `content` zorunlu bir alan olduğu için
  /// GitHub bu isteği yerine getiremez — yani izin olsa bile repoda hiçbir
  /// şey oluşmaz, hiçbir şey değişmez. Sonuç yorumu tek yönlüdür: 403 gelirse
  /// izin kesin yoktur; başka her yanıt (doğrulama hatası dahil) "bilinmiyor"
  /// sayılır. Böylece bu kontrol yanlış alarm veremez, yalnızca gerçek bir
  /// sorunu erken yakalayabilir.
  Future<String?> writeDenialReason(String path) async {
    try {
      await _dio.put<dynamic>(
        _url(path),
        data: {'message': 'izin denemesi (içerik gönderilmedi)'},
      );
      return null;
    } on DioException catch (e) {
      final response = e.response;
      if (response?.statusCode != 403) return null;

      // 403 rate limit de olabilir; o "izin yok" demek değildir.
      if (response!.headers.value('x-ratelimit-remaining') == '0') return null;

      // GitHub 403'te hangi iznin gerektiğini başlıkta söyler.
      return response.headers.value('x-accepted-github-permissions') ??
          'contents=write';
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
  ) =>
      sendGithub(request);
}

/// Bir yol yoklamasının sonucu: yol var mı, ve yanıt token'ın OAuth
/// scope'larını bildirdi mi (B-092).
class PathProbe {
  const PathProbe({required this.exists, this.oauthScopes});

  final bool exists;

  /// `X-OAuth-Scopes` başlığının ham değeri. Fine-grained token'larda GitHub
  /// bu başlığı hiç göndermez, o yüzden null olması olağandır.
  final String? oauthScopes;
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
