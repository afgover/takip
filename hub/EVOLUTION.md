# EVOLUTION.md — Projenin Evrimi

Proje aşamalar halinde ilerler. Aktif aşamanın bölümü sürekli güncellenir;
aşama kapanınca başlığına ✅ ve tarih eklenir, yeni aşama açılır. Verilen her
önemli karar, gerekçesiyle buraya işlenir — "neden böyle yaptık?" sorusunun
cevabı her zaman bu dosyadadır.

---

## Aşama 0 — Yön Değişikliği ✅ (2026-07-30)

**Hedef:** project-taskr'ın mimari yönünü belirlemek.

**Bağlam:** İlk taskr (Expo app + özel backend: JWT auth, offline kuyruk,
paylaşım, deploy) işletme yükü nedeniyle sürdürülemez bulundu; emek ürün yerine
altyapıya gidiyordu.

**Kararlar:**
- **K-001:** Backend işletmek yerine GitHub omurga olarak kullanılacak. Agent her
  şeyi bir hub reposuna kaydeder; kullanıcı uygulaması bu repoyu izler ve görev atar.
- **K-002:** Hub, kod reposu içinde bir klasör değil **ayrı private repo** olacak.
  Gerekçe: GitHub'da klasör bazlı izin yok; uygulamanın token'ı yalnızca hub'a
  scope'lanarak izolasyon sağlanır. Ayrıca hub verisi main'de yaşar, kod
  repolarının branch akışıyla çakışmaz.
- **K-003:** Anlık bildirim (webhook + relay + push) 2. plana alındı; ilk sürüm
  ETag'li polling kullanacak.
- **K-004:** Görevler dosya-başına-görev modeliyle, durum bilgisi klasörle
  (`inbox/active/done`) tutulacak. Gerekçe: çakışmasız eşzamanlı yazma + ucuz
  listeleme.
- **K-005:** Uygulama Flutter ile yazılacak (kullanıcının geçmiş tecrübesi).

**Sonuç:** Yön netleşti; Faz 0 backlog maddeleri (B-001…B-005) tamamlandı.

---

## Aşama 1 — Hub Kurulumu ✅ (2026-07-30)

**Hedef:** Format sözleşmesinin yazılması, hub reposunun açılması ve sözleşmenin
ilk gerçek oturumla test edilmesi.

**Durum:**
- 2026-07-30: `SYSTEM.md` 1.0, `AGENT_PROTOCOL.md`, `BACKLOG.md`, knowledge
  iskeletleri taslak olarak hazırlandı (taskr kod reposunda).
- 2026-07-30: İskelet hub reposuna taşındı, taskr reposundaki ön çalışma klasörü
  kaldırıldı (B-013 ✅, B-014 ✅). Flutter tasarımı
  `artifacts/reference/flutter-app-design.md` olarak kaydedildi.
- 2026-07-30: İsim düzeltmesi — hub yanlışlıkla `takip` reposuna kurulmuştu;
  tüm geçmiş `afgover/taskr_takip`e taşındı (K-007). Bu repo artık tek doğru
  kaynak; `takip` kullanım dışı bırakıldı, kullanıcı silebilir. → L-003
- 2026-07-30: Sözleşme döngü testi tamamlandı (B-016 ✅, görev T-001);
  revizyon ihtiyacı çıkmadı (B-017 ✅). B-015 (uygulama token'ı) kullanıcı
  kararıyla ertelendi — Faz 2 öncesi tamamlanacak.

**Kararlar:**
- ~~**K-006:** Hub reposunun adı `takip`.~~ (Geçersiz: yanlış repo adı; bkz. K-007)
- **K-007:** Hub reposu `afgover/taskr_takip`. Eski taskr reposu salt tarihçe
  olarak kalır; yeni çalışmalar yalnızca hub üzerinden yürür. `takip` reposu
  kullanım dışıdır. (`takip`in rolü K-011/K-012 ile, `taskr` ve `taskr_takip`in
  rolleri K-013 ile değişti.)
- **K-008:** Uygulama hedefi — önce **kişisel kullanım** (store'suz dağıtım);
  ileride **Android + iOS store** yayını. Onboarding'de PAT girişi kişisel
  aşama için yeterli; store aşamasında GitHub App OAuth değerlendirilecek
  (B-061 ile birlikte).
- **K-009:** Kişisel aşamada hedef platform **Android** (APK ile dağıtım).
  iOS, store aşamasıyla birlikte gelecek.
- **K-010:** Görev kategorileri — 5 sabit varsayılan (`gorev, arastirma,
  gelistirme, hata, fikir`) + **kullanıcı tanımlı** serbest değerler. App,
  seçim listesini varsayılanlar + mevcut görevlerde geçen kategorilerden
  türetir; ek kayıt dosyası gerekmez, R-001 değişmez. → Sözleşme 1.1
- **K-011:** Flutter uygulamasının evi, başta oluşturulan `afgover/takip`
  reposu — **çatı (uygulama) repo** olarak yeniden tanımlandı. Yapı:
  `takip` = uygulama kodu, `taskr_takip` = veri hub'ı, `taskr` = salt tarihçe.
  (`taskr_takip` kısmı K-012 ile, `taskr`ın rolü K-013 ile değişti.)
- **K-012:** `takip` projesi **kendi hub'ını barındırır**: tüm hub içeriği
  `takip/hub/` klasörüne taşındı; `takip_takip` gibi ek repo açılmadı,
  `taskr_takip` kullanım dışı bırakıldı (rolü K-013 ile güncellendi:
  taskr'ın hub'ı olacak). Gerekçe (kullanıcı kararı): tek
  proje-tek repo sadeliği. Bedeli bilinçli kabul edildi: uygulama token'ı
  artık kod+veri içeren `takip`e scope'lanır (R-005) ve commit geçmişinde
  uygulama commit'leriyle hub commit'leri karışır (app aktivite akışı §8
  önekleriyle filtreler). **Diğer projeler için işleyiş değişmez:** ayrı
  `<proje>_takip` hub reposu modeli geçerli kalır. → Sözleşme 1.2

---

## Aşama 2 — Uygulama MVP'si ✅ (2026-08-01)

**Hedef:** Flutter iskeleti + todo döngüsü: app'ten eklenen görevin hub'a düşmesi,
agent'ın ele alması, sonucun app'te görünmesi. (Backlog Faz 2–3.)

**Durum:**
- 2026-07-30: Aşama açıldı. İskelet (B-021) `takip` çatı reposuna yazıldı:
  katmanlı mimari (github → hub → features), Riverpod, tema, alt gezinme,
  onboarding + 4 ekran taslağı; frontmatter parser ve slug üretimi çalışır
  durumda, API katmanı TODO(B-023). Aşama 1'in kapanışında B-015 (token)
  ertelenmiş tek madde olarak Faz 2'ye devroldu.
- 2026-07-30: K-012 uygulandı — hub içeriği `takip/hub/` altına taşındı
  (sözleşme 1.2, R-005); `taskr_takip` kullanım dışı. Uygulama sabitleri
  (`lib/core/constants.dart`) `hub/` önekine, onboarding varsayılanı
  `afgover/takip`e güncellendi.
- 2026-07-30: Repo rolleri kullanıcı cevabıyla netleşti (K-013); K-012 teyit
  edildi, `takip/hub/` yapısında değişiklik gerekmedi. Kayıtlar (K-007/K-011/
  K-012 notları, README, flutter-app-design K-011 notu) güncellendi.
  → S-2026-07-30-repo-yapisi-netlestirme
- 2026-07-30: K-013 uygulandı — `taskr_takip`'teki takip hub geçmişi (12
  commit) tree'yi değiştirmeyen merge ile bu reponun tarihçesine bağlandı
  (8ed8134); dosya karşılaştırmasında eksik kayıt çıkmadı. `taskr_takip`,
  README güncellemesiyle taskr projesinin takip hub'ı olarak rezerve edildi
  (eski commit geçmişi orada kopya olarak duruyor; silinmesi kullanıcı
  onayına bırakıldı). Çalışma branch'i `main`'e merge edildi.
  → S-2026-07-30-gecmis-tasima-ve-merge
- 2026-07-30: B-023 tamamlandı — Contents API katmanı, SHA'lı iyimser kilit ve
  hata modeli yazıldı; R-001 hub katmanında yapısal kapıya bağlandı. Proje ilk
  kez derlendi: iskeletteki 2 derleme hatası düzeltildi, `flutter analyze`
  temiz, 27 test geçiyor. → S-2026-07-30-b023-github-istemci, L-005, L-006
- 2026-07-30: B-025 tamamlandı — frontmatter parser sağlamlaştırıldı (CRLF/BOM,
  bozuk YAML'a dayanıklılık, tipli erişim) ve serializer round-trip güvenli hâle
  getirildi (SK-004): app'in yazdığı sözleşme dosyası her durumda geçerli YAML.
  Tema uyumlu `HubMarkdown` altyapısı eklendi; parser artık gerçek hub
  dosyalarına karşı da test ediliyor. 55 test.
  → S-2026-07-30-b025-frontmatter-markdown
- 2026-07-30: B-022 tamamlandı — onboarding token'ı kaydetmeden önce tek GET
  ile doğruluyor; hata mesajları GitHub'ın 404 belirsizliğini dürüstçe
  anlatıyor (L-007). Yazma izni sınanamadığı için B-026 açıldı. 71 test.
  → S-2026-07-30-b022-onboarding
- 2026-07-30: B-024 tamamlandı — ETag doğrulama önbelleği ve tek commit
  isteğine dayanan ön plan yoklaması. Faz 2'nin **agent tarafı bitti**
  (B-021…B-025); açık kalanlar kullanıcıya bağlı B-015/B-020 ile sonradan
  açılan B-026. 87 test. → S-2026-07-30-b024-etag-polling
- 2026-07-30: Faz 3'ün agent tarafı tamamlandı — B-030 (görev ekleme), B-031
  (bekleyenler + detay), B-032 (outbox), B-033 (çakışma). B-034'ün sözleşme
  ayağı bitti (sahte hub üzerinde gerçek ekranlarla tam döngü + gerçek hub'da
  T-002), cihaz ayağı B-015/B-020'ye bağlı olduğu için madde açık.
  128 test. → S-2026-07-30-faz3-todo-dongusu, L-008
- **Aşama 2'nin durumu:** agent tarafında yapılacak iş kalmadı. Uygulama
  uçtan uca çalışır durumda ama henüz hiç gerçek cihazda koşmadı; aşamayı
  kapatmak için B-015 + B-020 + B-034'ün cihaz ayağı gerekiyor.
- 2026-07-30: Faz 5'in agent tarafı tamamlandı — B-050 (hata UX'i: her hata
  için başlık + yapılabilecek şey, her ekranda duran durum şeridi) ve B-051
  (yoklama aralığı, bağlantı düzenleme, önbellek temizleme, onaylı sıfırlama).
  B-046'nın yoklamayla etkileşiminden doğan hata düzeltildi: önbellekten gelen
  commit yanıtı artık "değişmedi" sayılmıyor, yoksa çevrimdışılık hiç
  görünmüyordu. 184 test. → S-2026-07-30-faz5-cilalama
- 2026-07-30: B-026 tamamlandı — yazma izni onboarding'de sınanıyor. Önerilen
  yöntem (`permissions.push`) araştırmada elendi (L-009); yerine yan etkisiz
  yoklama kondu (SK-006). 191 test. → S-2026-07-30-b026-yazma-izni
- **Agent tarafında açık iş kalmadı.** Kalanların hepsi kullanıcıya bağlı:
  B-015 (token), B-020 (SDK + `android/`), B-034'ün cihaz ayağı, B-052 (bir
  haftalık kullanım) ve ona bağlı B-053/B-035.
- 2026-07-30: Çalışma ortamı kapatıldı; devir notu yazıldı
  (`artifacts/reference/kurulum-ve-devir.md`) — Mac'te kurulum adımları, token
  üretimi, ilk gerçek döngü ve yeni oturum için okuma sırası.
  → S-2026-07-30-kapanis-ve-devir
- Sıradaki: kullanıcı adımlarından sonra B-034'ün cihaz koşumu ve B-035;
  ardından Faz 4 (hub tarayıcı) — B-026 de aradan alınabilir.
- 2026-08-01: **Uygulama ilk kez gerçek cihazda çalıştı.** B-020 tamamlandı:
  SDK kurulumu gerekmedi (Flutter 3.35.4 ve Android Studio hazırdı), `android/`
  üretildi (`us.gover.takip`, domain `gover.us`), debug APK derlenip SM F731B'ye
  (Android 16) kuruldu ve crash'siz açıldı. Sürüm sıçraması (3.27.1 → 3.35.4)
  tek bir deprecation'la atlatıldı; `analyze` temiz, 191 test geçiyor. Üretilen
  manifest'te INTERNET izni eksikti — debug'da görünmeyecek, yalnızca release'te
  patlayacak bir tuzak; bulunup giderildi (L-010). B-015 tamamlandı: kullanıcı
  fine-grained token'ı üretip cihaza girdi, uygulama `afgover/takip`'e bağlandı.
  Bu, B-022'nin okuma doğrulamasının ve B-026'nın yazma yoklamasının **gerçek
  GitHub'a karşı** ilk geçişiydi — ikisi de bugüne dek yalnızca taklit hub'da
  sınanmıştı. **Faz 1 ve Faz 2 kapandı.**
  → S-2026-08-01-b020-mac-kurulum, L-010, L-011, SK-007, SK-008
- 2026-08-01: **İlk gerçek görev döngüsü koştu.** Kullanıcı telefondan görev
  ekledi (`task(pending): inbox'a eklendi (app)`, 45cc3a5); dosya sözleşmeye
  uygun geldi. Agent T-003 ID'sini atayıp `inbox → active → done` geçirdi.
  Görevin içeriği gerçek bir istekti — "birden çok repo eklemek için arayüzü
  geliştir" — ve kullanıcının kararıyla aynı oturumda uygulandı (takip@d5c206e).
  219 test, analyze temiz. → S-2026-08-01-b020-mac-kurulum, K-018, L-012, L-013,
  SK-009
- 2026-08-01: **Aşama kapandı.** Kullanıcı T-003'ün sonucunu app'te
  "Tamamlananlar"da gördü; B-034 ve B-035 tamamlandı, **Faz 3 kapandı**. Aşama
  2'nin hedefi ("app'ten eklenen görevin hub'a düşmesi, agent'ın ele alması,
  sonucun app'te görünmesi") gerçek cihaz ve gerçek GitHub üzerinde uçtan uca
  doğrulandı. Aşamanın açılışından beri süren "hiçbir gerçek cihazda hiç
  çalışmadı" eşiği bugün aşıldı.
  Kapanışta release derlemesi cihaza kuruldu ve çalıştığı doğrulandı; ancak
  derleme türü değişikliği uygulamayı kaldırıp yeniden kurduğu için token
  silindi ve yeniden girilmesi gerekti (→ L-014). Bunun bir yan sonucu:
  T-003'ün eski anahtar göçü **cihazda sınanamadı**, yalnız birim testiyle
  doğrulanmış durumda.

**Kararlar:**
- **K-013:** Repo rolleri netleştirildi (kullanıcı cevabı). `taskr` salt
  tarihçe değil, **kendi kendine devam eden ayrı bir projedir**; içindeki
  `project-taskr` branch'i, bugünkü `takip` projesinin ilk versiyonunun
  geliştirildiği yerdi ve oradan bu repoya evrildi. `taskr_takip`, standart
  `<proje>_takip` modeline uygun olarak **orijinal taskr projesinin takip
  hub'ı** olarak kullanılacak — kullanım dışı değil. (İçinde duran
  takip-projesi hub geçmişi, taskr takibi fiilen başlatılırken ele alınacak.)
  `takip` için K-012 teyit edildi: takip dosyaları `takip/hub/`ta kalır,
  `takip_takip` açılmaz; repo tek kullanıcılı olduğundan risk kabul edilebilir
  (kullanıcı kararı). Diğer tüm projelerde `<proje>_takip` modeli geçerlidir.
- **K-017:** **Ayrı bir "pro" versiyon şimdilik yapılmayacak.** Kullanıcı, ekip
  çalışması için backend'li (webhook, doğrudan içerik aktarımı) ikinci bir
  versiyon önerdi; gerçek kullanım testinden sonra gerekirse yeniden gündeme
  gelmek üzere ertelendi. Gerekçeler: (a) light sürüm henüz hiçbir cihazda
  çalışmadı, "yetmiyor" tespitini yapacak veri yok; (b) L-001 — ilk taskr
  backend yükü yüzünden bırakılmıştı; (c) takım çalışmasının gerektirdiğinin
  çoğu GitHub'da zaten var (commit yazarı = kim yaptı, collaborator izinleri,
  K-004 sayesinde çakışmasız eşzamanlı yazma); geriye kalan gerçek boşluk
  **bildirim gecikmesi**. Tercih edilen yol: iki kod tabanı yerine **tek ürün +
  opsiyonel bileşen** — ürün aslında sözleşmedir (SYSTEM.md), app onun
  istemcisidir; B-060 (stateless relay) veri modeline dokunmadan push
  ekleyebilir. **Kararı yeniden açacak kanıtlar:** GitHub hesabı olmayan
  kullanıcılar, düzenli medya eki (Contents API 1 MB sınırı + git'te binary
  maliyeti), saniyeler mertebesinde bildirim ihtiyacı, repo dışı entegrasyon.
  → S-2026-07-30-versiyon-stratejisi, B-064
- **K-018:** Çoklu proje ihtiyacı **ayrı repo** modeliyle karşılanır: her proje
  kendi reposu, kendi `hub/` klasörü, kendi token'ı. Gerekçe: (1) kullanıcının
  isteği açıkça repo düzeyindeydi; (2) izin izolasyonu, B-003'te ayrı repo
  kararının zaten gerekçesiydi — tek repoda `projects/<ad>/` olsaydı bir
  token'ın kapsamı bütün projeler olurdu ve telefon kaybında kayıp büyürdü;
  (3) sözleşmeye (`SYSTEM.md`) hiç dokunulmadı, çünkü hub kökü tanımı zaten
  repo başına. Tek repoda çoklu proje seçeneği (B-063) kapanmadı: ayrı repo
  modeli gerçek kullanımda (B-052) yetersiz kalırsa yeniden açılır.
  → T-003, S-2026-08-01-b020-mac-kurulum

## Aşama 3 — Hub Tarayıcı ✅ (2026-07-30)

**Hedef:** Agent'ın hub'a kaydettiği her şeyin app'te kategoriler halinde
görüntülenmesi. (Backlog Faz 4.)

**Durum:**
- 2026-07-30: Faz 4 tamamlandı (B-040…B-046). Kategori ekranı, oturum ve
  artifact listeleri, bilgi tabanı, yol haritası, aktivite akışı ve kalıcı
  önbellek. 164 test. → S-2026-07-30-faz4-hub-tarayici

**Kararlar:**
- **K-014:** Tarayıcı listeleri **tek özyinelemeli ağaç isteğinden** üretilir
  (Git Trees API), klasör klasör gezilmez. Gerekçe: alternatifte istek sayısı
  kayıt sayısıyla büyürdü; ağaç isteği sabit sayıdadır ve ETag'lendiği için
  değişiklik yokken limitten düşmez. Ağaç kırpılırsa eksik liste gösterilmez,
  hata verilir.
- **K-015:** Aktivite akışında **kod commit'leri ayrı tür** sayılır ve
  varsayılanda gizlenir (K-012'nin öngördüğü filtre). §8 kalıbına uymayan
  mesaj insan diline çevrilmeye çalışılmaz, olduğu gibi gösterilir.
- **K-016:** Önbellek ağ yokken **son bilinen içeriği** gösterir ve bunu
  işaretler; ama sunucudan gelen hata (401/500) önbellekle gizlenmez —
  sorunu saklamak, bayat veri göstermekten daha kötüdür.

## Aşama 4 — Günlük Kullanım (aktif)

**Hedef:** Sistemi bir hafta gerçek işle kullanmak ve sürtünme noktalarını
uygulamanın kendi kanalından (inbox) toplamak. (Backlog: B-052 → B-053.)
Bu aşama kod yazmakla değil, **kullanmakla** ilerler; çıkacak işler B-053'te
toplanır ve gerekiyorsa Faz 6 maddelerini (B-060…B-064) yeniden sıralar.

**Durum:**
- 2026-08-01: Aşama açıldı. Uygulama release derlemesi olarak cihazda,
  `afgover/takip`'e bağlı ve çoklu repo destekli.
- 2026-08-01: Günlük kullanımın ilk sürtünmesi daha ilk saatte çıktı ve
  giderildi: her kurulumda ve her yeni repoda token girmek zorunda kalmak.
  Üç iş yapıldı — kaldırmayan kurulum scripti (B-054), parolayla şifreli
  bağlantı yedeği (B-055), yeni repoda kayıtlı token'ı yeniden kullanma
  (B-056). Ölçüm önemliydi: `flutter install`'ın kaldırması yapısal
  sanılmıştı, kaynağa bakılıp cihazda üç senaryo denenince bunun aracın hata
  yolu olduğu görüldü ve L-014 düzeltildi (L-016). 236 test.
- 2026-08-03: Günün tamamı gerçek kullanımdan çıkan sürtünmelerle geçti ve
  sözleşme dört sürüm ilerledi (1.8 → 1.11). Üç şey kalıcı olarak değişti:
  **not, görev değil** (`notes/`, 1.9 — kullanıcının kendine aldığı not agent'ın
  iş kuyruğuna düşüyordu), **güvenlik geçmişi tek yerde** (`SECURITY.md`, 1.10)
  ve **commit önekleri eksiksiz** (1.11 — `note:`/`security:` tanımsız olduğu
  için kullanıcının kendi notu aktivite akışında "kod" görünüyordu).
  Aynı gün üç hata da kaynağında çözüldü: işaretin satır akışını bozması
  (L-032, algoritma değişti), çapraz repo görev detayı (L-031) ve aktif olmayan
  repodaki değişikliğin hiç görünmemesi (L-034). Son ikisi aynı kalıbın iki
  yüzü: bir yeteneği çok kaynaklı yaparken zincirin **tamamını** saymamak.
  Ayrıca agent kurulum talimatı geçmişi olan projeleri de kapsayacak şekilde
  yenilendi, MIT lisansı ve yeni README eklendi, açık kaynak/store kararı
  ayrıştırıldı (K-032). 349 test.
- 2026-08-04: Gün ikiye bölündü. **Sabah — açık güvenlik işleri kapandı.**
  Bağımlılık/zafiyet taraması ilk kez koşuldu (SEC-008): 68 paket OSV'ye
  soruldu, bilinen zafiyet yok; "0 bulgu"yu yazmadan önce sorgunun çalıştığı
  bir kontrol grubuyla doğrulandı (L-035 — doğrulanmamış boş sonuç, olmayan
  bir güvence verir). Sır taraması çalışma ağacı **ve** git geçmişinin
  tamamında temiz çıktı. Tarama iki yeni bulgu üretti: Android otomatik
  yedeklemesi cihazdaki şifresiz hub kopyasını buluta taşıyor (SEC-009) ve
  release derlemesi debug anahtarıyla imzalanıyor (SEC-010 — B-097'nin APK
  adımının ön koşulu). Token kapsamı denetimi eklendi (SEC-006 kapandı):
  kapsam, erişim doğrulamasının **aynı yanıtından** okunuyor, fazladan istek
  yok (SK-011); yorum B-026'daki gibi tek yönlü ve uyarı engellemiyor —
  çalışan bir token'ı reddetmek uygulamayı kullanılamaz hâle getirirdi.
  Kapanmayan kısım dürüstçe ayrıldı (SEC-012) ve ölçümü kullanıcıya soruldu
  (T-006, `waiting/`).
  **Öğleden sonra — kullanımdan gelen iki istek, sözleşme 1.12.** İkisi de
  aynı boşluğun iki yüzüydü: sistem kullanıcıya **soru soramıyordu** ve
  kullanıcı bir yeri **sonra bulmak üzere** işaretleyemiyordu.
  (a) Seçenekli bekleme (T-007/B-104): `waiting/` görevi artık `options`
  taşıyabiliyor; kullanıcı seçiyor, yanına açıklama yazabiliyor, cevap
  `waiting-answer` olarak inbox'a düşüyor. Kural: bir görev = bir soru.
  (b) Yer imi (T-008/B-105): dördüncü işaret (mavi) ve ilk defa **göreve
  dönüşmeyen** bir işaret (R-007); bütün repolardaki işaretler Tarayıcı →
  İşaretler altında tek listede toplanıyor, dokununca kaydın kendi reposundaki
  belge açılıyor. Yer imi ancak sonradan bulunabiliyorsa bir işe yarar.
  Uygulama sırasında sessiz bir veri kaybı yakalandı: dalın koşulu genişleyince
  gövdesinin yazılmamış varsayımı yanlışa döndü ve yer imine yazılan not
  kaydedilmiyordu (L-036). 397 test.
- 2026-08-04 (akşam): Uygulama cihaza kuruldu ve **kullanımın ilk saatinde**
  1.12'nin bir kararı geri alındı: işaretler listesi bütün repoları
  birleştiriyordu, aktif repoya bağlandı (sözleşme 1.13, B-106, K-034).
  Döngünün kendisi kayda değer — özellik sabah yazıldı, akşam cihazda denendi,
  aynı gün düzeltildi ve düzeltme sözleşmeye işlendi. Aşama 4'ün hedefi
  (B-052: kullanımdan gelen sürtünmeyi toplamak) tam olarak bu. 399 test.
- 2026-08-05/06: Güvenlik katmanı tamamlandı ve sistem **çoklu kullanıcıya**
  hazırlandı. SEC-009 (bulut yedeklemesi) ve SEC-011 (tarama tekrarı) kapandı;
  tarama artık `tool/scan.sh` + Dependabot ile iki katmanlı ve tetikleyicisi
  hub'ın kendi kaydının yaşı (K-035). SEC-012'nin bilinmeyeni ölçüldü.
  Ardından sözleşme 1.15 ile kimlik geldi (`author`/`for`/`assignee`,
  `notes/<login>/`) ve ID çakışmaları görünür kılındı (K-036). 418 test.
  → S-2026-08-01-token-kaliciligi, K-019, R-006, L-015, L-016
- 2026-08-01: **Sisteme ikinci proje ekleme yolu açıldı.** Yeni proje ekleme
  prosedürü kalıcı belge oldu (`artifacts/reference/proje-ekleme.md`) ve bunu
  yazarken sözleşmeyle uygulama arasında bir çelişki bulundu: sözleşme "hub
  kökü `<proje>_takip` reposunun kökü" diyordu, uygulama `hub/` klasörünü
  sabit arıyordu — o hâliyle ikinci bir repo hiç eklenemezdi. Sözleşme 1.3'e
  güncellendi (K-020). Ayrıca Project Taskr arşive kaldırıldığı için oradaki
  35 belge takip hub'ına referans arşiv olarak taşındı (K-021); arşivde
  bulunmayan şey de kayda geçti: Project Taskr'ın yönettiği projelerin
  (CoPilot, Financer, Sarraf, DataSources) verisi repoda değil, uygulamanın
  veritabanındaydı. 247 test.
  → S-2026-08-01-proje-ekleme-ve-arsiv, K-020, K-021
- 2026-08-01: **Görev mekanizmasının eksik yönü kapatıldı.** Kullanıcının
  "agent'ın benden beklediği işler bekleyenlerde görünüyor mu?" sorusu
  ölçüldü: görünmüyordu. `inbox` ve `active`'in ikisi de "agent ele alacak"
  demekti; agent→user işleri yalnız `BACKLOG.md`'de `(user)` etiketiyle
  duruyordu (50 maddenin 2'si) ve uygulamada hiçbir yerde yoktu. Sözleşme
  1.4 ile `tasks/waiting/` eklendi (K-022), uygulama bu klasörü de okuyor ve
  "Yaptım" düğmesi kapatma yolunu sohbetten çıkarıyor. 258 test.
  → S-2026-08-01-bekleyen-isler, K-022, L-018

- 2026-08-02: **Kayıt sistemi iki yönden genişledi.** (a) Bekleyenler artık
  bütün repoların işlerini tek listede gösteriyor; repo/öncelik/kategori
  filtresi ve satır etiketleri eklendi (B-067, B-068). Bu, yerel kopya (B-057)
  sayesinde mümkün oldu — etiketler dosya indirilmeden bilinemezdi. (b) Herhangi
  bir belgede metin seçip **görev/yorum/düzeltme/tartışma** kaydı oluşturulabiliyor;
  işaret (sarı/kırmızı) kayıttan türüyor, ayrıca saklanmıyor (B-069, K-023).
  Ayrıca sözleşmenin ana kopyası tanımlandı ve geriden gelen hub'lar hem agent
  hem uygulama tarafından yakalanıyor (B-070, K-024, L-020). Sözleşme 1.5.
  284 test. → S-2026-08-02-secim-filtre-sozlesme
- 2026-08-08: **Dil, hub'ın özelliği oldu ve girişi açıldı.** Sözleşme
  1.19 kendi 1.18 kuralımı tersine çevirdi (K-037); ardından B-118 mekanizmanın
  girişini kırdı (K-038): kurulum talimatına §0, protokole madde 0, iki giriş
  belgesinin İngilizcesi. Sözleşme ve protokolün İngilizcesi hâlâ açık (B-116)
  ve bu, İngilizce belgelerin içinde **açıkça yazılı** — eksiği yumuşatmak
  İngilizce bir hub'ı tam sanmaya yol açardı. `B-097` (repoyu public yapmak)
  buna bağlı bekliyor.
  Kapanışta bir de yapısal boşluk çıktı: dokuz gündür açık duran bir oturum
  (L-042, sözleşme 1.20). Aşamanın kendi dersi de bu — sistemi kullanmak,
  yalnız kullanınca görünen şeyleri gösteriyor.

- 2026-08-08: **Yöntem iki dilde tam** (B-115, B-116; sözleşme 1.21). Arayüz,
  sözleşme ve protokol İngilizce'ye açıldı; hub dili artık yalnız okunan değil,
  **yazılan** tarafta da işliyor. Taşırken arayüz metni ile hub verisi
  arasındaki sınır netleşti (K-039) ve iki sessiz kusur çıktı: `waiting`
  bildirimleri hub diline hiç bakmıyordu, 25 çeviri anahtarı da tanımlıydı ama
  kullanılmıyordu (L-043). İkisi de artık ölçülüyor.
  `B-097` (repoyu public yapmak) böylece **açıldı** — tek kalan ön koşuldu.

- 2026-08-11: **Telefondan açılan dört görev** (T-012…T-015; sözleşme 1.22).
  Aşamanın hedefi tam olarak buydu — sistemi kullanmak, yalnız kullanınca
  görünen şeyleri çıkardı: çevrimdışı okuma yolunun eksikliği, sıralamanın
  yokluğu, "yaptım" demenin yanına bir şey ekleyememek. Üçü de sohbette değil
  **uygulamanın kendi kanalından** geldi (B-053'ün ölçtüğü şey).
  Sözleşmeye §13 (geçici maddeler) eklendi: yöntemin kendisi yaşlandıkça,
  yalnız eski hub'ları ilgilendiren kuralların kalıcı kurallardan ayrı
  durması gerekiyor.

**Kararlar:**
- **K-019:** Kolaylık için token'ın korumasız bir dizeye çevrilmesine izin
  verilmez. Çok repolu kurulumda veri kaybı sonrası token'ları tek tek yeniden
  girmek sistemi kullanılamaz kılıyordu; çözüm olarak yedekleme eklendi ama
  **yalnızca parolayla şifreli** biçimde (kullanıcı seçimi). Düz metin dışa
  aktarma, kullanıcı isteseydi bile eklenmeyecek: yedek metni token'ların
  kendisidir, panoya düşen bir dize repolara yazma yetkisinin kendisi olurdu.
  Şifreleme elle yazılmaz, denenmiş bir kütüphaneden gelir. Koşullar R-006'da.
  → B-055, S-2026-08-01-token-kaliciligi
- **K-020:** **Hub kökü her repoda `hub/` klasörüdür** — istisnasız. Sözleşme
  1.2 "diğer projeler için hub, `<proje>_takip` reposunun köküdür" diyordu;
  ikinci proje eklenirken bunun uygulamayla çeliştiği görüldü: app hub kökünü
  `hub/` diye **sabit** tutuyor (`Hub.basePath`) ve bağlantı başına
  ayarlanamıyor, dolayısıyla kök yerleşimli bir repo onboarding'de
  reddedilirdi. İki çıkış vardı — sözleşmeyi uygulamaya uydurmak ya da
  uygulamaya bağlantı başına `basePath` eklemek. Birincisi seçildi (kullanıcı
  kararı): tek kural her repoda geçerli olur, app hiç değişmez ve "yalnız
  `hub/tasks/inbox`'a yazar" garantisi derleme zamanı sabiti olarak kalır.
  Bedeli, yalnız hub verisi içeren bir repoda bir seviye fazladan klasör.
  → Sözleşme 1.3, `artifacts/reference/proje-ekleme.md`
- **K-021:** Arşive kaldırılan bir projenin belgeleri, o proje için ayrı hub
  reposu açılmadan **takip hub'ında referans arşiv** olarak tutulur
  (`artifacts/reference/<proje>/`). Project Taskr'da uygulandı: proje arşive
  kaldırıldığı için `project_taskr_takip` açılmadı, 35 belge kaynak yolları
  belirtilerek olduğu gibi taşındı. Gerekçe: ölü bir proje için ayrı repo +
  token + bağlantı bakımı, salt okunur tarihçe karşılığında fazla yük. Proje
  yeniden canlanırsa belgeler kendi `<proje>_takip` hub'ına taşınır.
  → `artifacts/reference/project-taskr/arsiv-dizini.md`
- **K-022:** Görev akışı **iki yönlü** modellenir: `tasks/waiting/`,
  agent'ın kullanıcıdan somut bir şey beklediği durumdur. Alternatifler
  elendi — (a) frontmatter alanı (`waiting_on: user`): durumun bir kısmı
  klasörde bir kısmı alanda olurdu, "durum = klasör" (K-004) bozulurdu ve
  listeler dosya indirmeden çizilemezdi; (b) yalnız `BACKLOG.md`'nin `(user)`
  maddelerini yüzeye çıkarmak: backlog yol haritası ölçeğinde, günlük
  "token üret" işiyle karışırdı. Ölçek ayrımı korundu: kısa vadeli somut
  işler `waiting/`, yol haritası işleri backlog.
  **R-001 gevşetilmedi:** kullanıcı işi bitirince app dosyayı taşımaz,
  inbox'a bildirim görevi yazar; taşımayı agent yapar. App'in yazma alanı
  tek klasör kalır ve bu garanti derleme zamanı sabitidir.
  → Sözleşme 1.4, B-065, L-018
- **K-023:** Belgeden seçilerek üretilen kayıtlar **normal görevdir**; ayrı
  bir dosya türü veya klasör açılmadı. R-001 korunuyor (app yalnız `inbox/`a
  yazar) ve agent bunları zaten bildiği döngüde ele alıyor. Ayırt edici olan
  `category` (gorev/yorum/duzeltme/tartisma) ve üç bağlam alanı
  (`source`/`quote`/`mark`).
  **İşaret ayrıca saklanmıyor, kayıttan türüyor.** Alternatif — işareti
  cihazda ya da ayrı bir dosyada tutmak — işaret ile kaydın ayrışmasına açıktı:
  kayıt kapanır işaret kalır, ya da cihaz değişir işaret gider. Türetilmiş
  olduğu için böyle bir tutarsızlık **mümkün değil**. Bedeli: alıntı belgede
  bulunamazsa işaret çizilmez; bu kabul edildi çünkü belge değişmesi normal ve
  kayıt yine geçerli kalıyor. → Sözleşme 1.5, B-069
- **K-024:** Sözleşmenin **ana kopyası** `afgover/takip`'tedir; diğer hub'lar
  ondan türer. Bayatlama kaçınılmaz olduğu için **fark edilmesi** iki yerden
  garantiye alındı: agent her oturum açılışında sürümü karşılaştırıp
  güncelliyor, uygulama da geride kalan repoyu Ayarlar → Repolar'da
  işaretliyor. Tek yere bırakılsaydı — yalnız agent'a — atlandığında kimse
  görmezdi; `financer_takip` tam olarak böyle 1.3'te kalmıştı (L-020).
  Sözleşme yalnız ana kopyada değiştirilir. → Sözleşme 1.5 §10, B-070
- **K-025:** Bir projede doğan iyi bir sözleşme kuralı **ana kopyaya taşınır**,
  o projede bırakılmaz. `financer_takip`'in agent'ı `reconstructed` alanını
  kendi kopyasına eklemişti (bağlam sıkıştırması yüzünden geriye dönük yazılan
  oturumu dürüstçe işaretlemek için). Kural iyiydi; ana kopyaya alınıp sürüm
  1.6'ya çıkarıldı, sonra o hub güncellendi — yani yerel ekleme kaybolmadı,
  herkese yayıldı. Alternatif (körü körüne üzerine yazmak) kuralı sessizce
  silerdi. Bu olay §10'daki sürüm kontrolünün eksiğini de gösterdi: iki hub
  aynı numarayı farklı değişikliklerle almıştı (L-022).
  → Sözleşme 1.6, B-072
- **K-026:** App, **kendi yazdığı ve hâlâ `inbox/`ta duran** bir kaydı
  silebilir (sözleşme 1.7). R-001 gevşemedi: app'in dokunduğu tek klasör hâlâ
  `inbox/` ve silme yol değil dosya adı alıyor, yani başka klasöre uzanması
  yapısal olarak mümkün değil. Agent kaydı `active/`e almışsa dosya orada
  değildir ve silme çalışmaz — ele alınmış bir işi sessizce yok etmek agent'ın
  çalışmasını çöpe atardı. Gerekçe: kullanıcı yanlışlıkla koyduğu bir işareti
  geri alabilmeli; bunun için agent'a görev açmak, tek dokunuşluk bir hatayı
  iki tarafın işine çevirirdi. → B-082
- **K-027:** İşaretler artık `MarkdownElementBuilder`'ın döndürdüğü
  `Text.rich` ile çiziliyor; `flutter_markdown` `Text` türündeki satır içi
  çocukları komşu metinle tek bir `RichText`e kaynattığı için işaret, metin
  akışının doğal parçası oluyor. Üç turdur çözülemeyen "alt satıra kayma"
  sorununun kalıcı cevabı bu. Alternatifler (paragrafı blok çiziciyle baştan
  çizmek, stil sözlüğüne özel etiket eklemek) paket tarafından kapalı; ikisi
  de denenip ölçümle elendi. → L-032, B-086
- **K-028:** Çok kaynaklı bir liste, listeden **açılan yolları** da çok
  kaynaklı yapmayı zorunlu kılıyor. Bekleyenler tüm repoları birleştirdiğinde
  detay okuma hâlâ aktif repoya bakıyordu ve başka repodaki görev "bulunamadı"
  diyordu. Artık kayıtla birlikte taşınan `repoSlug`, okuma/yazma/silmenin
  hepsinde hedefi belirliyor. → L-031, B-085
- **K-029:** Not, görev değildir (sözleşme 1.9, §11). Kullanıcı bir belgede
  metin seçip kendine not aldığında bu kayıt `notes/`a gidiyor; agent'ın iş
  kuyruğuna girmiyor. Önceki hâlde tek yazma alanı `tasks/inbox/` olduğu için
  kullanıcının kendine yazdığı her satır otomatik olarak agent'a iş oluyordu ve
  Bekleyenler'de görünüyordu — kullanıcının bildirdiği sorun buydu.
  R-001'in **özü korunarak** genişletildi: alan hâlâ kapalı bir küme
  (`HubFolder` enum'u) ve app yol değil dosya adı veriyor, yani üçüncü bir
  klasöre yazması tip düzeyinde imkânsız.
  Sarı işaret ve kırmızı çizgi bilinçli olarak **göreve gitmeye devam ediyor**:
  onlar agent'a sinyaldir ("buraya bak", "burası yanlış"). Ayrımı kullanıcının
  niyeti belirliyor, işaretin rengi değil. → B-088
- **K-030:** Güvenlik geçmişi tek bir canlı dosyada tutuluyor (`SECURITY.md`,
  sözleşme 1.10 §12): taramalar, alınan önlemler, bilinen açıklar ve yapılacak
  güvenlik işleri ID'li kayıtlar hâlinde. Gerekçe: bu bilgi şimdiye kadar
  oturum kayıtlarına ve `knowledge/rules.md`'ye dağılmıştı ve "bu konuda ne
  yapmıştık" sorusunun tek bir cevabı yoktu. Biçim `knowledge/` ile bilinçli
  olarak ortak — ayrı bir çözümleyici yazmak aynı fikrin iki yerde
  ayrışmasına yol açardı; nitekim ilk denemede kopyalanan regex bozuktu.
  Uygulamada Tarayıcı → Security altında, açık kayıtlar üstte listeleniyor.
  Tarayıcıdaki "Bekleyen görevler" kutusu kaldırıldı: alt menüde kendi sekmesi
  var ve aynı ekrana iki kapı, ikisinden birinin bayat kalmasına yol açıyor.
  → B-090
- **K-031:** Yeni bir kayıt türü eklenirken commit öneki de sözleşme §8'e
  yazılır. `notes/` (1.9) ve `SECURITY.md` (1.10) eklenirken bu atlanmıştı;
  sonuç, kullanıcının kendi notunun aktivite akışında "kod commit'i" olarak
  görünmesiydi — sessiz, çünkü hiçbir şey hata vermiyor, yalnız yanlış
  etiketleniyor. 1.11'de `note:` ve `security:` önekleri sözleşmeye ve
  uygulamanın ayrıştırıcısına eklendi. Test artık öneki **sözleşme dosyasından
  okuyup** uygulamanın tanıdığını doğruluyor, yani listeyi elle senkron tutmak
  gerekmiyor. → B-093
- **K-032:** Açık kaynak ve store dağıtımı **ayrı kararlar** olarak ele alındı;
  aynı kefeye konmaları yanlış olurdu çünkü maliyet profilleri temelden farklı.
  Repoyu açmak tek seferliktir ve kimse ilgilenmezse sürekli bir yükü yoktur.
  Store ise **tekrar eden bir taahhüt**: Google'ın yıllık hedef SDK yükseltmesi
  yapılmazsa uygulama listeden gizlenir, Apple periyodik yeniden derleme ve her
  güncellemede inceleme ister, gizlilik politikası güncel tutulmalıdır. Bakımsız
  bir store uygulaması durmaz, **çürür ve kaldırılır** — "koyup unutmak"
  seçeneği yok.
  Beklenen kazanç da ayrıştırıldı. Asıl varlık uygulama değil, **yöntem**:
  sözleşme + protokol + kurulum talimatı, hiçbir şey kurmadan benimsenebiliyor.
  Açık kaynağın somut getirisi bu yöntemin yayılması ve reponun yargı kanıtı
  olması (31 oturum kaydı, 34 numaralı ders, kendi açıklarını dürüstçe listeleyen
  güvenlik logu). Store'un bu getiriye katkısı yok denecek kadar az; karşılığında
  getireceği kullanıcı da bugünkü hâliyle (Türkçe tek dil, PAT ile onboarding)
  onlarca mertebesinde.
  Gelir beklenmiyor: ücretsiz + backend yok + MIT. MIT ayrıca üçüncü birinin
  aynı uygulamayı kendi adıyla yayımlamasına izin verir; bilinerek kabul edildi.
  **Bu projeye özel bedel:** §10 zinciri bu reponun raw adresini işaret ettiği
  için benimsenme, sözleşmede hızlı iterasyon özgürlüğünü bitirir — bugün bir
  günde 1.8→1.11 yapıldı, bu esneklik bugünkü en büyük avantaj.
  **Karar:** sıra bozulmayacak — önce repo + yöntemi anlatan yazı + GitHub
  Releases'ta APK; store yalnız **gerçek talep** gelirse ve ancak B-061 (GitHub
  App/OAuth) ile SEC-006 kapandıktan sonra. Talep gelmezse hiçbir şey kaybedilmiş
  olmaz. → B-097

- **K-033:** Sözleşme 1.12 iki eksiği kapattı ve ikisi de aynı boşluğun
  yüzleriydi: sistem kullanıcıya **soru soramıyordu** ve kullanıcı bir yeri
  **sonra bulmak üzere** işaretleyemiyordu.
  **(a) Seçenekli bekleme.** 1.4'ten beri `waiting/` vardı ama kullanıcının tek
  cevabı "Yaptım"dı; bir *karar* sorulduğunda karşılığı yoktu ve cevap
  sohbette kalıyordu — yani `waiting/`in var oluş sebebine (sohbet kapanır,
  kayıt kalır) aykırı bir yerde birikiyordu. Agent artık `options` yazıyor,
  kullanıcı seçiyor. Seçimin yanında **her zaman** isteğe bağlı açıklama var:
  seçenek listesi cevabı makinece okunur kılar, serbest metin listede olmayan
  durumu söyler; biri diğerinin yerine geçmez. Seçenek yoksa 1.11 davranışı
  aynen sürüyor — eski görevler bozulmadı. "Bir görev = bir soru" kuralı
  bilinçli: aynı dosyaya ikinci cevap, agent'ın kuyruğunda hangisinin geçerli
  olduğu belirsiz iki kayıt bırakırdı.
  **(b) Yer imi.** Dördüncü işaret (mavi) ve ilk defa **göreve dönüşmeyen** bir
  işaret (R-007). B-099'da ayrımı notun varlığı yapıyordu (notsuz → not, notlu
  → görev); yer iminde niyet zaten adında, o yüzden notlu olsa bile `notes/`a
  gidiyor. Asıl iş işaretin kendisi değil **listesi**: bütün repolardaki
  işaretler tek yerde toplanmadan yer imi işe yaramaz — "burayı sonra bulayım"
  ancak sonradan bulunabiliyorsa bir anlam taşır. Liste çok kaynaklı olduğu
  için açılan yol da çok kaynaklı yapıldı (`docContentForProvider`); L-031 ve
  L-034'ün üçüncü tekrarı, bu sefer baştan doğru kuruldu. → B-104, B-105
- **K-034:** Bir listenin kapsamı, listedeki **kaydın ne işe yaradığına** göre
  seçilir; "birleştirebiliyoruz" bir gerekçe değildir. İşaretler listesi 1.12'de
  bütün repoları birleştiriyordu ve aynı gün, ilk kullanımda ters teptiği
  görüldü: işaret bir belgedeki **yeri** hatırlatır, belge de bir projeye aittir
  — hepsi tek listede olunca ekran bağlam yığınına dönüyor. 1.13'te liste aktif
  repoya bağlandı (K-028'in çoklu-repo yönünü tersine çeviren değil,
  **tamamlayan** bir karar: teknik olarak birleştirebilmek, birleştirmenin doğru
  olduğu anlamına gelmiyordu).
  Ayrım şu soruyla yapılıyor: kayıt **nereye** ait? Bekleyenler birleşik kalıyor
  çünkü oradaki soru "hangi projede olursa olsun **bende** bekleyen ne var" —
  kaydın sahibi kullanıcı. İşaretler tek repoya bağlı çünkü oradaki soru "**bu
  belgede** ne işaretlemiştim" — kaydın sahibi belge.
  Tek repoya bağlı her listenin **hangi repo olduğunu yazması** da bu kararın
  parçası: yazmazsa kullanıcı eksik bir listeyi tam sanar ve bu, boş liste
  görmekten kötüdür. → B-106
- **K-035:** Tekrarlanması gereken bir işin **hatırlatıcısı, işin kaydının
  kendisinde** durur. Tarama tekrarı için üç seçenek vardı: takvim (haftalık
  cron), olay (her sürüm öncesi) ve kaydın yaşı. Kaydın yaşı seçildi: agent
  oturum açılışında `SECURITY.md`'deki son `tarama` kaydının tarihine bakıyor,
  30 günden eskiyse yeniliyor.
  Gerekçe, "daha az altyapı"dan fazlası. Takvime bağlı bir hatırlatıcının
  kendisi bakım ister ve sustuğunda **sessizce** susar — kimse "cron çalışmadı"
  diye bir bildirim almaz. Kaydın yaşı ise hub'ın içinde duruyor: hem agent hem
  kullanıcı aynı dosyaya bakıyor, tarama gecikmişse bu, uygulamanın Security
  ekranında da görünür bir veri. Yani hatırlatma, unutulduğunda **görünür**
  kalıyor — bu sistemin geri kalanıyla aynı ilke ("hub'a yansımayan iş,
  yapılmamış sayılır").
  Kapsam da katmanlara ayrıldı: bilinen zafiyet Dependabot'a devredildi (sürekli
  ve bakımsız), otomatik gözcüsü olmayan parçalar (sır, Android yapılandırması)
  `tool/scan.sh`'ta kaldı. Zamanlanmış bir GitHub Actions işi elendi çünkü
  Dependabot'un kapsadığı yeri ikinci kez kapsayıp geriye yalnız kendi bakımını
  bırakırdı.
  **Yan karar:** `AGENT_PROTOCOL.md` değişikliği de sözleşme sürümünü artırır.
  §10'un yayılma mekanizması yalnız `SYSTEM.md`'nin sürüm numarasına bakıyor;
  protokol tek başına değiştirilseydi diğer hub'lar yeni kuralı **hiç** almaz
  ve bunu fark eden bir kontrol de olmazdı. → B-102, SEC-011
- **K-036:** Çoklu kullanıcıda **kimlik**, eşzamanlılıktan önce gelir. İlk
  bakışta sorun "iki kişi aynı anda yazarsa ne olur" gibi görünüyor; ölçünce
  asıl boşluk başka çıktı: sistemde "kim" diye bir kavram **hiç yoktu**.
  `created_by` bir roldü (`user`/`agent`), kimlik değil; `waiting/`in tanımı
  ("agent **kullanıcıyı** bekliyor") birkaç kişide öznesiz kalıyordu ve herkes
  "herhalde diğeri bakar" diye geçerdi. Karmaşanın büyük kısmı çakışmadan değil
  bu belirsizlikten gelir, ve çözümü en ucuz olan katmandır.
  Eşzamanlılık ikinci sırada ele alındı ve **imkânsız kılınmadı, görünür
  kılındı.** ID biçimini değiştirmek (kullanıcı öneki, rastgele ID) çakışmayı
  yapısal olarak bitirirdi ama bugüne kadarki yüzlerce çapraz atfı ikinci
  sınıfa düşürür, iki biçimi kalıcı olarak yan yana yaşatırdı. Bunun yerine
  hub'ı okuyan bir test tekrarlı ID'yi yakalıyor — projenin tekrar eden ilkesi
  (sessiz bozulma, gürültülü bozulmadan kötüdür; L-035, L-039, K-035) burada da
  ölçü oldu.
  **Yapısal olanı yapısal bırakmak:** notlar `notes/<login>/` altına alındı,
  alan değil klasör. Alanla ayırmak daha az işti ama "agent notlara dokunmaz"
  garantisini bir kurala indirgerdi; klasörle sahiplik dosya açılmadan
  okunabiliyor. R-001'in kapalı kümesi korundu — app hâlâ yol değil **ad**
  veriyor ve ad, yol parçasına dönüşmeden temizleniyor.
  **Ertelenen:** `assignee` yazımı ve paylaşılan dosya kuralları (Katman 3-4)
  ikinci kişi gelene kadar bekliyor. Kullanılmayan bir soyutlamayı önceden
  taşımak, onu test edilmemiş hâlde eskitir. → B-108, B-109, B-110
- **K-037:** Dil, **hub'ın özelliğidir**; cihazın tercihi değil. Kurulumda
  seçilir ve üç şey birden onu izler: sözleşme (agent referansı oradan alır),
  uygulama arayüzü, ve o andan sonra üretilen kayıtlar.
  Bu karar 1.18'i **tersine çevirdi**. Orada "arayüz dili ≠ kayıt dili; gövde
  başlıkları Türkçe sabit" demiştim ve gerekçem geçerliydi: aynı hub'da iki
  başlık şeması oluşursa mevcut kayıtlar ayrıştırılamaz. Ama çözümü yanlış
  yerden almışım — tutarlılığı **şemayı tek bir dile sabitleyerek** değil,
  **hub başına tek dil** ile sağlamak gerekiyordu. Benimki İngilizce çalışan
  birine Türkçe başlıklı kayıtlar yazdırırdı, yani dil seçeneğini eklemenin
  sebebini (yöntemin başka dilleri konuşanlara açılması) baştan çürütürdü.
  **Genelleştirilebilir kısım:** bir tutarlılık sorununu çözerken "neyi sabit
  tutayım" diye sormak, çoğu zaman yanlış soru. Doğrusu "tutarlılığın sınırı
  nerede" — burada sınır hub'dı, şema değil. Sınırı doğru koyunca sabitlemeye
  gerek kalmadı.
  **İki yan karar:** (a) ayrıştırıcı hub'ın ilan ettiği dille sınırlanmıyor,
  bütün dillerin başlıklarını tanıyor — dil alanı eklenmeden önceki kayıtlar,
  elle düzenlemeler ve dili değişmiş hub'lar var; geniş kabulün maliyeti yok,
  dar kabulün maliyeti okunamayan kayıt. (b) Ayarlardaki dil seçici bir tercih
  olmaktan çıkıp **bilgi**ye dönüştü: uygulama `SYSTEM.md`'ye yazamaz (R-001),
  dolayısıyla dili değiştiremez. Hiçbir şeyi sürmeyen ama sürüyormuş gibi duran
  ayar silindi. → B-117
- **K-038:** Bir mekanizmanın **girişi**, mekanizmanın kendisi kadar iş.
  Dil alanı okunuyordu, sözleşme onu tanımlıyordu, arayüz onu izliyordu — ama
  alanı **yazan yol yoktu** ve yazılmasını anlatan belgenin kendisi Türkçe'ydi.
  Yani özellik teknik olarak tamdı ve pratikte kullanılamazdı: İngilizce
  konuşan biri ne dili seçebiliyor ne de nasıl seçeceğini okuyabiliyordu.
  Kırılma noktası, girişin **kullanıcının bulunduğu yerden** başlaması:
  README → kurulum talimatı → agent'ın ilk sorusu. Zincirin her halkası, bir
  öncekini okuyamayan için işe yaramaz.
  **Genelleştirilebilir kısım:** "özellik bitti mi" sorusunun cevabı,
  özelliğin ilk kullanıcısının onu nereden bulacağıyla ölçülür. Mekanizmayı
  yazan kişi girişi zaten bildiği için, eksik olduğunu **fark edemeyecek tek
  kişi** odur. → B-118
- **Sözleşme 1.20 (2026-08-08):** Aynı anda yalnız bir oturum açık olabilir, o
  da en yeni tarihli olan. Kural, kapanışta 30 Temmuz'dan beri `open` duran bir
  oturum bulunmasıyla kondu — projenin kurucu kararlarını (K-008…K-012)
  taşıyan, özetsiz bir oturum. Kapanış listesi "bu oturumu kapat" diye
  soruyordu; "açık kalan var mı" diye sormuyordu, yani hiçbir oturum bütüne
  bakmakla yükümlü değildi. Kural `session_state_test`'e bağlandı: cevabı
  repoda duran bir soru insana bırakılmaz (L-041, L-042).
- **K-039:** Aynı metin, **kim okuyacağına** göre farklı yerden gelir.
  Bir ekranda görünen her Türkçe cümle "arayüz metni" değil: güvenlik kaydının
  `Tür`/`Durum` alanları ve `waiting/` bildirimlerinin gövdesi ekranda görünüyor
  ama **dosyada duruyor**. İkisini aynı çeviri katmanına koymak, dosyada duran
  bir alan adını okuyanın diline göre değiştirmek demekti — aynı hub'da iki
  yazım birikir ve eski kayıtlar okunamaz hâle gelir.
  Ayrım sorunun kendisinde: arayüz "**okuyan** hangi dili konuşuyor" sorusuna,
  kayıt "bu dosya **hangi hub'a** yazılıyor" sorusuna cevap veriyor. Çoklu
  repoda ikisinin cevabı farklı olabiliyor, o yüzden arayüz aktif hub'ın,
  kayıt yazılacak reponun dilini izliyor (L-019'un aynı gerekçesi).
  Okuma tarafı ise bilerek **geniş**: ayrıştırıcı bütün dillerin alan adlarını
  tanıyor. Geniş kabulün maliyeti yok, dar kabulün maliyeti okunamayan kayıt.
  **Genelleştirilebilir kısım:** "bunu çevirelim mi" sorusunun cevabı metnin
  göründüğü yerde değil, **durduğu** yerde. Ekranda görünen bir şey veri
  olabilir; veri, onu okuyan kişinin diline göre değişmez.
- **Sözleşme 1.21 (2026-08-08):** Dil varyantları. Ana kopya `SYSTEM.md` (tr,
  **kanonik**) ve `SYSTEM.en.md` (en) olarak iki dosyada; her hub kendi diline
  uyanı çeker ama kendi hub'ında **düz adla** saklar. Dil ekini hub tarafına
  taşımak, sözleşmedeki her yolu dile bağımlı kılardı ve uygulamanın dosyayı
  bulmak için önce dili bilmesi gerekirdi — ama dili o dosyadan okuyor.
  Kanonik olanın Türkçe olması belgelerin **içinde** yazılı: dışarıda dursa,
  belgeyi tek başına okuyan iki eşit otorite görürdü (L-022).
- **Sözleşme 1.22 (2026-08-11):** §13 **Geçici maddeler**. Yalnız belirli bir
  sürümden önce kurulmuş hub'ları ilgilendiren ve işi bitince kaldırılacak
  kurallar için ayrı bölüm; ilk madde G-001 (1.12 öncesi `waiting/` sorularına
  seçenek ekleme).
  Ayrım yapısal: sıfırdan kurulan bir hub'da bu maddeler hiçbir şey yapmaz ve
  sözleşmenin gövdesinde dursalardı, yöntemi ilk kez okuyan biri için kalıcı
  kural gibi görünürlerdi. Bölüm her maddeden **kalkma koşulu** istiyor —
  koşulu olmayan geçici bir madde, kalıcı bir maddedir.
- **Sözleşme 1.23 (2026-08-11):** 30 dakika ritmi. Açık oturumun kayıtları en
  geç 30 dakikada bir push'lanır; aynı ritimde ve uzun aradan dönüşte
  `tasks/inbox/` kontrol edilir. Tek sayı, üç sayaç yerine — ve gerekçe
  sözleşmede zaten yaşıyordu: `reconstructed: true` (v1.6) tam bu boşluktan
  doğmuştu, ara kayıt boşluğu daraltıp o istisnayı ihtiyaç olmaktan çıkarmayı
  hedefliyor.
- **Sözleşme 1.24 (2026-08-12):** Bildirim hedef hub'ını kendisi söyler
  (`- **Repo:**` satırı) ve agent kapatmadan önce doğrular. Gerekçe yaşanmış
  vaka: uygulamanın kuyruğu üç bildirimi yanlış hub'a düşürdü (B-126, L-045)
  ve hub başına verilen ID'ler çakıştığı için az kalsın yanlış görevler
  kapatılıyordu (goverco L-009). Doktrin katmanı (yabancı kayda dokunmama,
  dosya adıyla doğrulama, §10 yükseltme yolu) hasarı önledi; yapısal boşluğu
  bu sürüm kapattı.
