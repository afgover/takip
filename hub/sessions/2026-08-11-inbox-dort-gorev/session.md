---
id: S-2026-08-11-inbox-dort-gorev
date: 2026-08-11
status: closed
reconstructed: false
author: afgover
topics: [offline, bekleyenler, waiting, sozlesme]
artifacts: []
tasks_touched: [T-012, T-013, T-014, T-015]
---

# Oturum: Inbox'taki dört görev

## Özet
Telefondan açılmış dört görev; hepsi bitti. Sözleşme 1.21 → **1.22**.

**T-012 (offline, `high`).** Şikâyet "liste görünüyor, tıklayınca bağlantı yok
diyor"du. Teşhis ölçüldü: senkron zaten bütün `.md` dosyalarını indiriyor ve
liste yerel kopyadan çiziliyordu (B-057) — ama `TaskRepo.read` ve `_list`
doğrudan API'ye gidiyordu. **Eksik olan indirme değil, okuma yoluydu.** Bu
ayrım önemli, çünkü "tam indirsin" isteği doğru okunmasaydı senkrona
dokunulacaktı; oysa senkron zaten doğruydu.
Bildirilmemiş aynı kusur da düzeltildi: `listDone` de ağa gidiyordu. Bildirilen
tek örneği düzeltip aynı sınıftaki diğerini bırakmak, hatayı "şikâyet gelene
kadar" ertelemek olurdu.

**T-013 (filtre ve sıralama).** Filtre zaten vardı; eksik olan sıralamaydı.
Tasarım kararı: varsayılan "bekleyenler önce" menüde **bir seçenek** olarak
duruyor, kullanıcının açık seçiminin üstüne binmiyor. K-022'nin gerekçesi
geçerli ama gizli bir kural sıralamayı bozuk gösterirdi.
Test bir hata yakaladı: değeri bilinmeyen görevlerde yön çevirmesi iki kez
uygulanıyordu, "artan"da listenin tepesi bilgisizlerle doluyordu.

**T-014 (seçeneksiz beklemede metin cevabı).** Metin `## Notlar`a gidiyor,
`## İstek`e değil — istek olgu, not kullanıcının söylediği şey.

**T-015 (geçici sözleşme maddesi).** §13 açıldı, ilk madde G-001. Ayrı bölüm
olması istenen "geçicilik"in yapısal karşılığı: gövdede dursalardı yöntemi ilk
kez okuyan biri için kalıcı kural gibi görünürlerdi. Bölüm her maddeden kalkma
koşulu istiyor — koşulu olmayan geçici bir madde, kalıcı bir madde.

**Yan bulgu:** çeviri kapsam testinin regex'i `'Temizle'`, `'Bekleyenler'`,
`'Yenile'` gibi Türkçe'ye özgü harf taşımayan metinleri **görmüyordu**. Testin
kendisi "kaba ama yeterli" diye yazılmıştı; yeterli değilmiş. Üçü taşındı,
sınır L-044'te kayıtlı.

482 test, analyze temiz.

## Kayıt

### Kullanıcı
> hubdaki gorevleri yap

### Agent
Inbox'ta telefondan açılmış dört görev vardı (2026-08-10). Hepsi `active/`e
alındı: T-012 (offline, `high`), T-013 (filtre/sıralama), T-014 (seçeneksiz
beklemede metin cevabı), T-015 (geçici sözleşme maddesi).

**T-012'nin teşhisi ölçüldü, tahmin edilmedi.** Şikâyet "liste görünüyor,
tıklayınca bağlantı yok diyor"du ve sebebi tam olarak buydu: `pendingFromStore`
listeyi **yerel kopyadan** çiziyor (B-057), ama `TaskRepo.read` ve `listDone`
doğrudan API'ye gidiyor. Yani senkron dosyaları zaten indirmiş — eksik olan
indirme değil, **okuma yolu**.

### Agent — T-012 ✅
`TaskRepo` isteğe bağlı `OfflineStore` alıyor; kopya varsa ağ hiç
kullanılmıyor, yoksa eski davranış korunuyor. `offline_read_test` ağı **kasten
kırık** kuruyor: geçen bir test tek şey kanıtlıyor, o yolda ağa hiç çıkılmadı.
"Yerel kopyayı tercih ediyor" ölçülmeden söylenirse, ağın sessizce devreye
girdiği bir sürümde de doğru görünür.

### Agent — T-013 ✅
`TaskOrder` + başlıktaki sıralama menüsü. Aynı ölçüte ikinci dokunuş yönü
çeviriyor — ayrı bir yön düğmesi koymaktansa listelerde alışılmış davranış.
Test, yön çevirmesinin `null` değerlere iki kez uygulandığını yakaladı.

### Agent — T-014 ✅
Açıklama alanı 1.12'de yalnız seçenekli sorulara konmuştu; "yaptım" yeterli
sanılmıştı. Değilmiş: kullanıcı işi yaparken bir şey öğreniyor ve söyleyecek
yeri olmayınca ya sohbete dönüyor ya hiç söylemiyor. İkincisi sessiz kayıp —
`waiting/` klasörünün var olma sebebinin aynısı (K-022).

### Agent — T-015 ✅, sözleşme 1.22
§13 ve G-001. Maddeye bir sınır kondu: emin olunamayan görev olduğu gibi
bırakılır. Uydurulmuş bir seçenek listesi kullanıcıyı agent'ın hiç düşünmediği
bir çerçeveye sıkıştırır ve **yanlış cevabı doğru görünen bir biçimde**
kaydeder. T-014'ten sonra zorunluluk da kalmadı: seçeneksiz beklemede artık
serbest metin yazılabiliyor, yani madde cevabı *makinece okunur* kılmak için
var, cevapsızlığı önlemek için değil.
