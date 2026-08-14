---
id: S-2026-08-14-backlog-gozden-gecirme
date: 2026-08-14
status: open
reconstructed: false
author: afgover
topics: [backlog, gozden-gecirme, acilis]
artifacts: []
tasks_touched: []
---

# Oturum: Backlog'un açık maddelerini gözden geçirme

## Özet
(oturum açık)

## Kayıt

### Kullanıcı
> yeni oturum aç ve backlogdaki acik maddeleri gozden gecir

### Agent — açılış kontrolleri

- Hub dili `tr`, kullanıcı da Türkçe yazıyor.
- `tasks/inbox/` boş, `active/` boş, `status: open` kalan başka oturum yok.
- Çalışma ağacı temiz, `origin/main` ile eşit.
- **Sözleşme kontrolü koştu** (§10): `curl` ana kopyayı çekti, yerel kopyayla
  fark yok. Dün 404 dönen komut bugün çalışıyor — repo public olduğu için.
- Son `tarama` kaydı [SEC-008](../../SECURITY.md#SEC-008), 2026-08-04 → 10
  günlük, 30 gün eşiğinin altında; tarama koşulmadı, gerekmiyordu.
- §13 geçici madde G-001: `waiting/`teki tek görev (T-010) zaten `options`
  taşıyor, madde idempotent — yapacak bir şey yok.

### Agent — açık maddelerin gözden geçirilmesi

12 satır `- [ ]` ile işaretli ama **biri gerçek madde değil**: `B-001`,
dosyanın başındaki biçim örneğinin içinde duruyor (``` bloğu). Markdown'da kod
olarak çiziliyor, yani ekranda kutu görünmüyor; ama satır bazlı sayan her şey
(grep, ve uygulamanın backlog görünümü) onu açık iş sayar. Gerçek sayı **11**.

Kalan 11 madde üç gruba ayrılıyor:

**1. Bayat: B-052 — "bir hafta gerçek kullanım".** Ön koşulları (B-015, B-020,
B-034'ün cihaz ayağı) çoktan kapanmış ve kullanım **fiilen yaşanmış**:
2026-08-01'den bugüne 13 gün, telefondan açılmış görevler (2026-08-10'da dört
görev, T-012…T-016), kullanımdan doğan düzeltmeler (B-054/B-055/B-056 daha ilk
gün), ve gerçek bir çoklu-hub vakası (2026-08-12, B-126/B-127). Madde açık
duruyor ama tarif ettiği iş olmuş; kapanması B-053'ü, dolaylı olarak
B-063/B-064'ü çözer.

**2. Kullanıcıya bağlı, tetikleyicisi net:** B-101/T-010 (imza anahtarı) —
repo dün public olduğu için "Releases'ta APK" adımının önündeki **tek** kapı
artık bu. B-103 (token kapsam eşiği) bir tasarım kararı bekliyor.

**3. Bilinçli beklemede:** B-098 (store, gerçek talep), B-110 (çoklu kullanıcı,
ikinci kişi), Faz 6'nın tamamı (B-060…B-064).
