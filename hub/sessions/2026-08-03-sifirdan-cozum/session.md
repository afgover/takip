---
id: S-2026-08-03-sifirdan-cozum
date: 2026-08-03
status: open
reconstructed: false
topics: [isaretleme, yorum, coklu-repo, render, test]
artifacts: []
tasks_touched: []
---

# Oturum: Üç sorunun sıfırdan çözümü

## Özet
Kullanıcı aynı üç sorunu üçüncü kez bildirdi ve "sorunları 0'dan ele al, başka
bir yaklaşımla, gerekirse algoritmayı değiştir" dedi. Üçü de çözüldü; ikisinde
algoritma değişti.

**Çapraz repo görev detayı (B-085).** Bekleyenler tüm repoları birleştiriyordu
ama detay okuma yolu hâlâ aktif repoya bakıyordu — financer görevi listede
görünüp dokununca "bulunamadı" diyordu. `taskRepoForSlugProvider` eklendi:
kayıt kendi bağlantısından okunuyor, `repoSlug` yoksa aktif repoya düşülüyor.
"Yaptım" bildirimi, işaret silme ve seçimden kayıt da aynı yoldan geçiyor
(L-031).

**Satır kırılması (B-086) — algoritma değişti.** Önceki iki çözüm (kelime
kelime yayma, sonra işaretsiz kelimeleri de kutulama) sorunu kullanıcı
tarafında hiç değiştirmemişti; ikincisi yalnız düz nesirde uygulanabildiği
için `**kalın**` ve `` `kod` `` dolu gerçek hub metinlerinde neredeyse hiç
devreye girmiyordu. Bu kez paketin **karar noktası** okundu:
`_mergeInlineChildren`, satır içi çocuğu `_getInlineSpanFromText` ile sınıyor
ve çocuk `Text`/`RichText` ise span'larını çıkarıp komşularıyla **tek bir
`RichText`e kaynatıyor**; yalnızca başka tür widget'lar `Wrap` içinde atomik
kalıyor. Yani sorun "satır içi widget olması" değil, **hangi tür** widget
olduğuydu. İşaret artık `Text.rich` döndürüyor; renk, kırmızı çizgi ve
dokunma tanıyıcısı aynı metin akışının içinde. Ölçüm: 300px genişlikte
işaretli ve işaretsiz metin **birebir aynı yükseklikte** (120.0), paragrafın
tamamı tek `RichText`, `Wrap` yok (L-032).

Denenip elenen iki yol da kaydedildi: paragrafı blok çiziciyle baştan çizmek
paketin `_inlines` yığınını dengesiz bırakıp assert patlatıyor; stil
sözlüğüne özel etiket yazmak `fallback.merge(widget.styleSheet)` adımında
düşüyor.

**Yorum (B-087).** Üç ayrı parça testi vardı ve üçü de geçiyordu; menü testi
gerçek seçim bile yapmıyor, yalnız etiket sabitlerini doğruluyordu. Uçtan uca
test yazılınca hata ilk koşuda çıktı: yorum kutusu `TaskMark.highlight`
döndürüyordu, yani yorum sarı işaretten ayırt edilemiyordu — kullanıcının
"çalışmıyor" dediği tam olarak buydu (L-033).

Ayrıca `AnnotatedDocument._create`'teki "yakalanan değer yoksa `ref`'ten oku"
yedek yolu kaldırıldı: `repoSlug` meşru olarak null olabildiği için o yedek,
ölmüş bir `ref`e uzanabiliyordu — L-029'un aynı tuzağı sessiz bir kalıntısı.

`flutter analyze` temiz, **316 test** (13 yeni; 3'ü eski algoritmanın yerine).

## Kayıt

### Kullanıcı
> financer reposundaki bekleyenler mesajlar gorunuyo tiklayinca bulunamadi
> uyarisi cikiyor, yorum ozelligi calismamis ve highligtta hala alt satira
> kirma devam ediyor, sorunlari 0dan ele al baska bir yaklasimla, gerekirse
> algoritmayi degistir ve oyle coz

### Agent
Üç sorunun ortak paydası, önceki turlarda **tahminle** ilerlenmiş olmasıydı.
Bu turda üçü de ölçümle ele alındı.

Satır kırılmasında ilk iş, başarısız denemenin neden başarısız olduğunu
görmekti: blok çizici assert patlatıyordu. Kaynağa dönülüp `_inlines`
yığınının nerede boşaldığı okundu, oradan `_mergeInlineChildren`'a ve asıl
karar satırı olan `_getInlineSpanFromText`'e gidildi. Çözüm o satırı okuduktan
sonra tek denemede oturdu — üç turdur eksik olan şey fikir değil, kaynağın
doğru yerini okumaktı.

Yorumda ise parça testlerinin hepsi yeşil olduğu için yeni bir parça testi
yazmanın anlamı yoktu. Zinciri baştan sona süren test yazıldı: gerçek metin
seçimi (uzun bas + sürükle), gerçek menü dokunuşu, sahte GitHub'a giden PUT
gövdesinin doğrulanması. Hata ilk koşuda düştü.

Çapraz repo düzeltmesinin testi, düzeltme geçici olarak geri alınarak
doğrulandı: test hatayı birebir yakalıyor (`/repos/afgover/takip/...` bekleniyordu,
`financer_takip` gitmesi gerekiyordu).

## Sonraki adım
Cihaza kurulup kullanıcının üç sorunu da doğrulaması bekleniyor.
