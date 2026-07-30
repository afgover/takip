import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/errors.dart';
import '../hub/hub_config.dart';

/// GET yanıtlarının ETag'lerini ve gövdelerini tutan doğrulama önbelleği.
///
/// Bu bir **süre bazlı** önbellek değildir: her istek yine sunucuya gider,
/// yalnızca `If-None-Match` başlığıyla. Sunucu "değişmedi" (304) derse gövde
/// buradan verilir. Dolayısıyla bayat veri gösterme riski yoktur — yazma
/// sonrası bir sonraki GET, ETag tutmadığı için 200 ve yeni içerik döner.
///
/// Kazanç: 304 yanıtları GitHub'ın istek limitinden düşmez (SK-002), yani
/// 45 saniyelik yoklama pratikte bedavadır.
class EtagCache {
  EtagCache({this.onChanged});

  final _entries = <String, ({String etag, dynamic data})>{};

  /// Önbellek değişince çağrılır — kalıcılaştırma buna bağlanır (B-046).
  final void Function()? onChanged;

  /// Diske yazılacak en fazla kayıt (en son yazılanlar önce).
  static const maxPersistedEntries = 80;

  static String keyFor(RequestOptions options) =>
      '${options.method} ${options.uri}';

  String? etagOf(String key) => _entries[key]?.etag;
  bool has(String key) => _entries.containsKey(key);
  dynamic dataOf(String key) => _entries[key]?.data;

  void write(String key, String etag, dynamic data) {
    _entries[key] = (etag: etag, data: data);
    onChanged?.call();
  }

  void clear() {
    _entries.clear();
    onChanged?.call();
  }

  int get length => _entries.length;

  /// Uygulama kapanıp açıldığında önbellek boş başlamasın diye (B-046).
  /// Kayıtlar sunucudan geldiği gibi (çözülmüş JSON) saklanır.
  Map<String, dynamic> toJson() {
    final keys = _entries.keys.toList().reversed.take(maxPersistedEntries);
    return {
      for (final key in keys)
        key: {'etag': _entries[key]!.etag, 'data': _entries[key]!.data},
    };
  }

  void loadJson(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is Map && value['etag'] is String) {
        _entries[entry.key] = (etag: value['etag'] as String, data: value['data']);
      }
    }
  }
}

/// GitHub REST istemcisi. Bu katman hub sözleşmesini bilmez; saf API'dir.
///
/// [readToken] her istekte çağrılır: token Dio örneğine gömülmez. Böylece
/// kullanıcı ayarlardan token değiştirdiğinde (B-051) elde eski token kalmaz,
/// ve onboarding henüz kaydedilmemiş bir aday token'la doğrulama yapabilir
/// (B-022).
///
/// [cache] verilirse GET'ler ETag ile doğrulanır (B-024).
Dio buildGithubDio(String? Function() readToken, {EtagCache? cache}) {
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
      // 304 hata değil, "değişmedi" cevabıdır; interceptor ele alacak.
      validateStatus: (s) => s != null && (s < 300 || s == 304),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (cache != null && options.method == 'GET') {
          final etag = cache.etagOf(EtagCache.keyFor(options));
          if (etag != null) options.headers['If-None-Match'] = etag;
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (cache == null || response.requestOptions.method != 'GET') {
          return handler.next(response);
        }
        final key = EtagCache.keyFor(response.requestOptions);

        if (response.statusCode == 304) {
          if (!cache.has(key)) {
            // Elimizde gövde yokken 304 gelemez; geldiyse önbellek
            // temizlenmiştir — sessizce boş veri döndürmek yerine belli et.
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                message: 'ETag önbelleği boşken 304 alındı',
              ),
            );
          }
          return handler.next(
            Response<dynamic>(
              requestOptions: response.requestOptions,
              statusCode: 200,
              data: cache.dataOf(key),
              headers: response.headers,
              extra: {...response.extra, notModifiedFlag: true},
            ),
          );
        }

        final etag = response.headers.value('etag');
        if (response.statusCode == 200 && etag != null) {
          cache.write(key, etag, response.data);
        }
        handler.next(response);
      },
      onError: (error, handler) {
        // Ağ yokken elimizde son bilinen içerik varsa boş ekran yerine onu
        // göster (B-046). Bayat olduğu `servedFromCacheFlag` ile belli edilir;
        // sunucuya ulaşabildiğimiz her durumda (4xx/5xx) bu yola girilmez.
        final isGet = error.requestOptions.method == 'GET';
        final isOffline = error.response == null;
        if (cache == null || !isGet || !isOffline) {
          return handler.next(error);
        }

        final key = EtagCache.keyFor(error.requestOptions);
        if (!cache.has(key)) return handler.next(error);

        handler.resolve(
          Response<dynamic>(
            requestOptions: error.requestOptions,
            statusCode: 200,
            data: cache.dataOf(key),
            extra: {...error.requestOptions.extra, servedFromCacheFlag: true},
          ),
        );
      },
    ),
  );

  return dio;
}

/// Yanıtın gövdesinin 304 sonrası önbellekten geldiğini işaretler
/// (`response.extra[notModifiedFlag] == true`).
const notModifiedFlag = 'takip.notModified';

/// Yanıtın ağ yokken önbellekten verildiğini işaretler (B-046) — yani veri
/// bayat olabilir.
const servedFromCacheFlag = 'takip.servedFromCache';

/// Önbelleği cihazda saklar: uygulama yeniden açıldığında ETag'ler elde
/// olduğu için içerik ya 304'le anında gelir ya da ağ yoksa doğrudan
/// önbellekten gösterilir (B-046).
class EtagCacheStore {
  EtagCacheStore(this._prefsKey);

  final String _prefsKey;
  bool _saving = false;
  bool _dirty = false;

  Future<void> restore(EtagCache cache) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      cache.loadJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_prefsKey); // bozuk önbellek takılıp kalmasın
    }
  }

  /// Üst üste gelen yazmaları teke indirir; yanıt işleme yolunu bloklamaz.
  Future<void> save(EtagCache cache) async {
    if (_saving) {
      _dirty = true;
      return;
    }
    _saving = true;
    try {
      do {
        _dirty = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, jsonEncode(cache.toJson()));
      } while (_dirty);
    } catch (_) {
      // Önbellek kaydedilemezse uygulama çalışmaya devam etmeli.
    } finally {
      _saving = false;
    }
  }
}

final etagCacheStoreProvider =
    Provider<EtagCacheStore>((ref) => EtagCacheStore('etag_cache'));

final etagCacheProvider = Provider<EtagCache>((ref) {
  final store = ref.watch(etagCacheStoreProvider);
  late final EtagCache cache;
  cache = EtagCache(onChanged: () => unawaited(store.save(cache)));
  unawaited(store.restore(cache));
  return cache;
});

final githubDioProvider = Provider<Dio>((ref) {
  final cache = ref.watch(etagCacheProvider);

  // Repo ya da token değişirse önceki hesabın gövdeleri elde kalmasın.
  ref.listen<AsyncValue<HubConfig?>>(hubConfigProvider, (prev, next) {
    final before = prev?.value;
    final after = next.value;
    if (before?.slug != after?.slug || before?.token != after?.token) {
      cache.clear();
    }
  });

  final dio = buildGithubDio(
    () => ref.read(hubConfigProvider).value?.token,
    cache: cache,
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Dio çağrısını sarar: dışarı yalnızca [HubError] sızar.
Future<Response<dynamic>> sendGithub(
  Future<Response<dynamic>> Function() request,
) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw mapGithubError(e);
  }
}

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
