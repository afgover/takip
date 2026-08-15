/// Token'ın **kaç repoyu gördüğünü** ölçer (SEC-012, B-103).
///
/// Dayandığı davranış tahmin değil, **ölçüm**: T-006'da (2026-08-06) gerçek bir
/// fine-grained token'la sınandı ve `GET /user/repos` yalnız token'ın kapsadığı
/// repoları döndürdü — hesabın tamamını değil. B-026'da tam tersi yapılıp
/// belgelenmemiş bir davranış varsayıldığı için (L-009) bu katman ancak ölçüm
/// yapıldıktan sonra yazıldı.
///
/// **Ölçümün sınırı, yorumu belirliyor:** kanıtlanan şey "dar token az repo
/// görür". "All repositories token'ı hepsini görür" doğrudan sınanmadı,
/// filtrelemenin varlığından çıkarıldı. Bu yüzden buradan çıkan sayı
/// "token'ın erişebildiği repo sayısı" olarak okunur; token'ın hangi modda
/// üretildiğine dair hiçbir iddia taşımaz. Kararı `hub/token_scope.dart` verir.
library;

import 'package:dio/dio.dart';

/// Token'ın gördüğü repo sayısı — **bilinmiyorsa null**.
///
/// Sayfa gövdesini indirmemek için `per_page=1` sorulur ve toplam, GitHub'ın
/// `Link` başlığındaki son sayfa numarasından okunur: sayfa başına bir kayıt
/// olduğu için "son sayfa" = "toplam kayıt". Böylece 200 repolu bir hesapta da
/// tek istek ve tek kayıtlık gövde yeter.
///
/// **Süzgeç parametresi bilerek verilmiyor** (`visibility`, `affiliation`,
/// `type`): T-006'da ölçülen istek sade `GET /user/repos`'tu ve bu katmanın
/// tamamı o ölçüme dayanıyor. `per_page` sonucun *kapsamını* değil yalnız
/// sayfalanışını değiştirdiği için ölçümün dışına çıkmıyor; bir süzgeç eklemek
/// çıkardı.
///
/// **En iyi çaba** (`hub/hub_access.dart`'taki `readLogin` ile aynı çizgi): ağ
/// hatası, yetki hatası, beklenmedik gövde — hepsi `null` döner, yani
/// "bilinmiyor". Hiçbiri `0` sayılmaz: sıfır, "bu token hiçbir repo görmüyor"
/// demek olurdu ve o cümle bir uyarı üretirdi. Bilinmeyeni veriye çevirmek,
/// bu dosyanın önlemek için yazıldığı hatanın ta kendisi.
Future<int?> readVisibleRepoCount(Dio dio) async {
  try {
    final res = await dio.get<dynamic>(
      '/user/repos',
      queryParameters: {'per_page': 1},
    );

    final fromLink = lastPageOfLinkHeader(res.headers.value('link'));
    if (fromLink != null) return fromLink;

    // `Link` yoksa sonuç tek sayfadır; o sayfadaki kayıt sayısı toplamdır
    // (`per_page=1` olduğu için 0 ya da 1).
    final data = res.data;
    if (data is List) return data.length;
    return null;
  } catch (_) {
    return null;
  }
}

/// GitHub'ın sayfalama başlığından `rel="last"` sayfa numarasını çıkarır.
///
/// Başlık şu biçimde gelir:
/// `<https://api.github.com/user/repos?per_page=1&page=2>; rel="next",
///  <https://api.github.com/user/repos?per_page=1&page=7>; rel="last"`
///
/// `rel="last"` yoksa null döner — çağıran bunu "bilinmiyor" değil, "gövdeden
/// say" olarak ele alır. (GitHub son sayfada `last` bağlantısını göndermez;
/// `per_page=1` ile ilk istek de son sayfa olabilir, o durumda gövdede tek
/// kayıt vardır ve toplam gerçekten 1'dir.)
int? lastPageOfLinkHeader(String? header) {
  if (header == null || header.isEmpty) return null;

  for (final part in header.split(',')) {
    if (!part.contains('rel="last"')) continue;

    final start = part.indexOf('<');
    final end = part.indexOf('>');
    if (start < 0 || end <= start) continue;

    final uri = Uri.tryParse(part.substring(start + 1, end));
    final page = int.tryParse(uri?.queryParameters['page'] ?? '');
    if (page != null && page > 0) return page;
  }
  return null;
}
