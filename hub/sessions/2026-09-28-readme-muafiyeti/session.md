---
id: S-2026-09-28-readme-muafiyeti
date: 2026-09-28
status: open
reconstructed: false
author: afgover
topics: [artifact-lint, readme, tool]
artifacts: []
tasks_touched: [T-025]
---

# Oturum: `artifact-lint.sh`'ta README muafiyeti

## Özet

*(oturum açık — kapanışta yazılacak)*

## Kayıt

### [09:10] Kullanıcı

> 1 uydur

### [09:15] Agent

1. seçeneği (README'ye artifact frontmatter'ı) uygulamadan önce durdu:
uygulama README'yi zaten artifact saymıyor —
[browse_repo.dart:48-54](../../../lib/hub/browse_repo.dart) artifact
listesinde `artifacts/**/README.md`'yi, `task.dart:87` görev klasörlerinde
README'yi "yardımcı dosya" diye eliyor. Frontmatter eklemek hub'a ikinci bir
"artifact nedir" tanımı sokardı; README'nin gerçek tarihi (2026-07-30) eşik
öncesine düştüğü için de bulgu düzelmeden gizlenirdi. Kullanıcıya yeniden
soruldu, 2. seçenek (linter'ı uygulamanın tanımıyla hizala) önerildi.

### [09:20] Kullanıcı

> 2 yap

### [09:26] Agent

Uygulamadan önce `audit.sh` §11'in lint çıktısını nasıl okuduğuna bakıldı:
yalnız özet satırı ve `  ! ` önekli bulgu satırları — biçim değişikliği
güvenli. Ama çıkış 2'de yalnız **stderr** gösteriliyor; T-025'te eklenen
"KOŞMADI" satırı stdout'a gidiyordu. Tüm artifact'ları eşik öncesi olan bir
hub'da `audit.sh` "lint koşamadı: bilinmeyen sebep" yazacaktı — T-025
düzeltmesinin getirdiği bir gerileme, bu adımda birlikte düzeltiliyor.
