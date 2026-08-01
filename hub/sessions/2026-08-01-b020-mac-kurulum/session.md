---
id: S-2026-08-01-b020-mac-kurulum
date: 2026-08-01
status: closed
topics: [kurulum, flutter, android, b020, b015, b034, coklu-repo]
artifacts: []
tasks_touched: [T-003]
---

# Oturum: B-020 — Mac'te Flutter kurulumu ve ilk cihaz koşumu

## Özet
Projenin en uzun süren eşiği aşıldı: uygulama **ilk kez gerçek bir cihazda
çalıştı** ve ilk gerçek görev döngüsü uçtan uca koştu.

Kurulum beklenenden kısa sürdü — Flutter 3.35.4 ve Android Studio makinede
zaten kuruluydu, SDK kurulumu gerekmedi. `android/` üretildi
(`us.gover.takip`, domain `gover.us`), sürüm sıçraması (3.27.1 → 3.35.4) tek bir
deprecation'la atlatıldı. Üretilen manifest'te INTERNET izni eksikti: debug'da
hiç görünmeyecek, yalnızca release'te patlayacak bir tuzak. Bulundu, giderildi
ve release APK üzerinde `aapt2` ile doğrulandı (L-010).

Token üretildi (B-015) ve uygulama `afgover/takip`'e bağlandı — B-022'nin okuma
doğrulamasıyla B-026'nın yazma yoklamasının gerçek GitHub'a karşı ilk geçişi.
Ardından kullanıcı telefondan görev ekledi; dosya sözleşmeye birebir uygun
şekilde inbox'a düştü, agent T-003 atayıp `inbox → active → done` geçirdi ve
sonuç app'te "Tamamlananlar"da göründü (B-034).

Görevin içeriği gerçek bir istekti — *"birden çok repo eklemek için arayüzü
geliştir"* — ve kullanıcının kararıyla aynı oturumda uygulandı. Çoklu repo,
uygulamanın "o an hangi repodayız" darboğazının (`hubConfigProvider`) **altına**
bir katman olarak kondu; böylece istemci, API'ler, yoklama ve görev deposu hiç
değişmedi (SK-009). Asıl iş bağlam taşıyan kalıcı kayıtlarda çıktı: outbox
repo-farkında yapıldı, yoksa çevrimdışı yazılan görev yanlış projeye düşerdi
(L-012). 191 → **219 test**, `analyze` temiz.

Kapanışta release derlemesi kuruldu ve çalıştığı doğrulandı; ancak derleme türü
değişikliği uygulamayı kaldırdığı için token silindi (L-014) — sıralama hatası,
release token'dan önce kurulmalıydı. Kullanıcının token'ı yeniden girmesi
gerekiyor; oturum kapanırken bu doğrulanamadı.

**Kapananlar:** B-015, B-020, B-034, B-035, T-003 · **Faz 1, Faz 2, Faz 3** ·
**Aşama 2**. Aşama 4 (Günlük Kullanım) açıldı; sıradaki iş B-052.

## Kayıt

### Kullanıcı
> takip projesinde devam ediyoruz. Önce şu üç dosyayı oku:
>
> - hub/AGENT_PROTOCOL.md   (kayıt prosedürü — uyman zorunlu)
> - hub/artifacts/reference/kurulum-ve-devir.md   (devir notu, nerede kaldığımız)
> - hub/BACKLOG.md   (açık maddeler)
>
> Bugün B-020'yi yapıyoruz: Mac'te Flutter kurulumu, android/ klasörünün
> üretilmesi ve uygulamanın ilk kez cihazda çalıştırılması. Token'ı (B-015)
> ben üreteceğim, sırası gelince söyle.
>
> https://github.com/afgover/takip
>
> reposu

### Agent
Çalışma klasörü (`~/Desktop/takip`) boştu; repo `main`'den klonlandı. Üç dosya
okundu, `SYSTEM.md` (sürüm 1.2) ve hub yapısı kontrol edildi.
`tasks/inbox/` boş — yeni görev yok.

Ortam taraması sonucu **beklenenden iyi**: Flutter SDK ve Android Studio zaten
kurulu, ayrıca kurulum gerekmiyor.

| Bileşen | Durum |
|---|---|
| Flutter | 3.35.4 stable / Dart 3.9.2 — `~/development/flutter` |
| Android Studio | kurulu (`/Applications`) |
| Android SDK | `~/Library/Android/sdk` mevcut |
| Java | Temurin 25.0.2 LTS |
| Xcode | kurulu (bu aşamada gerekmiyor, K-009) |
| Homebrew | yok (Flutter zaten kurulu olduğu için gerekmedi) |
| Mimari / OS | arm64 / macOS 26.5.1 |

İki risk not edildi: (1) Flutter 3.35.4, `pubspec.lock`'un çözüldüğü 3.27.1 /
Dart 3.6'dan yeni — `pub get` lock'u güncelleyebilir, analiz/test kırılırsa ilk
şüpheli budur (devir notu §2.4). (2) Disk boş alanı düşük görünüyor
(~2.6 GB) — Gradle ilk derlemede bundan fazlasını indirebilir, `flutter doctor`
ile birlikte doğrulanacak.

`flutter doctor -v`: Android toolchain (SDK 36.1.0, lisanslar kabul edilmiş) ve
Android Studio 2025.3 yeşil. Tek uyarı CocoaPods eksikliği — iOS'a ait, K-009
gereği bu aşamada gerekmiyor. Bağlı cihazlar: **SM F731B** (gerçek telefon,
Android 16) ve `sdk gphone64 arm64` emülatörü.

Sürüm farkı riski `android/` üretilmeden önce izole edildi (analyze/test bu
klasöre ihtiyaç duymuyor):

- `flutter pub get` → 14 bağımlılık güncellendi, `pubspec.lock` değişti. Devir
  notu §2.4'ün öngördüğü normal durum.
- `flutter test` → **191 test geçti**, kırılma yok.
- `flutter analyze` → 2 `info`: `DropdownButtonFormField`'ın `value` parametresi
  Flutter 3.33 sonrası `initialValue` lehine deprecate edilmiş
  (`add_task_screen.dart:150` ve `:164`).

Deprecation, lock'un bu oturumda güncellenmesinin doğrudan sonucu olduğu için
B-020 kapsamında düzeltildi. Flutter kaynağı önce doğrulandı: `dropdown.dart`
parametreyi `initialValue: initialValue ?? value` diye forward ediyor (saf isim
değişikliği) ve `didUpdateWidget` değer değişimini hâlâ yakalıyor — yani
`setState` ile sürülen öncelik/kategori seçimi davranışı aynı kalıyor. Düzeltme
sonrası `flutter analyze` → **No issues found!**, feature testleri (57) geçiyor.

### Kullanıcı
> (soruya cevap) Paket adı: "Başka bir org gireceğim" · Disk: "Önce yer açayım"
> · Hedef cihaz: "SM F731B — gerçek telefon"

### Agent
`flutter create` iki koşula bağlandığı için duruldu: (1) org değeri kullanıcıdan
bekleniyor — nihai paket adı `<org>.takip` olacak, (2) kullanıcı diskte yer
açacak. İlk koşum hedefi gerçek telefon olarak belirlendi.

Beklerken bağımsız iş kapatıldı: deprecation düzeltmesi + güncellenen
`pubspec.lock` commit'lendi.

### Kullanıcı
> domainim gover.us buna gore org adini gir

### Agent
Ters alan adı kuralıyla `--org us.gover` → paket adı **`us.gover.takip`**
(`gover.us.takip` değil). Disk de kullanıcı tarafından açılmıştı: 2,6 GB → 14 GB.

`flutter create . --platforms=android --org us.gover` çalıştırıldı. Devir
notunun §2.3 uyarısı kısmen gerçekleşti — komut `.gitignore`, `README.md` ve
`pubspec.yaml`'a **dokunmadı** (tracked diff boş), ama üç yeni dosya bıraktı:

- `android/` — hedef, `applicationId = "us.gover.takip"` doğrulandı.
- `.metadata` — Flutter'ın kendi proje dosyası, versiyon kontrolüne girmeli.
- `test/widget_test.dart` — **silindi.** Varsayılan sayaç şablonu, projede
  olmayan `MyApp` sınıfını çağırıyor; bırakılsa test paketini kırardı.

Üretilen manifest'te bir eksik bulundu ve düzeltildi: Flutter şablonu INTERNET
iznini yalnızca `debug/` ve `profile/` manifestlerine koyuyor, `main/`'e değil.
Uygulamanın tek işlevi `api.github.com` ile konuşmak olduğu için (K-001) release
derlemesinde ağ erişimi **sessizce kapalı** kalırdı — debug koşumunda fark
edilmeyecek, ancak yayına çıkarken ortaya çıkacak bir hata. İzin `main`
manifest'ine gerekçesiyle eklendi.

Doğrulama ve cihaza kurulum:

- `flutter analyze` temiz, **191 test** geçiyor.
- `flutter build apk --debug` → 43,9 sn'de başarılı. Uyarılar zararsız (SDK XML
  sürüm farkı; eklenti bağımlılıklarından gelen Java 8 hedefi).
- `flutter install -d R5CW71GRKPB` ilk denemede başarısız: komut varsayılan
  olarak **release** APK arıyor. `--debug` ile kuruldu.
- Uygulama `am start` ile başlatıldı: **PID 13566, çalışıyor, logcat'te crash
  veya `E/flutter` kaydı yok.**
- Ekran görüntüsü alınamadı: telefon kilit ekranında. (Yan bulgu: Z Flip 5
  katlanabilir olduğu için `adb exec-out screencap` stdout'a "Multiple displays"
  uyarısı basıp PNG'yi bozuyor; cihaza yazıp `adb pull` ile almak gerekiyor.)

Derleme ~2 GB tüketti (14 GB → 12 GB boş). Sırada B-015: kullanıcı token'ı
üretip **doğrudan telefona** girecek; token agent'a iletilmeyecek (R-005).

### Kullanıcı
> uygulamayi test ettim basarili bir sekilde takip reposuna baglandi

### Agent
Onboarding çalıştı: token üretildi, uygulama `afgover/takip`'e bağlandı. Bu,
B-022'nin okuma doğrulamasının ve B-026'nın yazma izni yoklamasının gerçek
GitHub'a karşı ilk kez geçtiği an — o iki madde bugüne kadar yalnızca taklit
hub üzerinde sınanmıştı.

**Doğrulamanın kaynağı:** kullanıcı beyanı. Telefon bu sırada USB'den ayrılmıştı
(`adb: device not found`), ekran görüntüsüyle teyit edilemedi. Uygulamanın
ayakta olduğu ve crash etmediği ise bağlantı kopmadan önce doğrudan ölçülmüştü.

**B-015 ✅** ve **B-020 ✅** işaretlendi. Bunlarla birlikte **Faz 1 ve Faz 2
tamamen kapandı** — ikisinde de açık madde kalmadı.

Oturumun ürettiği knowledge kayıtları:

- **L-010** — `flutter create` INTERNET iznini release manifest'ine koymaz.
  Sessiz tuzak: debug'da çalışır, yalnızca release'te patlar.
- **L-011** — `flutter install` `--debug` olmadan release APK arar.
- **SK-007** — Var olan projede `flutter create` sonrası artık temizliği
  (temiz ağaçla başla, `git status` + `git diff` ayrı oku, `widget_test.dart`
  sil, `.metadata` tut, manifest'i elle oku, `applicationId`'yi doğrula).
- **SK-008** — Katlanabilir cihazda `adb exec-out screencap` bozuk PNG üretir;
  cihaza yazıp `adb pull` ile alınır.

Kalan: **B-034'ün cihaz ayağı** — telefondan görev ekleme ve
inbox → active → done döngüsünün gerçek GitHub üzerinden koşması.

### Kullanıcı
> gorev ekledim

### Agent
Görev geldi: `hub/tasks/inbox/2026-08-01-ilk-gorev.md`, commit `45cc3a5`
(`task(pending): inbox'a eklendi (app)`). **Uygulama gerçek GitHub'a yazdı.**
Dosya sözleşmeye birebir uygun: `id: pending`, UTC zaman damgaları, §8 commit
öneki. İçerik gerçek bir istekti: *"birden çok repo eklemek için arayüzü
geliştir"*.

`T-003` atanıp `inbox → active` taşındı (`9eaec76`). İstek yüzeyde arayüz işi
gibi görünse de sözleşmenin hub kökü tanımına (K-012) dokunduğu ve backlog'da
aynı ihtiyacın farklı bir cevabı (B-063, tek repoda `projects/<ad>/`) durduğu
için kapsam kullanıcıya soruldu. Kullanıcı **"şimdi tamamen uygula"** dedi.

### Agent — T-003 uygulaması
Çatal **ayrı repo** yönünde çözüldü (K-018): istek açıkça repo düzeyindeydi ve
izin izolasyonu zaten B-003'te ayrı repo kararının gerekçesiydi — tek repoda
`projects/` olsaydı bir token bütün projeleri kapsardı.

Kod okumasının bulduğu kilit nokta: uygulamanın "o an hangi repodayız" sorusunu
sorduğu **tek** yer `hubConfigProvider`. Çoklu repo bu darboğazın *altına* bir
katman olarak kondu (`hub/hub_connections.dart`); darboğazın imzası korunduğu
için istemci, Contents/Commits/Trees API'leri, yoklama ve görev deposu ile
testlerindeki override'lar hiç değişmedi (→ SK-009).

Asıl iş, **bağlam taşıyan kalıcı kayıtlarda** çıktı:

- **Outbox repo-farkında yapıldı.** Taslak kuyruğa alınırken hedef repo
  damgalanıyor, boşaltmada her zaman kendi bağlantısına açıkça gönderiliyor.
  İki ayrı sessiz veri hatası bu sayede kapandı: (a) damga olmasaydı çevrimdışı
  yazılan görev, repo değiştikten sonra yanlış projeye düşerdi; (b) paylaşılan
  depoya güvenilseydi hedef, `hubConfigProvider`'ın **asenkron gecikmesine**
  bağlı kalırdı — testin yakaladığı gerçek kusur buydu (→ L-012).
- **Bağlantısı kaldırılan taslak** kuyrukta kalıyor, atılmıyor.
- **ETag önbelleği** artık repo geçişinde temizlenmiyor: anahtar isteğin tam
  URI'si olduğu için repolar zaten karışamıyor. Geçiş anında önbellekten
  çiziliyor.
- **Göç:** T-003 öncesi tek bağlantı anahtarları ilk açılışta listeye taşınıyor
  — kullanıcı token'ı yeniden girmiyor.

Arayüz: her ekranın üstünde aktif repoyu gösteren şerit (dokununca repo
listesi), repo yönetim ekranı, bağlantı ekranında isteğe bağlı ad ve repo başına
token.

Yol boyunca bir tasarım hatası testle yakalanıp geri alındı: yazma yolunda aktif
bağlantıyı `.future` ile beklemek, oraya bir `flutter_secure_storage` bağımlılığı
sokuyordu — iki widget testi asıldı, ama asıl mesele gerçek cihazda güvenli depo
cevap vermezse görev eklemenin askıda kalacak olmasıydı (→ L-013).

`flutter analyze` temiz, **219 test** geçiyor (28 yeni). takip@d5c206e.
`T-003` `active → done` taşındı (`115cd12`).

Release APK derlendi ve **INTERNET izninin release paketinde bulunduğu
`aapt2` ile doğrulandı** — sabahki manifest düzeltmesi teorik değil, ölçülmüş.
Telefon bu sırada USB'den ayrık olduğu için yeni sürüm cihaza kurulamadı.

### Kullanıcı
> t 003 sonucunu gordum, telefon bagli

### Agent
**B-034 kapandı, Aşama 2 tamamlandı.** Zincirin tamamı gerçek GitHub üzerinden
koştu: app görevi inbox'a yazdı → agent ID atayıp `inbox → active → done`
geçirdi → sonuç app'te "Tamamlananlar"da göründü. B-035 de kapatıldı (bu
oturumun dersleri: L-010…L-014, SK-007…SK-009). **Faz 3 kapandı.**

Release derlemesi cihaza kuruldu ve çalıştığı doğrulandı: uygulama crash'siz
açıldı, arayüz düzgün çiziliyor.

**Kurulumun bedeli oldu:** `flutter install --release`, cihazdaki debug
derlemesini **kaldırıp** yeniden kurdu ("Uninstalling old version..."). Android'de
kaldırma uygulama verisini de sildiği için token gitti ve uygulama onboarding
ekranına döndü (ekran görüntüsüyle doğrulandı). Bu, derleme türü değişikliğinin
kaçınılmaz sonucu; ama sıralama hatasıydı: release, kullanıcı sabah token
girmeden **önce** kurulmalıydı (→ L-014).

**Açık kalan tek adım:** kullanıcının token'ı yeniden girmesi. Oturum
kapanırken telefon kilitli olduğu için bağlantının kurulduğu doğrulanamadı;
bu satır, doğrulanmamış bir şeyi "yapıldı" diye kaydetmemek için burada.

İkinci yan sonuç: T-003'ün eski anahtar göçü **cihazda sınanamadı** — kaldırma,
göçün okuyacağı eski kaydı da sildi. Göç yalnız birim testiyle doğrulanmış
durumda (`hub_connections_test.dart`).

Aşama 4 (Günlük Kullanım) açıldı: sıradaki iş kod yazmak değil, B-052 —
bir hafta gerçek kullanım ve sürtünmelerin inbox'a görev olarak atılması.
