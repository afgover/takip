---
id: T-018
title: bekleyen görevlerin offline da tamamlanması
created_by: user
created: "2026-08-21T01:54:29Z"
updated: "2026-08-21T11:30:00Z"
priority: high
category: gorev
tags: [offline, kuyruk, mukerrer]
session: S-2026-08-21-offline-mukerrer-kuyruk
result: "Düzeltildi — B-135, 2026-08-21"
author: afgover
---

# bekleyen görevlerin offline da tamamlanması

## İstek
bekleyen görevler kullanıcı tarafından offline iken tamamlanınca yada diğer şıklar işaretlenince kuyruğa yeni bir görev olarak alınıyor, fakat o görev hala görünmeye devam ediyor, 2. kez tamamlandı derse user mükerrer olarak kuyruğa alıyor

## Notlar

- 2026-08-21 · Kök neden çevrimdışılık değildi: "bu bekleme bildirildi" bilgisi
  detay ekranının widget durumunda tutuluyordu ve ekran kapanınca ölüyordu.
  Aynı kusur çevrimiçinde de vardı; çevrimdışı yalnız **görünür** kılıyordu
  (iki taslak kuyrukta yan yana duruyor). Bilgi cihazda kalıcı bir kayda
  taşındı; iki gönderim yolu da onu yazıyor.

- 2026-08-21 · "Görev hâlâ görünüyor" kısmı **bilerek korundu** (kullanıcı
  kararı): app dosyayı `waiting/`ten taşıyamıyor (R-001) ve gizlemek, agent
  işlemezse sessiz kayıp demek olurdu. Satır listede kalıyor ama rozeti
  "Bildirildi" oluyor ve düğmeleri kapalı geliyor.

- 2026-08-21 · Kayıt, görev `waiting/`ten çıkınca senkronun silinmiş belge
  temizliğiyle aynı yerde düşüyor. → [B-135](../../BACKLOG.md#B-135),
  [P-010](../../PLAN.md), [L-051](../../knowledge/lessons.md#L-051)
