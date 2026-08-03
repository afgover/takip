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

### Kullanıcı
> 2si tamam yorum ekle diyince yorum ekleniyor, yorumu bekleyen gorevlerde
> goruntuluyorum, yorumdaki amacim gorev gibi olusturmak degildi, userin
> kendisi icin not tarzi yorum eklemesi idi, texte tiklayip olusturdugumuz
> yorumdan bu daha farkli yani, yorumdan ziyade not ekleme diyebiliriz

### Agent
İki sorun doğrulandı. Üçüncüsü hata değil **tasarım eksiğiymiş**: kullanıcının
kendine aldığı not, app'in tek yazma alanı `tasks/inbox/` olduğu için görev
olmak zorunda kalıyor ve Bekleyenler'de görünüyordu.

Saklama yeri kullanıcıya soruldu (hub'da ayrı klasör / yalnız cihazda / inbox'a
yazıp agent dosyalasın); "hub'da ayrı klasör" seçildi. Sözleşme 1.9 ile
`notes/` açıldı (§11) ve R-001 **özü korunarak** genişletildi: yazma alanı
ikiye çıktı ama hâlâ kapalı bir küme — app yol değil dosya adı veriyor ve
klasörü `HubFolder` enum'undan seçiyor, üçüncü bir klasöre yazması tip
düzeyinde imkânsız.

Not, görev yolundan tamamen ayrıldı: ayrı taslak (`TaskDraft.note`), ayrı
oluşturma fonksiyonu (`createNote`), ayrı kutu (`openNoteBox`). Aynı fonksiyona
bayrak eklemek ikisinin ayrı şeyler olduğunu gizlerdi. Menüdeki ad "Not ekle",
kutunun ipucu "Kendine not — agent'a iş düşmez". İşaret yeşil kalıyor,
dokununca "Notu sil" çıkıyor. Çevrimdışı kuyruk da hedefi taşıyor: ağ yokken
alınan bir not, bağlantı gelince yine `notes/`a gidiyor — göreve dönüşmüyor.

Sarı işaret ve kırmızı çizgi bilerek göreve gitmeye devam ediyor; onlar
agent'a sinyal ("buraya bak", "burası yanlış"). Ayrımı işaretin rengi değil
kullanıcının niyeti belirliyor. Bunu koruyan bir test de eklendi.

Yan iş: `isContractStale` testleri sürüme çivilenmişti ve her sürüm
yükseltmesinde kırılıyordu. Referans dışarıdan verilebilir hâle geldi; ayrıca
**sabit ile `SYSTEM.md`'nin ayrışmasını** yakalayan bir test eklendi — §10'un
tamamı o sayıya dayandığı için birini yükseltip diğerini unutmak bütün
bağlantılara yanlış "sözleşmen eski" uyarısı gönderirdi.

`flutter analyze` temiz, **318 test**.

### Kullanıcı
> not ekledim, bekleyenlerde gorunmuyor, silme calisiyor, tek eksik yesile
> tiklayinca altta cikan pencerede notun icerigi yer almiyor

### Agent
Kart, kullanıcının **zaten belgede gördüğü** alıntıyı tekrar edip asıl
taşıması gereken metni hiç göstermiyordu — `Annotation` böyle bir alan
taşımıyordu. `note` alanı eklendi ve kayıt gövdesinden çıkarılıyor
(`noteTextFrom`); fonksiyon iki gövde biçimini de tanıyor: notlarda metin
başlığın altında (§11), görevlerde `## İstek` altında (§4). Tanınmayan
gövdede null dönüyor, kart yine açılıyor.

İyimser katman da dolduruluyor: az önce yazılan bir nota dokununca senkron
beklenmeden metin görünüyor.

Testler gövdeyi **gerçek taslaktan** üretiyor; dosya biçimi değişirse test
düşer, elle yazılmış bir örnek sessizce eskimez.

Yan düzeltme: yorum işaretinin kart ikonu "altı çizili" ikonuydu (renk
eklenirken atlanmış), artık kendi ikonu.

`flutter analyze` temiz, **324 test**.

### Kullanıcı
> tamam, denedim çalışıyor
> Tarayici sekmesindeki Bekleyen gorevler butonunu kaldir(zaten alt menude
> var) onun yerine Security isimli bir buton koy, sozlesmeyi projenin security
> ile alakali alinan onlemleri, yapilan calismalari burada ayri bir security
> logu altinda loglama yapacagi bir madde ekle, yapilan taramalar, alinan
> onlemler, olasi aciklar, yapilmasi gereken isler ve benzeri kayitlar tutulup
> burda listelensin

### Agent
Sözleşme 1.10 §12: `SECURITY.md` — tek canlı dosya, ID'li kayıtlar
(`SEC-001`), `Tür` (tarama/onlem/acik/yapilacak) ve `Durum` (acik/kapali)
alanlarıyla. Biçim `knowledge/` ile **bilinçli olarak ortak**: ayrı bir
çözümleyici yazmak aynı "ID'li canlı liste" fikrinin iki yerde ayrışmasına yol
açardı. Nitekim ilk denemede alan okuyucusu kopyalanmıştı ve kopyadaki
kaçışlar bozuktu — ortak `KnowledgeEntry.field` yapılıp sorun kaynağında
çözüldü. Paylaşılan başlık deseni de `SEC-` gibi üç harfli ID'yi tanımıyordu
(`[A-Z]{1,2}`); ID uzunluğuna göre daraltılmış bir desen, yeni bir kayıt
ailesi eklendiğinde başlığı sessizce ayrıştırmadan geçiriyor.

Ekran açık kayıtları **üste** alıyor ve üstte "N açık kayıt" uyarısı
gösteriyor. Gerekçe: ekranın işi arşivi güzel göstermek değil, kapanmamış
güvenlik işini görünür kılmak — kronolojik sıra bir açığı kapanmış on kaydın
altına gömerdi. Türe göre filtre var; yalnız dosyada gerçekten geçen türler
çipe dönüşüyor.

Log boş açılmadı: projede gerçekten alınmış dört önlem (token'ın yalnız güvenli
depoda durması, şifreli yedek, yazma alanının yapısal kapalılığı, token'ın
isteğin yoluna göre seçilmesi) ve dürüstçe **üç açık kayıt** yazıldı — bağımlılık
taraması hiç koşulmadı, token kapsamı doğrulanmıyor, cihazdaki kopya şifresiz.
Son ikisi backlog'a da girdi (B-091, B-092). Test, dosyada token benzeri bir
değer geçmediğini de sınıyor (§12: sır yazılmaz).

Tarayıcıdaki "Bekleyen görevler" kutusu kaldırıldı — alt menüde kendi sekmesi
var ve aynı ekrana iki kapı, ikisinden birinin bayat kalmasına yol açıyor.

`flutter analyze` temiz, **334 test**.

### Kullanıcı
> security ekranı geldi, çalışıyor
> masaustundeki takip-agent-kurulum-talimati dosyasini yeni bir projede
> agentin 0dan tum isleyisi, mumkunse gecmise donuk de olarak yapacagi sekilde
> ve son guncellemelerimiz ile yenilermisin

### Agent
Talimat baştan yazıldı. En büyük ekleme §3 — **geçmişi olan projeler**.
Belge artık açılışta agent'ı ikiye ayırıyor: sıfırdan proje (A) ve geçmişi
olan proje (B). B'de geçmişi toplamak zorunlu bir adım: hangi kaynaklardan ne
çıkarılacağı tabloyla veriliyor (git log, etiketler, README/CHANGELOG,
issue'lar, TODO'lar, kullanıcının eski sohbetleri), geriye dönük oturumlar
`reconstructed: true` ile yazılıyor, zaman damgası uydurulmuyor, her iddianın
kaynağı gösteriliyor ve **cevabı yalnız kullanıcıda olan her soru ayrı bir
`waiting/` görevi** oluyor. Boşluğun boşluk olarak yazılması ayrıca kural.

Belge ayrıca oturum döngüsünü (açılış/boyunca/kapanış) ve bitirme kontrol
listesini kazandı; 1.9 (`notes/`), 1.10 (`SECURITY.md`) ve sürüm-ayrışma
durumu (§1 madde 6) işlendi.

Yazarken gerçek bir boşluk çıktı: `note:` commit öneki 1.9'da eklenirken
sözleşme §8'e ve uygulamanın aktivite ayrıştırıcısına yazılmamıştı — kullanıcının
kendi notu akışta **"kod commit'i"** olarak görünüyordu. Sessiz bir hata:
hiçbir şey patlamıyor, yalnız yanlış etiketleniyor. 1.11 ile `note:` ve
`security:` hem sözleşmeye hem ayrıştırıcıya eklendi. Test artık önek listesini
**sözleşme dosyasından okuyup** uygulamanın hepsini tanıdığını doğruluyor;
listeyi iki yerde elle senkron tutmak gerekmiyor. Düzeltme geri alınarak
testin hatayı yakaladığı doğrulandı.

`flutter analyze` temiz, **344 test**.

### Kullanıcı
> financer tarafinda guncelleme yapilip push edildi(financer_takip) fakat
> uygulamada guncellemeleri goremiyorum

### Agent
Senkron kodu doğruydu — `syncNow()` bağlı bütün repoları indiriyor. Eksik olan
**tetikleyici**ydi: yoklama yalnız aktif reponun son commit'ine bakıyordu, yani
aktif olmayan bir repoya yapılan push hiçbir sinyal üretmiyordu. Senkron ancak
aktif repo değişince, repo değiştirilince ya da elle tetiklenince koşuyordu.

L-031'in aynısı bir katman aşağıda: orada liste çok kaynaklıydı ama listeden
açılan yol tek kaynaklıydı; burada indirme çok kaynaklı ama uyandıran sinyal
tek kaynaklıydı.

Yoklama artık bütün bağlantıların başını okuyor (`HubStatus.heads`), değişen
slug'ları bildiriyor (`changedSlugs`) ve senkron bunu dinliyor. Maliyeti düşük:
değişiklik yokken yanıt ETag sayesinde 304 ve istek limitinden düşmüyor
(SK-002). Her repo kendi tokeniyle yoklanıyor — token isteğin yolundan
seçildiği için bu kendiliğinden oluyor (L-019).

Uçtan uca test önce **yanlış sebeple** geçti: tetiklenen senkron arka planda
koştuğu için ölçüm o bitmeden yapılıyordu. İstek listesine bakınca financer'a
hiç ağaç isteği gitmediği görüldü; test tetiklenen işi bekleyecek şekilde
düzeltildi. Sonra eski tetikleyici geri konularak testin hatayı gerçekten
yakaladığı doğrulandı (`eski içerik` ≠ `güvenlik duruşu belgesi`).

`flutter analyze` temiz, **349 test**.

### Kullanıcı
> bu repoyu public yapsam ve uygulamayi da storelara yuklesem ve herkese
> ucretsiz yapsam nasil olur?
> license ve readme ekle daha sonra public yapmak icin karar verecegiz

### Agent
İki ayrı karar olduğu ve cevaplarının farklı olduğu söylendi.

Ücretsizlik mimari gereği sürdürülebilir: backend yok, her kullanıcı kendi
token'ıyla kendi GitHub kotasını kullanıyor, ETag sayesinde yoklama pratikte
bedava. Kullanıcı sayısı maliyeti değiştirmiyor.

Store çıkışının önündeki asıl engel **token modeli**: uygulama kullanıcıdan PAT
isteyip yapıştırmasını bekliyor ve **kapsamını doğrulamıyor** (SEC-006 zaten
açık kayıt). Genel dağıtımda bu, kullanıcının bütün GitHub hesabını yazma
yetkisiyle vermesi ve uyarılmaması demek. Doğrusu GitHub App/OAuth — backlog'da
B-061 olarak duruyor ve tetikleyicisi tam olarak "çok kullanıcı olursa". Yanında:
iOS hiç denenmedi (`ios/` yok), i18n yok, gizlilik politikası ve store formları
gerekiyor. Ara adım olarak GitHub Releases / Play açık test önerildi.

Repoyu public yapmanın iki sessiz sonucu ayrıca söylendi: `hub/` de public olur
(sistemin "her şeyi hub'a yaz" ilkesiyle sürtüşür) ve §10 zinciri bu reponun raw
adresini işaret ettiği için başkalarının agent'ları burayı poll etmeye başlar —
sözleşmede kırıcı değişiklik özgürlüğü biter.

Kullanıcı LICENSE ve README istedi; public kararı ertelendi. MIT seçildi
(izin verici, kısa, spec benimsenmesi için uygun). README baştan yazıldı —
eskisi başlangıçtan kalmaydı ve yanlıştı (`project-taskr`, artık geçersiz
`flutter create` talimatı). Yeni README ne olduğunu, neden var olduğunu, akış
şemasını, kendi projende kurmayı, çalıştırmayı ve **dürüstçe sınırları**
anlatıyor (Android/tek dil, token kapsamı doğrulanmıyor, çevrimdışı kopya
şifresiz). README'deki her yol ve her ID (B-061, SEC-006, SEC-007, sözleşme
1.11) dosyalara karşı doğrulandı.

Git geçmişi token deseni açısından tarandı: temiz.

## Sonraki adım
Public yapma kararı kullanıcıda (B-097). `financer_takip` sözleşmesi 1.11'de.
