---
id: pending
title: "Sözleşme 1.43: Merkez görev işlemleri (aktör, istek kimliği, görev geçişi olayları)"
created_by: user
created: "2026-11-09T18:30:00Z"
updated: "2026-11-09T18:30:00Z"
priority: high
category: gelistirme
tags: [sozlesme, merkez]
session: none
result: none
author: afgover
via: asistan
---

# Sözleşme 1.43: Merkez görev işlemleri (aktör, istek kimliği, görev geçişi olayları)

## İstek
Merkez (çok kullanıcılı arka uç) uygulamadan gelen görev ekleme, düzenleme,
atama, kapatma ve yeniden açmayı hub'a yazacak. Kullanıcı kararı:
2026-11-09T18:19Z "önerildiği gibi yapabilirsin" (asistan#T-018, Merkez F2
planı). Sözleşmeyi takip kendi oturumunda yazar (R-001); bu kayıt öneridir.

- **Repo:** `afgover/takip`
- **Sıra:** inbox'taki "Sözleşme 1.42: karar kaydı biçimi ve öncelik puanı"
  önerisinden sonra gelir. takip oturumu ikisini tek sürümde (1.42) de
  çıkarabilir; numara takip'in kararı.

Hepsi isteğe bağlı alan; bilmeyen okuyucu yok sayar, eski uygulama ve
ajanlar olduğu gibi çalışır (R-008).

| Madde | Ne ekler | Neden |
| --- | --- | --- |
| `via: merkez` | §17'deki `via` alanına yeni değer | Merkez'in yazdığı kaydı uygulamadan ve asistandan ayırır |
| `actor` | İşlemi yapan kişi ya da ajan (Merkez kimliği + görünen ad) | `author` GitHub hesabıydı; Merkez üyesinin GitHub hesabı olmayabilir |
| `request_id` | Olay dosyasında istek kimliği | İkinci kez gelen istek aynı dosyayı hedefler, tekrar işlenmez |
| `uid` | Görevde kalıcı kimlik (ULID) | Numara verilmeden önce de görevi tek anlamlı gösterir |
| Olay türü `op` | `tags: [op]` ve `op: edit \| close \| reopen \| cancel \| defer` | 1.37'deki yorum/atama olay yoluna görev geçişlerini ekler |
| `base` | Olayda görevin bilinen blob SHA'sı | İşleyici çakışmayı bununla bulur |
| `closed_as` | `done/`daki görevde `done \| cancelled` | İptal için yeni klasör açmaz; "durum = klasör" korunur |
| `defer_until` | Bakılacak tarih (`YYYY-MM-DD`), `due`'dan ayrı | Ertelenen iş tarihi gelince Bugün'e döner |
| Yetkili işleyici | §4'e istisna: `op` olaylarını hub'ın tanımladığı işleyici uygular | Bugün klasörler arası taşımayı yalnız ajan yapıyor |

Yetkili işleyici ayrıntısı (Merkez F2 kararı 1: Merkez'in kendi işleyicisi,
proje başına açılır, varsayılan kapalı):

- Hub, işleyiciyi kök dosyada beyan eder (öneri: `ORTAM.md`'ye
  `**Görev işleyici:** merkez`). Beyan yoksa `op` olaylarını ajan işler ya da
  kullanıcıya sorar; işleyici o hub'da çalışmaz.
- İşleyici yalnız tanımlı geçişleri yapar: alan düzenleme (`title`,
  `priority`, `category`, `due`, `defer_until`, `assignee`), `active → done`
  (`closed_as`), `done → active` (yeniden aç), `→ done` iptal. Klasör dışına,
  `hub/tasks/` dışına yazmaz; olay dosyasını `tasks/events/`'e alır, hepsi tek
  commit.
- `id: pending` görevlere `T-` numarasını işleyici verir; commit üst commit'e
  bağlıdır (Git Data API), arada push olduysa yeniden okur ve dener. Ajanla
  aynı numarayı seçme yarışı böyle görünür olur, sessiz çakışma olmaz.
- `base` görevin güncel blob SHA'sıyla uyuşmazsa ve aynı alan başkası
  tarafından değiştirildiyse olay uygulanmaz; `result: cakisma` ile
  `tasks/events/`'e alınır, Merkez kullanıcıya iki değeri gösterir.

Alt görev ve bağımlılık (`parent`, `depends_on`) bu sürüme girmez; döngü
denetimi ve görünüm ayrı iş (sonraki sürüm).

## Notlar
Merkez tarafındaki F2.1 (merkez#23) bugünkü 1.41 biçimiyle çalışır; bu
öneri onaylanmadan hiçbir hub'da işleyici açılmaz.
