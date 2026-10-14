---
id: S-2026-10-14-apk-ve-denetim
date: 2026-10-14
status: open
reconstructed: false
author: afgover
topics: [apk, denetim, sozlesme, r-008, kablosuz-kurulum]
artifacts: []
tasks_touched: []
---

# Oturum: 1.36, iki denetim kontrolü ve kablosuz APK kurulumu

## Özet

*(oturum açık — kapanışta yazılacak)*

## Kayıt

### [10:30] Kullanıcı

> hepsini yap wifi uzerinden kur

### [10:33] Agent

Önceki oturumdaki üç öneri onaylandı: (1) APK derle ve kur — kullanıcı
Drive yerine **kablosuz adb** ile kurulmasını istedi; telefon (SM-F731B)
zaten `adb-tls-connect` ile bağlı. (2) `audit.sh`'a iki kontrol: dağıtılan
APK'nın sözleşme sürümü ve sürümsüz sözleşme değişikliği (R-008). (3) "Önce
eşitle"yi tüm hub'lara genelleştir (1.36). Sıra önemli: sabit 1.36 olacağı
için APK sözleşme değişikliğinden **sonra** derlenir. Plan
[P-029](../../PLAN.md).

### [10:45] Agent

Sözleşme 1.36: "önce eşitle" protokolün açılış bölümünün başına genel blok
olarak yazıldı (TR+EN); §16 alt başlığı ve Projects maddesi işaretçiye
indi — kural tek yerde. Ek gerekçe: telefon uygulaması GitHub'a yazdığı için
her hubın yerel kopyası geride kalabilir. Uygulama sabiti 1.36; tam süit
630/630. EVOLUTION notu yazıldı.

