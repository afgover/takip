---
id: S-2026-08-21-guvenlik-taramasi
date: 2026-08-21
status: closed
reconstructed: false
author: afgover
topics: [guvenlik, tarama, asama-5]
artifacts: [A-2026-08-21-001]
tasks_touched: []
---

# Oturum: Güvenlik taraması — Aşama 5'in üçüncü koşulu

## Özet

Aşama 5'in üçüncü kapanma koşulu — güvenlik taraması — koşuldu ve kayda
geçti ([SEC-014](../../SECURITY.md#SEC-014)). Tetikleyici takvim değildi:
30 günlük eşik (~2026-09-03) dolmadan, aşamanın koşulu olarak koşuldu.

**Boş sonuç doğrulanmış hâlde yazıldı.** Kontrol grubu 3/3 beklenen bulguyu
getirdi, yani "70 pakette bilinen zafiyet yok" cümlesi sorgunun çalıştığı
kanıtlanmışken kuruluyor — L-035'in `tool/scan.sh`'e gömülmüş hâli.

**Paket sayısı 68 → 70** ve fark bugünkü yükseltmeden geliyor
([B-136](../../BACKLOG.md#B-136)). Tarama yükseltilmiş kilit dosyasını ölçtü,
yani yükseltmenin kendisi yeni bir zafiyet getirmedi — sıralamanın bu yönde
olması işe yaradı.

**İki bulgu çıktı, ikisi de yeni değil.** Her ikisi de SEC-010 → B-101 → T-010
zincirinin görünümü: imza anahtarı üretilmediği için release debug anahtarıyla
imzalanıyor, ve 13 Ağustos'ta üretilmiş APK bu makinede o imzayla duruyor.
İkincisi `build/` altında ve `.gitignore`'da — repoya hiç girmedi, riski
yalnız "paylaşılırsa".

**Gerileme yok:** SEC-009'un yedekleme kuralları yerinde (script tam da
`flutter create`'in manifesti yeniden üretmesine karşı bakıyor), izin listesi
hâlâ tek — `INTERNET`.

**Aşama 5'in üç koşulu da karşılandı, ama aşama kapatılmadı.** Sıradaki
aşamanın hedefi bir yön kararı; agent uyduramaz (T-017'nin aynı gerekçesi).
Ayrıca sorulacak ikinci bir soru çıktı: aşama bir günde kapandığına göre
kapanma koşulu dar mı yazılmıştı. İkisi de kullanıcıya bırakıldı.

## Kayıt

### Kullanıcı
> taramayı şimdi koşalım

### Agent — tarama koşuldu, SEC-014 yazıldı

`tool/scan.sh` (çıkış kodu 1 — bulgu var). Dört parçanın tamamı koştu; tam
çıktı artifact'te
([A-2026-08-21-001](../../artifacts/S-2026-08-21-guvenlik-taramasi/guvenlik-taramasi.md)).

Bu, script'in **ilk otomatik koşumu** — SEC-008 elle koşulmuştu. Script'in var
oluş gerekçesi tam da buydu: elle koşumun sorunu tekrarında ortaya çıkıyor ve
bir sonraki koşum sessizce eksik oluyor. Bugünkü koşum onu sınadı: dört parçanın
hiçbiri hatırlanmak zorunda kalmadı.

**Ölçüm:** 70 paket + 3 kontrol sorgulandı, kontrol 3/3 doğrulandı, 2 bulgu
(ikisi de bilinen zincirden).
