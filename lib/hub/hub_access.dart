import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/errors.dart';
import '../github/client.dart';
import '../github/contents_api.dart';
import 'hub_config.dart';
import 'token_scope.dart';

/// Doğrulama sonucu. Hata fırlatmadıysa erişim tamam; buradaki alanların ikisi
/// de **engel değil**, bağlantıya iliştirilen bilgidir.
class HubAccess {
  const HubAccess({this.scopeWarning, this.login});

  /// Token çalışıyor ama kapsamı gereğinden geniş (B-092). Null = uyarılacak
  /// kesin bir şey yok.
  final TokenScopeWarning? scopeWarning;

  /// Token'ın sahibi olan GitHub hesabı (sözleşme 1.15). Okunamazsa null —
  /// bağlantı yine kurulur, kayıtlar `author` alanı olmadan yazılır.
  final String? login;
}

typedef HubAccessVerifier = Future<HubAccess> Function(HubConfig candidate);

/// Onboarding'de token kaydedilmeden **önce** çalışan tek istek (B-022).
///
/// Hub kökünü sorar; başarılıysa üç şey birden doğrulanmış olur: token
/// geçerli, repo erişilebilir ve repo gerçekten bir hub (içinde `hub/` var).
///
/// Doğrulanamayan tek şey **yazma** iznidir: salt okunur bir token bu kontrolü
/// geçer, sorun ilk görev gönderiminde 403 olarak görünür (B-026).
Future<HubAccess> verifyHubAccess(HubConfig candidate) async {
  final dio = buildGithubDio((_) => candidate.token);
  try {
    final api = ContentsApi(dio, owner: candidate.owner, repo: candidate.repo);
    final warning = await checkHubAccess(api, candidate);
    return HubAccess(scopeWarning: warning, login: await readLogin(dio));
  } finally {
    dio.close();
  }
}

/// Token'ın sahibi olan hesabın `login`'i — **en iyi çaba** (sözleşme 1.15).
///
/// Erişim doğrulaması geçtikten sonra çağrılır ve **hiçbir koşulda bağlantıyı
/// engellemez**: `/user`'ın fine-grained token'la davranışı bu proje için
/// ölçülmedi, dolayısıyla başarısı varsayılmıyor. Okunamazsa kimlik null kalır
/// ve kayıtlar tek kullanıcılı dönemdeki gibi `author`sız yazılır — yani
/// bilinmeyen, "hata" değil "bilinmiyor" olarak ele alınıyor (L-009'un kuralı).
Future<String?> readLogin(Dio dio) async {
  try {
    final res = await dio.get<dynamic>('/user');
    final login = (res.data as Map?)?['login'];
    return (login is String && login.isNotEmpty) ? login : null;
  } catch (_) {
    return null;
  }
}

/// [verifyHubAccess]'in ağ kurulumundan arındırılmış çekirdeği.
Future<TokenScopeWarning?> checkHubAccess(
  ContentsApi api,
  HubConfig candidate,
) async {
  final probe = await api.probePath(Hub.basePath);
  if (!probe.exists) {
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

  // Erişim tamam. Geriye tek soru kalıyor: token **fazlasını** da yapabiliyor
  // mu (SEC-006)? Bu bir hata değil, çünkü token çalışıyor; kullanıcıya
  // söylenir ve karar ona bırakılır — çalışan bir token'ı reddetmek,
  // uygulamayı kullanılamaz hâle getirirdi.
  return inspectTokenScope(
    token: candidate.token,
    oauthScopes: probe.oauthScopes,
    slug: candidate.slug,
  );
}

/// Yoklamada kullanılan yol. Dosya hiçbir zaman oluşturulmaz (istek içeriksiz
/// gönderilir); ad yalnızca kayıtlarda anlaşılır görünsün diye seçildi.
const _probeFileName = '.izin-denemesi.md';

/// Testlerde ve ileride farklı doğrulama stratejilerinde değiştirilebilsin
/// diye provider üzerinden veriliyor.
final hubAccessVerifierProvider =
    Provider<HubAccessVerifier>((ref) => verifyHubAccess);
