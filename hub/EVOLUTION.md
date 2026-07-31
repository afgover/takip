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

## Aşama 2 — Uygulama MVP'si (aktif)

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
- Sıradaki: kullanıcı adımlarından sonra B-034'ün cihaz koşumu ve B-035;
  ardından Faz 4 (hub tarayıcı) — B-026 de aradan alınabilir.

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
