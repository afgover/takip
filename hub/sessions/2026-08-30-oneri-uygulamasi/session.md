---
id: S-2026-08-30-oneri-uygulamasi
date: 2026-08-30
status: closed
reconstructed: false
author: afgover
topics: [token, sozlesme, acilis, claude-md]
artifacts:
  - artifacts/S-2026-08-30-uc-gorev/token-maliyeti.md
tasks_touched: []
---

# Oturum: token önerilerinin uygulanması (Ö1, Ö4, Ö2 — Ö3 hariç)

## Özet
Token çalışmasının üç önerisi kullanıcı kararıyla uygulandı (Ö3 hariç):
açılış kontrolleri `tool/acilis.sh` ile tek çağrıya indi (ölçülen gerekçe:
maliyetin kaynağı tur sayısı), `CLAUDE.md` işaretçisi uyumu sabitledi,
BACKLOG'a açılışta seçici bakış kuralı geldi — her önerinin §6'daki riski
uygulamada karşılandı. Sözleşme 1.28; 629 test.

## Kayıt

### [Kullanıcı]
> onerileri onerdigin sirayla uygula, Ö3 haric

### [Agent]
Karar net: Ö1 (açılış turlarını tek komuta), Ö4 (CLAUDE.md işaretçisi),
Ö2 (BACKLOG'a sayım denetimli seçici bakış). Ö3 (arşivleme) uygulanmıyor —
§6'daki gerekçeyle: şema değişikliği, app'i kırar.
Protokol değiştiği için sözleşme 1.28'e çıkacak (P-015'in dersi: prosedür-only
değişiklik diğer hub'lara görünmez kalır). Plan P-020.

### [Agent — uygulama tamam]
- **Ö1:** [`tool/acilis.sh`](../../../tool/acilis.sh) — 8 kontrol tek çağrıda,
  kompakt çıktı. Üç kusuru kendi test koşumları yakaladı: BSD `date`
  uyumsuzluğu, `awk` alan indeksi, ve boru hattının denetim çıkış kodunu
  yutması — üçü de düzeltildi. KOŞMADI kuralı script'te ve protokolde.
- **Ö4:** `CLAUDE.md` — tek satır işaretçi (L-022 gereği içerik taşımıyor).
- **Ö2:** protokol madde 3 artık seçici bakış tanımlıyor; iki koruma yazılı:
  boş desen şüphesi ve "iş yapmadan önce gövde okunur" (B-098 örneğiyle).
- Sözleşme **1.28**: SYSTEM ×2 + not, constants, README ×2. 629 test,
  `analyze` temiz. B-141 dağıtım paketi üç parçaya genişledi.
- **Ö3 uygulanmadı** (kullanıcı kararı, §6 gerekçesi).
