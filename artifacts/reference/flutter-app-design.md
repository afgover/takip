---
id: A-2026-07-30-001
session: S-2026-07-30-hub-tasima
type: design
title: "Flutter uygulama tasarımı"
created: 2026-07-30T12:25:00Z
---

# FLUTTER_APP.md — Taskr Uygulaması Tasarımı

Kullanıcı uygulamasının ön tasarımı. Uygulama, hub reposuna (`SYSTEM.md`
sözleşmesine) bağlanan bir **GitHub istemcisidir**; kendi backend'i yoktur.

## 1. Neden Flutter

- Kullanıcının geçmiş tecrübesi (birincil neden).
- Tek kod tabanından Android + iOS (+ gerekirse desktop) çıkar.
- İhtiyaç duyulan her şeyin olgun paketi var: HTTP, secure storage, markdown
  render, YAML parse.
- Uygulamanın işi UI + REST çağrısı; Flutter'ın en güçlü olduğu alan.

## 2. Teknoloji seçimi

| İhtiyaç | Paket | Not |
|---|---|---|
| State management | `flutter_riverpod` | Basit, test edilebilir; provider bazlı |
| HTTP | `dio` | Interceptor'larla ETag/token yönetimi kolay |
| Token saklama | `flutter_secure_storage` | PAT asla düz dosyada durmaz |
| Markdown render | `flutter_markdown` | session/artifact/backlog görüntüleme |
| YAML frontmatter | `yaml` | Görev ve artifact meta verisi |
| Lokal önbellek | `shared_preferences` + dosya | Son görülen içerik; offline açılış |
| Slug/base64/tarih | Dart stdlib | Ek bağımlılık gerekmez |

Bilinçli olarak **yok**: veritabanı, push SDK'sı (Faz 6'ya kadar), kendi auth.

## 3. Katman mimarisi

```
lib/
  core/            # sabitler, hata modeli, yardımcılar (slug, base64, tarih)
  github/          # GitHub API katmanı — sözleşmeden habersiz, saf REST
    client.dart          # dio kurulumu, auth header, ETag interceptor
    contents_api.dart    # getFile, listDir, putFile, deleteFile (SHA yönetimi)
    commits_api.dart     # aktivite akışı için commit listesi
  hub/             # sözleşme katmanı — SYSTEM.md'nin Dart karşılığı
    models/              # Task, Session, Artifact, KnowledgeEntry, BacklogItem
    task_repo.dart       # inbox'a yazma, inbox+active+done listeleme
    browse_repo.dart     # kategori içerikleri, markdown getirme
    frontmatter.dart     # YAML frontmatter parse/serialize
    outbox.dart          # gönderilemeyen görevlerin lokal kuyruğu
  features/        # ekranlar (aşağıda §4)
  app.dart, main.dart
```

İlke: `github/` sözleşmeyi bilmez, `hub/` UI'yi bilmez. Sözleşme değişirse yalnız
`hub/` güncellenir.

## 4. Ekranlar

1. **Onboarding** — token + repo (`owner/name`) girişi; doğrulama için tek GET;
   token secure storage'a. Ayarlardan değiştirilebilir.
2. **Görev Ekle** — başlık, açıklama, öncelik, kategori. Kaydet →
   `tasks/inbox/<tarih>-<slug>.md` PUT (`id: pending`, `created_by: user`).
   Ağ yoksa outbox'a; bağlantı gelince otomatik gönderim.
3. **Bekleyenler** (ana ekran) — `inbox/` + `active/` görevleri durum rozetiyle;
   dosyaya dokunmadan klasör listelemeyle çizilir, detaya girince içerik çekilir.
4. **Hub Tarayıcı** — `SYSTEM.md` §9 kategorileri:
   Bekleyenler · Tamamlananlar · Oturumlar · Raporlar & Planlar · Bilgi Tabanı ·
   Yol Haritası. Hepsi markdown render + frontmatter'dan liste görünümü.
5. **Aktivite** — commit geçmişi, `SYSTEM.md` §8 öneklerine göre insan diline
   çevrilmiş akış ("Agent T-003'ü tamamladı", "Oturum kapandı: ...").
6. **Ayarlar** — token/repo değiştirme, polling aralığı, önbellek temizleme.

## 5. Senkronizasyon (Faz 1 yaklaşımı: polling)

- Uygulama **ön plandayken** 30–60 sn'de bir, izlenen klasörlerin listesini
  `If-None-Match` (ETag) ile sorgular; 304 → hiçbir şey yapma (rate limit'e
  sayılmaz), 200 → değişen kısmı çek, UI'yi tazele.
- Uygulama açılışında önce lokal önbellek gösterilir, arkada tazeleme yapılır.
- Arka plan senkronu YOK (bilinçli): mobil arka plan kısıtları güvenilmez;
  anlık bildirim ihtiyacı Faz 6'daki relay ile çözülecek.

## 6. Yazma güvenilirliği

- PUT başarısız (ağ/5xx) → görev **outbox**'ta bekler, UI'de "gönderilecek"
  rozetiyle görünür; bağlantı gelince sırayla gönderilir.
- 409 (SHA çakışması — yalnız güncellemelerde) → dosyayı yeniden oku, yeniden
  uygula, tekrar dene (SK-001).
- App'in yazdığı tek yer `tasks/inbox/` (R-001); silme/taşıma UI'de yoktur.

## 7. Faz 6 için not: anlık bildirim tasarımı (şimdilik uygulanmayacak)

Hub reposuna `push` webhook'u → stateless relay (Cloudflare Worker / Vercel
function; imza doğrular, veri taşımaz, repo token'ı tutmaz) → FCM/APNs push →
app bildirimi alır ve veriyi kendi token'ıyla GitHub'dan çeker. Mevcut mimariye
eklenir; formatı ve token modelini değiştirmez.

## 8. Açık sorular ve cevapları

- ✅ **Dağıtım (K-008, 2026-07-30):** Önce kişisel kullanım (store'suz dağıtım);
  ileride Android + iOS store yayını. Kişisel aşamada onboarding'de PAT girişi
  yeterli; store aşamasına geçerken GitHub App OAuth akışı değerlendirilecek
  (B-061 ile birlikte).
- ✅ **Platform önceliği (K-009, 2026-07-30):** Kişisel aşama **Android**
  (APK dağıtımı); iOS store aşamasıyla birlikte. Kod tabanı yine platform
  bağımsız tutulur, yalnız test/dağıtım önceliği Android'dedir.
- ⏳ Görev ekleme ekranında kategori listesi sabit mi (`SYSTEM.md` §4'teki 5
  kategori), kullanıcı tanımlı mı?
