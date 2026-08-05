---
id: S-2026-08-05-tarama-tekrari
date: 2026-08-05
status: closed
reconstructed: false
topics: [guvenlik, tarama, otomasyon, sozlesme-1.14]
artifacts: []
tasks_touched: [T-009]
---

# Oturum: Tarama tekrar aralığı (SEC-011 kapandı)

## Özet
B-102 kapandı: taramanın nasıl ve hangi aralıkla tekrarlanacağına karar verildi.

**Tek mekanizma yetmiyordu.** SEC-008 dört parçaydı ve otomatikleşme dereceleri
farklı: bilinen zafiyetin sürekli bir gözcüsü olabilir, sır taraması ve Android
yapılandırmasının olamaz (secret scanning private repoda ücretli; yapılandırma
zaten insan işi). Araştırmada Dependabot'un `pub`'ı desteklediği — güvenlik
güncellemeleri dahil, private repolarda da — doğrulandı.

**Karar (kullanıcı seçti): Dependabot + `tool/scan.sh` + 30 gün.**
1. Bilinen zafiyet Dependabot'a devredildi: sürekli, bedava, bakımsız. İki repo
   ayarı gerekiyor → T-009 `waiting/`e kondu.
2. Kalan üç parça `tool/scan.sh`'ta toplandı — tek komut. Elle koşumun asıl
   sorunu tekrarında ortaya çıkıyordu: OSV toplu sorgusu, sır desenleri ve
   Android kontrolleri her seferinde yeniden hatırlanmak zorunda kalır ve bir
   sonraki koşum sessizce **eksik** olur.
3. Tetikleyici takvim değil, **kaydın yaşı**: agent oturum açılışında son
   `tarama` kaydının tarihine bakıyor, 30 günden eskiyse koşuyor (K-035).
   Takvime bağlı bir hatırlatıcı sustuğunda sessizce susar; hub'daki bir tarih
   unutulduğunda da görünür kalır.

**L-035 koda gömüldü.** `scan.sh`, bilinen açığı olan bir **kontrol grubunu** da
soruyor; kontrol boş dönerse tarama kendini geçersiz ilan edip `2` ile çıkıyor
ve "temiz" demiyor. Ağa ulaşılamadığında da aynı — koşmamak, temiz olmak
değildir. İki yol da sınandı: bozuk ekosistem adıyla koşum `2` verdi ve
anlaşılır mesaj yazdı; gerçek koşum kontrolü `3/3` doğrulayıp 68 pakette
zafiyet bulmadı.

**Sözleşme 1.14.** §12'ye `tarama` tarihinin tetikleyici olduğu, protokole de
oturum açılışı maddesi yazıldı. Yan karar §10'a eklendi: **`AGENT_PROTOCOL.md`
değişikliği de sürüm artırır** — yayılma yalnız `SYSTEM.md`'nin numarasına
bakıyor, protokol tek başına değiştirilseydi diğer hub'lar yeni kuralı hiç
almazdı ve bunu fark eden bir kontrol yok.

Bugünkü koşumun tek bulgusu zaten açık olan SEC-010 (release'in debug
anahtarıyla imzalanması, B-101). 404 test, analyze temiz.

## Kayıt

### Kullanıcı
> b-102 tarama tekrar araligina karar verelim

### Agent
Önce ölçüldü: repoda `.github` yok, `tool/` içinde yalnız `install.sh` var.
Sonra araştırıldı — Dependabot `pub` ekosistemini destekliyor (belgeden
doğrulandı; version updates **ve** security updates, private repolarda da).

Bu, kararı ikiye böldü: SEC-008'in dört parçasından yalnız biri sürekli
izlenebiliyor. Kullanıcıya dört mekanizma ve üç aralık seçeneği, kapsam
tablosuyla birlikte sunuldu. Seçim: **Dependabot + `tool/scan.sh`**, aralık
**30 gün**.

Uygulama: script yazıldı ve iki yoldan da sınandı (gerçek koşum + bozuk sorgu),
`AGENT_PROTOCOL.md`'ye madde 4, `SYSTEM.md` §12'ye tetikleyici kuralı ve §10'a
protokol-sürüm bağı eklendi, sürüm 1.14'e çekildi (uygulama sabiti, README ve
kurulum talimatı dahil). SEC-011 kapatıldı, T-009 açıldı, K-035 yazıldı.
