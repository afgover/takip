# Skiller (skills)

Agent'ın bu projede edindiği, tekrar kullanılabilir yetenek ve prosedürler.
Biçim: `SYSTEM.md` §5.

---

## SK-001 — Contents API ile SHA kontrollü dosya işlemleri
- **Tarih:** 2026-07-30
- **Kaynak:** Aşama 0 araştırması (B-005)
- **Açıklama:** Dosya oluşturma/güncelleme tek `PUT /repos/{o}/{r}/contents/{path}`
  çağrısıdır (içerik base64). Güncelleme ve silmede dosyanın güncel `sha`'sı
  zorunludur; 409 dönerse dosya yeniden okunup işlem tekrarlanır (iyimser kilit).
  Klasörler arası taşıma = eski yolu DELETE + yeni yola PUT.

## SK-002 — ETag'li ucuz polling
- **Tarih:** 2026-07-30
- **Kaynak:** Aşama 0 araştırması (B-004)
- **Açıklama:** GET isteklerinde `If-None-Match: <etag>` gönderilir; içerik
  değişmediyse 304 döner ve bu cevap rate limit'ten düşmez. Böylece 30–60 sn
  aralıklı yoklama pratikte bedavadır.

## SK-003 — Dio'yu ağsız test etmek: sahte HttpClientAdapter
- **Tarih:** 2026-07-30
- **Kaynak:** B-023
- **Açıklama:** `dio.httpClientAdapter` değiştirilerek ağa çıkmadan gerçek
  istek/yanıt döngüsü test edilir: adaptör `fetch(options, requestStream, _)`
  ile isteği yakalar, test yanıtı `ResponseBody.fromString(json, status,
  headers: {...})` ile üretir. Böylece URL kurulumu, base64 kodlama, gönderilen
  gövde ve HTTP durum → hata eşlemesi uçtan uca doğrulanır. İstek gövdesi
  `requestStream`'den okunur (byte'lar birleştirilip `utf8.decode`).

## SK-004 — Sözleşme dosyası yazarken güvenli YAML üretimi
- **Tarih:** 2026-07-30
- **Kaynak:** B-025
- **Açıklama:** App'in yazdığı frontmatter'ı agent okuyacağı için üretilen YAML
  her durumda geçerli olmalı. Kural: bir skaler ancak baş/son boşluğu yoksa,
  `true/false/yes/no/null/~` gibi ayrılmış bir kelime değilse, sayıya
  benzemiyorsa ve `^[\p{L}\p{N}][\p{L}\p{N} _./-]*$` kalıbına uyuyorsa tırnaksız
  yazılır; aksi halde çift tırnak + `\` `"` `\n` kaçışı. Türkçe harfler sade
  skalerde geçerlidir, tırnak gerektirmez. Doğrulama ölçütü tek cümle:
  `parse(serialize(x)) == x` (gövdenin de boş satır biriktirmemesi dahil).

## SK-005 — Zamana bağlı mantığı sahte saatle test etmek
- **Tarih:** 2026-07-30
- **Kaynak:** B-024
- **Açıklama:** `fakeAsync` yalnız **zamanlayıcıları ve mikro görevleri**
  sahteler; `DateTime.now()` gerçek duvar saatini okumaya devam eder. Bu yüzden
  "şu ana kadar bekle" türü mantık (rate limit sonrası geri çekilme) sahte
  zamanda hiç sona ermez ve test yanıltıcı biçimde kırılır. Çözüm: üretim
  kodunda `DateTime.now()` yerine `package:clock`'un `clock.now()`'u kullanmak;
  `fakeAsync` bu saati `elapse` ile birlikte ilerletir. Yan fayda: zaman damgası
  üreten kod (`lastChangedAt` gibi) testte belirlenimli olur, aynı mikrosaniyede
  üretilen iki damganın eşit çıkma riski kalkar.

## SK-006 — Yan etkisiz izin yoklaması: yerine getirilemez istek
- **Tarih:** 2026-07-30
- **Kaynak:** B-026
- **Açıklama:** Bir yazma iznini denemeden öğrenmenin yolu yoksa (L-009),
  istek **yapısal olarak yerine getirilemez** hâlde gönderilir: Contents
  API'de `content` alanı zorunlu olduğundan, `content` içermeyen bir PUT
  izin olsa bile hiçbir dosya oluşturamaz/değiştiremez. Yetkilendirme
  reddi (403) yine de döner. Yani sinyal alınır, yan etki sıfırdır. Yanıtın
  `X-Accepted-GitHub-Permissions` başlığı hangi iznin gerektiğini söyler ve
  hata mesajında doğrudan kullanılabilir. 403'ün rate limit hâli ayrılmalıdır
  (`x-ratelimit-remaining: 0`).
