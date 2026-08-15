import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/errors.dart';
import '../github/client.dart';
import '../github/contents_api.dart';
import '../github/repo_scope_api.dart';
import 'hub_config.dart';
import 'hub_connections.dart';
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
/// [neededRepos] = bu token'ın kaç hub reposuna hizmet ettiği (B-103). Fazla
/// erişim kontrolünün eşiği budur; hesabı [reposNeededForToken]'da.
Future<HubAccess> verifyHubAccess(
  HubConfig candidate, {
  int neededRepos = 1,
}) async {
  final dio = buildGithubDio((_) => candidate.token);
  try {
    final api = ContentsApi(dio, owner: candidate.owner, repo: candidate.repo);
    final warning = await checkHubAccess(
      api,
      candidate,
      neededRepos: neededRepos,
      countRepos: () => readVisibleRepoCount(dio),
    );
    return HubAccess(scopeWarning: warning, login: await readLogin(dio));
  } finally {
    dio.close();
  }
}

/// Bir token'ın hizmet ettiği **farklı repo** sayısı: kayıtlı bağlantılardan
/// aynı token'ı kullananlar + kurulmakta olan bağlantı (B-103).
///
/// Aynı token'ı birden çok hub'da kullanmak desteklenen ve teşvik edilen bir
/// akış (B-056); ihtiyaç bu yüzden "1" değil, o token'ın gerçekten gerektiği
/// repo sayısıdır. Slug kümesi üzerinden sayılıyor: aday zaten kayıtlıysa
/// (token güncelleme akışı) iki kez sayılmaz.
int reposNeededForToken(List<HubConfig> existing, HubConfig candidate) {
  final slugs = <String>{candidate.slug};
  for (final c in existing) {
    if (c.token == candidate.token) slugs.add(c.slug);
  }
  return slugs.length;
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

/// Token'ın gördüğü repo sayısını okuyan çağrı; testlerde değiştirilebilsin
/// diye dışarıdan veriliyor. `null` = ölçülemedi.
typedef RepoCountReader = Future<int?> Function();

/// [verifyHubAccess]'in ağ kurulumundan arındırılmış çekirdeği.
///
/// [countRepos] verilmezse fazla erişim kontrolü **hiç koşmaz** (B-103) —
/// varsayılan davranış 2026-08-15 öncesiyle aynı kalır.
Future<TokenScopeWarning?> checkHubAccess(
  ContentsApi api,
  HubConfig candidate, {
  RepoCountReader? countRepos,
  int neededRepos = 1,
}) async {
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
  final classic = inspectTokenScope(
    token: candidate.token,
    oauthScopes: probe.oauthScopes,
    slug: candidate.slug,
  );

  // Klasik token uyarısı çıktıysa fazla erişimi ayrıca ölçmüyoruz: klasik
  // token zaten hesabın tamamını kapsıyor, yani ölçüm yeni bir şey söylemez.
  // Uyarıyı da bölmüyoruz — iki kutu göstermek, ikisini de okunmaz yapardı;
  // klasik uyarı hem daha kesin hem daha eyleme dönük (B-092).
  if (classic != null || countRepos == null) return classic;

  return tokenScopeExcess(
    visibleRepos: await countRepos(),
    neededRepos: neededRepos,
    slug: candidate.slug,
  );
}

/// Yoklamada kullanılan yol. Dosya hiçbir zaman oluşturulmaz (istek içeriksiz
/// gönderilir); ad yalnızca kayıtlarda anlaşılır görünsün diye seçildi.
const _probeFileName = '.izin-denemesi.md';

/// Ayarlar'dan elle koşturulan kapsam ölçümü (B-103): token kaç repo görüyor?
/// `null` = ölçülemedi.
///
/// Bağlantı kurulurkenki yoldan **ayrı** duruyor, çünkü orada ölçüm erişim
/// doğrulamasının kuyruğuna takılı; burada kullanıcı yalnız bu soruyu soruyor
/// ve repoya yazma denemesi yapmanın anlamı yok.
typedef TokenScopeMeasure = Future<int?> Function(HubConfig config);

final tokenScopeMeasureProvider = Provider<TokenScopeMeasure>((ref) {
  return (config) async {
    final dio = buildGithubDio((_) => config.token);
    try {
      return await readVisibleRepoCount(dio);
    } finally {
      dio.close();
    }
  };
});

/// Testlerde ve ileride farklı doğrulama stratejilerinde değiştirilebilsin
/// diye provider üzerinden veriliyor.
///
/// İhtiyaç sayısını (B-103) burada hesaplıyoruz: doğrulamanın kendisi ağ
/// katmanıdır ve cihazdaki bağlantı listesini tanımaz; çağrı yerlerinde
/// hesaplansaydı onboarding ile bağlantı ekranının aynı kuralı iki kez
/// yazması gerekirdi ve ikisi zamanla ayrışırdı.
final hubAccessVerifierProvider = Provider<HubAccessVerifier>((ref) {
  return (candidate) async {
    final connections = await ref.read(hubConnectionsProvider.future);
    return verifyHubAccess(
      candidate,
      neededRepos: reposNeededForToken(connections.connections, candidate),
    );
  };
});
