---
id: A-2026-09-12-001
session: S-2026-09-12-sozlesme-analizi
type: analysis
title: "Sözleşmenin oturumlara yükü ve getirisi — 365 oturumun kaydından"
created: 2026-09-12T11:40:00Z
---

# Sözleşmenin oturumlara yükü ve getirisi

## Özet

On hub, 366 oturum, 2.289 commit mekanik olarak ölçüldü; 28 ajan koştu ve
yedi manşet iddia iki bağımsız çürütücüden geçti. Sonuç: defter tutma
commit'lerin yarısını aşıyor, kaydın üçte ikisi geri okunuyor, artifact'ların
yarısı bir daha hiç okunmuyor, ve 1.28'in yük azaltma tedbiri on hub'ın
dokuzuna hiç ulaşmadı. [DOGRULANMALI] işaretli satırlar ölçülemeyeni gösterir.

## Yöntem ve sınırları

Önceki çalışma ([A-2026-08-30-001](../S-2026-08-30-uc-gorev/token-maliyeti.md))
kontrollü bir A/B **simülasyonuydu**: aynı iş, hub'lı ve hub'sız. Bu çalışma
onun tersini yapıyor — simülasyon yok, yalnız **gerçekte olmuş 366 oturumun
bıraktığı iz**. Ölçülen her şey git grafiğinden ve dosya durumundan okundu;
hiçbir iddia bir kaydın kendi düzyazısına dayanmıyor, çünkü kaydı yazan taraf
denetlenen tarafın kendisidir.

Üç ölçüm katmanı koştu:

| Katman | Ne yaptı |
|---|---|
| Ana ajan | Deterministik sayım, 10 hub |
| 14 ölçüm ajanı | Hub başına kazı + 4 kesit |
| 14 çürütücü | 7 manşet iddia, ikişer mercek |

Ölçülemeyenler baştan yazılıyor, sonuçlar onlara göre okunmalı:

- **Token ve tur sayısı.** Hub'lar araç çağrısı tutmuyor. Önceki çalışmanın
  "+10.6k token, kaynak tur sayısı" teşhisi bu veriyle ne doğrulanabiliyor ne
  çürütülebiliyor. Elde yalnız bayt ve commit var. [DOGRULANMALI]
- **Hiç yazılmamış kayıt.** Denetim yalnız yazılanı görür. Yapılıp oturum
  açılmamış iş, alınıp kaydedilmemiş karar bu araçla ölçülemez — ve muhtemelen
  en büyük sapma sınıfı budur.
- **Kaydın doğruluğu.** Bir özetin oturumda olanı anlatıp anlatmadığı
  ölçülmedi; yalnız var olup olmadığı ölçüldü.

## 1. Yük: defter tutmanın payı

Dokuz hub kod taşımıyor (hub-only repo), bu yüzden "defter mi iş mi" sorusu
ancak hub ile kod reposu eşleştirilerek sorulabilir. Eşleşen pencerede
defter commit'inin kod commit'ine oranı:

| hub | defter / kod |
|---|---|
| goverco | 2,75 |
| vault | 2,33 |
| money | 1,50 |
| copilot | 1,46 |
| din | 1,22 |
| datasources | 1,11 |
| financer | 0,78 - 1,06 |
| power | 0,48 |

`takip` tek istisna: kod ve hub aynı repoda. Orada ölçü satır cinsinden
verilebiliyor — repoya yazılan tüm satırların **%39,5'i** hub'a gidiyor
(hub +24.681, kod +37.784 satır). Son 400 commit'in 275'i saf hub, 80'i saf
kod, 44'ü karışık.

Oturum başına hub commit'i hub'a göre **1,75 ile 12,6 arasında** değişiyor.
Aynı sözleşme, yedi kat fark. Fark sözleşmeden değil, onu uygulayan ajanın
alışkanlığından geliyor — ve bu, maliyetin sabit bir vergi değil, **değişken
bir davranış** olduğunu gösteriyor.

## 2. Yük: okuma yükü ve büyüme

Açılışta okunması emredilen çekirdek (sözleşme, protokol, backlog, plan,
güvenlik, evrim, dersler) hub başına bugün **16k - 118k token** karşılığı.
`takip`te bu set 6 haftada 60,4 KB'den 320,7 KB'ye çıktı; haftalık
görüntülerin **7/7'sinde arttı**, bir kez bile azalmadı.

Sözleşme metninin kendisi de hiç küçülmedi: SYSTEM + PROTOKOL + BACKLOG
toplamı 1.1'de 17,0 KB, 1.29'da 135,5 KB — 43 günde 8 kat. Yük azaltma
sürümü olan 1.28 bu toplamı **+3,7 KB büyüttü**, 1.29 +6 KB daha ekledi.

Ama "hiçbir sürüm yükü azaltmadı" cümlesi çürütüldü ve düzeltildi: 1.28
dosyayı küçültmedi, **okuma politikasını** değiştirdi. BACKLOG'un tamamını
okumayı kaldırıp seçici grep'e çevirmek, emredilen açılış setini hub başına
**2k - 70k token** azaltıyor (on hub toplamı ~282k). Azaltma gerçek; yalnız
dosyada değil, okuma kuralında yaşıyor.

## 3. 1.28 ne yaptı — ve ölçüm neden cevap veremiyor

1.28'in tur-eksenli tek tedbiri `tool/acilis.sh`. Makinede **tek bir kopyası
var**: `takip/tool/`. Sözleşmesi 1.28+ olan beş hub'ın dördünde
(copilot, vault, din, financer) dosya yok, ama dördünün de protokolü
`../tool/acilis.sh` diyor. Metin yayıldı, uygulama yayılmadı. [BLOKER]

Çürütücüler bu iddiayı daralttı ve üç şey ekledi:

- Kardeş script `audit.sh` `--hub` argümanı kabul ediyor ve **çapraz repo
  koşuldu** — yani 1.28 paketinin tamamı teslim edilmemiş değil.
- Protokolün kendi kaçış maddesi işledi: dört hub'ın üçü scriptin
  koşulamadığını EVOLUTION.md'ye **yazdı**; hiçbir hub "koştu" yalanı
  yazmadı. 1.28'in "koşmayan kontrol koştu yazılmaz" kuralı tuttu.
- Bu bir ihmal değil, **kayıtlı açık karar**: `din_takip` B-187 (2026-09-04)
  üç seçeneği adlandırıp kullanıcıya soruyor. [KARAR]

1.28'in etkisi ölçülmeye çalışıldı ve **ölçüm cevap veremedi**: sonrasındaki
reconstructed olmayan oturum sayısı 15, bunun 7-8'i tek hub'ın tek gününden.
Kümelenme düzeltmesiyle etkin örneklem ~4. Bu güçle %30'luk bir düşüşü görme
olasılığı %13. Hesaplanan p değerlerinin hiçbiri 0,28'in altına inmiyor.

Doğru cümle "1.28 işe yaramadı" değil, **"bu veriyle işe yarayıp
yaramadığı görülemez"**. Görülebilen tek şey, tedbirin dokuz hub'a hiç
ulaşmamış olması. [DOGRULANMALI]

## 4. Getiri: kaydın geri okunduğu yerler

Defterin tek savunması şu soruya verilen cevaptır: yazılan geri okunuyor mu?

- **Oturum kayıtlarının %70'i** (255/366) kendi klasörünün dışından atıf
  almış. Yani üçte ikiden fazlası en az bir kez yeniden kullanılmış.
- `money_takip`te kod commit'lerinin **%69,6'sı** bir hub kimliğine atıf
  yapıyor — kayıt kodun içine kadar giriyor.
- `datasources_takip`te 256 hub içi çapraz bağlantı var; 34 ders başka bir
  derse atıf yapıyor.
- Kullanıcı kararı taşıyan görevler sonraki kayıtlarda **%48**, sıradan
  görevler %34 oranında anılıyor. Karar kaydı, ortalama kayıttan daha çok
  geri okunuyor.

En sert kanıt tek bir olaydan geliyor: 2026-08-11'de beş bildirim yanlış
hub'a düştü, üçü kullanıcı kararı taşıyordu. 17 gün sonra çapraz denetimle
bulunup sahiplerine teslim edildiler. Hub'sız eşdeğerinde o üç karar
kaybolmuştu. [TAMAM]

## 5. Getiri: dersin koda dönüştüğü yer

499 ders başlığının **125'i (%25)** eşleşen kod reposunun bir kaynak
dosyasında, **37'si (%7)** bir test dosyasında anılıyor. Hub'ın kendi atıf
konvansiyonu (B-, T-, SEC- kimlikleri) da sayılınca oran %45'e çıkıyor.

Bu sayı bir **taban**, tavan değil: kimlik yazmadan koda geçmiş dersler
(örneğin kurulum scriptine gömülen bir kural) hiçbir sayımda görünmüyor.

Nedensellik iki vakada zincir olarak görülebiliyor:

- **copilot:** L-034 (2026-08-08) aynı gün pre-push kancasını doğurdu;
  2026-08-24'te L-057 kancanın Dart'ı kapsamadığını kaydetti; kanca aynı gün
  genişletildi. Ders, kapı, kapının kör noktası, kapının genişlemesi.
- **power:** L-010 CI kontrolüne bağlandı ve o sınıf bir daha tekrar etmedi;
  aynı ailenin bağlanmamış üyesi L-014 altı gün sonra tekrar etti.

Buradan çıkan ayrım, raporun en kullanışlı cümlesi olabilir: **bir teste ya
da kapıya bağlanan ders tekrarı önlüyor; düzyazıda kalan ders önlemiyor.**

## 6. Boşa giden yük

Aynı kayıtlar defterin işe yaramayan yarısını da gösteriyor.

- **Artifact'lar.** README dışı 196 markdown artifact var. Neredeyse hepsi
  hub'da bir yerde anılıyor, ama bu çoğunlukla sözleşmenin zorunlu kıldığı
  **doğum kaydı satırı** — kullanım değil. Doğduğu gün ve klasör dışından
  atıf alanlar 64-98 arası (ölçüt sıkılığına göre %33 - %50). Yani
  artifact'ların yarısı ile üçte ikisi **yazıldıktan sonra bir daha hiç
  okunmuyor**; 0,75 - 1,69 MB yazılmış ve geri dönülmemiş metin.
- **Durgun görevler.** On hub'da 64 `waiting` görevin %45'i eşiği aşmış.
  30 durgun görevin 21'i (%72) tek bir günden: 2026-08-03, altı hub'ın
  kurulduğu gün. `waiting/` yaşayan bir kuyruk değil, kurulum tortusu.
- **Güvenlik sicili.** 43 açık SECURITY kaydının 32'si 30 günden uzun süredir
  açık, yaş medyanı 33 gün. Sicil olarak çalışıyor, kapı olarak çalışmıyor.

Not: benim ilk ölçümüm "artifact'ların %86'sı atıf almış" diyordu; çürütme
turu bunun **zorunlu indeks satırını** saydığını gösterdi. Düzeltilmiş sayı
yukarıdaki. Ölçütün tanımı, sonucun kendisi kadar belirleyici.

## 7. Uyum: hangi madde tutmuyor

Mekanik denetim (`tool/audit.sh`, on hub) **79 bulgu, 14 kusur sınıfı**
verdi. Ama asıl bulgu denetimin **görmedikleri**:

- **Ritim maddesi.** Kural yürürlüğe girdikten sonraki 807 iş commit'inin
  475'inde (%58,9) oturum kaydı 30 dakika içinde güncellenmemiş. Hub'a göre
  %8,7 (takip) ile %78,6 (din) arası. Denetim bunu `info` olarak basıyor,
  **bulgu saymıyor** — korpustaki en büyük sapma çıkış kodunda görünmüyor.
- **Muafiyetler.** `author` alanı eksik 105 oturumun 101'i muaf; 86 oturum
  (%24) `reconstructed` bayrağıyla iki kontrolden muaf — ve bayrağı ajanın
  kendisi koyuyor, doğrulayan mekanizma yok. Korpusun dörtte biri denetim
  dışında.
- **Şema dışı kayıt.** `din_takip`te 8 oturum klasör yerine düz dosya olarak
  yazılmış; denetim döngüsü bunları hiç görmüyor. En ağır yapısal ihlal, kör
  noktada duruyor. [EKSIK]
- **Temiz hub'lar genç hub'lar.** `money` sıfır bulgu veriyor ama beş görevi
  28 günlük, eşik 30 — iki gün sonra beş bulgu verecek. Bulgu sayısı
  sözleşme sürümüyle ilişkisiz (Spearman +0,05), hub yaşıyla ilişkili
  (+0,45). "Geride kalan hub daha çok bulgu verir" hipotezi reddedildi.

Sürüm yayılımı ayrı bir uyum sorunu: dokuz türev hub'ın yedisi geride,
medyan gecikme 15 gün. Ölçülebilir oturumların **%31'i** (97/310) ana
kopyadan geri bir sözleşmeyle koştu. Buna karşılık **sessiz ayrışma yok**:
hub'ların 9/10'unun SYSTEM.md'si iddia ettiği sürümle bayt-eş. Sorun içerik
sadakati değil, zamanlama.

## 8. Doğrulama turu: hangi iddia düştü

Yedi manşet iddia ikişer bağımsız çürütücüye verildi. Sonuç, ölçümün kendi
kalitesi hakkında da bilgi veriyor:

| İddia | Hüküm |
|---|---|
| acilis.sh dağıtılmadı | Kısmen — sayı doğru, kapsam geniş |
| Sözleşme hiç küçülmedi | Çürük — okuma politikası küçüldü |
| 1.28'in etkisi yok | Çürük — "etki saptanamadı" doğrusu |
| Ritim tutmuyor | Kısmen — oran ve dönem düzeltildi |
| Ders koda bağlanmıyor | Doğrulandı — %25 taban |
| Artifact bir daha okunmuyor | Kısmen — ölçüt tanımı belirleyici |
| Ders tekrarı önlemiyor | Kısmen/çürük — 16 vaka degil 4 |

İki iddia tamamen düştü, dördü daraltıldı, biri ayakta kaldı. Bu oran
çalışmanın zayıflığı değil, çürütme turunun neden zorunlu olduğunun kanıtı:
ölçüm ajanları da tıpkı kayıt yazan ajanlar gibi kendi çıktısını
denetlemiyor.

## 9. Öneriler — karar değil (R-008)

Kaldıraç sırasıyla, hepsi bu çalışmanın ölçtüğü bir sayıya bağlı:

1. **`tool/` dağıtımını karara bağla.** B-187 zaten üç seçenekle açık;
   ölçüm kararı besledi: tedbir dokuz hub'a ulaşmadı, script taşınabilir,
   tek `cp` mesafesinde ama tek başına `acilis.sh` yetmez (audit ve lint de
   aynı klasörden çağrılıyor). [KARAR]
2. **Denetimin en büyük sapmayı görmesini sağla.** Ritim kontrolü `info`dan
   bulguya çevrilsin ya da eşiği gerçekçi hale getirilsin. Bugün %59 ihlal
   çıkış kodunda sıfır bulgu üretiyor.
3. **Muafiyetleri daralt.** `reconstructed` bayrağı doğrulanmıyor ve
   korpusun dörtte birini denetim dışına çıkarıyor; bayrağın en azından
   kendi commit deseninden sınanması mümkün.
4. **Şema dışı kaydı görünür kıl.** Denetim döngüsü düz `.md` oturumları da
   taramalı; bugün sekiz kayıt tamamen denetimsiz.
5. **Artifact'a kapanışta atıf zorunluluğu.** Yarısı bir daha okunmayan bir
   üretimin ya tüketicisi tanımlanmalı ya da üretim eşiği yükseltilmeli.
6. **Ölçülemeyeni ölçülebilir kıl.** Açılış kontrolünün koştuğu (fark
   bulunmasa bile) kayda yazılsın; tur sayısı hiçbir yerde tutulmadığı için
   1.28 tipi tedbirlerin etkisi bugün ölçülemiyor.
7. **Kurulum tortusunu temizle.** 2026-08-03'te doğan 21 cevapsız soru
   kuyruğun neredeyse yarısını tek başına oluşturuyor; toplu kapatma ya da
   toplu cevap kararı kullanıcıya ait. [KARAR]

## Sonuç

Defter, commit'lerin yarısından fazlasını yiyor ve dosyaları tek yönlü
büyüyor; buna karşılık yazdığının üçte ikisi geri okunuyor, kararları
kurtarıyor ve teste bağlandığı yerde hata sınıflarını mekanik olarak
kapatıyor. İki taraf da ölçüldü ve ikisi de gerçek.

Ama bu çalışmanın asıl bulgusu maliyet ya da getiri değil: **sözleşmenin
metni yayılıyor, uygulaması yayılmıyor.** Yük azaltma tedbiri dokuz hub'a
ulaşmadı, denetim en büyük sapmayı bulgu saymıyor, muafiyetler korpusun
dörtte birini kapsam dışında tutuyor, ve sekiz kayıt şemadan saptığı için
hiç denetlenmiyor. Sözleşmenin sorunu ağır olması değil, **ölçülen yerlerde
tutup ölçülmeyen yerlerde sessizce gevşemesi**.
