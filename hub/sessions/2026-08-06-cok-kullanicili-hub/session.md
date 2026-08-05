---
id: S-2026-08-06-cok-kullanicili-hub
date: 2026-08-06
status: open
reconstructed: false
topics: [coklu-kullanici, sozlesme, tasarim]
artifacts:
  - artifacts/S-2026-08-06-cok-kullanicili-hub/coklu-kullanici-tasarimi.md
tasks_touched: []
---

# Oturum: Aynı hub'ı birden çok kişi kullandığında

## Özet
(oturum kapanışında yazılacak)

## Kayıt

### Kullanıcı
> takip reposunu birden fazla kullanici kullandiginda karmasa yaratmamak bir
> yontem uretelim

### Agent
Önce neyin gerçekten kırıldığı ölçüldü (tahminle tasarlamamak için). Dört
somut kırılma bulundu: kimlik şemada hiç yok (`created_by` bir *rol*, kimlik
değil; uygulama GitHub `login`'ini bilmiyor), bütün ID'ler tekil sayaç ve
çakışmaları **sessiz**, altı dosyaya herkes ekleme yapıyor, `notes/` tanımı
gereği tek kişilik.

Senaryo soruldu; kullanıcı **takım** (aynı hub, 2-5 kişi) dedi. Tasarım
artifact'e yazıldı.
