---
id: T-016
title: "Bekleyenlerde filtre menüleri: 3 açılır buton, kalıcı, çoklu seçim"
created_by: user
created: "2026-08-11T01:10:00Z"
updated: "2026-08-11T01:55:00Z"
priority: normal
category: gorev
tags: []
session: S-2026-08-11-filtre-menuleri
result: "Çip şeridi yerine repo/kategori/öncelik menüleri + sıralama + sıfırla; seçimler kalıcı"
author: afgover
assignee: afgover
---

# Bekleyenlerde filtre menüleri

## İstek
Yan yana sıralanan repo ve kategoriler yerine, sıralama tuşunun yanında
tıklayınca aşağı açılan repo/kategori/öncelik menüleri. Seçimler kalıcı,
sıfırlama tuşu var, birden fazla seçenek seçilebiliyor.

## Notlar
- Menü seçimde **kapanmıyor** — çoklu seçimin asıl noktası bu.
- Kapalı menünün üstünde seçili sayı yazıyor: `Kategori (2)`.
- Sıralama düğmesi de aynı şeride indi; dördü AppBar'a sığmıyordu.
- Sıfırla yalnız bir şey seçiliyken görünüyor ve filtre+sıralamayı birlikte
  temizliyor — yarısı dönen sıfırlama, sıfırlama değil.
- Kalıcılık `AppSettings` deseniyle: senkron varsayılan + diskten geri yükleme;
  bozuk tercih filtresiz açar (yanlış filtre görevleri sessizce gizlerdi).
- Yan bulgu: lifecycle testi baştan beri yarışlıydı (10 koşumda 2), yeni
  SharedPreferences okumaları görünür kıldı; test belirlenimci yapıldı.
