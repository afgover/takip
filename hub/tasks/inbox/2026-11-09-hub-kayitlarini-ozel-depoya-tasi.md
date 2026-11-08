---
id: pending
title: "Hub kayıtlarını özel depoya taşı (sözleşme ana kopyası burada kalır)"
created_by: user
created: "2026-11-09T00:10:00Z"
updated: "2026-11-09T00:10:00Z"
priority: high
category: gelistirme
tags: [guvenlik, hub, merkez]
session: none
result: none
author: afgover
via: asistan
---

# Hub kayıtlarını özel depoya taşı (sözleşme ana kopyası burada kalır)

## İstek
takip deposu herkese açık kalır, ama içindeki hub kayıtları (oturumlar,
görevler, BACKLOG, EVOLUTION, SECURITY, knowledge, notes, artifacts) özel bir
depoya taşınır. Kullanıcı kararı: 2026-11-08T21:57Z "onerilerin uygun"
(asistan#K-013, asistan#SEC-005). Taşıma takip'in kendi oturumunda yapılır.

- **Repo:** `afgover/takip`

## Önerilen yol (takip oturumu karar verir)

1. **Kalanlar:** sözleşme ve yöntem belgeleri herkese açık ana kopya olarak
   burada kalır: `hub/SYSTEM.md`, `hub/SYSTEM.en.md`, `hub/AGENT_PROTOCOL.md`,
   `hub/AGENT_PROTOCOL.en.md`, `hub/artifacts/reference/` (kurulum talimatı,
   asistan katmanı). Bütün hub'ların `acilis.sh` karşılaştırması bu yolları
   okuyor; yerleri değişmemeli.
2. **Gidenler:** geri kalan kayıtlar, geçmişiyle birlikte özel depoya
   (`git filter-repo --path hub/` ile ayrı bir klonda). Ad önerisi
   proje düzenine uygun `afgover/takip_takip`.
3. **Testler:** takip testlerinin bir kısmı gerçek hub kayıtlarını fixture
   olarak okuyor (bilgi tabanı, ID tekilliği, oturum, plan). Taşımadan önce
   bunlar `test/fixtures/` altına kopyalanır ya da yeni depoyu okuyacak
   biçime çevrilir; `flutter test` yeşil kalmalı.
4. **Bağlantılar:** telefondaki takip uygulamasına yeni depo eklenir (token
   kapsamı), Merkez GitHub App kurulumuna yeni depo eklenir, asistan
   `projeler.json`'da takip'in hub yolu güncellenir (asistan kendi tarafını
   yapar).
5. **Geçmiş:** herkese açık geçmiş yeniden yazılmaz önerisi (zaten
   açıktı, yeniden yazmak geri alınamaz ve çatalları kırar); bunun yerine
   `tool/scan.sh` geçmiş taraması koşulur. Geçmişi yeniden yazmak istenirse
   bu ayrı bir kullanıcı kararıdır.

Depo görünürlüğü ya da silme gibi geri alınamaz adımlardan önce kullanıcıya
sorulur.
