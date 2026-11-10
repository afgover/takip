---
id: S-2026-11-10-sozlesme-1-42
date: 2026-11-10
status: open
reconstructed: false
author: afgover
surface: projects
thread: cmsg_015UWMzEHfYaAw8ghcFB1SaBCsGbZGh5xyT3pf2jgJQNAq
topics: [sozlesme, karar, merkez, supersedes]
artifacts: []
tasks_touched: []
---

# Oturum: sözleşme 1.42 — karar kaydı, Merkez görev işlemleri, karar serisi

## Özet

*(oturum açık — kapanışta yazılacak)*

## Kayıt

### [11:54] Koordinatör (asistan projesi, kullanıcı adına)

> takip deposunda takip'in kendi oturumu olarak gelen kutusundaki sözleşme
> önerilerini işle: 1.42 (karar kaydı biçimi, öncelik puanı; takip
> 2026-11-08 kaydı) ve 1.43 (Merkez görev işlemleri, takip 87690b2).
> Yürürlükte 1.41. R-001 gereği sözleşmeyi (SYSTEM.md) takip kendi
> oturumunda yazar; bu thread o oturumdur. İkisini tek sürümde
> çıkarabilirsin. [...] fatih işlerin beklemeden eş zamanlı yürümesini
> istiyor; geri döndürülebilir adımlara onaysız başla. Takip
> sözleşmesindeki biçim denetimlerini çalıştır.

Ek: supersedes önerisi `asistan` `hub/artifacts/S-2026-11-10-karar-eskime/sozlesme-supersedes-onerisi.md`
(asistan main 7a9a1c2).

### [12:05] Agent

Açılış: `tool/acilis.sh` koştu; saat GitHub `Date:` ile aynı gün. Hub
1.41. inbox: iki sözleşme önerisi, "hub kayıtlarını özel depoya taşı"
görevi (bu oturumun konusu değil, raporlandı), iki olay (yorum + atama,
2026-10-15 denemesi). 2026-10-14 oturumu 27 gündür açık.

Kararlar: üç öneri tek sürümde, **1.42** olarak çıkar (1.43 numarası
kullanılmaz; öneri kaydı da numarayı takip'e bırakıyordu). Metin Merkez'in
`main`'deki koduna (`src/operations/processor.ts`,
`task-processor.service.ts`, `src/hubs/decision-score.ts`,
`decision-series.ts`) karşı okunarak yazılır; öneriden ayrılan iki yer
kodun davranışına hizalanır:
- Çakışma ölçüsü `base` (blob SHA) değil alan karşılaştırması
  (bilinen → istenen); `base` isteğe bağlı kalır. Gerekçe: blob SHA bütün
  dosyaya bağlı, ajanın bir not satırı da onu bozar.
- `importance` taşımayan eski karar `orta` değil `priority`'den türer
  (urgent→kritik … low→dusuk), başlangıç 2026-11-08 (hub'lar arası aynı
  puan için sabit gün).
