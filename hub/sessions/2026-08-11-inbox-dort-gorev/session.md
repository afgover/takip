---
id: S-2026-08-11-inbox-dort-gorev
date: 2026-08-11
status: open
reconstructed: false
author: afgover
topics: [offline, bekleyenler, waiting, sozlesme]
artifacts: []
tasks_touched: [T-012, T-013, T-014, T-015]
---

# Oturum: Inbox'taki dört görev

## Özet
(oturum kapanışında yazılacak)

## Kayıt

### Kullanıcı
> hubdaki gorevleri yap

### Agent
Inbox'ta telefondan açılmış dört görev vardı (2026-08-10). Hepsi `active/`e
alındı: T-012 (offline, `high`), T-013 (filtre/sıralama), T-014 (seçeneksiz
beklemede metin cevabı), T-015 (geçici sözleşme maddesi).

**T-012'nin teşhisi ölçüldü, tahmin edilmedi.** Şikâyet "liste görünüyor,
tıklayınca bağlantı yok diyor"du ve sebebi tam olarak buydu: `pendingFromStore`
listeyi **yerel kopyadan** çiziyor (B-057), ama `TaskRepo.read` ve `listDone`
doğrudan API'ye gidiyor. Yani senkron dosyaları zaten indirmiş — eksik olan
indirme değil, **okuma yolu**.
