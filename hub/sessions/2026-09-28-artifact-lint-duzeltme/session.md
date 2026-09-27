---
id: S-2026-09-28-artifact-lint-duzeltme
date: 2026-09-28
status: open
reconstructed: false
author: afgover
topics: [artifact-lint, sahte-negatif, tool, T-025]
artifacts: []
tasks_touched: [T-025]
---

# Oturum: `artifact-lint.sh` sahte-negatif düzeltmesi (T-025)

## Özet

*(oturum açık — kapanışta yazılacak)*

## Kayıt

### [01:20] Kullanıcı

> T-025'e bakalım, düzeltmeyi uygula

### [01:22] Agent

`T-025` `active/`e taşındı. Görev, `financer_takip`ten iletilmiş:
`tool/artifact-lint.sh`'ın eşik-atlama mantığı (`created[:10] < since`)
tırnaklı ya da eksik `created` alanında string karşılaştırmasının kendisi
yüzünden sessizce "eşik öncesi" sanıyor ve dosyayı hiç denetlemeden
"temiz" diyor; ayrıca `checked == 0` durumunda da "temiz" (çıkış 0) yazıyor,
oysa script'in kendi başlığı bunun "KOŞMADI" (çıkış 2) olması gerektiğini
söylüyor.

### [01:35] Agent

Üç parçalı düzeltme uygulandı ([tool/artifact-lint.sh](../../../tool/artifact-lint.sh)):
1. `parse_date()` tırnağı soyar; eşik ataması yalnız `YYYY-MM-DD` ile
   eşleşen, ayrıştırılabilen bir tarihte yapılıyor. Ayrıştırılamıyorsa
   (eksik ya da bozuk) dosya atlanmıyor, denetleniyor ve zorunlu-alan
   kontrolü "frontmatter eksik/bozuk: created" bulgusunu veriyor.
2. `checked == 0` artık "KOŞMADI (... atlandı)" + çıkış 2; atlanan dosya
   sayısı (`skipped`) her üç çıktı satırında da yazılıyor.
3. `--selftest` bayrağı eklendi: T-025'in ölçüm tablosundaki dört satır
   (tırnaksız sağlam / tırnaklı geçerli / eksik / gerçekten eski+tırnaklı)
   birebir sınama olarak kodlandı.

### [01:40] Agent

Doğrulama: `bash tool/artifact-lint.sh --selftest` → 4/4 geçti.
`bash tool/artifact-lint.sh --all` → hub'ın tamamına karşı regresyon yok;
tek fark, fix'in daha önce sessizce atlanan
[hub/artifacts/README.md](../../artifacts/README.md)'yi (frontmatter'sız,
gerçek bir bulgu) artık göstermesi — 3 dosya denetlendi (eskiden 2), 48
atlandı, 7 bulgu (hepsi README'de). Bu yeni bir kırılma değil, fix'in tam
olarak düzeltmesi gereken sınıftan bir vaka.

## Notlar

- `hub/artifacts/README.md`'nin frontmatter'sız kalması ayrı bir soru:
  README bir "üretilen artifact" değil dizin belgesi; şemadan muaf mı
  tutulmalı yoksa minimal frontmatter mi eklenmeli — kullanıcıya soruldu,
  bu görevin (T-025) kapsamı dışında tutuldu.
- `PLAN.md`'ye [P-025](../../PLAN.md) iş bittikten sonra yazıldı (sözleşme
  1.26, `Türetilmiş: true`) — üç adımlık olduğu ancak bittiğinde netleşti.
