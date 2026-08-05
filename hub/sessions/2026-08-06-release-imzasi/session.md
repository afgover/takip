---
id: S-2026-08-06-release-imzasi
date: 2026-08-06
status: closed
reconstructed: false
topics: [guvenlik, imza, android]
artifacts: []
tasks_touched: [T-010]
---

# Oturum: Release imzası — yapılandırma hazır, anahtar ertelendi

## Özet
B-101 için gradle yapılandırması yazıldı ve **hazır bekliyor**; anahtar üretimi
kullanıcı kararıyla ertelendi. SEC-010 açık kalıyor.

**Yanlış anlaşılan nokta düzeltildi.** Kullanıcı "keystore'u uygulama son
hâlindeyken hazırlamak daha doğru olmaz mı?" diye sordu. İmza anahtarı
uygulamanın olgunluğundan **bağımsızdır**: bir kez üretilir ve bütün gelecek
sürümleri imzalar; sonradan üretilen anahtar daha iyi olmaz ve beklemenin
azalttığı bir maliyet yoktur (kaldır-kur bedeli sabit, hatta biriken veriyle
hafifçe artar). Doğru tetikleyici "uygulama bitsin" değil, **APK'nın bu
makineden çıkacağı gün** — yani B-097. Bu çerçevede erteleme meşru ve öyle
kaydedildi.

**Kapalı düşme kuralı bilerek gevşetildi.** İlk hâlinde `key.properties` yoksa
release derlemesi hata veriyordu; bu, anahtar üretilene kadar günlük kurulumu
engelliyordu. Erteleme kararıyla birlikte kural, uyarıp debug'a düşmeye
çevrildi.

**L-039:** Gevşetmenin gerekçesi "ama uyarı çıkıyor"du — ölçünce çıkmadığı
görüldü. `flutter build apk`, Gradle'ın `logger.warn` çıktısını yutuyor;
kullanıcı hiçbir şey görmüyordu. Uyarı iki gerçekten görülen yere taşındı:
`tool/install.sh` (kullanıcının çalıştırdığı ve çıktısını okuduğu yer) ve
`tool/scan.sh` (kalıcı — üretilmiş APK'nın **sertifikasına** bakıyor, iddiaya
değil).

Ayrıca `.gitignore`'a `*.jks` eklendi: `*.keystore` vardı ama `keytool`'un
ürettiği varsayılan uzantı o değil, yani imza anahtarı repoya girebilirdi.

404 test, analyze temiz. Yeni APK cihaza kuruldu.

## Kayıt

### Kullanıcı
> b-101 imzayi da halledelim

### Agent
Önce mevcut imza ölçüldü: `apksigner` sertifikayı `CN=Android Debug` gösterdi —
Android SDK ile gelen, herkeste aynı olan anahtar.

Devam etmeden iki bedel bildirildi: (1) imza değişince telefondaki uygulama
yerinde güncellenemez, kaldır-kur gerekir ve veri silinir (yedek yolu var,
SEC-002); (2) keystore üretmek parola gerektirdiği için agent yapamaz.

Kullanıcı "şimdi yapalım" ve "key.properties yoksa hata versin" dedi. Gradle
yazıldı, iki yol da sınandı: release hata verdi, debug etkilenmedi. `.gitignore`
genişletildi, T-010 açıldı.

### Kullanıcı
> bunlari neden yapiyorum anlamadim
>
> keystore u uygulama son halindeyken hazirlamamiz daha dogru olmaz mi? daha
> yapacak isler var

### Agent
Gerekçe yeniden anlatıldı ve **bugünkü riskin düşük olduğu dürüstçe söylendi**:
uygulamayı yalnız geliştirici kendi cihazına kuruyor, saldırı için sahte bir
APK'nın kurdurulması gerekir. Açık hâle geldiği iki durum: APK'nın makineden
çıkması (B-097) ve debug anahtarının kaybolması (bilgisayar değişimi → plansız
kaldır-kur).

"Son hâl" premisi düzeltildi (yukarıda). Kullanıcının önceliklendirmesi kabul
edildi; erteleme B-097'ye bağlanarak kayda geçti, kural gevşetildi, hatırlatıcı
görülen kanallara taşındı.
