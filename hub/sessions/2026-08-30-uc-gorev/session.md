---
id: S-2026-08-30-uc-gorev
date: 2026-08-30
status: open
reconstructed: false
author: afgover
topics: [taslak-kaybi, offline, kuyruk, token-arastirmasi]
artifacts: []
tasks_touched: [T-021, T-022, T-023]
---

# Oturum: inbox'taki üç görev

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
