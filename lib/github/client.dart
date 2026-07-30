import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hub/hub_config.dart';

/// GitHub REST istemcisi. Bu katman hub sözleşmesini bilmez; saf API'dir.
///
/// TODO(B-023): hata eşleme (401/403/409/429 → core/errors.dart).
/// TODO(B-024): ETag interceptor'ı — 304'te önbellekten dön, limit tüketme.
final githubDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(hubConfigProvider).value;
  return Dio(
    BaseOptions(
      baseUrl: 'https://api.github.com',
      headers: {
        if (config != null) 'Authorization': 'Bearer ${config.token}',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    ),
  );
});
