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
