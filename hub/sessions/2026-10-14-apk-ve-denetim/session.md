---
id: S-2026-10-14-apk-ve-denetim
date: 2026-10-14
status: closed
reconstructed: false
author: afgover
topics: [apk, denetim, sozlesme, r-008, kablosuz-kurulum]
artifacts: []
tasks_touched: []
---

# Oturum: 1.36, iki denetim kontrolü ve kablosuz APK kurulumu

## Özet

Önceki incelemenin üç önerisi uygulandı. Sözleşme 1.36: "önce eşitle" her
hub için (protokol açılışı; §16 işaretçi). Dağıtılan APK artık
`apk/<tarih>-<sha>` etiketiyle izleniyor (geçmiş üç APK geriye dönük;
`install.sh` kurunca etiketliyor); `audit.sh` §12 son etiketteki sabiti
ölçüyor, yeni §13 sürümsüz sözleşme değişikliğini (R-008) yakalıyor. APK
`fc20227` (sözleşme 1.36) kablosuz adb ile telefona kuruldu; imza önceden
ölçüldü, ilk kurulum tarihi (2026-08-01) değişmedi — veri yerinde.

## Kayıt

### [10:15] Kullanıcı

> hepsini yap wifi uzerinden kur

### [10:19] Agent

Önceki oturumdaki üç öneri onaylandı: (1) APK derle ve kur — kullanıcı
Drive yerine **kablosuz adb** ile kurulmasını istedi; telefon (SM-F731B)
zaten `adb-tls-connect` ile bağlı. (2) `audit.sh`'a iki kontrol: dağıtılan
APK'nın sözleşme sürümü ve sürümsüz sözleşme değişikliği (R-008). (3) "Önce
eşitle"yi tüm hub'lara genelleştir (1.36). Sıra önemli: sabit 1.36 olacağı
için APK sözleşme değişikliğinden **sonra** derlenir. Plan
[P-029](../../PLAN.md).

### [10:21] Agent

Sözleşme 1.36: "önce eşitle" protokolün açılış bölümünün başına genel blok
olarak yazıldı (TR+EN); §16 alt başlığı ve Projects maddesi işaretçiye
indi — kural tek yerde. Ek gerekçe: telefon uygulaması GitHub'a yazdığı için
her hubın yerel kopyası geride kalabilir. Uygulama sabiti 1.36; tam süit
630/630. EVOLUTION notu yazıldı.

### [10:24] Agent

Dağıtım izi: geçmiş üç APK commit'ine `apk/<tarih>-<sha>` etiketi kondu
(sabitleri 1.26, 1.29, 1.33). `tool/install.sh` bu çağrıda derlenmiş bir
release'i başarıyla kurunca commit'i etiketleyip push'luyor; uygulama
dosyalarında commit'lenmemiş değişiklik varsa etiketlemiyor.
`audit.sh` §12'ye ikinci ölçüm eklendi (son `apk/*` etiketindeki sabit ↔
SYSTEM.md) — şu an doğru bulguyu veriyor: APK 1.33, sözleşme 1.36. Yeni §13:
sözleşme dosyalarına dokunup sürüm satırını değiştirmeyen commit (R-008);
yürürlük bugün. Bir kerelik geçmiş ölçümü: R-008'den beri 2 ihlal
(`77bc7aa` 2026-10-09, `b3dfbb6` 2026-08-13).
**İki kendi hatası, ikisi de anında yakalandı:** (1) `install.sh`
düzenlemesinde script'e koyduğum "sınama" satırı gerçek bir değiştirme
çağrısıydı ve derleme bloğunun ilk iki satırını "x" yaptı; diff'te görüldü,
Edit aracıyla düzeltildi. Önlem: çok satırlı kod değişikliği Edit aracıyla,
script'li her düzenlemeden sonra diff. (2) §13'te `--since=2026-10-14`
saatsiz tarih git'te "bugünün şimdiki saati" demek; bugünkü commit
görünmedi, `T00:00:00` eklendi.

### [10:26] Agent

Kurulum: kurulu APK cihazdan çekildi, imza SHA-1'i (`f4994730…`) yerel debug
anahtarıyla aynı ölçüldü. `tool/install.sh` derledi (`fc20227`) ve
kablosuz adb ile yerinde kurdu ("Success"); etiket `apk/2026-10-14-fc20227`
push'landı. Cihazda `lastUpdateTime=10:25:47`, `firstInstallTime` hâlâ
2026-08-01 — uygulama hiç kaldırılmadı. `audit.sh` §12 ✓ (kaynak ve
dağıtılan APK 1.36), §13 ✓. APK makineden buluta çıkmadı (yerel ağ), SEC
kaydı gerekmedi.
**Saat düzeltmesi:** bu oturumdaki ilk dört başlık tahminle yazılmıştı
(10:30-11:15); commit saatlerinden düzeltildi. Kapanmış
S-2026-10-09-son-durum'daki son başlık da (10:25) gerçekte 10:14'tü;
kapanmış oturum değiştirilmediği için burada not edildi. Önlem: kayıt
başlığına saat `date`'ten alınır, tahmin edilmez (L-052).

