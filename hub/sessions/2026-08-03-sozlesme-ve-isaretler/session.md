---
id: S-2026-08-03-sozlesme-ve-isaretler
date: 2026-08-03
status: closed
reconstructed: false
topics: [sozlesme, isaretleme, secim, hata]
artifacts: []
tasks_touched: []
---

# Oturum: financer sözleşmesi, işaret hataları ve yorum eklemesi

## Özet
Dört iş: financer'ın sözleşmesini güncellemek, iki gerçek hatayı düzeltmek ve
seçim menüsüne yorum eklemek.

**Sözleşme (B-072, K-025, L-022).** Güncelleme sırasında beklenmeyen bir şey
çıktı: `financer_takip` **1.4**'teydi ama ana kopyanın 1.4'ünden farklı bir
1.4 — o hub'ın agent'ı oturum şemasına `reconstructed` alanı eklemişti
(sıkıştırma sonrası geriye dönük yazılan oturumu işaretlemek için). Yalnız
sürüm numarasına bakan kontrol bunu göremezdi; körü körüne üzerine yazılsaydı
iyi bir kural sessizce silinecekti. Alan ana kopyaya taşındı (**1.6**), §10'a
"ayrışma" maddesi eklendi, sonra financer 1.4 → 1.6 güncellendi.

**İşaret hataları (B-073, B-074).** Kullanıcı "sarı ancak çıkıp girince
görünüyor, kırmızı hiç görünmüyor" dedi. İki ayrı hata çıktı:

1. Render doğruydu — test, arka plan renginin ve alt çizginin widget ağacında
   olduğunu gösterdi. Sorun **alıntının bulunamamasıydı**: kullanıcı çizilmiş
   metni seçiyor, kod ham markdown'da arıyordu. `**kalın**` işaretleri,
   satır sarmaları ve girintiler eşleşmeyi bozuyordu. Kırmızının *hiç*
   görünmemesi tesadüf değildi: seçilen yer kalın yazılmıştı (L-023).
2. Kayıt hub'a gidiyor ama ekran işaretleri yerel kopyadan okuyor; kopya bir
   sonraki senkrona kadar yeni kaydı bilmiyordu (L-024).

**Yorum (B-075).** Menü beş eyleme çıktı: Sarı işaretle · Kırmızı çizgi
(görünür) · Yorum ekle · Görev oluştur · Kopyala (taşma menüsünde).

`flutter analyze` temiz, **292 test** (9 yeni). Cihazda menü ekran
görüntüsüyle doğrulandı.

## Kayıt

### Kullanıcı
> financer sözleşmesini sen güncelle, daha sonra texti secince acilan menu
> sari isaretle, kirmizi cizgi, 3nokktaya basinca2. menude gorev olustur ve
> kopyala seklinde, hepsi tek menude olsun, highlight ekleyince sayfada
> goruntulenmiyo, cikip tekrar girince goruntulendi, kirmizi cizgi hic
> goruntulenmiyo, bir de text yorum ekleme ekleyelim ayni menude gorunsun

### Agent
**Sözleşme.** Kopyalamadan önce hedefin durumu okundu ve iyi ki okunmuş:
financer 1.4'teydi ama içeriği ana kopyanın 1.4'ünden farklıydı. Üzerine
yazmak yerine yerel ekleme (`reconstructed`) ana kopyaya taşındı, sürüm 1.6
oldu ve §10'a ayrışma maddesi eklendi — sonra güncelleme yapıldı.

**Hatalar.** "Kırmızı hiç görünmüyor" ifadesi teşhisi hızlandırdı: eğer render
bozuk olsaydı sarı da hiç görünmezdi, oysa sarı bazen görünüyordu. Bu, sorunun
çizimde değil **eşleşmede** olduğunu söylüyordu. Bir sonda testiyle doğrulandı:
her iki işaret de widget ağacında doğru stille duruyordu.

Eşleştirme artık kaynağın düzleştirilmiş izdüşümünde yapılıyor (vurgu
işaretleri atılmış, boşluklar teke inmiş) ve konum geri haritalanıyor. Önce
birebir arama deneniyor; tutarsa daha kesin.

İkinci hata için ince bir köprü katman: az önce oluşturulan işaretler senkron
yetişene kadar bellekte tutuluyor, sonra kendini temizliyor. Çift çizim
olmuyor çünkü çakışan aralıklar zaten eleniyor (L-021).

**Menü.** İstenen sıra kuruldu. Yorum için tam sayfa yerine hafif bir giriş
kutusu yapıldı — okurken not düşen kullanıcıyı beş alanla karşılamamak için.

Cihazda menü doğrulandı (Sarı işaretle · Kırmızı çizgi · ⋮). İşaretin anında
görünmesi cihazda denenemedi: kör dokunuş dizisi uygulamadan çıkıp sistem
ayarlarına düştü. Davranış birim testleriyle kapsanıyor.
