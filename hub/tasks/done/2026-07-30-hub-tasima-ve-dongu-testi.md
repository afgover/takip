---
id: T-001
title: "Hub'ı taskr_takip'e taşı ve sözleşme döngüsünü test et"
created_by: user
created: 2026-07-30T12:40:00Z
updated: 2026-07-30T12:55:00Z
priority: high
category: gelistirme
tags: [kurulum, sozlesme-testi]
session: S-2026-07-30-duzeltme-ve-dongu-testi
result: "Hub geçmişi taskr_takip'e taşındı; döngü testi başarılı, sözleşme 1.0 revizyonsuz onaylandı (K-007, L-003, L-004)"
---

# Hub'ı taskr_takip'e taşı ve sözleşme döngüsünü test et

## İstek
Hub içeriği yanlışlıkla `takip` reposuna kurulmuştu; her şey `taskr_takip`e
taşınacak, düzeltme kayıtları işlenecek ve bu iş B-016 sözleşme döngü testinin
kendisi olarak kullanılacak (kullanıcı talimatı: "B-016'yı bu yaptıklarımızı
kullanabilirsin").

## Notlar
- 2026-07-30 12:45 — `takip` lokal klonundaki 4 commit'lik geçmiş `taskr_takip`e
  push'landı; içerik kaybı yok.
- 2026-07-30 12:50 — Düzeltme kayıtları işlendi: EVOLUTION (K-006 iptal,
  K-007/K-008), BACKLOG (B-013 düzeltme, B-015 ⏸, B-016/B-017 ✅),
  lessons (L-003, L-004), flutter-app-design §8 cevapları.
- 2026-07-30 12:55 — Döngü testi gözlemi: inbox → active → done akışı, klasör
  taşıma + frontmatter güncelleme + §8 commit önekleriyle pürüzsüz işledi;
  sözleşme değişikliği gerektiren bir durum çıkmadı.
