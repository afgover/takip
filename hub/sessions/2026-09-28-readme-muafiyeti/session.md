---
id: S-2026-09-28-readme-muafiyeti
date: 2026-09-28
status: closed
reconstructed: false
author: afgover
topics: [artifact-lint, readme, tool]
artifacts: []
tasks_touched: [T-025]
---

# Oturum: `artifact-lint.sh`'ta README muafiyeti

## Özet

T-025 düzeltmesinin ortaya çıkardığı `hub/artifacts/README.md` bulgusu
çözüldü. README'ye frontmatter eklemek yerine linter uygulamanın artifact
tanımıyla hizalandı: `README.md` denetlenmiyor, "N README" diye sayılıyor.
Aynı turda T-025'in getirdiği bir gerileme düzeltildi: KOŞMADI mesajı
stdout'tan stderr'e alındı, çünkü `audit.sh` §11 sebebi oradan okuyor.
Selftest 7/7, `--all` ve `audit.sh` §11 temiz. P-025.5/.6 işaretlendi.

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

### [09:35] Agent

[tool/artifact-lint.sh](../../../tool/artifact-lint.sh) değişti:
- `README.md` adlı dosya denetlenmiyor, `readme` sayacına ekleniyor; özet
  satırı "atlanan: N eşik öncesi, M README" diyor — muafiyet sessiz değil.
- `checked == 0` mesajı stderr'e alındı (script'in öbür çıkış-2
  mesajlarıyla aynı yere).
- Selftest 4 → 7 satır: README tek başına (KOŞMADI + "1 README"), README +
  gerçek artifact (artifact denetlenmeye devam ediyor), KOŞMADI'nın stderr'de
  olduğu (stdout boş).

Doğrulama: selftest 7/7; `--all` → temiz (2 denetlendi; 48 eşik öncesi,
1 README); `audit.sh` §11 → ✓ aynı satır. `PLAN.md` P-025.5/P-025.6
işaretlendi.

**Gerilemenin kök nedeni:** T-025'te çıkış davranışı değiştirilirken
çıktıyı okuyan taraf (`audit.sh` §11) aranmadı. Bu turda çağıranlar önce
`grep`'le bulunduğu için yakalandı. Önlem mekanik: selftest'in son satırı
stderr sözleşmesini sınıyor — bir sonraki değişiklik aynı yeri bozarsa
selftest kırmızıya düşer.
