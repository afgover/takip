---
id: S-2026-08-30-uc-gorev
date: 2026-08-30
status: closed
reconstructed: false
author: afgover
topics: [taslak-kaybi, offline, kuyruk, token-arastirmasi]
artifacts:
  - artifacts/S-2026-08-30-uc-gorev/token-maliyeti.md
tasks_touched: [T-021, T-022, T-023]
---

# Oturum: inbox'taki üç görev

## Özet

App'ten gelen üç görev aynı oturumda kapandı.

**T-022 + T-021 ([P-018](../../PLAN.md#P-018)):** taslak kaybının kökü
`_screens[_index]`'in sekme değişiminde ekranı öldürmesiydi →
`IndexedStack` + her değişiklikte diske inen, açılışta geri gelen,
gönderimde temizlenen otomatik taslak. Kuyruk taslakları artık Ayarlar'dan
listelenir, düzenlenir (sıra `replace` ile korunur) ve onayla silinir.
Test, düzenleme diyaloğunda erken `dispose` kusurunu yakaladı. 629 test.

**T-023 ([P-019](../../PLAN.md#P-019),
[A-2026-08-30-001](../../artifacts/S-2026-08-30-uc-gorev/token-maliyeti.md)):**
kontrollü A/B — aynı tek satırlık iş, hub'sız 38.5k / protokollü 49.1k =
**+%28**; maliyetin kaynağı dosya okumak değil **tur sayısı** (2'ye karşı 11
araç çağrısı). Çekirdek hub dosyaları 25k–132k token ve tek yönlü büyüyor;
risk tamamı okunan `BACKLOG` gibi dosyalarda. Geçmiş toplam kaba tahmin
3M–18M. Dört azaltma önerisi yazıldı (tur birleştirme en güçlü kaldıraç);
karar kullanıcıda. Yan bulgu: bir simülasyon ajanı protokolü kendiliğinden
atladı — uyum değişkenliği maliyet ölçümünde de görünüyor.

## Kayıt

### [01:55] Kullanıcı
> son eklediğim görevleri ele alırmısın

### [01:56] Agent
inbox'ta üç görev (app, 2026-08-29 akşamı). ID'ler dosyadaki en büyükten
(T-020) türetildi, geliş sırasıyla:

- **T-021** (normal/gorev) — offline eklenen görev değiştirilip silinemiyor
- **T-022** (urgent/hata) — ekleme ekranı: klavye/app değişiminde yazı kaybı
- **T-023** (high/arastirma) — hub'ın token/bağlam maliyeti çalışması

Sıra: T-022 (acil) → T-021 (bitişik kod bölgesi) → T-023 (araştırma).
Üçü `active/`e alındı.

### [02:40] Agent — T-022 ve T-021 kapandı
[P-018](../../PLAN.md#P-018) tamamlandı. T-022'nin kök nedeni tekti ama
katman ikiydi: `_screens[_index]` sekme değişiminde ekranı yok ediyordu
(→ `IndexedStack`) ve süreç ölümünde bellekteki her şey gidiyordu
(→ taslak her değişiklikte diske, açılışta geri, gönderimde temiz).
T-021: kuyruk satırı dokunulabilir oldu — taslak listesi, başlık+açıklama
düzenleme (`Outbox.replace` sırayı koruyor; öteki alanlar taslağın
kendisinden okunuyor ki iki kaynak ayrışmasın) ve "hiçbir yere yazılmadı"
cümlesini açıkça kuran onaylı silme. Test, düzenleme diyaloğunda erken
`dispose` kusurunu yakaladı — diyalog kendi durumuna ayrıldı.
629 test, `analyze` temiz. Sırada T-023 (token araştırması).

### [03:15] Agent — T-023 kapandı, oturum kapanıyor
A/B sayıları geldi; analiz artifact'e, öneriler karar olarak kullanıcıya
bırakıldı. Üç görev de `done/`, iki plan kapandı. Kapanış kontrolü: açık
oturum yok, üretilen her dosya linkli, çalışma ağacı temiz.

