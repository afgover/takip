---
id: T-012
title: offline özellikleri
created_by: user
created: "2026-08-10T15:32:19Z"
updated: "2026-08-10T15:32:19Z"
priority: high
category: gorev
tags: []
session: S-2026-08-11-inbox-dort-gorev
result: "Yerel kopyadan okuma yolu tamamlandı. Teşhis: senkron zaten bütün `.md` — bkz. S-2026-08-11-inbox-dort-gorev"
author: afgover
assignee: afgover
---

# offline özellikleri

## İstek
offline modda bekleyenler kısmı başlık olarak görünüyor, tıklayınca bağlantı yok diyor, tam indirsin herşeyi sync olduğu zaman

## Notlar
Yerel kopyadan okuma yolu tamamlandı. Teşhis: senkron zaten bütün `.md`
dosyalarını indiriyordu (`isSyncable`), liste de yerel kopyadan çiziliyordu
(`pendingFromStore`, B-057) — ama `TaskRepo.read` ve `_list` doğrudan API'ye
gidiyordu. Eksik olan indirme değil, **okuma yoluydu**.
`TaskRepo` artık isteğe bağlı bir `OfflineStore` alıyor; kopya varsa ağ hiç
kullanılmıyor, yoksa eski davranış korunuyor (ilk açılış, senkron bitmeden).
Bildirilmeyen aynı kusur da düzeltildi: `listDone` de ağa gidiyordu.
`offline_read_test` ağı **kasten kırık** kurup ölçüyor — geçen test tek şey
kanıtlıyor: o yolda ağa hiç çıkılmadı.
