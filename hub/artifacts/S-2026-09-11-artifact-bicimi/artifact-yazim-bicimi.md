---
id: A-2026-09-11-001
session: S-2026-09-11-artifact-bicimi
type: analysis
title: "Artifact yazım biçimi: render sınırları ve kurallar"
created: 2026-09-11T19:40:00Z
---

# Artifact yazım biçimi: render sınırları ve kurallar

## Özet

Kullanıcı iki bozuk rapor ekran görüntüsü getirdi: sıkışmış tablo ve `â` +
boş kutu olarak çıkan işaretler. Sebep ölçüldü — biri uygulamanın render
ayarı, diğeri dosyanın kendi kodlaması. Biçim kuralı sözleşmeye yazıldı
(1.29, SYSTEM.md §3), app kusuru düzeltildi ve kural `tool/artifact-lint.sh`
ile makinece koşuyor. [TAMAM]

## Neye bakıldı

Ekran görüntülerindeki iki belge başka bir projenin hub'ından geliyor ve
CoPilot tarafından üretilmiş. İkisi de aynı yerde okunuyor: bu uygulamanın
belge ekranı, yani `flutter_markdown` 0.7.7. Soru "daha güzel nasıl yazılır"
değil, **"bu render neyi çizemiyor"**; kural ancak ölçülen sınırın üstüne
kurulursa tutar.

## Ölçülen render sınırları

Hepsi paketin kaynağından okundu, denenerek değil tahmin edilerek değil.

| Sınır | Ekrandaki sonucu |
|---|---|
| HTML işleyen kod yok | etiket düz metin görünür |
| `h4`-`h6` gövde stiline düşer | başlık, başlık gibi durmaz |
| Kod bloğu sarmaz | uzun satırın sonu gizli kalır |

Ayrıntı ve kanıt yolları:

- HTML: `flutter_markdown-0.7.7+1/lib/src/builder.dart` içinde `html`
  geçen tek satır yok; `markdown` paketi ham HTML'i metin düğümü olarak
  üretiyor. Yani `<table>` yazan bir rapor, ekranda etiketleriyle görünür.
- Başlıklar: `style_sheet.dart:118` — `h4`, `h5`, `h6` üçü de
  `theme.textTheme.bodyLarge`. Dördüncü seviye başlık gövdeden ayırt
  edilemez.
- Kod bloğu: `builder.dart:409` — `pre` yatay kaydırmaya sarılıyor,
  sarmıyor. Sığmayan satır kaydırılmadan okunamaz.
- Tablo: `builder.dart:515` — tablo **yalnız** `tableColumnWidth`
  `IntrinsicColumnWidth` ya da `FixedColumnWidth` ise yatay kaydırmaya
  sarılıyor.

## İki kusurun ayrı ayrı sebebi

Ekran görüntüleri iki farklı sorunu birlikte gösteriyordu; çözümleri de ayrı.

**Sıkışmış tablo — app kusuru.** `hub_markdown.dart` `tableColumnWidth`
ayarını hiç yazmıyordu, yani varsayılan `FlexColumnWidth` kalıyordu: tablo
ekran genişliğine zorla sığdırılır ve kaydırma sarmalayıcısı hiç oluşmaz.
Yedi sütunlu denetim tablosunda her hücre üç-dört karaktere indi ve metin
karakter karakter sardı. Düzeltildi: `IntrinsicColumnWidth`. Testi de var —
dar ekranda tablo genişliğinin ekranı aştığı ölçülüyor.

**`â` + kutu — dosyanın kodlaması.** Bu bir font ya da emoji sorunu değil:
`·` karakterinin `Â·` olarak çıkması, UTF-8 baytlarının Latin-1 sanılmasının
imzasıdır. Uygulamanın okuma yolu temiz (`contents_api.dart:233` `utf8`
çözüyor), dolayısıyla bozulma dosyanın kendisinde — onu üreten araç bozuk
yazmış. [DOGRULANMALI] Kesin kaynağı bilmek için o reponun ham dosyası
gerekiyor; bu oturumda elde yok.

Önemli olan şu: hangi tarafta olursa olsun, **anlamı emojiye yükleyen bir
belge bozulduğunda okunamaz hâle gelir.** Efsane satırı `[BLOKER] / [EKSIK] /
[TAMAM]` yazsaydı, kodlama bozulsa bile belge anlaşılırdı. Bu yüzden kural
"emoji kullanma" değil, **"anlamı işaretin biçimine emanet etme"**.

## Karara bağlanan kurallar

Sözleşme 1.29, `SYSTEM.md` §3 "Yazım biçimi" altında dokuz madde:

- Biçim markdown; HTML yazılmaz. Okunaklılık etiketten değil düzenden gelir.
- İskelet sabit: frontmatter, `#` başlık, `## Özet` (en çok beş satır),
  gövde, `## Sonuç`.
- Başlık en çok üç seviye.
- Tablo en çok üç sütun, hücre tek satır; genişi listeye çevrilir.
- Hücreye dosya yolu ya da kod konmaz; yol alttaki maddeye yazılır.
- Durum işaretleri ASCII sözlükten: `[BLOKER]`, `[EKSIK]`, `[TAMAM]`,
  `[DOGRULANMALI]`, `[RISK]`, `[KARAR]`.
- Satır 80, kod bloğu satırı 72 karakteri geçmez.
- Her artifact `session.md`'nin `artifacts:` listesine bağlanır.
- Bir ekranı aşan her üretilmiş metin önce dosya olur; sohbette yalnız özeti
  ve bağlantısı durur.

## Neden kurala bir de script eşlik ediyor

Bu hub'ın ölçülmüş dersi: hatırlanması gereken kurala uyulmuyor. Açılış
kontrolleri, hub denetimi ve bağımlılık taraması aynı sebeple script.
`tool/artifact-lint.sh` aynı listeyi mekanik koşar: frontmatter, `## Özet`
uzunluğu, başlık seviyesi, tablo sütunu, hücre uzunluğu, emoji, bozuk kodlama
izi, satır genişliği, HTML etiketi ve dosyanın yeri.

Yürürlük tarihi eşiği var (`--since`, varsayılan 2026-09-11): kuraldan önce
yazılmış artifact'lar denetlenmez. Gerekçe, geriye dönük düzeltmenin bu hub'da
zaten reddedilmiş olması — eski kayıt yazıldığı hâliyle kalır.

## Sonuç

İki bozuk gösterimin ikisi de kapandı: tablo sıkışması kodda düzeltildi,
işaret bozulması kuralla imkânsızlaştı. Kural sözleşmede olduğu için diğer
hub'lar bir sonraki oturumlarında kendiliğinden alacak; linter `takip`
reposunda durduğu için bekçi dağıtımıyla (B-141) aynı yoldan yayılabilir.
