---
id: S-2026-07-30-b024-etag-polling
date: 2026-07-30
status: closed
topics: [gelistirme, github-api, senkron]
artifacts: []
tasks_touched: []
---

# Oturum: B-024 — ETag'li polling servisi

## Özet
B-024 tamamlandı; Faz 2'nin agent tarafındaki maddeleri bitti.

**ETag katmanı.** GET'lere `If-None-Match` ekleyen, 304'te gövdeyi
önbellekten veren bir interceptor eklendi. Bu bir süre bazlı önbellek değil,
**doğrulama** önbelleği: her istek yine sunucuya gidiyor, yalnızca "değişti mi?"
diye soruyor. Dolayısıyla bayat veri gösterme riski yok — yazma sonrası ilk
GET'te ETag tutmaz, 200 ve yeni içerik gelir. Kazanç 304'lerin istek
limitinden düşmemesi (SK-002). Repo ya da token değişince önbellek
temizleniyor ki önceki hesabın gövdeleri elde kalmasın. Elde gövde yokken
gelen 304 sessizce boş veri döndürmek yerine hata veriyor.

**Yoklama.** `HubWatcher`, klasörleri tek tek taramak yerine reponun son
commit'ini soruyor: hub'da ne değişirse değişsin sinyal tek istekte geliyor,
ve değişiklik yoksa o istek 304 olduğu için pratikte bedava. Ekranlar
`headSha`'yı izleyip değiştiğinde veriyi tazeleyecek (Faz 3–4).

Davranış ayrıntıları: yavaş ağda istekler üst üste binmiyor; token geçersizse
yoklama duruyor (boşuna istek atmak yerine kullanıcının düzeltmesi bekleniyor);
rate limit yendiğinde `x-ratelimit-reset` anına kadar bekleniyor; repo
değişirse önceki hub'ın sürümü taşınmıyor. Ön plan/arka plan kararını servis
bilmiyor — `HubWatcherScope` widget'ı `start`/`stop` çağırıyor, böylece
"hub katmanı UI'yi bilmez" ilkesi korunuyor.

**Test sırasında çıkan gerçek sorun:** `fakeAsync` zamanlayıcıları sahteliyor
ama `DateTime.now()`'ı sahtelemiyor; rate limit beklemesi sahte zamanda hiç
bitmiyordu. Üretim kodu `package:clock`'un `clock.now()`'una geçirildi
(SK-005). Yan fayda: zaman damgaları testte belirlenimli.

Sonuç: 87 test geçiyor, `flutter analyze` temiz.

## Kayıt

### Kullanıcı
> b024den devam

### Agent
B-024 uygulanıyor: GET isteklerine `If-None-Match` ekleyen ETag katmanı
(304'te önbellekten sessiz dönüş, rate limit tüketmeden — SK-002) ve
foreground'da çalışan yoklama servisi. Yoklama, klasörleri tek tek taramak
yerine reponun son commit'ini soruyor: değişiklik olmadığında istek 304
olduğu için pratikte bedava.
