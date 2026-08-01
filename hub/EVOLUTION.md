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
