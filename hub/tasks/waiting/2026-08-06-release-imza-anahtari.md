---
id: T-010
title: "Release imza anahtarını üret ve geçişi yap"
created_by: agent
created: "2026-08-06T00:10:00Z"
updated: "2026-08-06T00:10:00Z"
priority: high
category: gorev
tags: [guvenlik, imza]
session: S-2026-08-06-release-imzasi
result: none
options: ["Keystore hazır, key.properties yazıldı", "Yedeği aldım ama keystore'da takıldım", "Şimdilik vazgeçtim"]
multi: false
---

# Release imza anahtarını üret ve geçişi yap

## İstek

Release derlemesi bugüne kadar Android SDK'nın **debug** anahtarıyla
imzalanıyordu (`CN=Android Debug`) — herkeste aynı olan, bilinen bir anahtar
(SEC-010). Gradle tarafı bağlandı; artık `android/key.properties` yoksa release
derlemesi **hata veriyor**, sessizce debug'a düşmüyor.

Kalan kısım sende, çünkü keystore üretmek **parola belirlemeyi** gerektiriyor ve
parolan agent'a geçmemeli.

⚠ **İmza değişince telefondaki uygulama yerinde güncellenemez.** Android
"signature mismatch" der; kaldırıp yeniden kurmak gerekir, o da uygulama
verisini siler. Bu yüzden **1. adım yedek almak.**

## Notlar

- 2026-08-06 · Beklenen adımlar:

  **1) Önce yedek al (telefonda).** Ayarlar → Yedekleme → "Yedek oluştur".
  Parolayla şifreli tek bir metin çıkacak; parolayı parola yöneticine kaydet.
  Bu adım atlanırsa bütün repo bağlantıları ve token'lar kaybolur.

  **2) Keystore üret (bilgisayarda).** Depo **dışında** bir yere:

  ```
  mkdir -p ~/keys
  keytool -genkeypair -v -keystore ~/keys/takip-release.jks \
    -keyalg RSA -keysize 4096 -validity 10000 -alias takip
  ```

  Sorulan parolayı parola yöneticine kaydet. "First and last name" gibi alanlar
  serbest; yalnız kendi kullanımın için (Play'e yüklemiyorsun).

  **3) `android/key.properties` yaz** (bu dosya `.gitignore`'da):

  ```
  storeFile=/Users/<kullanıcı>/keys/takip-release.jks
  storePassword=<parola>
  keyAlias=takip
  keyPassword=<parola>
  ```

  **4) Agent'a söyle.** Derleyip imzayı doğrular (`apksigner` ile sertifikanın
  artık `CN=Android Debug` olmadığını gösterir), sonra kaldır-kur adımını
  birlikte yaparız.

  **5) Kurulumdan sonra** Ayarlar → Yedekleme → "Geri yükle" ile bağlantıları
  geri al.

- **Keystore'u ve parolayı kalıcı olarak sakla.** Kaybedersen bu döngü baştan
  yaşanır: yeni anahtar = yeni imza = yine kaldır-kur. Yedekle (parola
  yöneticisi ya da şifreli bir yedek), ama **repoya koyma**.

- `.gitignore` `*.jks`, `*.keystore` ve `key.properties`'i dışarıda tutuyor.
  Yine de keystore'un depo dışında durması esas koruma; gitignore ikinci
  savunma.
