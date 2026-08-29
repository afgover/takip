---
id: S-2026-08-29-store-calismasi
date: 2026-08-29
status: closed
reconstructed: false
author: afgover
topics: [store, play, dagitim, imza]
artifacts:
  - artifacts/S-2026-08-29-store-calismasi/store-calismasi.md
tasks_touched: [T-010, T-020]
---

# Oturum: store çalışması

## Özet

Kullanıcı mağaza dağıtımı için çalışma istedi — B-098'in beklediği "gerçek
talep" bu. Çalışma yapıldı:
[A-2026-08-29-001](../../artifacts/S-2026-08-29-store-calismasi/store-calismasi.md).

Ana sonuçlar: **Play yolu günler mertebesi** ve önündeki tek sert kapı imza
(T-010 — tetikleyicisi mağazayla resmen geldi; Play App Signing/upload key
önerildi). Veri hikâyesi mağaza için avantaj: geliştiriciye hiçbir veri
akmıyor, tek izin `INTERNET`. Ekran görüntüleri **gerçek hub'la çekilmez**
(Copilot'un "kişisel bilgi yok sanmıştım" dersi) — sentetik simhub demo
bağlantı olarak kullanılır. **iOS ertelenmesi önerildi**: iskelet hiç yok,
haftalar mertebesi. Çalışmanın en önemli cümlesi bakım taahhüdü: Play
yıllık targetSdk yükseltmesi ister, B-138'in ertelediği geçişler takvime
bağlanır — mağaza "biten iş" değil, yıllık abonelik.

Kaynak olarak `Copilot_takip`'in mağaza birikimi kullanıldı (hukuki risk
raporu, bugünkü Play Console oturumu, Sekuvo emsali) — hesabın canlı olduğu
oradan ölçüldü.

Beş karar kullanıcıya: [T-020](../../tasks/waiting/2026-08-29-store-kararlari.md)
(`waiting/`, üç seçenekli). B-098 ve T-010'a tarihli notlar düşüldü.

## Kayıt

### [15:40] Kullanıcı
> uygulamayi store lara koymak icin de bir calisma yaparmisin

### [15:55] Agent
Ölçümler (android yapılandırması, ios yokluğu, veri akışı, Copilot
birikimi) yapıldı; çalışma artifact'e, kararlar T-020'ye yazıldı.
