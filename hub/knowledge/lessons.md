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
  gider ve kullanıcı onboarding'e döner. Sürüm yükseltmesi değil, **derleme
  türü değişikliği** olduğu için kaçınılmaz.
  **Sonuç:** derleme türü değiştirilecekse kullanıcıya *önceden* söylenir
  ("token'ı yeniden gireceksin") ve mümkünse token girilmeden **önce** yapılır.
  Bu oturumda tersi yapıldı: kullanıcı sabah debug sürüme token girdi, akşam
  release kurulunca yeniden girmek zorunda kaldı.
  **Yan etki:** cihazda tutulan göç yolları (burada T-003'ün eski anahtar
  göçü) bu şekilde **sınanamaz** — kaldırma, göçün okuyacağı eski kaydı da
  siler. Göç yolu ancak birim testiyle ya da aynı derleme türünde sürüm
  yükseltmesiyle doğrulanabilir.
