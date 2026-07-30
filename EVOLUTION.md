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

## Aşama 1 — Hub Kurulumu (aktif)

**Hedef:** Format sözleşmesinin yazılması, hub reposunun açılması ve sözleşmenin
ilk gerçek oturumla test edilmesi.

**Durum:**
- 2026-07-30: `SYSTEM.md` 1.0, `AGENT_PROTOCOL.md`, `BACKLOG.md`, knowledge
  iskeletleri taslak olarak hazırlandı (taskr kod reposunda).
- 2026-07-30: Hub reposu `afgover/takip` oluşturuldu (B-013 ✅); iskelet buraya
  taşındı, taskr reposundaki ön çalışma klasörü kaldırıldı (B-014 ✅). Flutter
  tasarımı `artifacts/reference/flutter-app-design.md` olarak kaydedildi.
  Bu repo artık tek doğru kaynak.
- Bekleyen: uygulama token'ı (B-015), sözleşmenin ilk gerçek oturumla testi (B-016).

**Kararlar:**
- **K-006:** Hub reposunun adı `takip`. Eski taskr reposu salt tarihçe olarak
  kalır; yeni çalışmalar yalnızca hub üzerinden yürür.

---

## Aşama 2 — Uygulama MVP'si (planlandı)

**Hedef:** Flutter iskeleti + todo döngüsü: app'ten eklenen görevin hub'a düşmesi,
agent'ın ele alması, sonucun app'te görünmesi. (Backlog Faz 2–3.)

## Aşama 3 — Hub Tarayıcı (planlandı)

**Hedef:** Agent'ın hub'a kaydettiği her şeyin app'te kategoriler halinde
görüntülenmesi. (Backlog Faz 4.)
