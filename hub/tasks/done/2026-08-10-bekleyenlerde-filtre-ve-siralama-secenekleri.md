---
id: T-013
title: bekleyenlerde filtre ve sıralama seçenekleri
created_by: user
created: "2026-08-10T15:37:08Z"
updated: "2026-08-10T15:37:08Z"
priority: normal
category: gorev
tags: []
session: S-2026-08-11-inbox-dort-gorev
result: "Filtre (repo/öncelik/kategori) zaten vardı; eksik olan sıralamaydı ve o — bkz. S-2026-08-11-inbox-dort-gorev"
author: afgover
assignee: afgover
---

# bekleyenlerde filtre ve sıralama seçenekleri

## İstek
filtre olarak 3 ayrı seçim butonu; repo, öncelik ve kategori,
sıralamada tarihe göre ve önceliğe göre, artan ve azalan

## Notlar
Filtre (repo/öncelik/kategori) zaten vardı; eksik olan sıralamaydı ve o
eklendi: tarihe ve önceliğe göre, artan/azalan. Başlıktaki menüden seçiliyor,
aynı ölçüte ikinci dokunuş yönü çeviriyor.
Varsayılan "bekleyenler önce" **menüde bir seçenek olarak** duruyor: K-022'nin
gerekçesi geçerli ama kullanıcının açık seçimine sessizce binmiyor — binseydi
sıralama bozuk görünürdü.
Test bir hata yakaladı: değeri bilinmeyen görevlerde yön çevirmesi iki kez
uygulanıyor, "artan"da listenin tepesi bilgisizlerle doluyordu. Bilinmeyen
artık yönden bağımsız olarak sona gidiyor.
