# SECURITY.md — Güvenlik Logu

Bu projede güvenliğe dair yapılan taramalar, alınan önlemler, bilinen açıklar
ve yapılması gereken işler. Biçim ve kurallar: `SYSTEM.md` §12.

**Sır yazılmaz.** Kayıtlar neyin korunduğunu anlatır, korunan şeyin kendisini
değil. Token, parola veya anahtar bu dosyada hiçbir koşulda yer almaz.

---

## SEC-001 — Token yalnızca cihazın güvenli deposunda tutulur
- **Tarih:** 2026-07-30
- **Tür:** onlem
- **Durum:** kapali
- **Kaynak:** R-005, Aşama 0 tasarım oturumu
- **Açıklama:** GitHub token'ı `flutter_secure_storage` üzerinden saklanır
  (Android'de Keystore destekli). Token dosyaya, commit'e, log'a ve hata
  mesajına yazılmaz; kaynak kodda ya da hub'da hiçbir kopyası yoktur.
  Kullanıcı token'ı doğrudan cihaza girer — geliştirme sohbetine, ekran
  görüntüsüne veya repoya hiç girmez.

## SEC-002 — Token dışa yalnızca parolayla şifreli yedek olarak çıkar
- **Tarih:** 2026-08-01
- **Tür:** onlem
- **Durum:** kapali
- **Kaynak:** R-006, K-019, S-2026-08-01-token-kaliciligi
- **Açıklama:** Bağlantı yedeği PBKDF2-HMAC-SHA256 (150.000 tur) ile türetilen
  anahtarla AES-GCM kullanılarak şifrelenir. Düz metin token dışa aktarımı
  **yok** — kullanıcı istese de eklenmez, çünkü yedek metni panoya, e-postaya
  ve yedeklenen dosya sistemine düşen bir şeydir.
  Doğrulaması `test/hub/connections_backup_test.dart`: yedek metninde token
  düz hâliyle geçmiyor.

## SEC-003 — App'in yazma alanı yapısal olarak kapalı
- **Tarih:** 2026-08-03
- **Tür:** onlem
- **Durum:** kapali
- **Kaynak:** R-001, K-029
- **Açıklama:** Uygulama hub'da yalnızca `tasks/inbox/` ve `notes/` altına
  yazabilir. Kural runtime kontrolüne bırakılmamıştır: yazma kapısı yol değil
  **dosya adı** alır ve klasörü kapalı bir enum'dan (`HubFolder`) seçer, yani
  üçüncü bir klasöre yazmak tip düzeyinde imkânsızdır. Silme de aynı kapıdan
  geçer. Bir hata ya da bozuk girdi yüzünden agent'ın dosyalarının üzerine
  yazılması bu yüzden mümkün değil.
  Doğrulaması `test/hub/write_permission_test.dart`.

## SEC-004 — Token isteğin gittiği repoya göre seçilir
- **Tarih:** 2026-08-02
- **Tür:** onlem
- **Durum:** kapali
- **Kaynak:** L-019, T-003
- **Açıklama:** Çoklu repo desteğinde adres ile token farklı zamanlarda
  okunuyordu; repo değiştirildiği anda A reposunun adresine B reposunun
  token'ı gidebiliyordu. Artık token, isteğin **yolundan** çıkarılan
  `owner/repo` ile eşleşen bağlantıdan seçilir. Bir projenin token'ının başka
  bir projeye gönderilmesi böylece yapısal olarak engellendi.

## SEC-005 — Bağımlılık taraması yapılmadı
- **Tarih:** 2026-08-03
- **Tür:** yapilacak
- **Durum:** kapali
- **Kaynak:** S-2026-08-03-sifirdan-cozum
- **Açıklama:** Projede `dart pub outdated` / bilinen zafiyet taraması hiç
  koşulmadı. Doğrudan bağımlılıklar az ve tanınmış paketler (dio, riverpod,
  flutter_secure_storage, cryptography, flutter_markdown) ama bu bir denetim
  yerine geçmez. Yapılacak: sürüm ve zafiyet taraması koşulup bulguları
  `tarama` kaydı olarak buraya yazmak.
- **Nasıl giderildi:** 2026-08-04'te tarama koşuldu ve bulguları SEC-008
  olarak kaydedildi (S-2026-08-04-guvenlik-taramasi, B-091). Taramanın
  kendisi tek seferlik bir iş değil — tekrarı SEC-011'de duruyor.

## SEC-006 — Token izin kapsamı daraltılmadı doğrulanmadı
- **Tarih:** 2026-08-03
- **Tür:** yapilacak
- **Durum:** kapali
- **Kaynak:** R-005
- **Açıklama:** Token'ın fine-grained ve yalnız ilgili repolara scope'lu
  olması **kullanıcının elinde**; uygulama bunu doğrulamıyor. Token geniş
  kapsamlıysa uygulama bunu fark etmez. Yapılacak: onboarding'de token'ın
  kapsamını `/user` ve repo erişimiyle sınayıp gereğinden geniş kapsamda
  kullanıcıyı uyarmak.
- **Nasıl giderildi:** 2026-08-04, B-092. Onboarding ve bağlantı düzenleme,
  erişim doğrulamasının **aynı yanıtından** iki belgelenmiş sinyal okuyor
  (fazladan istek yok): `X-OAuth-Scopes` başlığı ve token öneki. Klasik
  (`ghp_`) bir token ya da dolu bir scope listesi görülürse kullanıcıya
  hangi scope'lara sahip olduğu ve neyi riske attığı söyleniyor, dar token
  üretme adımları veriliyor. Uyarı **engellemiyor** — çalışan bir token'ı
  reddetmek uygulamayı kullanılamaz hâle getirirdi; karar kullanıcının,
  "Vazgeç" hiçbir şeyi kaydetmiyor. Yorum B-026'daki gibi tek yönlü: kontrol
  yanlış alarm veremez. `lib/hub/token_scope.dart`, doğrulaması
  `test/hub/token_scope_test.dart` + onboarding uçtan uca testleri (SK-011).
- **Kapanmayan kısım:** "All repositories" seçilerek üretilmiş bir
  fine-grained token da hesabın tamamını kapsar ve bu kontrol onu göremez —
  ayrı kayıt: SEC-012.

## SEC-012 — Fine-grained token'ın repo genişliği ölçülemiyor
- **Tarih:** 2026-08-04
- **Tür:** acik
- **Durum:** kapali
- **Kaynak:** SEC-006, B-092
- **Açıklama:** B-092'nin kontrolü klasik token'ı kesin olarak yakalıyor ama
  fine-grained bir token "Only select repositories" ile de "All repositories"
  ile de üretilmiş olabilir; ikisi dışarıdan aynı görünüyor. İkincisi
  hesaptaki bütün repolara erişim demek, yani SEC-006'nın asıl kaygısı bu
  yoldan sürüyor.
  Ölçmenin mümkün olup olmadığı **bilinmiyor**: `GET /user/repos`'un
  fine-grained bir token'la yalnız seçili repoları mı yoksa hepsini mi
  döndürdüğü belgelenmemiş. Buraya belgelenmemiş bir davranışa dayanan tahmin
  konmadı — B-026'da tam olarak bu hata yapılmış ve `permissions.push` alanı
  token kapsamını yansıtıyor sanılmıştı (L-009).
  Yapılacak: davranışın gerçek bir token'la sınanması. Token agent'a
  verilemez (SEC-001), bu yüzden ölçümü kullanıcı yapar → `tasks/waiting/`,
  B-103.
- **Ölçüldü (2026-08-06, T-006):** `GET /user/repos` fine-grained bir token'la
  **kapsamı yansıtıyor**. Kullanıcının token'ı 1 repo döndürdü; hesapta en az
  iki repo var (`takip`, `financer_takip`), yani uç nokta hepsini değil yalnız
  token'ın kapsadığını veriyor. Belgelenmemiş davranış böylece **ölçülmüş**
  oldu ve tahmine dayanmayan bir zemin çıktı.
  **Ölçümün sınırı:** tek veri noktası ve tek yön. Kanıtlanan şey "dar token az
  repo görür"; "All repositories token'ı hepsini görür" doğrudan sınanmadı,
  filtrelemenin varlığından çıkarıldı. Bir kontrol kurulacaksa yorumu bu yüzden
  tek yönlü olmalı (B-026'daki kural).
  **Kayıt neden hâlâ `acik`:** ölçüm mümkün olduğu anlaşıldı ama uygulamada bir
  kontrol **yok**. Kapanması B-103'e bağlı.
- **Kapatıldı (2026-08-15, [B-103](BACKLOG.md#B-103)):** kontrol uygulamada.
  Kaydın başlığındaki iddia — "repo genişliği ölçülemiyor" — artık geçerli
  değil: genişlik ölçülüyor ve uygulama ölçtüğünü kullanıyor.
  **Nasıl giderildi:** token'ın *nasıl üretildiğini* tespit etmeye çalışmaktan
  vazgeçildi; onun yerine **fazla erişim** ölçülüyor. `N` = token'ın gördüğü
  repo sayısı (`GET /user/repos`, sayfalama başlığından tek istekle), `K` = o
  token'la bağlı hub sayısı. `N > K` → uyarı. Eşik keyfi bir sabit değil,
  uygulamanın kendi ihtiyacı: B-056 aynı token'ı birden çok hub'da kullanmayı
  teşvik ettiği için "1'den fazlaysa uyar" yanlış alarm üretirdi.
  Yorum **tek yönlü** kaldı (B-026, L-009): kontrol yalnız `N > K` durumunda
  konuşur ve söylediği şey token'ın modu değil, erişimin gözlenen genişliğidir.
  "Bu token dar" cümlesi hiçbir yoldan çıkmıyor; "ölçülemedi" ile "fazla
  erişim görünmüyor" ayrı gösteriliyor (L-035'in kuralı).
  Koştuğu yerler: bağlantı kurulurken (onboarding + bağlantı ekranı) ve
  Ayarlar'da elle tetiklenen "Token kapsamı" satırı.
  **Kalan sınır — kapanmadı, etrafından dolaşıldı:** "All repositories" ile
  üretilmiş bir token, hesapta `K`'dan fazla repo yokken dar bir token'dan
  hâlâ ayırt edilemez (N = K → kontrol susar). Böyle bir token hesaba repo
  eklendikçe **sessizce genişler**. Ayarlar'daki elle tetiklenen ölçümün
  sebebi tam olarak bu: bağlantı gününde doğru olan cevap bir ay sonra yanlış
  olabilir. Düzenli koşan bir kontrol yazılmadı — "ne zaman koştu" durumunu
  diske yazmayı gerektirirdi ve tetikleyicisi henüz oluşmadı.

## SEC-007 — Hub içeriği cihazda şifresiz duruyor
- **Tarih:** 2026-08-03
- **Tür:** acik
- **Durum:** acik
- **Kaynak:** B-057 çevrimdışı kopya
- **Açıklama:** Çevrimdışı kopya (`shared_preferences`) hub'ın markdown
  içeriğini düz metin tutuyor. Token orada değil (SEC-001), ama proje
  içeriği cihaz ele geçerse okunabilir. Risk kabul edilmiş durumda: içerik
  zaten GitHub'da duruyor ve depolama uygulama korumalı alanında. Kararın
  değişmesi gereken durum: hub'a gizli sayılacak içerik girmesi.
- **2026-08-04 eki:** "Uygulama korumalı alanında" varsayımı eksikmiş —
  Android otomatik yedeklemesi o alanı kullanıcının Google hesabına
  kopyalıyor (SEC-009). Kabul edilen risk, kabul edildiğinde bilinenden
  geniş; kapsamı SEC-009 kapanınca cihazla sınırlı hâle gelir.

## SEC-008 — Bağımlılık, sır ve Android yapılandırma taraması
- **Tarih:** 2026-08-04
- **Tür:** tarama
- **Durum:** kapali
- **Kaynak:** SEC-005, B-091, S-2026-08-04-guvenlik-taramasi
- **Açıklama:** Tam çıktı:
  [`artifacts/S-2026-08-04-guvenlik-taramasi/bagimlilik-ve-yapilandirma-taramasi.md`](artifacts/S-2026-08-04-guvenlik-taramasi/bagimlilik-ve-yapilandirma-taramasi.md).
  Özet:
  (1) `pubspec.lock`'taki 68 paketin tamamı OSV'ye (Pub ekosistemi) soruldu →
  **bilinen zafiyet yok**. Boş sonucun sorgu hatasından gelmediği, bilinen
  açıkları olan sürümlerden kurulu bir kontrol grubuyla doğrulandı.
  (2) Sürüm güncelliği: `flutter_secure_storage` (9.2.4 → 10.3.1) ve
  `flutter_riverpod` (2.6.1 → 3.4.2) bir ana sürüm geride; ikisi de bilinen
  bir açık taşımıyor ama ana sürüm farkı, bir danışmanlık çıktığında yamayı
  "sürüm yükselt"ten "kırıcı değişikliği karşıla"ya çeviriyor. Flutter SDK
  (3.35.4, 2025-09-16) ~11 aylık; TLS yığını motorun içinde olduğu için paket
  taraması o yüzeyi görmüyor.
  (3) Sır taraması: çalışma ağacı **ve git geçmişinin tamamı** token/anahtar
  desenlerine karşı tarandı → eşleşme yok (SEC-001'in bağımsız doğrulaması).
  (4) Android izinleri yalnız `INTERNET`; düz metin HTTP kapalı.
  İki bulgu çıktı: SEC-009 (otomatik yedekleme) ve SEC-010 (release imzası).
  **Sınır:** tarama koştuğu **anın** veritabanına göredir; tek seferlik bir
  onay değildir (→ SEC-011).

## SEC-009 — Android otomatik yedeklemesi cihazdaki şifresiz kopyayı buluta taşıyor
- **Tarih:** 2026-08-04
- **Tür:** acik
- **Durum:** kapali
- **Kaynak:** SEC-008 Bulgu A, SEC-007
- **Açıklama:** `AndroidManifest.xml`'de yedekleme kuralı tanımlı değildi, yani
  Android varsayılanı (`allowBackup=true`) geçerliydi: uygulamanın özel veri
  alanı Auto Backup ile kullanıcının Google hesabına kopyalanabiliyordu. O
  alanda SEC-007'de kayıtlı **şifresiz hub kopyası** duruyor (hub'ın bütün
  markdown içeriği). SEC-007'de kabul edilen risk "cihaz ele geçerse okunabilir"
  idi; yedekleme bu sınırı genişletip korumayı Google hesabının güvenliğine
  devrediyordu.
- **Düzeltme (2026-08-05):** İlk kayıtta "token EncryptedSharedPreferences'ta"
  yazıyordu — **yanlış.** Uygulama `const FlutterSecureStorage()` kullanıyor,
  `AndroidOptions` vermiyor, yani o mod açık değil. Gerçek durum: AES anahtarı
  Keystore'daki RSA çiftiyle sarmalanıp **sıradan** iki prefs dosyasında
  tutuluyor (`FlutterSecureStorage`, `FlutterSecureKeyStorage`).
  Sonuç değişmiyor — Keystore anahtarı dışa aktarılamadığı için yedeğe düşen
  şifreli metin başka cihazda çözülemez, yani token sızmıyor. Ama ilk kayıtta
  atlanan bir yan etki var: dosyalar sıradan prefs olduğu için **yedeğe
  giriyorlar**, geri yüklendiğinde uygulama çözemediği bir veriyle karşılaşıyor.
  Yedekleme token'ı yalnız kurtarmıyor değil, okumasını sessizce de bozabiliyor.
- **Nasıl giderildi:** B-100, sözleşme dışı (yalnız Android yapılandırması).
  `allowBackup="false"` yerine **ayrımlı** çözüm seçildi:
  `res/xml/data_extraction_rules.xml` (API 31+) buluta **hiçbir şey**
  göndermiyor ama cihazdan-cihaza aktarımı açık bırakıyor; aktarımdan yalnız
  yukarıdaki iki token dosyası çıkarıldı (taşınsalar çözülemezlerdi).
  `res/xml/backup_rules.xml` (API 24–30, `minSdk` 24) aynı kuralı eski
  sürümlerde uyguluyor — orada cihaz aktarımı diye bir ayrım yok. Yalnız biri
  tanımlansaydı cihazların bir bölümünde açık sessizce açık kalırdı.
  Doğrulama üç adımda yapıldı, iddiaya dayanmadan: (1) `test/android/
  backup_rules_test.dart` iki dosyayı ve manifest bağlarını okuyor,
  (2) birleştirilmiş **release** manifestinde iki öznitelik de görüldü,
  (3) `aapt2 dump xmltree` ile derlenmiş APK'nın manifestinde doğrulandı.
  Üçüncü adım gerekliydi: L-010'da kaynak manifestte olan bir şeyin release
  çıktısında olmadığı görülmüştü.
  **Kalan sınır:** bu ayarlar `adb backup` benzeri yerel yedeklemeyi ve root'lu
  bir cihazı kapsamaz; SEC-007'nin "cihaz ele geçerse okunabilir" kabulü
  olduğu gibi duruyor. Kapanan şey **buluta çıkma** yoludur.

## SEC-010 — Release derlemesi debug anahtarıyla imzalanıyor
- **Tarih:** 2026-08-04
- **Tür:** acik
- **Durum:** acik
- **Kaynak:** SEC-008 Bulgu B
- **Açıklama:** `android/app/build.gradle.kts`'in release bloğu Flutter
  şablonundan geldiği gibi duruyor ve **debug imza yapılandırmasını**
  kullanıyor. Debug anahtarı Android SDK ile gelen, herkeste aynı olan bilinen
  bir anahtardır. Bugünkü etkisi sınırlı — APK yalnız `tool/install.sh` ile
  geliştiricinin kendi cihazına kuruluyor. Ama B-097'nin planı "GitHub
  Releases'ta APK" diyor; o adımda üçüncü biri aynı paket adıyla, aynı bilinen
  anahtarla imzalanmış bir APK üretip **güncelleme olarak kurulabilir** hâle
  getirebilir. Yapılacak: yayımlanacak yapı kendi anahtarıyla imzalanır, anahtar
  repoya girmez (`.gitignore` `*.keystore`, `*.jks` ve `key.properties`'i
  dışarıda tutuyor). **B-097'nin (APK yayımlama) ön koşuludur.** → B-101
- **2026-08-06 durumu:** Yapılandırma yazıldı ve hazır bekliyor —
  `android/key.properties` konulduğu an release kendi anahtarıyla imzalanır.
  Anahtar üretimi kullanıcıda (parola gerektiriyor, T-010) ve kullanıcı
  kararıyla **ertelendi**; kayıt bu yüzden `acik` kalıyor.
  Erteleme bilinçli ve sınırı belli: bugünkü risk düşük (APK yalnız
  geliştiricinin kendi cihazına kuruluyor), açık hâle geldiği an APK'nın bu
  makineden çıktığı andır. **B-097 kapanmadan bu kayıt kapanmalı.**
  Hatırlatıcı derleme çıktısına bırakılmadı: `flutter build` Gradle'ın uyarısını
  yutuyor (L-039). Bunun yerine `tool/install.sh` her release kurulumunda
  yazıyor ve `tool/scan.sh` üretilmiş APK'nın **sertifikasına** bakıp bulgu
  veriyor — iddiaya değil, artefaktın kendisine.
- **2026-08-13 durumu:** B-097 kapandı (repo public) ama bu kayıt `acik`
  kalıyor ve yukarıdaki "**B-097 kapanmadan bu kayıt kapanmalı**" cümlesi
  **yanlış hedefe bağlanmış**tı. Ayrım şu: tehlikeli olan repo görünürlüğü
  değil, **APK'nın bu makineden çıkması**. B-097 ikisini tek maddede
  topluyordu (sıra: repo → yazı → Releases'ta APK); gerçekleşen yalnız
  birincisi. Public repo tek başına debug anahtarlı bir APK'yı kimsenin
  eline vermiyor, dolayısıyla bugün risk artmadı.
  **Bağlayıcı koşul yeniden yazılıyor:** bu kayıt kapanmadan
  **Releases'a APK konmaz** (B-097'nin kapanması değil, APK adımı).
  Tetikleyici T-010'da duruyor ve kullanıcı kararıyla ertelenmiş durumda.

## SEC-013 — Repo public yapıldı: hub içeriği ve commit geçmişi herkese açık
- **Tarih:** 2026-08-13
- **Tür:** karar
- **Durum:** kapali
- **Kaynak:** B-097, T-011, S-2026-08-13-durum-ozeti
- **Açıklama:** `afgover/takip` public yapıldı (kullanıcı). Doğrulandı:
  `api.github.com/repos/afgover/takip` → `"private": false`; §10 zincirinin
  kendi komutu (`curl .../main/hub/SYSTEM.md`) 200 dönüyor ve yerel kopyayla
  fark yok. Kararın bilerek kabul edilen veri sonuçları:
  (1) **Bütün `hub/` içeriği görünür** — oturum kayıtları (kullanıcının kendi
  mesajları dâhil), artifact'ler, notlar, kararlar ve bundan sonra yazılacak
  her şey. B-097 bunu "sessiz bozulma" riski olarak yazmıştı: public bir hub'da
  dürüst not almak zorlaşır. Risk teknik değil davranışsal ve ölçülemez;
  kaydın burada durmasının sebebi, ileride not alma dilinin değiştiği fark
  edilirse sebebinin bilinmesi.
  (2) **Geçmiş commit'lerdeki e-posta artık halka açık.** 2026-08-06'da
  `git config user.email` noreply'a çevrildi ama geçmiş yeniden yazılmadı
  (kullanıcı kararı: hub'ın SHA atıfları ölmesin). O tarihe kadarki 172
  commit'te `afgover@gmail.com` görünür — bunlar zaten GitHub'ın public commit
  API'sinde standart olan bir veri ve geri alınamaz sayılmalı.
  (3) **Açık güvenlik kayıtları da yayımlandı** (SEC-007, SEC-010, SEC-012).
  Bilinçli: hiçbiri uzaktan sömürülebilir değil ve projenin değeri kendi
  açıklarını dürüstçe listelemesinde (K-032).
  (4) **Geri dönüşü yok sayılır.** Private'a çevirmek mümkün, ama fork'lanan,
  klonlanan ve indekslenen içerik geri gelmez.
- **Sır durumu:** görünürlük değişmeden önce çalışma ağacı **ve git geçmişinin
  tamamı** token/anahtar deseni için tarandı ve temizdi (SEC-008, `tool/scan.sh`).
  Bu tarama 2026-08-04 tarihlidir; o günden bu yana eklenen commit'ler o
  taramanın kapsamında **değildir**. Sınır bilinçli yazıldı: "taradık" cümlesi
  tekrarlanmazsa sessizce yanlışa döner (SEC-011).
- **Bundan sonrası için değişen şey:** repo public olduğu için bir sırrın
  yanlışlıkla commit'lenmesi artık **geri alınamaz** bir olaydır — private'ta
  `git push --force` ile geçmişi temizlemek çare olabiliyordu, public'te
  değil (klon, fork, indeks). Sır taramasının düzenli koşması bu yüzden
  önceki günden daha kritik; tetikleyici değişmedi (30 günlük `tarama`
  kaydı, §12) ama sonucu ağırlaştı.
- **Kayıt neden `kapali`:** bu bir açık değil, sonuçları belgelenmiş bir
  **karar**. Kararın kendisi uygulandı ve doğrulandı; açık kalan bir iş yok.

## SEC-011 — Tarama tekrarlanmıyor
- **Tarih:** 2026-08-04
- **Tür:** yapilacak
- **Durum:** kapali
- **Kaynak:** SEC-008
- **Açıklama:** SEC-008 koştuğu **anın** danışmanlık veritabanına göre
  temizdi; yarın yayımlanacak bir danışmanlık o sonucu geçersiz kılar. Tek
  seferlik tarama, geçtiği gün dışında hiçbir şey garanti etmez ve "taradık"
  cümlesi zamanla sessizce yanlışa döner. Yapılacak: taramanın hangi aralıkla
  ve nasıl tekrarlanacağına karar vermek (ölçeğe uygun en ucuz yol: her sürüm
  öncesi elle koşum; alternatifi GitHub Actions'ta zamanlanmış iş). Karar
  verilene kadar bu kayıt açık kalır. → B-102
- **Nasıl giderildi (2026-08-05, B-102):** Tek bir mekanizma yetmiyordu —
  SEC-008 dört parçaydı ve otomatikleşme dereceleri farklı. **Katmanlı** karar
  verildi:
  1. **Bilinen zafiyet → Dependabot.** GitHub'ın Dependabot'u `pub` ekosistemini
     destekliyor (güvenlik güncellemeleri dahil, private repolarda da) ve aynı
     danışmanlık veritabanına bakıyor. Sürekli, bedava, bakımsız.
     **2026-08-06: açıldı** — dependency graph, alerts ve security updates
     (T-009). Yani yeni bir danışmanlık çıktığında haber gelecek ve açık bulunan
     paket için otomatik PR açılacak. Ayarın açık olduğu agent tarafından
     ölçülmedi (bu makinede `gh` yok, token yok); kayıt kullanıcı bildirimine
     dayanıyor.
  2. **Kalan üç parça → `tool/scan.sh`.** Sır taraması ve Android
     yapılandırması için otomatik bir gözcü yok (secret scanning private repoda
     ücretli); zaten SEC-009 ve SEC-010 tam olarak oradan çıkmıştı. Tek komut.
  3. **Tetikleyici takvim değil, kaydın kendisi.** Agent her oturum açılışında
     bu dosyadaki son `tarama` kaydının tarihine bakıyor; **30 günden eskiyse**
     taramayı yeniliyor (sözleşme 1.14 §12, `AGENT_PROTOCOL.md` madde 4).
     Hatırlatma hub'ın içinde durduğu için ayakta tutulacak ikinci bir sistem
     yok — ve unutulduğunda da görünür kalıyor.
  Zamanlanmış GitHub Actions elendi: 1. maddeyi zaten Dependabot karşılıyor,
  geriye kalanı otomatikleştirmek için eklenecek workflow'un kendisi bakım
  isteyen bir parça olurdu.
  **Script'in içine gömülen kural (L-035):** `scan.sh`, bilinen açığı olan
  sürümlerden bir **kontrol grubunu** da soruyor. Kontrol boş dönerse tarama
  kendini geçersiz ilan edip `2` ile çıkıyor ve "temiz" demiyor. Ağa
  ulaşılamadığında da aynı: koşmamak, temiz olmak değildir. Bu davranış bozuk
  bir ekosistem adıyla sınandı.

## SEC-014 — Tarama: bağımlılık, sır ve Android yapılandırması (2. koşum)
- **Tarih:** 2026-08-21
- **Tür:** tarama
- **Durum:** kapali
- **Kaynak:** SEC-011, [Aşama 5](EVOLUTION.md), S-2026-08-21-guvenlik-taramasi
- **Açıklama:** `tool/scan.sh`'in ilk **otomatik** koşumu (SEC-008 elle
  koşulmuştu). Tam çıktı:
  [`artifacts/S-2026-08-21-guvenlik-taramasi/guvenlik-taramasi.md`](artifacts/S-2026-08-21-guvenlik-taramasi/guvenlik-taramasi.md).
  Özet:
  (1) `pubspec.lock`'taki **70 paket** OSV'ye soruldu → **bilinen zafiyet yok**.
  Boş sonuç, bilinen açıkları olan sürümlerden kurulu kontrol grubuyla
  doğrulandı: **3/3** beklenen bulgu geldi (L-035). Paket sayısı 68 → 70; fark
  aynı gün yapılan yükseltmeden ([B-136](BACKLOG.md#B-136)) geliyor, yani
  yükseltme yeni bir zafiyet getirmedi.
  (2) Sır taraması: çalışma ağacı **ve git geçmişinin tamamı** temiz.
  (3) Android: yedekleme kuralları yerinde (SEC-009'da **gerileme yok**),
  izin listesi hâlâ tek — `INTERNET`.
  (4) Sürüm güncelliği (bulgu değil, bilgi): geride kalan üç doğrudan
  bağımlılığın üçünün de gerekçesi yazılı — iki major
  [B-138](BACKLOG.md#B-138)'de tetikleyicisiyle ertelendi, `intl` SDK'nın
  `flutter_localizations` paketi tarafından tam eşitlikle sabitli.
  **İki bulgu çıktı, ikisi de yeni değil** — ikisi de SEC-010 → B-101 → T-010
  zincirinin görünümü: (a) imza anahtarı üretilmediği için release derlemesi
  debug anahtarıyla imzalanıyor, (b) 2026-08-13'te üretilmiş release APK bu
  makinede o imzayla duruyor. (b) `build/` altında ve `.gitignore`'da, yani
  repoya hiç girmedi; riski yalnız "paylaşılırsa".
  **Tetikleyici takvim değildi:** 30 günlük eşik (~2026-09-03) dolmadan,
  Aşama 5'in üçüncü kapanma koşulu olarak koşuldu.
  **Sınır (değişmedi):** tarama koştuğu **anın** veritabanına göredir (SEC-011);
  Flutter SDK 3.35.4 ~11 aylık ve TLS yığını motorun içinde olduğu için paket
  taraması o yüzeyi görmüyor.

## SEC-015 — Release APK debug imzasıyla makineden çıktı (Drive)
- **Tarih:** 2026-08-28
- **Tür:** karar
- **Durum:** kapali
- **Kaynak:** [SEC-010](#SEC-010), [SEC-014](#SEC-014),
  [B-101](BACKLOG.md#B-101), T-010, S-2026-08-28-apk-drive
- **Açıklama:** `5f3b6db`ten derlenen release APK, kullanıcının Google Drive
  hesabına (`Drive'ım/Takip APK/takip-2026-08-28-5f3b6db.apk`) yüklendi.
  İmza hâlâ Android SDK'nın **debug** anahtarı (`CN=Android Debug`, SHA-1
  `f4994730…`) — SEC-010 açık, T-010 bekliyor.
  **Bu, SEC-014'ün (b) bulgusundaki "riski yalnız paylaşılırsa" koşulunun
  gerçekleşmesidir** ve T-010'un erteleme gerekçesindeki tetikleyicinin
  kendisidir ("APK'nın bu makineden çıkacağı gün"). Karar bilerek verildi:
  - **Kabul edilen risk:** anahtar herkeste aynı olduğu için, dosyaya erişebilen
    biri aynı anahtarla imzalanmış sahte bir "güncelleme" üretip kurulu sürümün
    üstüne — veri kaybı olmadan — kurdurabilir. Kapsam bugün dar: dosya
    kullanıcının kendi Drive'ında, paylaşım bağlantısı verilmedi.
  - **Neden şimdi düzeltilmedi:** anahtar değişimi kurulu sürümün kaldırılıp
    yeniden kurulmasını şart koşar; o gün cihazdaki repo bağlantıları ve
    token'lar gider (L-014'ün ölçtüğü kayıp). Bedel bilinçli olarak
    ertelendi.
  - **Tetikleyici güncellendi:** bir sonraki eşik "makineden çıkma" değil,
    **üçüncü bir kişiye ya da halka açık bir yere verilme** (Releases, store,
    paylaşım bağlantısı). O adımdan önce T-010 kapanmalı.
  Yüklenen dosyanın SHA-256'sı kaynak APK'nınkiyle doğrulandı
  (`10bad8cb…`); yanına `OKU.txt` konuldu ve imza uyarısı orada da yazılı.

## SEC-016 — Bekçi ve denetçi script'lerinin güvenlik incelemesi
- **Tarih:** 2026-08-29
- **Tür:** tarama
- **Durum:** kapali
- **Kaynak:** S-2026-08-28-apk-drive, [P-017](PLAN.md#P-017), kullanıcı isteği
- **Açıklama:** Dağıtım kararından önce `tool/hub-guard.sh`, `tool/audit.sh`
  ve hook bağlantısı (`.claude/settings.json`) güvenlik gözüyle incelendi.

  **Güvenlik sözleşmesi (üç script için ölçülen davranış):**
  | script | okur | yazar | ağ | çalıştıran |
  |---|---|---|---|---|
  | `hub-guard.sh` | git durumu | yalnız `$TMPDIR`'a işaret dosyası | **yok** | harness (hook) |
  | `audit.sh` | hub dosyaları + git grafiği | **hiçbir şey** | **yok** | ajan (madde 4b) |
  | `scan.sh` | pubspec, git geçmişi | **hiçbir şey** | yalnız OSV sorgusu | ajan (madde 4) |

  **Bir bulgu çıktı ve kapatıldı:** `hub-guard.sh` stdin'deki `session_id`'yi
  süzmeden bir dosya yoluna koyuyordu; `../` taşıyan bir stdin, işaret
  dosyasını `$TMPDIR` dışına yazdırabilirdi (var olan bir dosyayı
  sıfırlayabilirdi). stdin'i harness'in kendisi verdiği için sömürü,
  harness'in ele geçmesini gerektirirdi — olasılık düşük; ama script
  dağıtılacak ve düzeltme tek satır: SID artık `[A-Za-z0-9._-]`e süzülüp 64
  karakterde kesiliyor. Sızmadığı ölçüldü (kaçış denemesi `$TMPDIR` içinde
  kaldı). Ek olarak `python3` yokken JSON kaçışı yapılmadan çıktı üreten
  yedek yol da kaçış yapar hâle getirildi.

  **Public repo sorusu kapandı:** `takip` public olduğu için ".claude
  hook'unu klonlayan herkeste çalışır mı" sorusu dün açık bırakılmıştı.
  Belgelerden doğrulandı: proje hook'ları **workspace trust** onayı olmadan
  koşmaz — klonlayan kişi klasöre güven vermeden hook çalışmaz, ve `/hooks`
  menüsü kurulu her hook'u kaynağıyla gösterir. Dokuz hub reposu zaten
  private (ölçüldü); public olan yalnız `takip`.

  **Bilinen ve kabul edilen sınır:** iki script de repo içeriğinden gelen
  metni (dosya adları, frontmatter) çıktısına koyar ve bu çıktı ajanın
  bağlamına girer. Bu, prompt injection yüzeyidir — ama **yeni değildir**:
  ajan aynı repo içeriğini zaten doğrudan okuyor. Script'ler yüzeyi
  genişletmiyor; kural aynı kalıyor: çıktı veridir, talimat değildir.

## SEC-017 — Tarama: public repoda kişisel veri + güvenlik (3. koşum)
- **Tarih:** 2026-08-29
- **Tür:** tarama
- **Durum:** kapali
- **Kaynak:** S-2026-08-29-public-tarama, kullanıcı isteği
- **Açıklama:** Repo public olduğu için üç eksende tarandı.
  **(1) Güvenlik (`tool/scan.sh`):** 70 pakette bilinen zafiyet yok (kontrol
  grubu 3/3 doğrulandı); sır taraması çalışma ağacında ve git geçmişinin
  tamamında temiz; Android yedekleme kuralları yerinde, izin listesi tek
  (`INTERNET`). İki bulgu çıktı, ikisi de bilinen SEC-010 → B-101 → T-010
  zinciri (debug imza + elde duran APK).
  **(2) Kişisel veri (çalışma ağacı):** sır yok; üç *tanımlayıcı* sınıfı var —
  cihaz serisi (3 oturum kaydında), e-posta (referans arşivinin içeriğinde,
  2 yer; commit yazarlığı zaten SEC-013 kararı), macOS kullanıcı adı yolları
  (arşivde ~5 dosya). Telefon/TC/IBAN kalıbı **yok**. Uç temizliği yapıldı:
  testteki gerçek e-posta örnek adrese, `tool/install.sh`'taki gerçek seri
  yer tutucuya çevrildi. Kayıtlardaki tanımlayıcılar için karar kullanıcıya
  bırakıldı — "silme yok" kuralının tek meşru istisnası kişisel veridir ve
  istisnayı agent kendi başına kullanmaz: T-019 (`waiting/`, üç seçenek).
  **(3) Hub güncelliği:** kurulum talimatları (TR+EN) 1.21'e göre yazılmıştı;
  satır satır yeniden yazılmadı, 1.22–1.27 eklerini özetleyen tarihli sürüm
  notu kondu ve `contract:` alanı 1.27 yapıldı — yanlış "1.27'ye göre
  yazıldı" iddiası kurulmadı.
  **Sınır:** tarama koştuğu anın kalıp listesine ve danışmanlık veritabanına
  göredir; kişisel veri taraması kalıp temellidir (ad/e-posta/seri/yol/telefon/
  TC/IBAN) — kalıba girmeyen serbest metin ifşasını görmez.
