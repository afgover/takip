import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/errors.dart';
import '../github/client.dart';
import '../github/contents_api.dart';
import 'hub_config.dart';

typedef HubAccessVerifier = Future<void> Function(HubConfig candidate);

/// Onboarding'de token kaydedilmeden **önce** çalışan tek istek (B-022).
///
/// Hub kökünü sorar; başarılıysa üç şey birden doğrulanmış olur: token
/// geçerli, repo erişilebilir ve repo gerçekten bir hub (içinde `hub/` var).
/// Yanlış token'la aylarca sessizce boş liste görmek yerine kullanıcı daha
/// ilk ekranda uyarılır.
///
/// Doğrulanamayan tek şey **yazma** iznidir: salt okunur bir token bu kontrolü
/// geçer, sorun ilk görev gönderiminde 403 olarak görünür (B-026).
Future<void> verifyHubAccess(HubConfig candidate) async {
  final dio = buildGithubDio(() => candidate.token);
  try {
    final api = ContentsApi(dio, owner: candidate.owner, repo: candidate.repo);
    await checkHubAccess(api, candidate);
  } finally {
    dio.close();
  }
}

/// [verifyHubAccess]'in ağ kurulumundan arındırılmış çekirdeği.
Future<void> checkHubAccess(ContentsApi api, HubConfig candidate) async {
  if (!await api.pathExists(Hub.basePath)) {
    // GitHub, "repo yok", "token bu repoyu görmüyor" ve "klasör yok"
    // durumlarının üçüne de 404 döner; ayırt edemediğimiz için üçünü de
    // söylüyoruz.
    throw HubNotFoundError(
      '${candidate.slug} içindeki "${Hub.basePath}/" klasörüne erişilemedi. '
      'Repo adı yanlış olabilir, token bu repoyu kapsamıyor olabilir ya da '
      'repoda henüz hub klasörü yok.',
    );
  }

  // Okuma tamam; yazma iznini de sınayalım (B-026). Bu kontrol yalnız kesin
  // olumsuzu bildirir, "izin var" diye kesin konuşmaz.
  final denied = await api.writeDenialReason('${Hub.inboxDir}/$_probeFileName');
  if (denied != null) {
    throw HubAuthError(
      'Token bu repoya yazamıyor, yalnız okuyabiliyor. Görev eklemek için '
      'gereken izin: $denied. Token ayarlarında Contents iznini '
      '"Read and write" yapman gerekiyor.',
    );
  }
}

/// Yoklamada kullanılan yol. Dosya hiçbir zaman oluşturulmaz (istek içeriksiz
/// gönderilir); ad yalnızca kayıtlarda anlaşılır görünsün diye seçildi.
const _probeFileName = '.izin-denemesi.md';

/// Testlerde ve ileride farklı doğrulama stratejilerinde değiştirilebilsin
/// diye provider üzerinden veriliyor.
final hubAccessVerifierProvider =
    Provider<HubAccessVerifier>((ref) => verifyHubAccess);
