---
id: S-2026-08-29-denetci-duzeltmesi
date: 2026-08-29
status: closed
reconstructed: false
author: afgover
topics: [denetim, yanlis-pozitif, copilot]
artifacts: []
tasks_touched: []
---

# Oturum: denetçiye `reconstructed` istisnası

## Özet

`Copilot_takip` gövde temizliği sırasında (o hub'ın
S-2026-08-29-govde-temizligi kaydı) denetçinin 1. kontrolü 16 yanlış pozitif
üretti: 2026-02..08 tarihli oturumlar hub kurulurken 2026-08-03'te geçmişten
içe aktarılmış ve `reconstructed: true` ile dürüstçe işaretlenmiş — kayıt
tarihi ile commit tarihinin ayrışması bu sınıfta **beklenen** davranış (v1.6).
`tool/audit.sh` bu sınıfı artık atlıyor; dürüstçe işaretlenmiş kayıt suçlanmaz.

Aynı temizlikte denetçi **bu oturumun kendi işini de yakaladı**: eksik `## Özet`
başlıkları, `updated:` alanları, ve hafızadan türetilmiş bir ID'nin (T-056)
gerçek bir çakışmaya dönüşmesi — protokolün "numarayı dosyadaki en büyükten
türet" kuralının ihlali, bu hub'ların çakışmalarını doğuran hatanın aynısı.
Dördü de düzeltildi (T-066); Copilot_takip denetimi 18 bulgudan 1'e indi
(kalan: bilinen app push gecikmesi).
