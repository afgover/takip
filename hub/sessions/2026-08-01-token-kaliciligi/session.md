---
id: S-2026-08-01-token-kaliciligi
date: 2026-08-01
status: closed
topics: [kurulum, token, yedekleme, coklu-repo, guvenlik]
artifacts: []
tasks_touched: []
---

# Oturum: Token kalıcılığı — kurulumda ve çoklu repoda

## Özet
Kullanıcı, geliştirme döngüsünün asıl sürtünmesini bildirdi: her yeni APK
kurulumunda ve her yeni repo eklemede token girmek zorunda kalmak. İki ayrı
neden vardı ve ikisi de çözüldü; üçüncü olarak kaçınılmaz veri kaybına karşı
yedekleme eklendi.

Önce ölçüldü: `flutter install` kaldırmayı **kaçınılmaz olarak** yapmıyor —
kaynak koda bakıldığında `adb install -t -r` önce deneniyor, yalnız çıktısında
`Failure` görülürse kaldırma yoluna giriliyor. Gerçek cihazda üç yönde de
(release→release, debug→release, release→debug) yerinde güncelleme **başarılı**
oldu; sabahki kaldırma tekrarlanamadı. Yani veri kaybı aracın hata yolundan
geliyordu, derleme türü değişikliğinden değil.

Yapılanlar:

1. **`tool/install.sh`** — yalnız `adb install -r` kullanır, asla kaldırmaz.
   Başarısızlıkta ne yapılacağını yazar (önce yedek al, sonra kaldır). Gerçek
   cihazda doğrulandı. → takip@e796e0d
2. **Parolayla şifreli bağlantı yedeği** — Ayarlar → Yedekleme. Bütün repolar
   ve token'lar tek metne çevriliyor, aynı metinden geri yükleniyor.
   → takip@735efbc, R-006
3. **Token yeniden kullanımı** — yeni repo eklerken kayıtlı bir bağlantının
   token'ı seçilebiliyor. → takip@2730ea4

`flutter analyze` temiz, **236 test** geçiyor (219'dan 17 yeni). Yeni sürüm
`tool/install.sh` ile cihaza kuruldu; kurulum veriyi silmedi.

## Kayıt

### Kullanıcı
> uygulamayi gelistirmeye ve yeni apklari telefona yukledikce her seferinde
> tokeni girmemiz gerekmeyecek sekilde duzenleme yaparmisin, ozellikle birden
> fazla repo ile calisinca her seferinde yeni token girmek isi cok
> zorlastiracak benim icin

### Agent
Şikâyetin iki ayrı ayağı olduğu ayrıldı: (a) yeniden kurulumda token'ın
silinmesi, (b) her repo için ayrı token üretme zorunluluğu.

**(a) için önce ölçüm yapıldı, tahmin edilmedi.** Flutter kaynağı
(`android_device.dart`) okundu: `installApp`, `adb install -t -r`'yi önce
deniyor; **yalnızca** başarısız olursa "Uninstalling old version..." diyor.
Sonra gerçek cihazda üç senaryo denendi — release→release, debug→release
(sabah patlayan senaryonun birebir aynısı) ve release→debug: **üçü de yerinde
güncellemeyle başarılı**, veri korunarak. İmzalar da karşılaştırıldı: debug ve
release APK'lar aynı sertifikayla imzalı (aynı SHA-256), keystore 2056'ya kadar
geçerli. Yani sabahki kaldırma yapısal değil, `adb`'den gelen geçici bir
`Failure` satırından tetiklenmişti ve tekrarlanamıyor.

Bu, çözümü değiştirdi: sorun "debug ve release birbirinin üstüne kurulamaz"
değil, "`flutter install` hata görünce kaldırmaya kendi başına karar veriyor".
Bu yüzden düzeltme uygulamada değil, kurulum yolunda: `tool/install.sh` yalnız
`adb install -r` çağırıyor. Ya yerinde günceller ya sesli hata verir; kaldırma
yok. Gerekçe scriptin başında yazılı — sesli hata kurtarılabilir, sessiz silme
kurtarılamaz.

**(b) için** yeni repo ekleme ekranına "mevcut token'ı kullan" seçici kondu.
Fine-grained token'lar birden çok repoyu kapsayabildiği için çoğu durumda
elindeki token yeni repoyu da kapsıyor. Doğrulama gevşetilmedi: seçilen token
yine `verifyHubAccess`'ten geçiyor, repoyu kapsamıyorsa kaydedilmiyor ve
kullanıcı sebebini görüyor.

**Üçüncü olarak** kullanıcı, kaçınılmaz veri kaybına karşı yedekleme istedi ve
iki seçenek sunulduğunda **parolayla şifreli** olanı seçti. Yedek token'ların
kendisini taşıdığı için düz metin olsaydı panoya düşen dize, repolara yazma
yetkisinin kendisi olurdu. PBKDF2-HMAC-SHA256 (150 bin tur) + AES-GCM
kullanıldı, `package:cryptography` üzerinden — token koruyan bir yerde
şifreleme elle yazılmaz. AES-GCM kimlik doğrulamalı olduğu için yanlış parola
ile kurcalanmış yedek aynı hatayı veriyor; ayırt etmek saldırgana bilgi
sızdırmak olurdu. Geri yükleme upsert: elde çalışan bağlantıları silmiyor.

Yol boyunca iki test kırılması çıktı, ikisi de aynı kökten: Flutter'ın tembel
listesi test ekranında alt alanları hiç oluşturmuyor. Ayarlarda `ensureVisible`
işe yaramadı (widget ağaçta yok), `scrollUntilVisible` gerekti; yedekleme
ekranında test ekranı yükseltildi. → L-015

`flutter analyze` temiz, **236 test** (17 yeni). Yeni sürüm `tool/install.sh`
ile kuruldu, kurulum veriyi silmedi ve uygulama crash'siz açıldı.
