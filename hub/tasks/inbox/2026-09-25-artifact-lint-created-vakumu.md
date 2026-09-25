---
id: T-025
title: "artifact-lint.sh vakumu: created'ı eksik ya da tırnaklı dosyayı atlıyor, 0 dosyada 'temiz' diyor"
created_by: agent
created: "2026-09-25T11:12:18Z"
updated: "2026-09-25T11:12:18Z"
priority: normal
category: hata
tags: [artifact-lint, vakum, sahte-negatif, tool]
session: none
result: none
author: afgover
---

# artifact-lint.sh vakumu: created'ı eksik ya da tırnaklı dosya atlanıyor

## İstek

financer oturumundan geliyor (`financer#B-331`'in yan bulgusu; kullanıcı
iletilmesini onayladı). Araç `takip`te durduğu için düzeltme burada.

### Ne oldu

`financer_takip`te 5 artifact, sözleşme dışı Türkçe anahtarlarla
(`tarih` / `konu` / `durum`) yazılmıştı. `tool/artifact-lint.sh` beşine de
şunu dedi (çıkış 0):

    temiz (0 dosya denetlendi; 2026-09-11 öncesi hariç).

Frontmatter şemaya (`id/session/type/title/created`) çevrilince
(`afgover/financer_takip@e638e36`) aynı 5 dosya **1.667 bulgu** verdi.
İki sonuç da 2026-09-25'te yeniden üretildi (`e638e36^` ↔ `e638e36`).

### Neden (`tool/artifact-lint.sh`)

    99   created = fields.get("created", "")
    100  if since and created[:10] < since:
    101      continue   # kural yürürlüğe girmeden önce yazılmış

- `created` yoksa değer `""` olur; `"" < "2026-09-11"` doğru → dosya
  "kural öncesi" sayılıp sessizce atlanır.
- `created` **tırnaklı** yazılmışsa (YAML'da geçerli) değer `"` ile başlar;
  `"` (0x22) < `2` (0x32) → yine atlanır. Bu hub'daki görev dosyalarının
  22/25'i `created`'ı tırnaklı yazıyor; aynı alışkanlık artifact'a
  taşınırsa denetim hiç koşmaz.
- 109. satırdaki `frontmatter eksik: created` denetimi tam bu durumu
  yakalamak için var, ama 100. satırın arkasında kalıyor: varsayılan eşikle
  hiç çalışmıyor (yalnız `--since ''` ile ulaşılıyor).
- 186. satır `checked == 0` iken de "temiz" yazıp 0 ile çıkıyor; oysa
  betiğin başlığı "2 = denetim KOŞAMADI — sonucu temiz diye yazma" diyor.

### Ölçüm (2026-09-25, tek dosya modu)

| frontmatter | sonuç | çıkış |
|---|---|---|
| `created: 2026-09-24T…` (sağlama) | 1 bulgu, 1 dosya | 1 |
| `created: "2026-09-24T…"` | temiz, 0 dosya | 0 |
| `created` yok | temiz, 0 dosya | 0 |
| `created` yok + `--since ''` | 2 bulgu (created dahil) | 1 |

`takip`'in kendi hub'ında bugün etkin değil: `--all` 2 dosya denetliyor,
48'i gerçekten eşik öncesi, 1'i frontmatter'sız `README.md`; eksik ya da
tırnaklı `created` 0. Etki, artifact'ı başka anahtarlarla ya da tırnaklı
tarihle yazan hub'larda.

### Önerilen düzeltme

1. Eşik atlaması yalnız **ayrıştırılabilen** bir tarihte yapılsın: tırnak
   soyulsun; ilk 10 karakter `YYYY-MM-DD` değilse dosya atlanmasın,
   denetlensin ve `frontmatter eksik/bozuk: created` bulgusu versin.
   (Alternatif: `created` yoksa git'teki ilk commit tarihi eşik için
   kullanılsın; bulgu yine yazılsın.)
2. `checked == 0` ise "temiz" yazılmasın: "KOŞMADI (0 dosya denetlendi,
   N atlandı)" + çıkış 2. Atlanan dosya sayısı her sonuçta yazılsın.
3. Kapının kendisi ölçülsün: yukarıdaki dört satır sınama olarak eklensin
   (tırnaklı ve eksik `created` kırmızıya düşmeli).

İlgili: B-142 (aracın diğer hub'lara ulaşması). `--all`, çağıranın değil
betiğin kendi deposuna `cd` ediyor (satır 37; `acilis.sh` satır 21 ile
aynı); başka bir hub'dan koşulunca `takip`'in artifact'larını denetler.

## Notlar

- 2026-09-25: `financer#S-2026-09-23-nobetci-ve-ekran-sadelestirme`
  oturumundan iletildi; kanıt yeniden üretildi, araçta değişiklik yapılmadı.
