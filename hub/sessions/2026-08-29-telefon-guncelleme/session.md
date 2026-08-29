---
id: S-2026-08-29-telefon-guncelleme
date: 2026-08-29
status: closed
reconstructed: false
author: afgover
topics: [apk, kurulum, telefon]
artifacts: []
tasks_touched: []
---

# Oturum: telefonun HEAD'den güncellenmesi

## Özet

Kullanıcı isteğiyle telefon (`R5CW71GRKPB`) `tool/install.sh` ile HEAD'den
(`8483c72`) güncellendi — yerinde kurulum, kaldırma yok, veri ve token'lar
korundu. Cihazdan doğrulandı: `lastUpdateTime=2026-08-29 15:07:40`.

Telefonun kazandığı iki şey (2026-08-21 21:00 kurulumuna göre ölçülmüştü):
[B-140](../../BACKLOG.md#B-140) — hedefi kalmayan kuyruk taslakları
Ayarlar'da ayrı satırda + onaylı silme; ve sözleşme sabiti **1.27** —
bayat-sözleşme uyarısı artık bir sürüm geriden bakmıyor (1.26'da kalmış
hub'ları da yakalar).

İmza değişmedi: hâlâ debug anahtarı ([SEC-010](../../SECURITY.md#SEC-010),
T-010 `waiting/`te; tetikleyici [SEC-015](../../SECURITY.md#SEC-015)'te
daraltılmış haliyle duruyor — üçüncü kişiye/halka verilme).

Not: Drive'daki `takip-2026-08-28-5f3b6db.apk` artık telefondakinden geride
(1.27 sabiti yok). Kullanıcı Drive kopyasının tazelenmesini istemedi;
istenirse tek komut.
