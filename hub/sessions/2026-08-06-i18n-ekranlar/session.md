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
