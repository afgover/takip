import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../hub/hub_config.dart';

/// GitHub REST istemcisi. Bu katman hub sözleşmesini bilmez; saf API'dir.
///
/// TODO(B-024): ETag interceptor'ı — 304'te önbellekten dön, limit tüketme.
///
/// [readToken] her istekte çağrılır: token Dio örneğine gömülmez. Böylece
/// kullanıcı ayarlardan token değiştirdiğinde (B-051) elde eski token kalmaz,
/// ve onboarding henüz kaydedilmemiş bir aday token'la doğrulama yapabilir
/// (B-022).
Dio buildGithubDio(String? Function() readToken) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.github.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
}

final githubDioProvider = Provider<Dio>((ref) {
  final dio = buildGithubDio(() => ref.read(hubConfigProvider).value?.token);
  ref.onDispose(dio.close);
  return dio;
});

/// Dio istisnasını uygulama hata modeline (core/errors.dart) çevirir.
///
/// Ekranlar `HubError` dışında bir istisna görmez; B-050'deki hata UX'i bu
/// tiplere göre dallanır, B-032 outbox'ı yalnız [HubNetworkError]'da devreye
/// girer, B-033 yeniden deneme akışı yalnız [HubConflictError]'ı yakalar.
HubError mapGithubError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const HubNetworkError('Bağlantı zaman aşımına uğradı.');
    case DioExceptionType.connectionError:
      return const HubNetworkError('Ağ bağlantısı yok.');
    case DioExceptionType.badCertificate:
      return const HubNetworkError('Sunucu sertifikası doğrulanamadı.');
    case DioExceptionType.cancel:
      return const HubNetworkError('İstek iptal edildi.');
    case DioExceptionType.unknown:
      if (e.error is SocketException) {
        return const HubNetworkError('Ağ bağlantısı yok.');
      }
      return HubUnexpectedError('Beklenmeyen hata: ${e.message ?? e.error}');
    case DioExceptionType.badResponse:
      return mapGithubResponse(e.response!);
  }
}

/// Başarısız bir yanıtı hata modeline çevirir (test edilebilirlik için ayrı).
HubError mapGithubResponse(Response<dynamic> res) {
  final status = res.statusCode;
  final detail = _githubMessage(res);

  switch (status) {
    case 401:
      return HubAuthError('Token geçersiz veya süresi dolmuş. ($detail)');

    // 403 hem yetki hem rate limit anlamına gelebilir; ayrım header'dadır.
    case 403:
    case 429:
      if (status == 429 || res.headers.value('x-ratelimit-remaining') == '0') {
        return HubRateLimitError(
          'GitHub istek limiti doldu. ($detail)',
          resetAt: _rateLimitReset(res),
        );
      }
      return HubAuthError(
        "Bu işlem için yetki yok — token'ın izinlerini kontrol edin. ($detail)",
      );

    case 404:
      return HubNotFoundError('Kayıt bulunamadı. ($detail)');

    case 409:
      return HubConflictError('Dosya bu arada değişti. ($detail)');

    // 422: sha verilmeden güncelleme denendi ya da sha eşleşmedi — çağıran
    // için 409 ile aynı çözüm: yeniden oku, yeniden dene (B-033).
    case 422:
      if (detail.toLowerCase().contains('sha')) {
        return HubConflictError('Dosya bu arada değişti. ($detail)');
      }
      return HubUnexpectedError('İstek reddedildi: $detail', statusCode: 422);

    default:
      return HubUnexpectedError(
        'GitHub beklenmeyen yanıt verdi: $detail',
        statusCode: status,
      );
  }
}

DateTime? _rateLimitReset(Response<dynamic> res) {
  final epoch = int.tryParse(res.headers.value('x-ratelimit-reset') ?? '');
  if (epoch == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
}

String _githubMessage(Response<dynamic> res) {
  final data = res.data;
  if (data is Map && data['message'] is String) return data['message'] as String;
  return 'HTTP ${res.statusCode}';
}
