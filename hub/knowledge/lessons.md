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

## L-030 — Satır içi widget, paragrafı `Wrap`'e çevirip metin akışını bozar
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-akis-ve-renk
- **Açıklama:** İşaretlenen kelimeden sonraki metin alt satıra düşüyordu.
  İlk düzeltme (işareti kelime kelime yayma) yetmedi ve **ölçüm sebebi
  gösterdi**: `flutter_markdown` bir paragrafta satır içi widget varsa
  paragrafı tek `RichText` yerine **`Wrap`** olarak kuruyor. `Wrap` çocuklarını
  atomik öğe sayar; işaretten sonraki metin tek büyük parça olduğu için kalan
  boşluğa sığmıyor ve **tamamı** alt satıra iniyor. İşaretin boyutu değil,
  **komşusunun** boyutu sorundu.
  Doğru görünen yol (stil sözlüğüne özel etiket yazmak, gerçek `TextSpan`
  üretir) paket tarafından kapalı: `MarkdownWidget` kendi merge adımında
  `copyWith` ile sözlüğü sıfırdan kurup tanımadığı etiketleri düşürüyor.
  ~~**Çözüm:** işaretli satırdaki *işaretsiz* kelimeler de kutulanıyor, böylece
  `Wrap`'in bütün öğeleri kelime boyunda ve akış normal metne benziyor.~~
  **Düzeltme (2026-08-03, L-032):** teşhis (satır içi widget → `Wrap`) doğru,
  çözüm yanlıştı. Kelime kutulama yalnız düz nesirde uygulanabildiği için
  gerçek hub metinlerinde (`**kalın**`, `` `kod` `` dolu) hemen hiç devreye
  girmiyordu; kullanıcıda hiçbir şey değişmedi. Doğru çözüm L-032'de.
  **Genel kural:** bir düzen sorununda yalnız suçlanan öğeyi değil, onunla
  aynı kapta duran komşularını da ölç. Ve bir düzeltmenin işe yaradığını
  varsayma — aynı ölçümü tekrarla.

## L-031 — Liste birleşti ama detay hâlâ tek repodan okuyordu
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-sifirdan-cozum
- **Açıklama:** Bekleyenler tüm repoların işlerini birlikte göstermeye başladı
  (B-084); financer görevleri listede göründü ama dokununca "bulunamadı"
  çıkıyordu. Sebep: liste çoklu repoya geçirilirken **detay okuma yolu**
  geçirilmemişti — `taskDetailProvider` hâlâ aktif reponun deposunu
  kullanıyordu ve o repoda o dosya yok.
  **Çözüm:** `taskRepoForSlugProvider(slug)` — görevin kendi bağlantısından
  depo üretir, `repoSlug` yoksa aktif repoya düşer. Detay, "Yaptım" bildirimi,
  işaret silme ve seçimden kayıt — dördü de artık kaydın **kendi** reposuna
  gidiyor.
  **Genel kural:** bir listeyi çok kaynaklı hâle getirirken listenin
  **kendisi** işin yarısı; o listeden açılan her yol da çok kaynaklı olmak
  zorunda. Tarama sorusu: "bu listeden nereye gidiliyor ve oralar hangi
  kaynağı varsayıyor?"

## L-032 — `flutter_markdown` satır içi çocuğu `Text` ise metin akışına kaynatır
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-sifirdan-cozum
- **Açıklama:** L-030'un çözümü işe yaramadı; kullanıcı üçüncü kez aynı
  sorunu bildirdi ("sorunları 0'dan ele al, gerekirse algoritmayı değiştir").
  Paketin kaynağı bu kez `_MarkSyntax`/`Wrap` yerine **`_mergeInlineChildren`**
  tarafından okundu ve karar noktası oradaymış: fonksiyon her satır içi çocuğu
  `_getInlineSpanFromText` ile sınıyor; çocuk `Text`/`RichText`/`SelectableText`
  ise span'ları çıkarılıp **komşularıyla tek `RichText`e kaynıyor**, değilse
  `Wrap` içinde atomik kutu olarak kalıyor.
  Yani sorun "satır içi widget olması" değil, **hangi tür** widget olduğuydu.
  `MarkdownElementBuilder` `Text.rich(...)` döndürünce işaret kendi stiliyle
  ve kendi `TapGestureRecognizer`'ıyla aynı metin akışının parçası oluyor.
  Ölçüm: işaretli ve işaretsiz metin 300px genişlikte **birebir aynı
  yükseklikte** (120.0), paragrafın tamamı **tek** `RichText`.
  Denenip elenen iki yol da kayda değer: (1) blok (`p`) çizicisiyle paragrafı
  baştan çizmek — paketin `_inlines` yığınını dengesiz bırakıp assert
  patlatıyor; (2) `styleSheet.styles`'a özel etiket yazmak — `MarkdownWidget`
  `fallback.merge(widget.styleSheet)` derken sözlüğü constructor'dan yeniden
  kuruyor ve özel anahtarlar düşüyor.
  **Genel kural:** bir kütüphane "şunu yapamıyor" diye kabullenmeden önce
  kararın **verildiği satırı** bul. Burada üç deneme, karar noktasını okumadan
  yapılmıştı; kaynağın doğru yerini okumak işi tek denemede bitirdi.

## L-033 — Parçaların hepsi yeşilken zincir kopuk olabilir
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-sifirdan-cozum
- **Açıklama:** Yorum ekleme özelliği için üç ayrı test vardı ve üçü de
  geçiyordu: menü kuruluyor mu, kutu notu döndürüyor mu, depo PUT atıyor mu.
  Buna rağmen kullanıcıda "yorum çalışmıyor"du. Testlerin hiçbiri **aralara**
  bakmıyordu; menü testi gerçek seçim bile yapmıyor, yalnız etiket sabitlerini
  doğruluyordu. Uçtan uca test yazılınca hata ilk koşuda çıktı: kutu
  `TaskMark.highlight` döndürüyordu, yani yorum sarı işaretten ayırt
  edilemiyordu — kullanıcının "çalışmıyor" dediği şey buydu.
  **Çözüm:** `test/features/selection_flow_test.dart` — gerçek metin seçimi
  (uzun bas + sürükle), gerçek menü dokunuşu, sahte GitHub'a giden PUT'un
  gövdesinin doğrulanması. Aynı dosya sarı işaret yolunu da sürüyor.
  **Genel kural:** kullanıcı "çalışmıyor" diyorsa ve parça testleri yeşilse,
  hata neredeyse kesinlikle parçaların **arasındadır**. Yeni parça testi
  yazmak yerine zinciri baştan sona süren bir test yaz.

## L-034 — Çok kaynaklı senkron, tek kaynaklı tetikleyiciyle çalışmaz
- **Tarih:** 2026-08-03
- **Kaynak:** S-2026-08-03-sifirdan-cozum
- **Açıklama:** Kullanıcı `financer_takip`'e push yaptı ve uygulamada hiçbir
  şey değişmedi. Senkron kodu **doğruydu**: `syncNow()` bağlı bütün repoları
  indiriyor. Eksik olan tetikleyiciydi — yoklama yalnız **aktif** reponun son
  commit'ine bakıyor, dolayısıyla aktif olmayan bir repoya yapılan push hiçbir
  sinyal üretmiyordu. Senkron ancak aktif repo değişince, repo değiştirilince
  ya da elle tetiklenince koşuyordu.
  L-031'in aynısı bir katman aşağıda: orada liste çok kaynaklı olmuştu ama
  listeden **açılan yol** tek kaynaklıydı; burada indirme çok kaynaklı ama
  **uyandıran sinyal** tek kaynaklı.
  **Çözüm:** yoklama bütün bağlantıların başını okuyor (`HubStatus.heads`),
  değişen slug'ları bildiriyor (`changedSlugs`) ve senkron bunu dinliyor.
  Maliyeti düşük: değişiklik yokken yanıt ETag sayesinde 304 ve istek
  limitinden düşmüyor (SK-002).
  **Genel kural:** bir yeteneği çok kaynaklı yaparken **zincirin tamamını**
  say — veriyi getiren, uyandıran, gösteren ve yazan. Biri tek kaynaklı
  kalırsa özellik "bazen çalışan" bir şeye dönüşür ki bu, hiç çalışmamaktan
  daha kötüdür: kullanıcı ne zaman güveneceğini bilemez.
  **Test notu:** ilk yazdığım uçtan uca test yanlış sebeple geçiyordu —
  senkron arka planda tetiklendiği için ölçüm o bitmeden yapılıyordu.
  Tetiklenen işi bekleyip ölçmek gerekti; "geçti" ile "doğru sebeple geçti"
  arasındaki farkı istek listesine bakarak gördüm.


## L-035 — Boş tarama sonucu, doğrulanmadan "temiz" sayılmaz
- **Tarih:** 2026-08-04
- **Kaynak:** S-2026-08-04-guvenlik-taramasi (B-091)
- **Açıklama:** `pubspec.lock`'taki 68 paketi zafiyet veritabanına sorduğumda
  cevap "0 bulgu" geldi. Bu cevabın iki farklı sebebi olabilir ve **ikisi
  ekranda birebir aynı görünür:** gerçekten açık yoktur, ya da sorgu yanlış
  kurulmuştur (ekosistem adı tutmuyor, paket adları eşleşmiyor, uç nokta
  değişmiş). İkincisinde "taradık, temiz" cümlesi olmayan bir güvence verir —
  ve güvenlik kaydına girdiği an, sonraki herkes ona dayanır.
  **Yaptığım:** aynı sorguyu bilinen açıkları olan sürümlerden kurulu bir
  **kontrol grubuyla** tekrarladım (`archive 3.3.0`, `http 0.13.0`,
  `dio 4.0.0`). Beklenen danışmanlık kayıtları döndü, yani araç çalışıyordu;
  ancak ondan sonra 0 bulguyu sonuç olarak yazdım.
  **Genel kural:** olumsuz sonuç veren her kontrole, olumlu vermesi gereken
  bir örnek de sor. Bu yalnız zafiyet taraması için değil; "hiç eşleşme yok"
  diyen her grep, "hiç kayıt yok" diyen her sorgu için geçerli. Aracın
  sustuğunu, aramanın boş döndüğünden ayırt edecek tek şey budur.
  Aynı fikrin başka görünümü L-033: parçalar yeşilken zincir kopuk olabilir.

## L-036 — Bir dalın "hep boş" varsayımı, dal genişleyince sessizce veri yer
- **Tarih:** 2026-08-04
- **Kaynak:** S-2026-08-04-guvenlik-taramasi (T-008, B-105)
- **Açıklama:** `AnnotatedDocument._create` iki dala ayrılıyordu: not boşsa
  `createNote`, doluysa görev. Boş dalda `note` parametresi hiç geçirilmiyordu
  — **gerek yoktu**, çünkü o dala yalnız not boşken giriliyordu. Doğru bir
  varsayım, tanımı gereği yazılmamış bir kural.
  Yer imi (1.12) o dalın koşulunu genişletti: artık notlu kayıtlar da oradan
  geçiyor. Kod derlendi, analyze temiz kaldı, ekranda hiçbir hata çıkmadı;
  yalnız kullanıcının yazdığı not **kaydedilmedi**. Sessiz veri kaybı.
  Testten yakalandı ("not kaybolmamalı") — dalın koşulunu değiştirirken
  yazılmış bir test olduğu için.
  **Genel kural:** bir dalın koşulunu genişletirken, o dalın gövdesinin eski
  koşula dayanan **yazılmamış** varsayımlarını da say. "Buraya yalnız X
  durumunda gelinir" bilgisi koşulda durur, gövdede durmaz; koşul değişince
  gövde uyarı vermeden yanlışa döner. Pratik karşılığı: yeni dalın taşıdığı
  her alan için "bu alan gerçekten aktarılıyor mu?" diye tek bir test yaz.

## L-037 — Bir ekranın kapsamı değişince, o ekrana **giden** metinler de değişir
- **Tarih:** 2026-08-04
- **Kaynak:** S-2026-08-04-isaretler-aktif-repo (B-106)
- **Açıklama:** İşaretler listesi aktif repoya bağlandı: sağlayıcı, ekran,
  testler, sözleşme, kurulum talimatı ve README güncellendi. Tarayıcıdaki
  **kartın alt satırı** ("tüm repolar") olduğu gibi kaldı. Kullanıcının ilk
  gördüğü yer orasıydı; kartta bir şey, ekranda başka bir şey yazıyordu.
  Kaçmasının sebebi mekanik: etiket başka bir dosyada, tek bir string
  literalinde duruyordu ve hiçbir test ona bakmıyordu. Derleyici bir metnin
  bayatladığını söyleyemez.
  **Genel kural:** bir ekranın **kapsamını** değiştirirken o ekrana giden
  yolları da say — kart/menü etiketleri, boş durum metinleri, bildirimler,
  yardım satırları. Bunlar ekranın parçası gibi düşünülmez ama kullanıcı için
  ekranın **ilk** cümlesidir.
  **Önlem:** kapsam iddiası taşıyan metinleri tek yerde tut ve teste sok.
  Tarayıcı testi artık kartın alt satırını doğruluyor, ayrıca kartlarda
  "repolar" geçmemesini şart koşuyor — kapsam iddiası kartta değil, ekranın
  kendisinde yazar. Aynı kalıbın kardeşi L-036: orada dalın koşulu genişleyince
  gövdenin varsayımı, burada ekranın kapsamı değişince etiketin iddiası bayatladı.

## L-038 — Bir kütüphanenin "nasıl sakladığını" okumadan güvenlik kaydına yazma
- **Tarih:** 2026-08-05
- **Kaynak:** S-2026-08-05-yedekleme-kurallari (B-100, SEC-009)
- **Açıklama:** SEC-009'a "token EncryptedSharedPreferences'ta tutuluyor" diye
  yazmıştım. Yanlıştı: `flutter_secure_storage` o modu ancak
  `AndroidOptions(encryptedSharedPreferences: true)` verilirse kullanıyor,
  uygulamada ise `const FlutterSecureStorage()` var. Gerçekte AES anahtarı
  Keystore'daki RSA çiftiyle sarmalanıp **sıradan** iki prefs dosyasında
  duruyor (`FlutterSecureStorage`, `FlutterSecureKeyStorage`).
  Vardığım sonuç (yedeğe düşen şifreli metin başka cihazda çözülemez) tesadüfen
  doğru kaldı, çünkü iki modda da anahtar Keystore'da. Ama **doğru sonuç,
  doğru gerekçe demek değil** — ve gerekçe yanlışken bir ayrıntı gözden kaçtı:
  dosyalar sıradan prefs olduğu için yedeğe **giriyorlar**, dolayısıyla geri
  yükleme token okumasını sessizce bozabiliyor. Bu, kararı değiştirmedi ama
  gerekçesini güçlendirdi; kaydı yazarken bilmiyordum.
  Kaçış yolu ucuzdu: paketin kaynağı `~/.pub-cache`'te duruyor ve tek bir grep
  hem varsayılan modu hem **iki** dosya adını veriyordu — ki o adlar sonradan
  yazılan dışlama kuralının doğru çalışması için zaten gerekliydi.
  **Genel kural:** güvenlik kaydına bir kütüphanenin davranışı yazılacaksa,
  o davranış **kaynağından** doğrulanır; "bu paket şöyle yapar" bilgisi
  genellikle paketin *bir* yapılandırmasına aittir ve senin kullandığın o
  olmayabilir. Aynı ailenin dersleri: L-009 (belgelenmemiş API davranışına
  dayanmak), L-035 (doğrulanmamış boş sonucu "temiz" saymak).

## L-039 — Görünmeyen uyarı, olmayan uyarıdır
- **Tarih:** 2026-08-06
- **Kaynak:** S-2026-08-06-release-imzasi (B-101)
- **Açıklama:** Release derlemesi anahtar yokken debug'a düşerken kullanıcının
  bunu bilmesi için `build.gradle.kts`'e `logger.warn` kondu. Çalıştı — Gradle
  uyarıyı üretti — ama kullanıcı hiçbir şey görmedi: `flutter build apk`
  Gradle'ın çıktısını sarmalıyor ve uyarı seviyesindeki satırları göstermiyor.
  Ölçmeseydim "uyardık" diye kayda geçecekti; uyarının **görüldüğünü** varsaymak
  ile görüldüğünü doğrulamak arasındaki fark, güvenlik gevşetmesinin gerekçesini
  tümden çürütüyordu (gevşetmeyi savunan cümle "ama uyarı çıkıyor"du).
  **Çözüm iki yere taşımak oldu:** `tool/install.sh` (kullanıcının doğrudan
  çalıştırdığı ve çıktısını okuduğu yer) ve `tool/scan.sh` (kalıcı: üretilmiş
  APK'nın sertifikasına bakıyor, yani iddiaya değil artefaktın kendisine).
  **Genel kural:** bir uyarıyı, onu **göreceği kanıtlanmış** kanala koy. Aracın
  ürettiği çıktı ile kullanıcının gördüğü çıktı aynı şey değildir; arada
  sarmalayan her katman (flutter, CI, IDE) sessizce filtreliyor olabilir.
  Uyarıya dayanan her karar, önce uyarının görüldüğünü ölçmeyi gerektirir.
  K-035'in aynı ilkesi: hatırlatıcı, kaybolmayan bir yerde durmalı.

## L-040 — Otomatik okunan bir değer, elle girilebilir olmadan tamam sayılmaz
- **Tarih:** 2026-08-06
- **Kaynak:** S-2026-08-06-kimlik-gorunur (B-108)
- **Açıklama:** Sözleşme 1.15'in kimlik katmanını yazarken `author` alanını
  `/user`'dan okunan `login`'e bağladım ve **başka hiçbir giriş yolu
  bırakmadım**. Üstelik o uç noktanın fine-grained token'la çalıştığını
  ölçmemiştim; kodu "en iyi çaba" yapıp okunamazsa sessizce geçmesini sağladım.
  İki hatanın birleşimi kötü çıktı: değer okunamadığında kullanıcının elinde
  **hiçbir çare yoktu** ve bunu göreceği bir ekran da yoktu. Kullanıcı tek
  cümlede ikisini birden gösterdi: "author yok, nickname'i bir yerde
  tanımlamadık".
  Ölçülmemiş bir kaynağa tek ayaklı bağlanmak, "en iyi çaba" diye yazılınca
  daha da sinsi oluyor: hata vermiyor, yalnız özellik hiç çalışmıyor.
  **Genel kural:** bir değer otomatik türetiliyorsa, (a) kullanıcı onu bir
  yerde **görebilmeli**, (b) türetme başarısız olduğunda **elle
  girebilmeli**. Elle giriş otomatiğe üstün gelmeli — kullanıcı bilerek farklı
  bir değer isteyebilir. Bu, L-039'un ("görünmeyen uyarı, olmayan uyarıdır")
  veri tarafındaki karşılığı.
