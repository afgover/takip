/// Token kapsamı denetimi (SEC-006, B-092).
///
/// Uygulamanın ihtiyacı tek bir repoda `Contents: Read and write` +
/// `Metadata: Read`. Kullanıcı bunun yerine hesabın tamamını kapsayan bir
/// token verirse uygulama bunu bugüne kadar hiç fark etmiyordu — geniş token
/// her kontrolü geçer, çünkü fazlası da yeter. Sonuç: cihaz ele geçtiğinde
/// kaybedilen şey tek bir hub reposu değil, hesabın tamamı olurdu.
///
/// Denetim iki **belgelenmiş** sinyale dayanır ve yorumu B-026'daki gibi tek
/// yönlüdür: yalnız kesin olumsuzu bildirir, "bu token dar" diye asla
/// konuşmaz. Bilinmeyen, "geniş değil" demektir.
///
///  1. **`X-OAuth-Scopes` yanıt başlığı.** GitHub, klasik (OAuth) token'larda
///     yetkilendirilmiş scope'ları her kimlikli yanıtta bu başlıkta bildirir.
///     Başlık doluysa token klasiktir ve o scope'lara sahiptir — tahmin yok.
///     Fine-grained token'larda başlık hiç gelmez.
///  2. **Token öneki.** `ghp_` klasik, `github_pat_` fine-grained (GitHub'ın
///     belgelediği önekler). Önek klasik diyorsa token tek repoya
///     kısıtlanamaz: klasik token'larda repo seçimi diye bir şey yoktur,
///     `repo` scope'u hesaptaki **bütün** repoları kapsar.
///
/// Neden `permissions` alanı ya da bir izin uç noktası değil: yok. Bu tam
/// olarak B-026'da araştırılıp bulunamayan şey (L-009); oradaki cevap yan
/// etkisiz bir yazma denemesiydi, buradaki cevap da aynı ruhta — GitHub'ın
/// kendiliğinden söylediği şeye bakmak.
///
/// **Yakalayamadığı durum:** "All repositories" seçilerek üretilmiş bir
/// fine-grained token. O da hesabın tamamını kapsar ama uygulamaya bunu
/// söyleyen belgelenmiş bir sinyal yok — kapsamı ölçmenin yolu araştırılmadan
/// buraya bir tahmin konmadı (SEC-012).
library;

/// Kapsamı gereğinden geniş bir token bulunduğunda üretilen uyarı.
/// `null` dönmesi "token dar" demek değil, "geniş olduğuna dair kesin bir
/// kanıt yok" demektir.
class TokenScopeWarning {
  const TokenScopeWarning({
    required this.title,
    required this.body,
    this.scopes = const [],
  });

  /// Tek satırlık başlık.
  final String title;

  /// Ne olduğu ve ne yapılması gerektiği.
  final String body;

  /// GitHub'ın bildirdiği scope'lar (yalnız klasik token'da dolu).
  final List<String> scopes;
}

/// Kimlikli bir yanıttan okunan kapsam bilgisini değerlendirir.
///
/// [oauthScopes] `X-OAuth-Scopes` başlığının ham değeri (yoksa null).
/// [slug] uyarı metnini somutlaştırmak için: `owner/repo`.
TokenScopeWarning? inspectTokenScope({
  required String token,
  required String? oauthScopes,
  required String slug,
}) {
  final scopes = parseOauthScopes(oauthScopes);
  final looksClassic = token.startsWith('ghp_');

  // Başlık boş gelmiş ve önek de klasik demiyorsa elimizde bir şey yok.
  if (scopes.isEmpty && !looksClassic) return null;

  final risky = scopes.where(_riskyScopes.containsKey).toList();

  final buffer = StringBuffer(
    'Klasik (classic) bir kişisel erişim token\'ı kullanıyorsun. Klasik '
    'token\'lar tek bir repoya kısıtlanamaz: repo scope\'u hesabındaki '
    'bütün repolara okuma-yazma erişimi verir. Bu uygulamanın ihtiyacı '
    'yalnız $slug reposunda Contents.',
  );
  if (risky.isNotEmpty) {
    buffer.write('\n\nBu token şunları da yapabiliyor:');
    for (final scope in risky) {
      buffer.write('\n• $scope — ${_riskyScopes[scope]}');
    }
  }
  buffer.write(
    '\n\nCihaz ele geçerse kaybedilen şey bir repo değil, hesabın tamamı '
    'olur. Fine-grained token üretmen önerilir: Only select repositories → '
    '$slug, Contents: Read and write, Metadata: Read. Sonra bu token\'ı '
    'GitHub\'dan sil.',
  );

  return TokenScopeWarning(
    title: 'Bu token gereğinden geniş',
    scopes: scopes,
    body: buffer.toString(),
  );
}

/// `X-OAuth-Scopes` başlığı virgülle ayrılmış gelir (`"repo, gist"`).
/// Başlık yoksa ya da boşsa boş liste.
List<String> parseOauthScopes(String? header) => (header ?? '')
    .split(',')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

/// Etkisi hub'ın çok ötesine geçen scope'lar. Listede olmayan bir scope
/// "zararsız" demek değil; yalnızca kullanıcıya tek tek anlatılacak kadar
/// ağır olanlar burada — hepsi zaten yukarıdaki genel uyarının kapsamında.
const _riskyScopes = <String, String>{
  'repo': 'bütün repolara (private dahil) okuma-yazma',
  'public_repo': 'bütün public repolara yazma',
  'delete_repo': 'repo silme',
  'admin:org': 'organizasyonu ve takımları yönetme',
  'admin:repo_hook': 'webhook yönetimi',
  'admin:public_key': 'hesaba SSH anahtarı ekleme',
  'admin:gpg_key': 'hesaba GPG anahtarı ekleme',
  'workflow': 'GitHub Actions iş akışlarını değiştirme',
  'write:packages': 'paket yayımlama',
  'delete:packages': 'paket silme',
  'gist': 'gist oluşturma ve değiştirme',
  'user': 'profil bilgilerini okuma-yazma',
  'notifications': 'bildirimleri okuma ve işaretleme',
};
