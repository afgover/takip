---
id: S-2026-08-06-i18n-ekranlar
date: 2026-08-06
status: open
reconstructed: false
author: afgover
topics: [i18n, dil]
artifacts: []
tasks_touched: []
---

# Oturum: Ekran metinleri ve yöntem belgeleri İngilizce'ye

## Özet
(oturum kapanışında yazılacak)

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
