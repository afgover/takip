---
id: S-2026-08-05-yedekleme-kurallari
date: 2026-08-05
status: closed
reconstructed: false
topics: [guvenlik, android, yedekleme]
artifacts: []
tasks_touched: []
---

# Oturum: Yedekleme kuralları (SEC-009 kapandı) ve kayıt düzeltmesi

## Özet
Kullanıcı B-100'ün gerekçesini sordu; cevabı yazarken kaydın kendisinde bir
yanlış olduğu görüldü ve önerinin daha ince bir hâli ortaya çıktı.

**Kayıt düzeltmesi (L-038).** SEC-009'da "token EncryptedSharedPreferences'ta"
yazıyordu. Uygulama `const FlutterSecureStorage()` kullanıyor, `AndroidOptions`
vermiyor — o mod açık değil. Gerçekte AES anahtarı Keystore'daki RSA çiftiyle
sarmalanıp **sıradan** iki prefs dosyasında duruyor. Vardığım sonuç (yedekten
dönen şifreli metin çözülemez) doğru kalmıştı ama gerekçe yanlıştı, ve yanlış
gerekçe bir ayrıntıyı gizlemişti: dosyalar sıradan prefs olduğu için yedeğe
**giriyorlar**, yani geri yükleme token okumasını sessizce bozabiliyor. Bu,
kararı değiştirmedi; gerekçesini güçlendirdi.

**Çözüm `allowBackup="false"` değil, ayrımlı oldu.** Sızıntı bulut tarafında;
cihazdan-cihaza aktarımı da kapatmak gereksiz bir kayıp olurdu.
`data_extraction_rules.xml` (API 31+) buluta hiçbir şey göndermiyor, aktarımı
açık bırakıyor; aktarımdan yalnız iki token dosyası çıkarıldı (taşınsalar yeni
cihazda çözülemezler). `backup_rules.xml` aynı kuralı API 24–30'da uyguluyor —
`minSdk` 24, ve yalnız biri tanımlansaydı cihazların bir bölümünde açık sessizce
açık kalırdı.

**Doğrulama iddiaya bırakılmadı:** (1) dosya testi, (2) birleştirilmiş release
manifesti, (3) `aapt2 dump xmltree` ile derlenmiş APK'nın manifesti. Üçüncüsü
L-010 yüzünden gerekliydi — kaynak manifestte olan bir şeyin release çıktısında
olmadığı bu projede yaşandı.

404 test, analyze temiz. SEC-009 `kapali`. Kalan sınır kayda yazıldı: bu
ayarlar yerel yedeklemeyi ve root'lu cihazı kapsamaz, SEC-007'nin kabulü
yerinde duruyor.

## Kayıt

### Kullanıcı
> b-100 yedeklemeyi neden kapatmayi onerdin?

### Agent
Gerekçe zinciri anlatıldı: `allowBackup` tanımsız → Android varsayılanı `true`
→ uygulamanın özel veri alanı Google hesabına kopyalanıyor → o alanda hub'ın
şifresiz kopyası var (SEC-007). SEC-007'de kabul edilen risk "cihaz ele
geçerse"ydi; yedekleme bunu buluta genişletiyor. Maliyeti yok, çünkü token
yedekten zaten geri gelmiyor ve hub içeriği GitHub'da.

Cevabı hazırlarken kodda `AndroidOptions` verilmediği görüldü ve kayıttaki
"EncryptedSharedPreferences" iddiasının yanlış olduğu ortaya çıktı (L-038).
Ayrıca `allowBackup="false"` yerine `dataExtractionRules` ile bulut/aktarım
ayrımının mümkün olduğu söylenip seçim kullanıcıya bırakıldı.

### Kullanıcı
> dataExtractionRules ile yap, SEC-009'u da duzelt

### Agent
Önce ölçüldü: birleştirilmiş release manifestinde `allowBackup`,
`dataExtractionRules`, `fullBackupContent` — hiçbiri yok, `minSdk=24`,
`targetSdk=36`. `minSdk` 24 olduğu için **iki** kural dosyası gerekti.

Prefs dosya adları paketin kaynağından okundu (`FlutterSecureStorage`,
`FlutterSecureKeyStorage`) — tahminle yazılsaydı dışlama kuralı sessizce hiçbir
şey yapmazdı.

`test/android/backup_rules_test.dart` eklendi: bu ayarlara hiçbir çalışma
zamanı testi değmiyor ve kaybolmaları sessiz — `flutter create` bir kez
manifesti yeniden üretirse öznitelikler gider, uygulama çalışmaya devam eder,
yalnız veri yeniden buluta çıkmaya başlar (L-010'un aynısı).

SEC-009 düzeltilip kapatıldı, B-100 işaretlendi, L-038 yazıldı. APK derlendi ve
APK'nın kendi manifesti aapt2 ile doğrulandı; cihaz o sırada bağlı olmadığı
için kurulum kullanıcı telefonu bağlayınca yapılacak.
