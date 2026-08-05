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
- **Durum:** acik
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
     danışmanlık veritabanına bakıyor. Sürekli, bedava, bakımsız. Kullanıcı
     tarafında iki ayar açılması gerekiyor → T-009 (`waiting/`).
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
