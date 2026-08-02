# BACKLOG.md — Yapılacak İşler

Tek doğru kaynak. Biçim:

```
- [ ] B-001 · (sorumlu) Başlık — açıklama
- [x] B-002 · (sorumlu) Başlık — ✅ 2026-07-30 · sonuç/link
```

Sorumlu: `agent` | `user` | `agent+user`. Tamamlanan iş silinmez, işaretlenir ve
listede kalır. Yeni işler ilgili faza ID sırasıyla eklenir. Faz tamamlanınca faz
başlığına ✅ ve tarih yazılır.

---

## Faz 0 — Karar & Araştırma ✅ (2026-07-30)

- [x] B-001 · (agent) GitHub erişim modeli araştırması — ✅ 2026-07-30 ·
      Fine-grained PAT / GitHub App / OAuth karşılaştırıldı; klasör bazlı izin
      olmadığı, iznin repo seviyesinde olduğu doğrulandı.
- [x] B-002 · (agent) Yeniden yapılandırma fizibilitesi — ✅ 2026-07-30 ·
      GitHub-omurga mimarisi mevcut backend'e kıyasla değerlendirildi; onaylandı.
- [x] B-003 · (agent+user) "Ayrı repo mu, klasör mü?" kararı — ✅ 2026-07-30 ·
      Ayrı private hub reposu kararlaştırıldı (izin izolasyonu + branch sadeliği).
- [x] B-004 · (agent) Anlık senkron seçenekleri araştırması — ✅ 2026-07-30 ·
      Webhook+relay vs polling; webhook 2. plana alındı, ilk sürüm ETag'li polling.
- [x] B-005 · (agent) Contents API maliyet değerlendirmesi — ✅ 2026-07-30 ·
      Görev yazma = tek PUT; rate limit ve gecikme açısından sorunsuz.

## Faz 1 — Hub Tasarımı & Kurulumu ✅ (2026-08-01)

- [x] B-010 · (agent) Format sözleşmesi (`SYSTEM.md`) taslağı — ✅ 2026-07-30
- [x] B-011 · (agent) Agent kayıt prosedürü (`AGENT_PROTOCOL.md`) taslağı — ✅ 2026-07-30
- [x] B-012 · (agent) Backlog / evrim / knowledge iskeletleri — ✅ 2026-07-30
- [x] B-013 · (user) Yeni hub reposunu oluştur ve agent'a bildir — ✅ 2026-07-30 ·
      `afgover/taskr_takip` (önce yanlışlıkla `takip` kullanıldı; bkz. K-007, L-003)
- [x] B-014 · (agent) `hub-template/` içeriğini yeni repoya taşı, ilk commit'leri
      sözleşme kurallarıyla at — ✅ 2026-07-30 · S-2026-07-30-hub-tasima
- [x] B-015 · (user) Uygulama için fine-grained token üret — Only select
      repositories → `takip`; `Contents: R&W`, `Metadata: R` (K-012)
      — ✅ 2026-08-01 · S-2026-08-01-b020-mac-kurulum; token üretildi ve
      cihazdaki onboarding ekranından doğrulandı: uygulama hem okuma hem yazma
      kontrolünü (B-022, B-026) geçip `afgover/takip`'e bağlandı. Token
      yalnızca cihazın güvenli deposunda; hiçbir kayda veya commit'e girmedi
      (R-005)
- [x] B-016 · (agent+user) Sözleşmeyi ilk gerçek oturumla test et: bir oturum
      kaydı + bir görev döngüsü (inbox → active → done) elle işlet, pürüzleri
      `knowledge/lessons.md`'ye yaz — ✅ 2026-07-30 · T-001,
      S-2026-07-30-duzeltme-ve-dongu-testi; dersler: L-003, L-004
- [x] B-017 · (agent) Sözleşme test sonuçlarına göre `SYSTEM.md` 1.1 revizyonu
      (gerekirse) — ✅ 2026-07-30 · revizyon ihtiyacı çıkmadı, sözleşme 1.0 kaldı

## Faz 2 — Flutter Uygulama İskeleti ✅ (2026-08-01)

- [x] B-020 · (user) Flutter ortamı hazırlığı (SDK kurulumu) — platform kararı
      verildi: Android öncelikli (K-009). İlk kurulum: `takip` reposunda
      `flutter create . --platforms=android && flutter pub get &&
      flutter analyze` (iskeletin derleme doğrulaması dahil)
      — ✅ 2026-08-01 · S-2026-08-01-b020-mac-kurulum; takip@212c294.
      SDK kurulumu gerekmedi (Flutter 3.35.4 ve Android Studio zaten kuruluydu).
      `android/` üretildi, paket adı **`us.gover.takip`** (domain `gover.us`).
      Debug APK derlendi, gerçek cihaza (SM F731B, Android 16) kuruldu ve
      çalıştırıldı; onboarding'den repoya bağlanma doğrulandı. Sürüm farkı
      (3.27.1 → 3.35.4) tek deprecation üretti, düzeltildi: `analyze` temiz,
      191 test geçiyor. Üretilen manifest'te INTERNET izni eksikliği bulunup
      giderildi (→ L-010), `flutter create`'in bıraktığı artıklar temizlendi
      (→ SK-007). Ayrıca L-011, SK-008
- [x] B-021 · (agent) Proje iskeleti (`afgover/takip` çatı reposunda, K-011):
      klasör yapısı, state management (Riverpod), tema, navigasyon —
      `artifacts/reference/flutter-app-design.md` §3'e göre — ✅ 2026-07-30 ·
      takip@417da6b; SDK'sız ortamda elle yazıldı, derleme doğrulaması
      B-020'ye bağlı. Onboarding/ekran taslakları dahil; API katmanı
      TODO(B-023) işaretli
- [x] B-022 · (agent) Onboarding ekranı: token + repo adı girişi, token'ın
      `flutter_secure_storage`'a kaydı — ✅ 2026-07-30 ·
      S-2026-07-30-b022-onboarding; kaydetmeden önce tek GET ile doğrulama
      (`hub/` kökü), anlaşılır hata kutusu, token göster/gizle, yapıştırılan
      GitHub adresini kabul eden repo ayrıştırma, "token nasıl alınır"
      yardımı. 71 test, analyze temiz. → L-007
- [x] B-023 · (agent) GitHub istemci katmanı: Contents API (get/put/delete),
      base64, SHA yönetimi, hata modeli — ✅ 2026-07-30 ·
      S-2026-07-30-b023-github-istemci; `flutter analyze` temiz, 27 test geçti.
      R-001 yapısal kapıya bağlandı (`TaskRepo.writeToInbox`); dersler L-005,
      L-006; skill SK-003
- [x] B-024 · (agent) ETag'li polling servisi: foreground'da 30–60 sn aralıkla
      değişiklik kontrolü, 304'te sessiz geçiş — ✅ 2026-07-30 ·
      S-2026-07-30-b024-etag-polling; `EtagCache` + `If-None-Match`
      interceptor'ı (doğrulama önbelleği: bayat veri göstermez),
      `HubWatcher` tek commit isteğiyle değişiklik izliyor, arka planda
      duruyor; auth hatasında durur, rate limit'te reset'e kadar bekler.
      87 test, analyze temiz. → SK-005
- [x] B-025 · (agent) Frontmatter parser (yaml) + markdown render altyapısı —
      ✅ 2026-07-30 · S-2026-07-30-b025-frontmatter-markdown; parser CRLF/BOM
      ve bozuk YAML'a dayanıklı, tipli erişimciler + round-trip güvenli
      serializer (SK-004). `HubMarkdown` widget'ı GitHub eklenti setiyle
      (tablo, `~~üstü çizili~~`, görev kutusu) tema uyumlu çiziyor.
      Sözleşme uyum testi eklendi: parser gerçek hub dosyalarına karşı
      koşuyor. 55 test, analyze temiz
- [x] B-026 · (agent) Onboarding'de **yazma izni** doğrulaması — ✅ 2026-07-30 ·
      S-2026-07-30-b026-yazma-izni. Araştırma sonucu: `permissions.push`
      **kullanılamaz** — alan token'ın kapsamını değil kullanıcının rolünü
      yansıtıyor, token'larla hatalı değerler döndüğü bildirilmiş ve token
      izinlerini sorgulayan belgelenmiş bir uç nokta yok (L-009). Onun yerine
      yan etkisiz yoklama: `content` alanı olmayan bir PUT gönderiliyor — bu
      istek izin olsa bile hiçbir dosya oluşturamaz, ama izin yoksa 403 döner
      (SK-006). Yorum tek yönlü: 403 "izin yok" demek, 403 gelmemesi "izin var"
      demek değil — kontrol yanlış alarm veremez. Eksik izin adı
      `X-Accepted-GitHub-Permissions` başlığından okunup mesaja konuyor

## Faz 3 — Todo Döngüsü (MVP çekirdeği) ✅ (2026-08-01)

- [x] B-030 · (agent) "Görev ekle" ekranı: başlık, açıklama, öncelik, kategori →
      `tasks/inbox/<tarih>-<slug>.md` olarak PUT — ✅ 2026-07-30 ·
      S-2026-07-30-faz3-todo-dongusu; `TaskDraft` (dosya adı + içerik + commit
      mesajı) yazma yolunun tek kaynağı, JSON'a çevrilebilir olduğu için
      outbox da aynı taslağı gönderiyor. `id: pending` — ID'yi agent atar.
      Kategoriler K-010'a göre: varsayılanlar + cihazda biriken + serbest
      giriş (bütün görev dosyalarını indirmemek için)
- [x] B-031 · (agent) Bekleyenler ekranı: `inbox/` + `active/` listesi, durum
      rozetleri, görev detayı görünümü — ✅ 2026-07-30 ·
      S-2026-07-30-faz3-todo-dongusu; liste iki klasör isteğiyle çiziliyor
      (dosya indirilmiyor), detay açılınca içerik çekilip `HubMarkdown` ile
      render ediliyor; yoklama değişiklik görünce liste kendiliğinden
      tazeleniyor. Boş/hata/yükleniyor durumları ayrı ayrı ele alındı
- [x] B-032 · (agent) Görev yazma dayanıklılığı: offline kuyruk (tek cihaz,
      basit: gönderilemeyen görev lokalde bekler, bağlantı gelince PUT edilir)
      — ✅ 2026-07-30 · S-2026-07-30-faz3-todo-dongusu; yalnız ağ hatası
      kuyruğa alınır (yetki hatası beklemekle düzelmez, hemen söylenir).
      Bağlantı sinyali için ayrı dinleyici yok: yoklamanın başarılı kontrolü
      "çevrimiçiyiz" demek (B-024 yeniden kullanıldı). Kuyruktakiler
      bekleyenler listesinin başında "Gönderilecek" rozetiyle görünüyor
- [x] B-033 · (agent) 409/SHA çakışması yönetimi: yeniden oku → yeniden dene —
      ✅ 2026-07-30 · S-2026-07-30-faz3-todo-dongusu; çakışmada dosya okunup
      iki durum ayrılıyor: (a) içerik aynı → görev zaten gönderilmiş, kopya
      açılmıyor (outbox yeniden denerken yanıtın kaybolduğu gerçek durum),
      (b) içerik farklı → aynı gün aynı başlıkla başka görev, ad sonuna sayı
      ekleniyor; üstüne asla yazılmıyor. 5 denemede çözülemezse anlaşılır hata
- [x] B-034 · (agent+user) Uçtan uca test: app'ten görev ekle → agent ele alsın →
      done'a taşısın → app'te "Tamamlananlar"da görünsün — ✅ 2026-08-01 ·
      **sözleşme ayağı 2026-07-30'da, cihaz ayağı 2026-08-01'de tamamlandı.**
      Yapılanlar: (1) gerçek
      ekranlarla, GitHub Contents API'sini taklit eden hub üzerinde tam döngü
      testi (ekle → agent taşır → app'te durum değişir → tamamlananlarda
      sonucuyla görünür) + ağ kesintisi senaryosu; (2) gerçek hub'da T-002:
      dosya app'in `TaskDraft` üreticisinden çıktığı gibi inbox → active →
      done geçirildi, biçim bozulmadı. → L-008
      Cihaz ayağı: kullanıcı telefondan görev ekledi → dosya gerçek GitHub'da
      inbox'a düştü (45cc3a5, sözleşmeye uygun) → agent T-003 atayıp
      `inbox → active → done` geçirdi → kullanıcı sonucu app'te
      "Tamamlananlar"da gördü. Zincirin tamamı gerçek GitHub üzerinden koştu.
      → S-2026-08-01-b020-mac-kurulum
- [x] B-035 · (agent) Test çıktılarını `knowledge/lessons.md`'ye işle —
      ✅ 2026-08-01 · döngü testinden L-008; cihaz koşumundan L-010 (release
      manifestinde INTERNET izni), L-011 (`flutter install` varsayılanı),
      L-014 (derleme türü değişikliği veriyi siler) ve SK-007/SK-008.
      T-003'ün uygulanmasından L-012 (türetilmiş asenkron provider bayattır),
      L-013 (yazma yolunda platform kanalı beklenmez), SK-009

## Faz 4 — Hub Tarayıcı (kategorili görüntüleme) ✅ (2026-07-30)

- [x] B-040 · (agent) Kategori ana ekranı: SYSTEM.md §9'daki 6 kategori —
      ✅ 2026-07-30 · S-2026-07-30-faz4-hub-tarayici; kategoriler gezinmeye
      bağlandı, ayrıca Aktivite ve Sözleşme kartları eklendi
- [x] B-041 · (agent) Oturumlar görünümü: liste + session.md render (özet üstte)
      — ✅ 2026-07-30 · liste tek ağaç isteğinden çiziliyor (dosya
      indirilmeden), belge açılınca frontmatter rozet + gövde markdown
- [x] B-042 · (agent) Raporlar & Planlar görünümü: artifacts listesi,
      frontmatter `type`'a göre filtre — ✅ 2026-07-30 · liste ağaçtan,
      başlık/tür frontmatter'dan tamamlanıyor (üst sınırlı, gerekçesi kodda);
      okunamayan artifact listeden düşmüyor
- [x] B-043 · (agent) Bilgi tabanı görünümü: rules/skills/lessons kayıtları —
      ✅ 2026-07-30 · üç dosya sekmeli; kayıtlar `## ID — başlık` bloklarından
      ayrıştırılıyor, geçersiz kılınanlar (R-004) üstü çizili işaretleniyor
- [x] B-044 · (agent) Yol haritası görünümü: BACKLOG.md ve EVOLUTION.md render
      — ✅ 2026-07-30 · iki sekme; görev kutuları ve üstü çizili kararlar
      GitHub'daki gibi çiziliyor (B-025 eklenti seti)
- [x] B-045 · (agent) Aktivite akışı: commit geçmişini §8 öneklerine göre
      okunur akışa çevir — ✅ 2026-07-30 · "task(T-001): active → done" →
      "T-001 tamamlandı"; K-012 gereği kod commit'leri ayrı tür sayılıp
      varsayılanda gizleniyor, düğmeyle açılıyor. Tanınmayan kalıpta mesaj
      olduğu gibi bırakılıyor (uydurma yok)
- [x] B-046 · (agent) Basit önbellekleme: son görülen içerik lokalde tutulur,
      açılışta önce cache gösterilir — ✅ 2026-07-30 · ETag önbelleği cihazda
      saklanıyor: açılışta ETag'ler elde olduğu için içerik 304'le anında
      geliyor, ağ yokken son bilinen içerik gösteriliyor (bayat olduğu
      işaretli). Sunucu hatası (401/500) önbellekle gizlenmiyor

## Faz 5 — Cilalama & Günlük Kullanım

- [x] B-050 · (agent) Hata durumları UX'i: token geçersiz, rate limit, ağ yok
      — ✅ 2026-07-30 · S-2026-07-30-faz5-cilalama; her hata tipi için başlık +
      ne yapılabileceği (`describeHubError`): token hatasında ayarlara giden
      düğme ve gereken izinler, rate limit'te kalan süre, ağ hatasında
      kuyruk hatırlatması. Ayrıca her ekranın üstünde duran durum şeridi:
      sorun bağlamdan bağımsız görünüyor. Yoklamanın çevrimdışıyken
      "her şey yolunda" sanması düzeltildi (B-046 ile oluşan etkileşim)
- [x] B-051 · (agent) Ayarlar: polling aralığı, token değiştirme, repo değiştirme
      — ✅ 2026-07-30 · S-2026-07-30-faz5-cilalama; aralık (30 sn…5 dk) diske
      yazılıyor ve çalışan yoklamaya anında uygulanıyor; bağlantı düzenleme
      B-022'deki kuralı sürdürüyor (doğrulanmadan kaydetme yok), token boş
      bırakılırsa yalnız repo değişiyor; önbellek temizleme ve onaylı
      sıfırlama (kuyrukta bekleyen görev varsa uyarıyla)
- [ ] B-052 · (user) Bir hafta gerçek kullanım; sürtünme noktalarını görev olarak
      inbox'a at — B-015, B-020 ve B-034'ün cihaz ayağı tamamlandıktan sonra
- [ ] B-053 · (agent) Kullanım geri bildirimlerine göre revizyon turu
- [x] B-067 · (agent) Bekleyenler tüm repolardaki işleri göstersin —
      ✅ 2026-08-02 · takip@ec267a3; senkron tüm bağlı repoları kapsıyor,
      liste yerel kopyadan çiziliyor
- [x] B-068 · (agent) Bekleyenlerde repo/öncelik/kategori filtresi ve satır
      etiketleri — ✅ 2026-08-02 · takip@ec267a3; seçenekler listede gerçekten
      geçen değerlerden türüyor, etiketi bilinmeyen görev filtreye takılmıyor
- [x] B-069 · (agent) Metin seçince kayıt oluşturma (görev/yorum/düzeltme/
      tartışma) ve sarı/kırmızı işaretleme — ✅ 2026-08-02 · takip@ec267a3;
      sözleşme 1.5 (K-023). İşaret kayıttan türüyor, ayrıca saklanmıyor.
      → L-021
- [x] B-070 · (agent) Sözleşme sürüm kontrolü ve güncelleme kuralı —
      ✅ 2026-08-02 · sözleşme 1.5 §10 (K-024); agent her oturum açılışında
      ana kopyayla karşılaştırıyor, uygulama geride kalan repoyu işaretliyor.
      → L-020
- [x] B-066 · (agent) Çoklu repoda geçiş sonrası "Bulunamadı" hatası —
      ✅ 2026-08-01 · takip@98f21be; S-2026-08-01-coklu-repo-404.
      Kök neden: isteğin adresi sağlayıcı kurulurken, token'ı istek
      gönderilirken okunuyordu; repo değişimi araya girince adres ve token
      farklı bağlantılara ait olabiliyordu (private repoda karşılığı 404).
      Token artık isteğin yolundan seçiliyor. → L-019
- [x] B-065 · (agent) Agent'ın kullanıcıdan beklediği işler uygulamada
      görünsün — ✅ 2026-08-01 · takip@90b9d42; sözleşme 1.4, `tasks/waiting/`
      (K-022). Sistem o güne kadar yalnız kullanıcı→agent yönünü modelliyordu;
      agent→user işleri sadece bu listede `(user)` etiketiyle duruyor ve
      uygulamada hiç görünmüyordu. Bekleyenler listesi üçüncü klasörü de
      okuyor, kullanıcıyı bekleyenler listenin başında. "Yaptım" düğmesi
      inbox'a bildirim yazıyor; R-001 korunuyor. İlk gerçek görev: T-004
- [x] B-058 · (agent) Yeni proje ekleme prosedürünü kalıcı belge yap —
      ✅ 2026-08-01 · `artifacts/reference/proje-ekleme.md`;
      S-2026-08-01-proje-ekleme-ve-arsiv. Beş adım (repo aç, token kapsat,
      iskelet kur, uygulamaya ekle, agent'a söyle) + sık karşılaşılanlar +
      projeyi arşive kaldırma. Yazarken sözleşme/uygulama çelişkisi bulundu →
      sözleşme 1.3, K-020
- [x] B-059 · (agent) project-taskr belgelerini takip hub'ına taşı —
      ✅ 2026-08-01 · 35 belge `artifacts/reference/project-taskr/` altında,
      kaynak yolları ve arşiv notlarıyla; dizin `arsiv-dizini.md`. Proje arşive
      kaldırıldığı için ayrı hub açılmadı (K-021). **Bulunamayan:** Project
      Taskr'ın yönettiği projelerin (CoPilot, Financer, Sarraf, DataSources)
      verisi repoda değil, uygulamanın veritabanındaydı; repoda yalnız ad
      olarak geçiyorlar
- [x] B-054 · (agent) Kurulum veriyi silmesin — `tool/install.sh`, yalnız
      `adb install -r` kullanır, asla kaldırmaz — ✅ 2026-08-01 · takip@e796e0d;
      S-2026-08-01-token-kaliciligi. `flutter install`'ın kaldırması yapısal
      değil, hata yoluymuş (L-016; L-014 düzeltildi). Gerçek cihazda doğrulandı
- [x] B-055 · (agent) Bağlantıların parolayla şifreli yedeği (dışa aktar /
      geri yükle) — ✅ 2026-08-01 · takip@735efbc; PBKDF2-HMAC-SHA256 +
      AES-GCM (`package:cryptography`). Veri kaybında bütün repolar tek
      yapıştırmayla geri geliyor. Koşulları R-006'da bağlayıcı
- [x] B-056 · (agent) Yeni repo eklerken kayıtlı token'ı yeniden kullanabilme —
      ✅ 2026-08-01 · takip@2730ea4; fine-grained token birden çok repoyu
      kapsayabildiği için "her repo için yeni token" zorunluluğu kalktı.
      Doğrulama gevşetilmedi (B-022, B-026 yolundan geçiyor)
- [x] B-057 · (agent) Tarayıcı içeriği cihaza insin, çevrimdışı çalışsın ve
      kendiliğinden güncellensin — ✅ 2026-08-01 · takip@1161e2b;
      S-2026-08-01-cevrimdisi-tarayici. Hub'ın tamamı (`hub/**.md`) indiriliyor,
      ağaç farkıyla yalnız değişen dosya yeniden iniyor. Kopya repo başına ayrı.
      Ayarlar → Çevrimdışı: durum + elle indirme. → SK-010
      · ℹ Görev listeleri (Bekleyenler/Tamamlananlar) bu kopyadan okunmuyor;
      onlar hâlâ ETag önbelleğiyle (B-046) çalışıyor, yani çevrimdışı yalnız
      daha önce görülen hâli gösteriyor. Gerekirse ayrı madde açılır

## Faz 6 — 2. Plan (şimdilik bekliyor)

- [ ] B-060 · (agent) Webhook + stateless relay + push bildirimi tasarımının
      uygulanması (tasarım: `artifacts/reference/flutter-app-design.md` §7)
- [ ] B-061 · (agent) GitHub App'e geçiş değerlendirmesi (çok kullanıcı olursa)
- [ ] B-062 · (agent) `done/` yıllık arşivleme otomasyonu
- [ ] B-063 · (agent) Çoklu proje desteği (`projects/<ad>/` yapısına geçiş
      değerlendirmesi) — ℹ 2026-08-01: aynı ihtiyacın **ayrı repo** cevabı
      T-003'te uygulandı (K-018). Bu madde tek repoda çoklu proje seçeneği
      olarak açık kalıyor; ön koşulu, ayrı repo modelinin gerçek kullanımda
      (B-052) yetersiz kaldığının görülmesi
- [ ] B-064 · (agent+user) "Pro versiyon" değerlendirmesinin yeniden açılması —
      K-017 ile ertelendi. **Ön koşul:** B-052 (bir haftalık gerçek kullanım).
      Kararı yeniden açacak kanıtlar: GitHub hesabı olmayan kullanıcılar,
      düzenli medya eki, saniyeler mertebesinde bildirim ihtiyacı, repo dışı
      entegrasyon. Bunlar çıkmazsa yol "tek ürün + opsiyonel bileşen"
      (B-060/B-061/B-063) olarak sürer
