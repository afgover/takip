---
id: S-2026-09-11-artifact-bicimi
date: 2026-09-11
status: closed
reconstructed: false
author: afgover
topics: [artifact, bicim, sozlesme, render]
artifacts:
  - artifacts/S-2026-09-11-artifact-bicimi/artifact-yazim-bicimi.md
tasks_touched: []
---

# Oturum: artifact yazım biçimi sözleşmeye giriyor

## Özet

Kullanıcının getirdiği iki bozuk rapor ekran görüntüsünden iki ayrı kusur
çıktı ve ikisi de kapandı.

**1 — Tablo sıkışması app kusuruydu:** `hub_markdown.dart` `tableColumnWidth`
yazmadığı için `flutter_markdown` varsayılanı (`FlexColumnWidth`) kalıyor ve
paketin yatay kaydırma sarmalayıcısı hiç oluşmuyordu. `IntrinsicColumnWidth`
ile düzeltildi; test dar ekranda tablo genişliğinin ekranı aştığını ölçüyor
([L-055](../../knowledge/lessons.md#L-055)).

**2 — İşaret bozulması kodlama hatasıydı,** font değil: `·` → `Â·` deseni
UTF-8'in Latin-1 sanılmasının imzası. Asıl ders zincirin nerede koptuğu değil,
anlamın tamamının emojiye yüklenmiş olması ([L-054](../../knowledge/lessons.md#L-054)).

**3 — Sözleşme 1.29:** artifact yazım biçimi §3'e yazıldı (tr+en), protokol
maddesi 5 genişletildi, `tool/artifact-lint.sh` yazıldı ve `tool/audit.sh`
§11'den her açılışta koşuyor ([A-2026-09-11-001](../../artifacts/S-2026-09-11-artifact-bicimi/artifact-yazim-bicimi.md),
[P-022](../../PLAN.md#P-022)).

**4 — APK:** kullanıcı uzakta olduğu için derlenip Drive'a kondu; veri
korunumu iddia değil ölçüm — imza SHA-1, paket adı ve versionCode kurulu
sürümle birebir aynı ([P-023](../../PLAN.md#P-023)).

## Kayıt

### [22:20] Kullanıcı

> takip reposu için oturum aç. Başlangıç olarak son durumu özetle: git durumu
> (branch, bekleyen değişiklikler, son commitler) ve yarım kalan iş var mı.

### [22:25] Agent

Açılış `tool/acilis.sh` ile koştu; sekiz kontrolün hepsi geçti, denetim dört
tarihsel bulgu verdi. Durum özeti verildi: ağaç temiz, `origin/main` ile
senkron, son iş 2026-08-30. Yarım kalan iki iş: store görselleri (token
kapsamına `takip-demo` eklenmeli) ve T-010 imza anahtarı (`waiting/`).

### [22:40] Kullanıcı

İki ekran görüntüsü: başka bir projenin hub'ındaki iki rapor — biri sıkışmış
tablo, diğeri kutuya dönmüş emoji işaretler. Artifact'lar için bir biçim ve
kural belirlenmesini, "HTML tadında okunaklı" dosyalar üretilmesini ve
agent'ın hazırladığı dosyaları mutlaka bu klasöre koymasını istedi.

### [22:55] Agent

Önce render sınırları ölçüldü (`flutter_markdown` 0.7.7 kaynağı): builder'da
HTML işleyen kod yok, `h4`-`h6` gövde stiline düşüyor, kod bloğu sarmıyor,
tablo yalnız `Intrinsic`/`Fixed` sütun genişliğinde yatay kaydırmaya sarılıyor.
Bozuk işaretlerin font değil **kodlama** sorunu olduğu saptandı (`·` → `Â·`
deseni). Üç karar kullanıcıya soruldu.

### [23:00] Kullanıcı

Kararlar: (1) kural sözleşmeye, tüm hub'lara; (2) app kusuru bu oturumda
düzeltilsin; (3) işaretler ASCII sözlükten.

### [23:30] Agent

Uygulandı: app düzeltmesi + test, sözleşme 1.29 §3 (tr+en), protokol maddesi 5
(tr+en), `tool/artifact-lint.sh`, `audit.sh` §11, kayıtlar.

### [23:40] Kullanıcı

> uzaktayım derleyip drive'a yükler misin, telefona kurunca mevcut datanın
> silinmediğine emin olalım

### [23:55] Agent

Release derlendi ve Drive'a kondu ([P-023](../../PLAN.md#P-023)). Veri
korunumu iddia değil ölçüm: yeni APK ile Drive'daki 2026-08-28 APK'sı yan
yana karşılaştırıldı — imza SHA-1 `f4994730...`, paket `us.gover.takip` ve
versionCode `1` üçü de aynı. Android'de veriyi silen tek şey imza değişimi
olduğu için bağlantılar ve token'lar yerinde kalıyor. Eski APK geri dönüş
için klasörde bırakıldı.

### [2026-09-12 09:50] Kullanıcı

> sözleşmenin session'lara olan yükünü/getirisini ölçen bir simülasyon
> çalıştırmıştık, geçmiş session'ları da inceleyerek (tüm repolar) bir analiz
> çalıştırmanı istiyorum

### [2026-09-12 10:10] Agent

Önceki çalışma simülasyondu ([A-2026-08-30-001](../../artifacts/S-2026-08-30-uc-gorev/token-maliyeti.md));
bu çalışma **gerçek kayıtlara** bakıyor. Deterministik taban ana ajan
tarafından çıkarıldı: 10 hub, 365 oturum, 2289 commit, 207 artifact, 499
ders. Ardından çok ajanlı ölçüm koştu (10 hub + 4 kesit).

## Notlar

- Açılış `tool/acilis.sh` ile tek çağrıda koştu: hub dili tr, saat ağla aynı
  gün, sözleşme ana kopyayla aynı (1.28), son tarama 2026-08-29 (13 gün),
  açık oturum yok, inbox boş, waiting'te T-010.
- §13/G-001 kontrol edildi: T-010 zaten `options` taşıyor, madde idempotent →
  yapılacak bir şey yok.
- Denetim 4 bulgu verdi (üçü tarihsel kayıt tutarsızlığı, biri app tarafı
  push gecikmesi); kayda geçirilip geçirilmeyeceği kullanıcıya soruldu.
- Oturum slug'ı `durum-ozeti` iken konusu netleşince `artifact-bicimi` olarak
  değiştirildi (aynı gün, tek commit sonrası).
- Linter iki kendi kusurunu test koşumunda yakaladı ve düzeltildi: (a) satır
  içi kod denetleniyordu, yani kuralı **anlatan** belge kuralı çiğnemiş
  sayılıyordu; (b) satırdaki ilk işaretten sonra durduğu için geçerli bir
  işaretin arkasındaki uydurma işareti görmüyordu.
- B-141'in pilot değerlendirmesi ~2026-09-05'te yapılacaktı; bugün 09-11 ve
  henüz yapılmadı. Bu oturumun konusu değil, kullanıcıya hatırlatıldı.
- APK: `takip-2026-09-11-7d211e7.apk`, SHA-256
  `d4fa0e7734775c2f14009184f78d026c47d1b54d71486fbf1538e835e764c2b0`,
  Drive'ım/Takip APK/. Yüklemenin **tamamlandığı** makineden doğrulanamadı
  (DriveFS durum kaydı dışarı vermiyor); dosya yerel Drive klasöründe ve
  istemci çalışıyor.
- `versionCode` her derlemede 1 kalıyor: telefondan "hangi derleme kurulu"
  sorusu cevaplanamıyor, cevap yalnız OKU.txt'de. Kullanıcıya soruldu.
