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

## Faz 1 — Hub Tasarımı & Kurulumu

- [x] B-010 · (agent) Format sözleşmesi (`SYSTEM.md`) taslağı — ✅ 2026-07-30
- [x] B-011 · (agent) Agent kayıt prosedürü (`AGENT_PROTOCOL.md`) taslağı — ✅ 2026-07-30
- [x] B-012 · (agent) Backlog / evrim / knowledge iskeletleri — ✅ 2026-07-30
- [x] B-013 · (user) Yeni hub reposunu oluştur ve agent'a bildir — ✅ 2026-07-30 ·
      `afgover/taskr_takip` (önce yanlışlıkla `takip` kullanıldı; bkz. K-007, L-003)
- [x] B-014 · (agent) `hub-template/` içeriğini yeni repoya taşı, ilk commit'leri
      sözleşme kurallarıyla at — ✅ 2026-07-30 · S-2026-07-30-hub-tasima
- [ ] B-015 · (user) Uygulama için fine-grained token üret — Only select
      repositories → `takip`; `Contents: R&W`, `Metadata: R` (K-012)
      · ⏸ 2026-07-30 kullanıcı kararıyla ertelendi; Faz 2 öncesi yapılacak
- [x] B-016 · (agent+user) Sözleşmeyi ilk gerçek oturumla test et: bir oturum
      kaydı + bir görev döngüsü (inbox → active → done) elle işlet, pürüzleri
      `knowledge/lessons.md`'ye yaz — ✅ 2026-07-30 · T-001,
      S-2026-07-30-duzeltme-ve-dongu-testi; dersler: L-003, L-004
- [x] B-017 · (agent) Sözleşme test sonuçlarına göre `SYSTEM.md` 1.1 revizyonu
      (gerekirse) — ✅ 2026-07-30 · revizyon ihtiyacı çıkmadı, sözleşme 1.0 kaldı

## Faz 2 — Flutter Uygulama İskeleti

- [ ] B-020 · (user) Flutter ortamı hazırlığı (SDK kurulumu) — platform kararı
      verildi: Android öncelikli (K-009). İlk kurulum: `takip` reposunda
      `flutter create . --platforms=android && flutter pub get &&
      flutter analyze` (iskeletin derleme doğrulaması dahil)
      · ℹ 2026-07-30: derleme doğrulaması kısmı agent ortamında yapıldı
      (Flutter 3.27.1 / Dart 3.6, `pubspec.lock` repoda). Sende kalan:
      SDK kurulumu + `flutter create .` ile `android/` üretimi + cihazda
      `flutter run`. Kod tarafı artık her oturumda analiz+test'ten geçiyor (L-006)
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

## Faz 3 — Todo Döngüsü (MVP çekirdeği)

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
- [ ] B-034 · (agent+user) Uçtan uca test: app'ten görev ekle → agent ele alsın →
      done'a taşısın → app'te "Tamamlananlar"da görünsün — ⏳ 2026-07-30 ·
      **sözleşme ayağı tamam, cihaz ayağı bekliyor** (madde açık kalır).
      Yapılanlar: (1) gerçek
      ekranlarla, GitHub Contents API'sini taklit eden hub üzerinde tam döngü
      testi (ekle → agent taşır → app'te durum değişir → tamamlananlarda
      sonucuyla görünür) + ağ kesintisi senaryosu; (2) gerçek hub'da T-002:
      dosya app'in `TaskDraft` üreticisinden çıktığı gibi inbox → active →
      done geçirildi, biçim bozulmadı. **Kalan:** gerçek GitHub üzerinden
      cihazda koşum — B-015 (token) ve B-020 (SDK + `flutter create .`)
      tamamlanınca yapılacak. → L-008
- [ ] B-035 · (agent) Test çıktılarını `knowledge/lessons.md`'ye işle —
      döngü testinden çıkan ders L-008 olarak işlendi; cihaz koşumundan sonra
      tekrar bakılacak

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

## Faz 6 — 2. Plan (şimdilik bekliyor)

- [ ] B-060 · (agent) Webhook + stateless relay + push bildirimi tasarımının
      uygulanması (tasarım: `artifacts/reference/flutter-app-design.md` §7)
- [ ] B-061 · (agent) GitHub App'e geçiş değerlendirmesi (çok kullanıcı olursa)
- [ ] B-062 · (agent) `done/` yıllık arşivleme otomasyonu
- [ ] B-063 · (agent) Çoklu proje desteği (`projects/<ad>/` yapısına geçiş
      değerlendirmesi)
- [ ] B-064 · (agent+user) "Pro versiyon" değerlendirmesinin yeniden açılması —
      K-017 ile ertelendi. **Ön koşul:** B-052 (bir haftalık gerçek kullanım).
      Kararı yeniden açacak kanıtlar: GitHub hesabı olmayan kullanıcılar,
      düzenli medya eki, saniyeler mertebesinde bildirim ihtiyacı, repo dışı
      entegrasyon. Bunlar çıkmazsa yol "tek ürün + opsiyonel bileşen"
      (B-060/B-061/B-063) olarak sürer
