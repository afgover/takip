# Skiller (skills)

Agent'ın bu projede edindiği, tekrar kullanılabilir yetenek ve prosedürler.
Biçim: `SYSTEM.md` §5.

---

## SK-001 — Contents API ile SHA kontrollü dosya işlemleri
- **Tarih:** 2026-07-30
- **Kaynak:** Aşama 0 araştırması (B-005)
- **Açıklama:** Dosya oluşturma/güncelleme tek `PUT /repos/{o}/{r}/contents/{path}`
  çağrısıdır (içerik base64). Güncelleme ve silmede dosyanın güncel `sha`'sı
  zorunludur; 409 dönerse dosya yeniden okunup işlem tekrarlanır (iyimser kilit).
  Klasörler arası taşıma = eski yolu DELETE + yeni yola PUT.

## SK-002 — ETag'li ucuz polling
- **Tarih:** 2026-07-30
- **Kaynak:** Aşama 0 araştırması (B-004)
- **Açıklama:** GET isteklerinde `If-None-Match: <etag>` gönderilir; içerik
  değişmediyse 304 döner ve bu cevap rate limit'ten düşmez. Böylece 30–60 sn
  aralıklı yoklama pratikte bedavadır.

## SK-003 — Dio'yu ağsız test etmek: sahte HttpClientAdapter
- **Tarih:** 2026-07-30
- **Kaynak:** B-023
- **Açıklama:** `dio.httpClientAdapter` değiştirilerek ağa çıkmadan gerçek
  istek/yanıt döngüsü test edilir: adaptör `fetch(options, requestStream, _)`
  ile isteği yakalar, test yanıtı `ResponseBody.fromString(json, status,
  headers: {...})` ile üretir. Böylece URL kurulumu, base64 kodlama, gönderilen
  gövde ve HTTP durum → hata eşlemesi uçtan uca doğrulanır. İstek gövdesi
  `requestStream`'den okunur (byte'lar birleştirilip `utf8.decode`).

## SK-004 — Sözleşme dosyası yazarken güvenli YAML üretimi
- **Tarih:** 2026-07-30
- **Kaynak:** B-025
- **Açıklama:** App'in yazdığı frontmatter'ı agent okuyacağı için üretilen YAML
  her durumda geçerli olmalı. Kural: bir skaler ancak baş/son boşluğu yoksa,
  `true/false/yes/no/null/~` gibi ayrılmış bir kelime değilse, sayıya
  benzemiyorsa ve `^[\p{L}\p{N}][\p{L}\p{N} _./-]*$` kalıbına uyuyorsa tırnaksız
  yazılır; aksi halde çift tırnak + `\` `"` `\n` kaçışı. Türkçe harfler sade
  skalerde geçerlidir, tırnak gerektirmez. Doğrulama ölçütü tek cümle:
  `parse(serialize(x)) == x` (gövdenin de boş satır biriktirmemesi dahil).

## SK-005 — Zamana bağlı mantığı sahte saatle test etmek
- **Tarih:** 2026-07-30
- **Kaynak:** B-024
- **Açıklama:** `fakeAsync` yalnız **zamanlayıcıları ve mikro görevleri**
  sahteler; `DateTime.now()` gerçek duvar saatini okumaya devam eder. Bu yüzden
  "şu ana kadar bekle" türü mantık (rate limit sonrası geri çekilme) sahte
  zamanda hiç sona ermez ve test yanıltıcı biçimde kırılır. Çözüm: üretim
  kodunda `DateTime.now()` yerine `package:clock`'un `clock.now()`'u kullanmak;
  `fakeAsync` bu saati `elapse` ile birlikte ilerletir. Yan fayda: zaman damgası
  üreten kod (`lastChangedAt` gibi) testte belirlenimli olur, aynı mikrosaniyede
  üretilen iki damganın eşit çıkma riski kalkar.

## SK-006 — Yan etkisiz izin yoklaması: yerine getirilemez istek
- **Tarih:** 2026-07-30
- **Kaynak:** B-026
- **Açıklama:** Bir yazma iznini denemeden öğrenmenin yolu yoksa (L-009),
  istek **yapısal olarak yerine getirilemez** hâlde gönderilir: Contents
  API'de `content` alanı zorunlu olduğundan, `content` içermeyen bir PUT
  izin olsa bile hiçbir dosya oluşturamaz/değiştiremez. Yetkilendirme
  reddi (403) yine de döner. Yani sinyal alınır, yan etki sıfırdır. Yanıtın
  `X-Accepted-GitHub-Permissions` başlığı hangi iznin gerektiğini söyler ve
  hata mesajında doğrudan kullanılabilir. 403'ün rate limit hâli ayrılmalıdır
  (`x-ratelimit-remaining: 0`).

## SK-007 — Var olan projede `flutter create` sonrası artık temizliği
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-b020-mac-kurulum (B-020)
- **Açıklama:** `flutter create .` var olan bir projeye platform klasörü
  eklerken yalnız istenen klasörü üretmez; şablonun tamamını uygular. Kod yazılıp
  sonra platform eklenen projelerde sıra şu:
  1. Komut öncesi çalışma ağacı **temiz** olmalı — tek ayırt edici araç `git`.
  2. Komut sonrası `git status` **ve** `git diff --stat` ayrı ayrı okunur:
     birincisi yeni dosyaları, ikincisi var olanlara dokunulup dokunulmadığını
     (`.gitignore`, `README.md`, `pubspec.yaml`) gösterir.
  3. `test/widget_test.dart` üretilmişse **silinir** — varsayılan sayaç şablonu
     projede olmayan `MyApp` sınıfını çağırır ve test paketini kırar.
  4. `.metadata` **tutulur**; Flutter'ın proje/migration dosyasıdır.
  5. `<platform>/app/src/main/` manifest'i elle okunur (→ L-010).
  6. `applicationId`/`namespace` doğrulanır: `--org` yanlışsa geri dönüş
     uygulamayı cihazdan silip yeniden kurmayı gerektirir.
  Kapanış doğrulaması: `flutter analyze` + `flutter test` (L-006).

## SK-008 — Katlanabilir cihazdan ekran görüntüsü almak
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-b020-mac-kurulum (B-020)
- **Açıklama:** Birden fazla ekranı olan cihazlarda (örn. Galaxy Z Flip)
  `adb exec-out screencap -p > x.png` **bozuk dosya** üretir: `screencap`
  "Multiple displays were found" uyarısını stdout'a basar ve uyarı PNG
  baytlarının başına karışır. Çözüm, çıktıyı cihaz üzerinde dosyaya yazıp
  çekmek: `adb shell screencap -p /sdcard/x.png && adb pull /sdcard/x.png`.
  Doğrulama: `file x.png` → "PNG image data" demeli.

## SK-009 — Var olan darboğazın altına boyut eklemek
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-b020-mac-kurulum (T-003)
- **Açıklama:** "Tek X" varsayımını "çok X"e çevirirken (tek repo → çok repo,
  tek hesap → çok hesap) kodun tamamını dolaşmak gerekmez; önce **tek
  darboğazı** bulunur: uygulamanın "o anki X" sorusunu sorduğu tek yer. Burada
  `hubConfigProvider`'dı. Yöntem: darboğazın *imzası korunur*, altına liste
  katmanı konur ve darboğaz "listenin aktif elemanı"nı yayınlar. Böylece
  tüketiciler (istemci, API'ler, yoklama, depo) ve testlerindeki override'lar
  hiç değişmez; iş, listenin kendisine ve arayüze iner.
  Darboğazdan sonra kalan gerçek iş, **bağlam taşıyan kalıcı kayıtlardır**:
  kuyruk, önbellek, ayarlar. Her biri için tek soru sorulur — "bu kayıt hangi X'e
  ait?" Cevabı kaydın içinde değilse (bizde outbox taslağında değildi) oraya
  yazılmalıdır; yoksa kayıt yanlış bağlama uygulanır (→ L-012).

## SK-010 — Ağaç farkıyla artımlı içerik senkronu
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-cevrimdisi-tarayici (B-057)
- **Açıklama:** Bir depoyu cihazda güncel tutmanın ucuz yolu, dosyaları tek tek
  "değişti mi?" diye sormak değil; **ağacı bir kez isteyip SHA'ları
  karşılaştırmaktır.** Git Trees API özyinelemeli çağrıldığında her dosyanın
  blob SHA'sını tek yanıtta verir; SHA değişmemişse içerik de değişmemiştir.
  Böylece her senkronun maliyeti = 1 ağaç isteği + **değişen dosya sayısı**
  kadar indirme. Ağaç isteği ETag'li olduğu için değişiklik yokken istek
  limitinden de düşmez (SK-002).
  Uygulama sırası önemli: **ağaç en sona yazılır.** İndirme yarıda kalırsa
  (ağ koptu, uygulama kapandı) yerel ağaç eski kalır ve bir sonraki senkron
  eksikleri yeniden dener; ağaç önce yazılsaydı sistem "her şey güncel"
  sanırdı. Ayrıca uzaktan silinen yollar yerel kopyadan düşürülür, yoksa
  kullanıcı artık var olmayan bir belgeyi listede görmeye devam eder.
  **Önbellek ile kopya ayrımı:** ETag önbelleği (B-046) gidilen yolu
  ucuzlatır — yalnız açılmış şeyi tutar. Çevrimdışı kopya ise **kasıtlı**
  indirmedir. İkisi aynı yerde tutulmaya çalışılırsa hangi kaydın niçin
  orada olduğu belirsizleşir; ayrı tutuldular.

## SK-011 — Token'ın kapsamını fazladan istek yapmadan okumak
- **Tarih:** 2026-08-04
- **Kaynak:** S-2026-08-04-guvenlik-taramasi (B-092)
- **Açıklama:** GitHub'da bir token'ın izinlerini soran uç nokta **yok**
  (L-009, B-026). Ama klasik (OAuth) token'larda GitHub, yetkilendirilmiş
  scope'ları **her kimlikli yanıtın** `X-OAuth-Scopes` başlığında kendiliğinden
  bildirir. Yani kapsam bilgisi için ayrı bir çağrı gerekmez: zaten yaptığın
  isteğin yanıtından okunur. Fine-grained token'larda başlık hiç gelmez —
  başlığın **yokluğu** da bir bilgidir (token klasik değil).
  İkinci ücretsiz sinyal token'ın kendisidir: `ghp_` klasik, `github_pat_`
  fine-grained (GitHub'ın belgelediği önekler).
  **Yorum kuralı B-026'daki gibi tek yönlü:** bu sinyaller yalnız "kapsam
  geniş" diyebilir, "kapsam dar" diyemez. Fine-grained bir token "All
  repositories" seçilerek de üretilmiş olabilir ve bunu söyleyen belgelenmiş
  bir sinyal yok (SEC-012). Tek yönlü yorum sayesinde kontrol yanlış alarm
  veremez; verseydi kullanıcı ilk yanlış alarmdan sonra uyarıyı okumaz olurdu.
  **Uyarı engellemez.** Çalışan bir token'ı reddetmek, elinde klasik token
  olan kullanıcıya uygulamayı tümden kapatırdı. Güvenlik kontrolü kullanıcıyı
  işini yapamaz hâle getirirse sonuç daha güvenli değil, kontrolsüz olur.
