---
id: A-2026-08-21-001
session: S-2026-08-21-guvenlik-taramasi
type: analysis
title: "Güvenlik taraması — Aşama 5 kapanma koşulu 3"
created: 2026-08-21T13:41:00Z
---

# Güvenlik taraması — 2026-08-21

`tool/scan.sh`'in tam çıktısı. Özet kayıt `SECURITY.md` → SEC-014.

**Koşum tarihi:** 2026-08-21 · **Çıkış kodu:** 1 (bulgu var)
**Ortam:** Flutter 3.35.4 (stable, 2025-09-16) · macOS arm64
**Tetikleyici:** takvim değil — [Aşama 5](../../EVOLUTION.md)'in üçüncü
kapanma koşulu. Önceki tarama (SEC-008) 2026-08-04 tarihliydi, yani 30 günlük
eşik (~2026-09-03) **dolmadan** koşuldu.

---

## Tam çıktı

```
Güvenlik taraması — 2026-08-21T13:41:01Z

1. Bilinen zafiyetler (OSV)
  · 70 paket soruluyor (+3 kontrol)
  · kontrol grubu doğrulandı (3/3 beklenen bulgu geldi)
  ✓ 70 pakette bilinen zafiyet yok

2. Sürüm güncelliği (bilgi)
  · flutter_riverpod                           *2.6.1    *2.6.1      *3.3.2      3.4.2    
  · flutter_secure_storage                     *9.2.4    *9.2.4      *10.3.1     11.0.0   
  · intl                                       *0.20.2   *0.20.2     *0.20.2     0.20.3   

3. Sır taraması
  ✓ çalışma ağacı temiz
  ✓ git geçmişi temiz

4. Android yapılandırması
  ✓ yedekleme kuralları bağlı (SEC-009)
  · izinler: android.permission.INTERNET 
  ! anahtar yok — release DEBUG anahtarıyla imzalanıyor (SEC-010, B-101)
  ! elde duran release APK debug anahtarıyla imzalı — paylaşma

Sonuç
  ! 2 bulgu — SECURITY.md'ye kaydet, gerekiyorsa BACKLOG'a madde aç
```

---

## Okuma

**Boş sonuç doğrulandı.** Kontrol grubu 3/3 beklenen bulguyu getirdi, yani
"70 pakette zafiyet yok" cümlesi sorgunun çalıştığı kanıtlanmış hâlde
yazılıyor. Bu, L-035'in script'e gömülmüş hâli: doğrulanmamış bir "temiz",
olmayan bir güvence verir.

**Paket sayısı 68 → 70.** Fark bugünkü yükseltmeden
([B-136](../../BACKLOG.md#B-136)) geliyor; tarama, yükseltilmiş kilit
dosyasını ölçtü — yani yükseltmenin kendisi yeni bir zafiyet getirmedi.

**İki bulgu da yeni değil.** İkisi de SEC-010 → B-101 → T-010 zincirinin
görünümü: imza anahtarı üretilmediği için release derlemesi debug anahtarıyla
imzalanıyor, ve 2026-08-13'te üretilmiş APK bu makinede o imzayla duruyor.
İkincisi `build/` altında ve `.gitignore`'da, yani repoya hiç girmedi —
riski yalnız "paylaşılırsa".

**Gerileme yok.** SEC-009'un yedekleme kuralları yerinde (script bunu tam da
`flutter create`'in manifesti yeniden üretmesine karşı kontrol ediyor) ve
izin listesi hâlâ tek: `INTERNET`.

**Sürüm güncelliği bölümü bulgu değil, bilgi.** Üç satırın üçünün de gerekçesi
bugün yazıldı: iki major [B-138](../../BACKLOG.md#B-138)'de tetikleyicisiyle
ertelendi, `intl` ise SDK tarafından tam eşitlikle sabitli.

**Sınır (değişmedi):** tarama koştuğu **anın** danışmanlık veritabanına
göredir; tek seferlik bir onay değildir (SEC-011). Flutter SDK 3.35.4 ~11
aylık ve TLS yığını motorun içinde olduğu için paket taraması o yüzeyi
görmüyor — SEC-008'de yazılan bu sınır bugün de geçerli.
