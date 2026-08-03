# Çıkarılan Dersler (lessons)

Yapılan hatalar ve öğrenilenler; tekrarlanmaması için tek tek kayıt altında.
Biçim: `SYSTEM.md` §5.

---

## L-001 — Altyapı işletmek ürünün önüne geçebilir
- **Tarih:** 2026-07-30
- **Kaynak:** İlk taskr deneyimi (Expo + özel backend)
- **Açıklama:** Auth, offline senkron, deploy ve güvenlik yamaları; görev
  yönetimi ürününün kendisinden daha fazla emek tüketti. Yönetilen bir omurga
  (GitHub) üzerine kurulmak bu yükü sıfıra yaklaştırır. Yeni bileşen eklerken
  ölçüt: "Bunu biz mi işletmek zorundayız?"

## L-002 — Paylaşılan tek dosya, eşzamanlı yazmada çakışır
- **Tarih:** 2026-07-30
- **Kaynak:** Aşama 0 tasarımı (K-004)
- **Açıklama:** Tüm görevleri tek `todos.json`'da tutmak iki yazarın sürekli
  çakışmasına yol açar. Kayıt-başına-dosya modelinde ekleme hiçbir zaman
  çakışmaz; güncellemede de çakışma tek göreve izole kalır.

## L-003 — Kritik parametreleri işleme başlamadan teyit et
- **Tarih:** 2026-07-30
- **Kaynak:** S-2026-07-30-duzeltme-ve-dongu-testi
- **Açıklama:** Hub, kullanıcının kastettiği `taskr_takip` yerine yanlışlıkla
  `takip` reposuna kuruldu; iki benzer adlı repo varken isim teyit edilmeden
  taşıma yapıldı ve iş iki kez yapıldı. Kural: repo adı, hedef branch gibi geri
  alması maliyetli parametrelerde belirsizlik varsa önce listele/teyit et,
  sonra uygula.

## L-004 — Görev döngüsünün Contents API yolu ayrıca test edilmeli
- **Tarih:** 2026-07-30
- **Kaynak:** B-016 testi
- **Açıklama:** T-001 döngüsü (inbox → active → done) git ile işletildi ve
  sözleşme sorunsuz çalıştı; ancak uygulamanın kullanacağı yol Contents API'dir
  (taşıma = DELETE + PUT, SHA zorunlu). Bu yol Faz 3'te (B-034) uçtan uca ayrıca
  test edilecek.

## L-005 — Contents API'de "boş dizin" diye bir şey yok
- **Tarih:** 2026-07-30
- **Kaynak:** B-023
- **Açıklama:** Git boş dizin tutmaz; bir klasörün son dosyası silinince klasör
  de yok olur. Contents API bu durumda 404 döner — yani "içi boşalmış dizin" ile
  "hiç var olmayan dizin" ayırt edilemez. Dizin listelemede 404'ü hata olarak
  göstermek yanlış olur (kullanıcı boş inbox'ta hata ekranı görür); `listDir`
  404'ü **boş liste**ye çevirir. Tek dosya okumada 404 gerçek hatadır, olduğu
  gibi bırakılır.

## L-006 — Doğrulanmamış kod sessizce birikir
- **Tarih:** 2026-07-30
- **Kaynak:** B-023 (iskeletin ilk derlenmesi)
- **Açıklama:** B-021 iskeleti SDK'sız ortamda yazıldığı için hiç derlenmemişti.
  İlk `flutter analyze` çalıştırıldığında iskelette 2 gerçek derleme hatası
  çıktı (`DropdownButtonFormField.initialValue` — o sürümde alan adı `value`).
  Hata küçüktü ama kod yazıldığı anda değil, haftalar sonra görülecekti. Kural:
  SDK gerektiren iş yapılıyorsa SDK ortama kurulur ve **her oturumda** analiz +
  test çalıştırılır; "sonra doğrularız" borcu faiziyle geri döner.

## L-007 — GitHub'da 404, üç ayrı sorunun ortak cevabı
- **Tarih:** 2026-07-30
- **Kaynak:** B-022
- **Açıklama:** Contents API'de 404; (a) repo yok, (b) token bu repoyu
  kapsamıyor, (c) yol/klasör yok durumlarının üçünde de dönüyor. Fine-grained
  token görmediği repoyu "yok" sayar — varlığını sızdırmamak için bilinçli bir
  tasarım. Sonuç: tek istekle bu üçü ayırt edilemez. Kullanıcıya "repo
  bulunamadı" demek yanlış yönlendirir; mesajda üç olasılık birlikte
  söylenmelidir. Yetki hatası (401/403) ise gerçekten ayrıdır ve "yok" ile
  karıştırılmamalıdır — bu yüzden `pathExists` yalnız 404'ü false'a çevirir,
  yetki hatalarını yukarı geçirir.

## L-008 — `testWidgets` içinde gerçek async işi doğrudan beklemek kilitler
- **Tarih:** 2026-07-30
- **Kaynak:** B-034
- **Açıklama:** `testWidgets` gövdesi sahte saatli bir zonda koşar; olay
  döngüsü ancak `pump()` ile ilerler. Bu yüzden bir HTTP çağrısını (sahte
  adaptörle bile olsa) doğrudan `await` etmek testi sonsuza kadar askıda
  bırakır — hata mesajı da vermez, sadece asılır. İki doğru yol var:
  (a) isteği bir kullanıcı eylemi tetikliyorsa `pumpAndSettle()` yeterlidir,
  (b) test gövdesinden doğrudan çağrılıyorsa `await tester.runAsync(() => ...)`
  ile gerçek zonda çalıştırılır. Aynı kod düz `test()` içinde sorunsuz
  çalıştığı için sorun kolayca yanlış yere aranıyor.

## L-009 — GitHub'da bir token'ın kendi izinlerini sorması mümkün değil
- **Tarih:** 2026-07-30
- **Kaynak:** B-026 araştırması
- **Açıklama:** `GET /repos/{o}/{r}` yanıtındaki `permissions` alanı, isteği
  yapan **kullanıcının repo rolünü** yansıtır; token'ın kapsamını değil.
  Fine-grained token'larla alanın hatalı (hepsi `false`) döndüğü de bildirilmiş
  durumda. Token izinlerini sorgulayacak belgelenmiş bir uç nokta yok. Sonuç:
  "izin var mı?" sorusu doğrudan sorulamaz; ancak bir işlem denenip **403**
  alınarak *kesin olumsuz* öğrenilebilir. Böyle bir kontrol tasarlanırken
  yorum tek yönlü tutulmalı — 403 "izin yok" demektir, ama 403 gelmemesi
  "izin var" demek değildir.

## L-010 — `flutter create` INTERNET iznini release manifest'ine koymaz
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-b020-mac-kurulum (B-020)
- **Açıklama:** Flutter şablonu `android.permission.INTERNET` iznini yalnızca
  `android/app/src/debug/` ve `profile/` manifestlerine yazar — gerekçesi, iznin
  geliştirme sırasında hot reload için gerekmesi. `main/AndroidManifest.xml`'e
  konmaz, çünkü şablon "her uygulama ağ kullanmaz" varsayar. Ağ kullanan bir
  uygulamada bu sessiz bir tuzaktır: debug ve profile koşumları sorunsuz
  çalışır, hata **yalnızca release derlemesinde** ve çoğu zaman ağ hatası gibi
  görünerek ortaya çıkar. Bu proje `api.github.com` dışında hiçbir şey yapmadığı
  için (K-001) izin `main` manifest'ine gerekçesiyle eklendi. **Genel kural:**
  platform klasörü üretildikten sonra `main` manifest'i elle okunur; debug'da
  çalışıyor olmak release'te çalışacağının kanıtı değildir.

## L-011 — `flutter install` varsayılan olarak release APK arar
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-b020-mac-kurulum (B-020)
- **Açıklama:** `flutter build apk --debug` ile derleyip ardından
  `flutter install -d <cihaz>` çağırmak "APK does not exist" hatası verir; komut
  `--debug` bayrağı olmadan `app-release.apk` arar. Derleme ve kurulum
  bayraklarının eşleşmesi gerekir: `flutter install -d <cihaz> --debug`.

## L-012 — Türetilmiş asenkron provider, kaynağının bir adım gerisindedir
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-b020-mac-kurulum (T-003)
- **Açıklama:** `hubConfigProvider` (aktif bağlantı) `hubConnectionsProvider`
  (liste) üzerinden **asenkron** türüyor: liste değiştiğinde türetilmiş
  provider'ın yeni değeri bir sonraki mikro-görevde oluşur. Repo değiştirildiği
  anda `ref.read(hubConfigProvider).value` hâlâ **eski** repoyu verir. Outbox
  boşaltmasında bu, geçişin hemen ardından görevin yanlış repoya yazılması
  demekti — test bunu yakaladı. **Kural:** bir yazma işleminin hedefi
  belirlenirken türetilmiş değil **kaynak** provider okunur; kaynak
  (`state = AsyncData(next)`) senkron güncellenir. Daha genel hâli: "hangi
  bağlama yazıyorum?" sorusu asla gecikmeli bir değere dayanmamalı.

## L-013 — `testWidgets` içinde platform kanalına inen `.future` beklemesi asar
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-b020-mac-kurulum (T-003)
- **Açıklama:** Outbox'ın yazma yolunda aktif bağlantıyı `.future` ile beklemek,
  o yola bir `flutter_secure_storage` bağımlılığı soktu. Mock kurulmamış
  testlerde kanal cevaplamadığı için `pumpAndSettle` zaman aşımına uğradı — ve
  aynı risk gerçek cihazda da var: güvenli depo cevap vermezse görev ekleme
  askıda kalır. L-008'in kardeşi: orada gerçek async iş doğrudan bekleniyordu,
  burada **platform kanalı** dolaylı olarak bekleniyor. **Kural:** kullanıcı
  etkileşiminin bulunduğu yol, platform kanalı çözülmesini beklememeli; değer
  zaten çözülmüş olmalı (burada kabuk `app.dart` bunu garanti ediyor) ve
  senkron okunmalı.

## L-014 — Debug'dan release'e geçmek uygulama verisini siler (token dahil)
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-b020-mac-kurulum
- **Açıklama:** `flutter install --release`, cihazda debug derlemesi varken
  paketi **kaldırıp** yeniden kurar ("Uninstalling old version..."). Android'de
  kaldırma uygulama verisini de siler; `flutter_secure_storage`'daki token
  gider ve kullanıcı onboarding'e döner. ~~Sürüm yükseltmesi değil, **derleme
  türü değişikliği** olduğu için kaçınılmaz.~~
  **Düzeltme (2026-08-01, L-016):** "kaçınılmaz" kısmı yanlıştı. Kaldırma,
  derleme türü değişikliğinin zorunlu sonucu değil; `flutter install`'ın
  yerinde güncelleme başarısız olunca girdiği **hata yolu**. `adb install -r`
  ile kurulduğunda debug↔release geçişi de veriyi korur (`tool/install.sh`).
  Kaydın geri kalanı (kaldırma olursa veri gider, göç yolu sınanamaz) geçerli.
  **Sonuç:** derleme türü değiştirilecekse kullanıcıya *önceden* söylenir
  ("token'ı yeniden gireceksin") ve mümkünse token girilmeden **önce** yapılır.
  Bu oturumda tersi yapıldı: kullanıcı sabah debug sürüme token girdi, akşam
  release kurulunca yeniden girmek zorunda kaldı.
  **Yan etki:** cihazda tutulan göç yolları (burada T-003'ün eski anahtar
  göçü) bu şekilde **sınanamaz** — kaldırma, göçün okuyacağı eski kaydı da
  siler. Göç yolu ancak birim testiyle ya da aynı derleme türünde sürüm
  yükseltmesiyle doğrulanabilir.

## L-015 — Test ekranında tembel liste alt alanları hiç oluşturmaz
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-token-kaliciligi
- **Açıklama:** `ListView` içindeki bir widget, varsayılan test ekranının
  (800x600) dışında kalıyorsa **hiç oluşturulmaz**; `find.byKey` boş döner ve
  hata "widget yok" gibi görünür — oysa widget vardır, sadece çizilmemiştir.
  Ekrana bir satır eklemek, alakasız görünen bir testi bu yüzden kırabilir.
  İki çözüm, ikisi de yerinde:
  - `tester.scrollUntilVisible(finder, delta)` — listeyi kaydırıp oluşturur.
    `ensureVisible` **işe yaramaz**, çünkü o widget'ın zaten ağaçta olmasını
    ister.
  - Uzun formlarda `tester.view.physicalSize` ile test ekranını yükseltmek;
    her etkileşimden önce kaydırmaktan kısa ve okunur. `addTearDown` ile
    `resetPhysicalSize` unutulmamalı.

## L-016 — `flutter install`'ın kaldırması kaçınılmaz değil, hata yoludur
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-token-kaliciligi
- **Açıklama:** L-014'te "derleme türü değişikliği veriyi siler" diye
  kaydedilmişti; kaynak okunup ölçülünce tablo değişti.
  `flutter_tools/.../android_device.dart` içinde `installApp` önce
  `adb install -t -r` deniyor ve **yalnızca** çıktısında `Failure` görürse
  "Uninstalling old version..." diyor. Gerçek cihazda release→release,
  debug→release ve release→debug'ın üçü de yerinde güncellemeyle başarılı
  oldu; imzalar da aynıydı. Yani veri kaybının sebebi derleme türü değil,
  aracın tek bir başarısızlıkta kaldırmaya kendi başına karar vermesiydi.
  **Sonuç:** kurulum `adb install -r` ile yapılır (`tool/install.sh`), böylece
  kaldırma hiç ihtimal dışı kalır. **Genel ders:** "araç şöyle yapıyor" diye
  kaydedilen bir davranış, aracın kaynağına bakılarak ve tekrar denenerek
  doğrulanmadan kalıcı kural sayılmamalı — L-014 tek gözleme dayanıyordu.

## L-017 — Testin geçmesi arayüzün doğru göründüğü anlamına gelmez
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-cihazda-dogrulama
- **Açıklama:** Çoklu repo şeridi 237 testten geçiyordu ama gerçek cihazda
  **durum çubuğunun altına giriyordu**: repo adı saatin ve pil ikonunun
  üzerine biniyordu. Sebep, kabuğun `AppBar`sız başlaması ve güvenli alanın
  bırakılmamasıydı. Widget testleri varsayılan olarak sistem alanı (`padding`)
  olmayan bir ekranda koşuyor, dolayısıyla bu sınıf hatayı **yapısal olarak**
  göremez.
  **Kural:** ekranın en üstüne ya da en altına yerleşen her yeni bileşen
  cihazda gözle doğrulanır; doğrulandıktan sonra da testi
  `MediaQueryData(padding: ...)` ile yazılır. Yazılan testin gerçekten
  koruduğu, düzeltme geri alınıp testin kırıldığı görülerek sınanır — geçen
  test ile yakalayan test aynı şey değildir.

## L-018 — Tek yönlü modellenmiş bir akış, eksik yönü sessizce sohbete yıkar
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-bekleyen-isler (B-065)
- **Açıklama:** Görev sistemi `inbox → active → done` olarak kuruldu; üçü de
  "agent ele alacak" demekti. Agent'ın **kullanıcıdan** beklediği işler için
  hiçbir durum yoktu, dolayısıyla o işler `BACKLOG.md`'de `(user)` etiketiyle
  yaşadı ve uygulamada hiçbir yerde görünmedi. Sonuç: sistemin taşıması
  gereken bir yükü sohbet taşıdı — B-015 (token) ve B-020 (SDK) 30 Temmuz'dan
  1 Ağustos'a kadar bekledi ve yalnızca agent sohbette hatırlattığı için
  ilerledi. Kullanıcının telefonunda hiçbir iz yoktu.
  **Kural:** iki tarafı olan bir akış modellenirken **her iki yön de** temsil
  edilmeli. Eksik yön yok olmaz; en kırılgan kanala (sohbet, hafıza, "sonra
  söylerim") kayar ve orada kaybolur. Tarama sorusu: "bu akışta karşı taraf
  bir şey yapmalıysa, sistemde nerede duruyor?"

## L-019 — Adres ve kimlik farklı anlarda okunursa eşleşmeyebilir
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-coklu-repo-404
- **Açıklama:** GitHub istemcisinde isteğin **adresi** (`owner/repo`) sağlayıcı
  kurulurken sabitleniyordu; **token** ise `onRequest` içinde, istek
  gönderilirken okunuyordu. Token'ı geç okumak bilinçli bir tercihti (B-051:
  kullanıcı token'ı değiştirince elde eski token kalmasın). Tek repo varken
  zararsızdı — okunan token her zaman o tek reponundu.
  Çoklu repoda (T-003) bu iki okuma arasına **aktif bağlantının değişmesi**
  girebiliyor: sonuç, A reposunun adresine B reposunun token'ıyla gitmek.
  Private repoda GitHub'ın cevabı **404**, yani kullanıcıya "Bulunamadı" —
  yetki hatası gibi bile görünmüyor. Belirti geçiciydi (bir sonraki yoklamada
  siliniyordu), bu yüzden kolayca "ağ dalgalanması" sanılabilirdi.
  **Kural:** bir isteğin **adresi ile kimliği aynı kaynaktan ve aynı anda**
  belirlenmeli. Geç okunan bir değer, erken sabitlenmiş bir değerle eşleşmek
  zorundaysa, ikisini birbirine bağla — burada token isteğin **yolundan**
  seçilerek bağlandı. Tarama sorusu: "bu iki değer farklı anlarda okunuyorsa,
  arada değişirlerse ne olur?"

## L-020 — Kopyalanan sözleşme geriden gelir ve bunu kimse fark etmez
- **Tarih:** 2026-08-02
- **Kaynak:** S-2026-08-02-secim-filtre-sozlesme
- **Açıklama:** Her proje hub'ı `SYSTEM.md`'nin bir **kopyasını** taşıyor.
  Ana kopya güncellendiğinde diğerleri kendiliğinden güncellenmiyor ve
  aradaki fark hiçbir yerde görünmüyordu. `financer_takip` bunun canlı
  örneğiydi: sözleşmesi 1.3'te kalmışken `tasks/waiting/` klasörünü
  kullanıyordu — yani **kullandığı klasörü kendi sözleşmesi tanımlamıyordu.**
  Oraya bakan yeni bir agent `waiting/`in ne olduğunu bilemez, dolayısıyla
  mekanizmayı sürdüremezdi.
  Kopyalanan bir sözleşmenin bayatlaması kaçınılmaz; **fark edilmemesi**
  düzeltilebilir. İki yönlü kapatıldı: agent her oturum açılışında sürümü ana
  kopyayla karşılaştırıp güncelliyor (§10), uygulama da geride kalan repoyu
  Ayarlar → Repolar'da işaretliyor. Agent atlarsa kullanıcı görüyor.
  **Genel kural:** bir şeyin kopyası dağıtılıyorsa, "kopya bayat mı?"
  sorusunun cevabı sistemde bir yerde **görünür** olmalı. Görünmeyen fark,
  olmayan fark gibi davranır.

## L-021 — Sırayla yerine koymak, iç içe geçen aralıkları bozar
- **Tarih:** 2026-08-02
- **Kaynak:** S-2026-08-02-secim-filtre-sozlesme (B-069)
- **Açıklama:** Belgedeki alıntıları işaretlerken her kaydı sırayla
  `replaceRange` ile sarmak yeterli sanılmıştı. Uzun alıntı önce işaretlenip
  kısa alıntı onun **içine** düşünce dıştaki işaret ikiye bölünüyor ve hiçbiri
  doğru çizilmiyordu. Uzunu önce işlemek tek başına yetmedi — sorun sıralama
  değil, **her adımın metni değiştirmesiydi.**
  Çözüm: konumlar **özgün metin üzerinde** toplanır, çakışanlar elenir, sonra
  hepsi sondan başa doğru tek seferde uygulanır. **Genel kural:** aynı diziyi
  birden çok kez değiştiren bir işlemde, konumlar her adımda kayar; önce
  aralıkları hesapla, sonra uygula.

## L-022 — Kopyalar ayrışınca sürüm numarası aynı kalabilir
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-sozlesme-ve-isaretler
- **Açıklama:** §10'daki sürüm kontrolü "geride mi, ileride mi?" diye
  soruyordu. Gerçekte üçüncü bir durum çıktı: **aynı numara, farklı içerik.**
  `financer_takip` 1.4'ü `reconstructed` alanı için kullanmıştı, ana kopya
  1.4'ü `tasks/waiting/` için. İki hub da "1.4" diyordu ve yalnız numaraya
  bakan bir kontrol farkı **göremezdi**; ana kopya körü körüne üzerine
  yazılsaydı iyi bir kural sessizce silinecekti.
  **Kural:** dağıtılan kopyalarda sürüm numarası eşitliği "içerik aynı"
  demek değildir. Güncellemeden önce içerik de karşılaştırılır; ayrışma
  varsa yerel ekleme önce ana kopyaya taşınır, sürüm oradan artar
  (bu olayda `reconstructed` 1.6 olarak ana kopyaya alındı). §10'a 6. madde
  bu yüzden eklendi.

## L-023 — Kullanıcı çizilmiş metni seçer, kod ham kaynakta arar
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-sozlesme-ve-isaretler
- **Açıklama:** Seçimden üretilen kayıtların işareti çizilmiyordu; kırmızı
  hiç görünmüyor, sarı bazen görünüyordu. Render doğruydu — test, arka plan
  renginin ve alt çizginin widget ağacında olduğunu gösterdi. Sorun
  **alıntının belgede bulunamamasıydı:** kullanıcı ekrandaki *çizilmiş*
  metni seçiyor, kod *ham markdown*'da `indexOf` yapıyordu. Üç fark eşleşmeyi
  sessizce bozuyor: `**kalın**` işaretleri seçimde yok, satır sarması
  kaynakta `\n` ama seçimde boşluk, girintiler seçimde yok. Kırmızının hiç
  görünmemesi tesadüf değildi — kullanıcı kalın yazılmış bir yeri seçmişti.
  **Çözüm:** kaynağın vurgu işaretleri atılmış, boşlukları teke inmiş bir
  izdüşümünde aranıp konum geri haritalanıyor. **Genel kural:** kullanıcının
  gördüğü metinle programın işlediği metin aynı değilse, eşleştirme ikisinin
  **ortak normalleştirilmiş** biçimi üzerinden yapılır.

## L-024 — Yazma başarılı olsa da ekran kaynağı okumaya devam eder
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-sozlesme-ve-isaretler
- **Açıklama:** İşaret ancak sayfadan çıkıp tekrar girince görünüyordu. Kayıt
  hub'a gidiyordu ama ekran işaretleri **yerel kopyadan** okuyor ve yerel
  kopya bir sonraki senkrona kadar yeni kaydı bilmiyordu. Yazma yolu ile
  okuma yolu farklı kaynaklara bakınca, başarılı bir yazma bile ekranda
  görünmüyor.
  **Çözüm:** az önce oluşturulanları tutan ince bir katman; senkron yetişince
  kendini temizliyor. **Genel kural:** yazdığın yer ile okuduğun yer farklıysa,
  aradaki gecikmeyi kullanıcı görmemeli — ya okuma kaynağı hemen güncellenir
  ya da arada bir köprü katman olur.

## L-025 — Kapanan bir diyalogun `ref`'iyle iş yapılmaz
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-menu-ve-gecikme
- **Açıklama:** "Yorum eklendi" mesajı çıkıyor ama işaret ekranda hiç
  görünmüyordu. Sebep: kaydı **diyalogun kendi** `ref`'iyle oluşturuyordum ve
  diyalog kapandığı anda o `ref` ölüyordu; hub'a yazma tamamlanıyor ama yerel
  işaret katmanına ekleme sessizce düşüyordu. Aynı hata görev sayfasında da
  vardı — orada fark edilmemesinin nedeni, görevin zaten listede görünmesiydi.
  **Kural:** bir diyalog/sayfa **karar toplar**, işi yapmaz. Sonucu döndürür;
  işi, ondan uzun yaşayan ekran yapar. Kapanan bir widget'ın `ref`'i üzerinden
  yapılan her iş, "başarılı göründü ama olmadı" sınıfına girer.

## L-026 — Ağı beklemek, geri bildirimi de bekletiyor
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-menu-ve-gecikme
- **Açıklama:** İşaretleme "gönder → sonra çiz" sırasıyla çalışıyordu;
  kullanıcı sarıya basıp bir ağ turu kadar boş ekrana bakıyordu. Okurken not
  alma akışı için bu gecikme kabul edilemez — işaretlemenin tek amacı hızlı
  olmasıdır.
  Sıra tersine çevrildi: **işaret hemen çizilir, gönderim arkada sürer.**
  Kalıcı hatada işaret geri alınır. **Kural:** kullanıcının anlık geri bildirim
  beklediği eylemlerde ağ, geri bildirimin önüne konmaz; iyimser çiz, hata
  olursa geri al. Geri alınabilir olması şart — geri alınamayacak bir işlemde
  iyimserlik yalan olur.

## L-027 — Yatay araç çubuğu, sığmayanı gizler
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-menu-ve-gecikme
- **Açıklama:** Seçim menüsü `AdaptiveTextSelectionToolbar` ile yatay
  çiziliyordu ve sığmayan eylemler üç nokta arkasına düşüyordu. Ekran
  genişliğine bağlı bir davranış: aynı menü bir cihazda beş öğe gösterirken
  diğerinde ikide kesiliyor. Kullanıcı gizlenen eylemleri "yok" sayıyor.
  **Çözüm:** dikey liste (`TextSelectionToolbarLayoutDelegate` ile
  konumlandırılmış bir kart). Eylem sayısı arttıkça liste uzuyor, hiçbiri
  gizlenmiyor. **Kural:** eylem sayısı sabitse ve hepsi eşit önemdeyse,
  düzeni ekran genişliğine bağlı bırakma.

## L-028 — `WidgetSpan` satır içinde bölünmez
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-isaret-duzeltmeleri
- **Açıklama:** İşaretlenen kelimeden sonraki kelime alt satıra düşüyordu.
  Sebep: `flutter_markdown` özel builder'ın döndürdüğü **widget**'ı
  `WidgetSpan` olarak gömüyor ve WidgetSpan satır içinde bölünemeyen tek bir
  kutudur — çok kelimeli bir işaret satır sonuna sığmayınca tamamı alt satıra
  iniyor ve arkasındaki metni de itiyor.
  Stil sözlüğü yolu denendi (`styleSheet.styles[tag]`, gerçek `TextSpan`
  üretiyor) ama `MarkdownWidget` kendi `fallback.merge(seninki)` adımında
  `copyWith` ile sözlüğü **sıfırdan kuruyor** ve tanımadığı etiketleri
  düşürüyor — bu yol paket tarafından kapalı.
  Çözüm: işaret **kelime kelime** yayılıyor, aradaki boşluklar düz metin
  kalıyor; satır normal yerlerinden kırılıyor. **Genel kural:** metin akışına
  widget gömüyorsan, o widget bir kelimeden büyük olmasın.

## L-029 — Kullanıcı yazarken ekran yeniden kurulabilir
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-isaret-duzeltmeleri
- **Açıklama:** Yorum kutusu tek başına doğru çalışıyordu (test etti) ama
  gerçek kullanımda kayıt oluşmuyordu. Fark **süre**ydi: sarı/kırmızı anlık,
  yorumda kullanıcı saniyelerce yazıyor. O sırada arka plandaki yoklama
  belgeyi tazeleyince ekran widget'ı disposed oluyor, `mounted` false kalıyor
  ve onun `ref`'iyle yapılacak iş sessizce düşüyordu.
  L-025'in daha derin hâli: orada kapanan **diyalogun** ref'iydi, burada
  kapanan **sayfanın**. İkisinin ortak dersi: kullanıcı etkileşimi süren bir
  akışta hiçbir adım widget yaşam döngüsüne bağlı olmamalı.
  **Çözüm:** iş `ProviderContainer` ve `ScaffoldMessengerState` ile yapılıyor;
  ikisi de widget ağacından bağımsız yaşıyor ve diyalog açmadan **önce**
  yakalanıyor. **Tarama sorusu:** "kullanıcı burada 10 saniye durursa ve ekran
  bu arada yenilenirse ne olur?"
