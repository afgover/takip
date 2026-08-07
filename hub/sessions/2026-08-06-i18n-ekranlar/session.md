---
id: S-2026-08-06-i18n-ekranlar
date: 2026-08-06
status: closed
reconstructed: false
author: afgover
topics: [i18n, dil, giris-belgeleri]
artifacts: []
tasks_touched: []
backlog_touched: [B-115, B-117, B-118]
---

# Oturum: Ekran metinleri ve yöntem belgeleri İngilizce'ye

## Özet
Oturum "23 ekranın metnini çevir" diye başladı, **dilin ne olduğu** sorusuna
dönüştü ve orada bir sözleşme kuralımı geri almamla bitti.

**Kalıcı olan karar (K-037, sözleşme 1.19):** dil bir kullanıcı tercihi değil,
**hub'ın özelliği**. Kurulumda seçilir, `SYSTEM.md`'de yazılıdır; sözleşme,
arayüz ve o andan sonra üretilen her kayıt birlikte onu izler. Sonradan
değiştirmek geriye dönük çalışmaz — mevcut kayıtlar yazıldıkları dilde kalır.

Kendi 1.18 kuralım ("gövde başlıkları Türkçe sabit") bunun tersiydi ve
**dil seçeneğini eklemenin sebebini çürütüyordu**: İngilizce çalışan birine
Türkçe başlıklı kayıt yazdırıyordu. Gerekçem (aynı hub'da iki başlık şeması =
okunamayan kayıt) geçerliydi; tutarlılığı yanlış yerden almıştım — şemayı tek
dile sabitleyerek değil, **hub başına tek dil** ile sağlanmalıydı.

**Mekanizma vardı ama girişi yoktu (B-118).** Dil alanı okunuyordu, yazan yol
yoktu; üstelik nasıl seçileceğini anlatan belgenin kendisi Türkçe'ydi.
İngilizce konuşan biri ne seçebiliyor ne de okuyabiliyordu. Kırıldı: kurulum
talimatına §0 (agent önce dili sorar), protokole madde 0 (agent hub dilini okur
ve o dilde yazar; kullanıcının yazdığı dil farklıysa **sorar**), ve iki giriş
belgesinin İngilizcesi.

İngilizce belgeler sözleşmenin henüz yalnız Türkçe olduğunu **açıkça söylüyor**.
Eksiği yumuşatmak, İngilizce bir hub'ı tam sanmaya yol açardı — kalan iş B-116.

**Ölçüm, iddia değil.** Kapsam testi kalan ekranları sayıyor; `language_switch_test`
aynı ekranı iki dilde çizip karşılaştırıyor; `entry_docs_test` giriş çiftinin
sessizce kaybolmasını engelliyor. "Altyapı kuruldu" demek bu haftanın üç kez
tekrarlanan hatası olurdu (L-035, L-039, L-040).

**Yan çıktı:** ortak `testApp` yardımcısı (delege listesi uygulamayla aynı
kaynaktan) ve testlerin dilinin sabitlenmesi — testler artık koşuldukları
makinenin diline bağımlı değil.

**Kapanışta ölçülen kalan iş:** B-115'te 6 ekran (79 metin), B-116 bütünüyle
açık; B-097 (public) B-116'ya bağlı. 448 test, analyze temiz.

## Kayıt

### Kullanıcı
> 115 ve 116yi sirayla yap

### Agent
B-115 (23 ekranın metinleri) ve ardından B-116 (yöntem belgeleri). Kapsam testi
her adımda kalanı ölçüyor, yani ilerleme iddiaya değil listeye bağlı.

**İlerleme (bu oturumda):** 23 dosya → **10 dosya**, 219 metin → **165 metin**.
Taşınanlar: kabuk, tarayıcı, oturum/artifact listeleri, onboarding, bekleyenler,
tamamlananlar, yol haritası, bilgi tabanı, işaretler, aktivite, belge
görüntüleyici, durum şeridi, repo şeridi, kapsam uyarısı.

**Testte çıkan iki yapısal sorun ve çözümleri:**

1. **Delege eksikliği her testte tekrar ediyordu.** Ekranlar `L.of(context)`
   kullanmaya başladıkça delegesi olmayan her test "null check operator used on
   a null value" ile kırıldı — mesaj çeviriyle ilgisiz göründüğü için her
   seferinde yeniden teşhis gerekti. Ortak `testApp` yardımcısı yazıldı ve **14
   test dosyası** ona taşındı. Delege listesi `L.localizationsDelegates`'ten,
   yani uygulamanın kendisiyle **aynı kaynaktan** geliyor; ayrı tanımlansaydı
   test ortamı uygulamadan sessizce ayrışırdı.
2. **Testler İngilizce çiziliyordu.** Test ortamının platform dili `en_US` ve
   desteklenen diller arasında İngilizce de var; ekranlar İngilizce çizilince
   Türkçe metin arayan onlarca test kırıldı. `testApp` dili **Türkçe'ye
   sabitliyor** — bu aynı zamanda testleri koşuldukları makinenin diline
   bağımlı olmaktan çıkarıyor. İngilizce'yi sınayan test locale'i açıkça
   veriyor.

**Özelliğin kendisi ölçüldü** (`language_switch_test`): aynı ekran iki dilde
çizilip karşılaştırılıyor, ayrıca desteklenmeyen bir dilin (Almanca)
İngilizce'ye düştüğü doğrulanıyor. "Altyapı kuruldu, İngilizce eklendi" demek
bu haftanın üç kez tekrarlanan hatası olurdu (L-035, L-039, L-040): iddia
edilen ama ölçülmeyen davranış.

435 test, analyze temiz.

### Kullanıcı
> dil secimi ile ilgi bir ayrimi netlestirmek istiyoruym,
> ingilizce yada diger bir dili secince, sozlesme o dilde olmali(referans olarak
> bilgiler ordan gelecegi icin) uygulama dili ingilizce olmali, akabinde
> olusturulcak icerik de o dilde devam edecektir,
> dili degistirmek daha cok ilk kurulumda yapilcak bir is, daha sonra dil
> degistirilince eklenen kayitlar dokumanlar gibi seylerin dilinin degismesi cok
> anlamli degil,
> dil secenegi koymamizin sebebi repoyu farkli dilleri konusanlarinda
> kullanabilmesidir

### Agent — sözleşme 1.19, 1.18'i tersine çevirdi
Kullanıcının modeli benimkinden tutarlı çıktı ve **kendi kuralımı geri aldım**.

1.18'de "arayüz dili ≠ kayıt dili; gövde başlıkları Türkçe sabit" demiştim.
Gerekçe geçerliydi (aynı hub'da iki başlık şeması = okunamayan kayıt) ama çözümü
yanlış yerden almışım: tutarlılığı **şemayı tek dile sabitleyerek** değil,
**hub başına tek dil** ile sağlamak gerekiyordu. Benimki İngilizce çalışan birine
Türkçe başlıklı kayıt yazdırırdı — yani dil seçeneğini eklemenin sebebini baştan
çürütürdü. → K-037

**Uygulanan model:** dil hub'ın özelliği, `SYSTEM.md`'de `**Hub dili:**` olarak
yazılı; sözleşme, arayüz ve yeni kayıtlar birlikte onu izliyor. Sonradan
değiştirmek geriye dönük bir şey yapmıyor ve bu kabul edilmiş bir durum.

Çoklu repoda arayüz dili **aktif hub**'ı izliyor (kullanıcı seçti); yazma
hedefinin dili ise o reponun (`languageForRepoProvider` — L-019'un aynı
gerekçesi: kimlik gibi dil de yazılacak repodan seçilmeli).

**Ayrıştırıcı bütün dillerin başlıklarını tanıyor**, hub'ın ilan ettiğiyle
sınırlı değil: dil alanı eklenmeden önceki kayıtlar, elle düzenlemeler ve dili
değişmiş hub'lar var. Geniş kabulün maliyeti yok; dar kabulün maliyeti okunamayan
kayıt. Testte "hub İngilizce'ye geçti, Türkçe kayıtlar duruyor" senaryosu var.

**İki temizlik:** Ayarlar'daki dil seçici bir tercih olmaktan çıkıp **bilgi**ye
dönüştü — uygulama `SYSTEM.md`'ye yazamaz (R-001), dolayısıyla dili
değiştiremez. Cihaz ayarı (`localeCode`/`setLocale`) tamamen silindi: hiçbir
şeyi sürmeyen ama sürüyormuş gibi duran bir ayar, ayarın kendisinden kötü.

445 test, analyze temiz. → B-117, K-037

### Kullanıcı
> kisir donguyu duzelt

### Agent — B-118 ✅
Kısır döngü: dili seçmeyi anlatan belge Türkçe'ydi, yani onu okuyamayan kişi
tam olarak o yüzden İngilizce'yi seçemiyordu.

`README.en.md` + `setup-instruction.en.md` yazıldı, iki yön birbirine bağlandı.
Zincir tamam: README → kurulum talimatı → agent §0'da dili sorar →
`**Hub dili:** en` yazılır → arayüz ve yeni kayıtlar İngilizce.

İki **bağlayıcı** kopya sessizce ayrışır (L-022 bunu bu projede yaşattı), o
yüzden her İngilizce belge kendi içinde "kanonik olan Türkçe kopyadır"
diyor — daha iyi olduğu için değil, iki otoritesi olan sistem kayarken kimse
fark etmediği için. Frontmatter'da `translated_from` ve türediği sözleşme
sürümü var.

`entry_docs_test` dosyaların varlığını, çapraz linki ve türetilmiş olanın
kaynağını yazdığını ölçüyor. İçerik **denkliğini** ölçmüyor: o, elle tutulan
bir listeye dönerdi ve kendisi bayatlardı — ölçtüğünü sandığın şeyi ölçmeyen
bir test, testsizlikten kötü.

448 test, analyze temiz.

### Kullanıcı
> repoya kayitlari yap sessioni bitirelim

### Agent — kapanış
Kapanış tutarlılık kontrolünde **30 Temmuz'dan beri açık kalan bir oturum**
bulundu ve kapatıldı (özeti kendi kaydından türetildi, dosyada işaretli).
Dokuz gün boyunca hiçbir kontrol bunu görmedi: kapanış listesi "bu oturumu
kapat" diyordu, "açık oturum kaldı mı" demiyordu. → L-042, sözleşme 1.20 ve
`session_state_test` (aynı anda en fazla bir oturum açık olabilir, o da en
yenisi).
