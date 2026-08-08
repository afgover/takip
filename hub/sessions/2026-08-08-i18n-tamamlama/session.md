---
id: S-2026-08-08-i18n-tamamlama
date: 2026-08-08
status: closed
reconstructed: false
author: afgover
topics: [i18n, dil, sozlesme]
artifacts: []
backlog_touched: [B-115, B-116]
tasks_touched: []
---

# Oturum: B-115 ve B-116'nın tamamlanması

## Özet
B-115 ve B-116 kapandı; sözleşme 1.20 → **1.21**.

**B-115 (337 metin, 23 dosya).** Kalan 6 ekran taşındı. Asıl bulgu taşımanın
kendisi değil, taşırken çıkan **sınır**: metinlerin bir kısmı arayüz değil
**hub verisiydi** — güvenlik kaydının `Tür`/`Durum` alanları, `waiting/`
bildirimlerinin gövdesi. İkisi ayrı yerden gelmeli, çünkü ayrı sorulara cevap
veriyorlar: arayüz "okuyan hangi dili konuşuyor", kayıt "bu dosya hangi hub'a
yazılıyor". Arayüz **aktif** hub'ın dilini, kayıt **yazılacak reponun** dilini
izliyor (L-019'un aynı gerekçesi).
Bu ayrım bir kusuru ortaya çıkardı: `waitingDone`/`waitingAnswer` hub diline
**hiç bakmıyordu**. İngilizce bir hub'da arayüz İngilizce çizilip kayıtlar
Türkçe yazılacaktı ve hiçbir şey hata vermeyecekti.

**B-116 (sözleşme + protokolün İngilizcesi).** Sözleşme 1.21 dil varyantını
tanımladı: hub `**Hub dili:**` alanına göre `SYSTEM.md` ya da `SYSTEM.en.md`
çeker, ama hangisini çekerse çeksin kendi hub'ında **düz adla** saklar. Hub
dosyalarının dil eki taşımaması bilinçli — sözleşmedeki her yol her dilde aynı
kalıyor ve uygulamanın dosyayı bulmak için dili bilmesi gerekmiyor.
Türkçe kopya kanonik ve bu **belgelerin içinde** yazılı; dışarıda dursa
belgeyi tek başına okuyan iki eşit otorite görürdü.

**Çevrilmeyen şeyler bilerek çevrilmedi:** kayda yazılan kategori değerleri
(`gorev`, `duzeltme`…) ve güvenlik `Tür` değerleri veri, düzyazı değil.
Çevirmek aynı hub'da tek kategorinin iki yazımını biriktirirdi. Sınır
İngilizce belgelerde açıkça yazılı — söylenmemiş bir sınır, keşfedildiğinde
hata gibi görünür.

**Ölçüm tarafında iki yeni kontrol**, ikisi de bu oturumda gerçekten bir şey
yakaladı: `record_language_test` (kaydın dili) ve ölü ARB anahtarı kontrolü —
25 anahtar tanımlıydı ve hiç kullanılmıyordu, biri de yeni eklerken sessizce
üzerine yazılıp menü metnini değiştirdi (L-043).

460 test, analyze temiz. B-097 (public) artık açık.

## Kayıt

### Kullanıcı
> 115 ve 116 yi tamamla

### Agent
Kalan iş ölçüldü: B-115'te 6 ekran, B-116 bütünüyle açık.

### Agent — B-115 ✅
Kalan 6 ekran (90 metin) taşındı; kapsam listesi boşaldı.

Taşırken çıkan sınır: `security_screen`'in `'Tür'`/`'Durum'` metinleri arayüz
değil **hub verisi**. Onları `L`'ye taşımak yanlış olurdu — dosyada duran bir
alan adı, okuyanın diline göre değişemez. `HubLanguage`'a taşındılar ve
ayrıştırıcı iki dili de tanıyor: dili değişmiş bir hub eski kayıtlarını
okumaya devam etmeli.

Aynı yerden bir kusur çıktı: `waitingDone`/`waitingAnswer` hub diline hiç
bakmıyordu. İngilizce hub'da arayüz İngilizce, kayıtlar Türkçe olacaktı ve
hiçbir şey hata vermeyecekti — tam olarak bu projenin "sessiz kırılma"
tanımı. Beş taslak fabrikasının hepsi artık dil alıyor.

**Ölü anahtar kazası ve alınan ders:** ARB'ye eklerken `markYellow`'u ikinci
kez yazdım; menüdeki metin sessizce değişti ve bunu yalnız `git diff` gösterdi.
Arkasından 25 kullanılmayan anahtar çıktı — bir kısmı bu ekranlar için önden
hazırlanmıştı (görmediğim için paralel bir set ürettim), bir kısmı 1.18'in
iptal edilmiş modelini anlatıyordu. Yani ölü değil, **yanlış**. Kullanılmayan
anahtarı ölçen test eklendi. → L-043

450 test, analyze temiz.

### Agent — B-116 ✅, sözleşme 1.21
`SYSTEM.en.md` ve `AGENT_PROTOCOL.en.md`.

**Karar: hub dosyaları dil eki taşımaz.** Varyantlar yalnız ana kopyada yan
yana duruyor; hub hangisini çekerse çeksin `hub/SYSTEM.md` olarak saklıyor.
Alternatif (`hub/SYSTEM.en.md` diye saklamak) sözleşmedeki her yolu dile
bağımlı kılardı ve uygulamanın dosyayı bulmak için önce dili bilmesi
gerekirdi — ama dili o dosyadan okuyor. Döngü.

**Uygulama tarafında görünmez bir tuzak vardı:** `**Hub dili:**` alanının
kendisi hub dilinde yazılıyor, yani İngilizce bir hub `**Hub language:**`
yazacak. Ayrıştırıcı yalnız Türkçe yazımı tanısaydı, İngilizce bir hub "dil
alanı yok" görünüp sessizce `tr`'ye düşerdi — kurduğun dilin tam tersi.
`languageCodeIn` ve `contractVersionOf` iki yazımı da tanıyor ve test
**gerçek** `SYSTEM.en.md` dosyasına karşı koşuyor: uydurma bir metne karşı
koşan test, dosya değiştiğinde haber vermez.

**Neyi çevirmediğimi de yazdım.** Kategori değerleri (`gorev`, `duzeltme`) ve
güvenlik `Tür` değerleri veri; çevirmek tek kategorinin iki yazımını aynı
hub'da biriktirirdi. Bu sınır İngilizce belgelerin içinde yazılı — söylenmemiş
bir sınır, sonradan keşfedildiğinde eksiklik gibi görünür.

460 test, analyze temiz. → K-039
