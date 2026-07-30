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
- [ ] B-026 · (agent) Onboarding'de **yazma izni** doğrulaması — B-022'deki
      kontrol yalnız okumayı sınıyor; salt okunur token onboarding'i geçip ilk
      görev gönderiminde 403 veriyor. Önce araştırılacak: fine-grained token'da
      `GET /repos/{o}/{r}` yanıtı `permissions.push`'u güvenilir biçimde
      veriyor mu? Vermiyorsa alternatif, hatayı B-050'de net anlatmak

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
- [ ] B-033 · (agent) 409/SHA çakışması yönetimi: yeniden oku → yeniden dene
- [ ] B-034 · (agent+user) Uçtan uca test: app'ten görev ekle → agent ele alsın →
      done'a taşısın → app'te "Tamamlananlar"da görünsün
- [ ] B-035 · (agent) Test çıktılarını `knowledge/lessons.md`'ye işle

## Faz 4 — Hub Tarayıcı (kategorili görüntüleme)

- [ ] B-040 · (agent) Kategori ana ekranı: SYSTEM.md §9'daki 6 kategori
- [ ] B-041 · (agent) Oturumlar görünümü: liste + session.md render (özet üstte)
- [ ] B-042 · (agent) Raporlar & Planlar görünümü: artifacts listesi,
      frontmatter `type`'a göre filtre
- [ ] B-043 · (agent) Bilgi tabanı görünümü: rules/skills/lessons kayıtları
- [ ] B-044 · (agent) Yol haritası görünümü: BACKLOG.md ve EVOLUTION.md render
- [ ] B-045 · (agent) Aktivite akışı: commit geçmişini §8 öneklerine göre
      okunur akışa çevir
- [ ] B-046 · (agent) Basit önbellekleme: son görülen içerik lokalde tutulur,
      açılışta önce cache gösterilir

## Faz 5 — Cilalama & Günlük Kullanım

- [ ] B-050 · (agent) Hata durumları UX'i: token geçersiz, rate limit, ağ yok
- [ ] B-051 · (agent) Ayarlar: polling aralığı, token değiştirme, repo değiştirme
- [ ] B-052 · (user) Bir hafta gerçek kullanım; sürtünme noktalarını görev olarak
      inbox'a at
- [ ] B-053 · (agent) Kullanım geri bildirimlerine göre revizyon turu

## Faz 6 — 2. Plan (şimdilik bekliyor)

- [ ] B-060 · (agent) Webhook + stateless relay + push bildirimi tasarımının
      uygulanması (tasarım: `artifacts/reference/flutter-app-design.md` §7)
- [ ] B-061 · (agent) GitHub App'e geçiş değerlendirmesi (çok kullanıcı olursa)
- [ ] B-062 · (agent) `done/` yıllık arşivleme otomasyonu
- [ ] B-063 · (agent) Çoklu proje desteği (`projects/<ad>/` yapısına geçiş
      değerlendirmesi)
