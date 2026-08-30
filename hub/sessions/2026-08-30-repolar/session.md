---
id: S-2026-08-30-repolar
date: 2026-08-30
status: closed
reconstructed: false
author: afgover
topics: [store, pages, demo-hub]
artifacts:
  - artifacts/S-2026-08-30-store-hazirligi/store-hazirlik-paketi.md
tasks_touched: []
---

# Oturum: store hazırlığının iki reposu açıldı

## Özet

Kullanıcı onayıyla ("repolari aç") iki repo kuruldu:

1. **`afgover/takip-site`** (public) + GitHub Pages: gizlilik politikası
   TR+EN tek sayfada, karanlık tema destekli —
   `https://afgover.github.io/takip-site/`, HTTP 200 doğrulandı. İçerik
   hazırlık paketindeki taslağın birebir yayımı; Data Safety beyanıyla aynı
   dili konuşuyor. İletişim satırında geliştirici e-postası var — Console
   kişisel hesapta bu adresi zaten yayımlıyor (SEC-013 çizgisi).
2. **`afgover/takip-demo`** (private): mağaza görselleri için sentetik hub —
   simülasyon altyapısındaki simhub içeriği. Gerçek proje verisi yok;
   README'si bunu açıkça söylüyor.

**Kalan görsel adımı kullanıcıya bağlı:** fine-grained token'ın
`takip-demo`'yu görmesi için repo, token kapsamına eklenmeli; sonra telefonda
demo bağlantı kurulup görseller çekilir.
