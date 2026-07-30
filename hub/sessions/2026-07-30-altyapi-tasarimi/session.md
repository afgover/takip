---
id: S-2026-07-30-altyapi-tasarimi
date: 2026-07-30
status: closed
topics: [mimari, github-izinleri, hub-formati, flutter]
artifacts:
  - SYSTEM.md
  - AGENT_PROTOCOL.md
  - BACKLOG.md
  - EVOLUTION.md
tasks_touched: []
---

# Oturum: Altyapı yön kararı ve hub tasarımı

## Özet
project-taskr'ın yeni mimarisi kararlaştırıldı: özel backend yerine GitHub omurga.
GitHub izin modeli araştırıldı (klasör bazlı izin yok → ayrı private hub reposu
kararı, K-002). Anlık senkron için webhook+relay tasarımı yapıldı ama 2. plana
alındı (K-003); ilk sürüm ETag'li polling. Görev modeli dosya-başına-görev +
klasörle durum olarak belirlendi (K-004). Uygulama Flutter olacak (K-005).
Format sözleşmesi (SYSTEM.md 1.0), agent protokolü, detaylı backlog, evrim
dosyası ve knowledge iskeletleri bu oturumda üretildi.

> Not: Bu oturum hub reposu açılmadan önce, taskr kod reposunda gerçekleşti;
> kaydı örnek format olarak buraya taşındı. Zaman damgaları yaklaşıktır.

## Kayıt

### Kullanıcı
> project-taskr'ı sıfırdan ele alacağız; token/bağlantı yükünden kurtulup işi
> GitHub üzerinden, sistematik yapacağız. Repoda belirlediğimiz formatta bir
> klasör olacak, agent her şeyi oraya kaydedecek, user app GitHub'a bağlanıp
> takip edecek ve görev atayacak. GitHub erişimi app'e eklenebilir mi? Read-only
> mü, yazmaya izin var mı? Sadece belirli klasöre izin mümkün mü? Araştır.

### Agent
Araştırma yapıldı. Bulgular: erişim GitHub App / fine-grained PAT / OAuth ile
mümkün; izinler read-only veya read&write seçilebilir (`Contents`). Klasör bazlı
izin GitHub'da YOK — iznin en dar kapsamı repo. Çözüm önerisi: dedicated repo
(repo = klasör = izin sınırı).

### Kullanıcı
> Peki project-taskr'ı bu şekilde yeniden yapılandırmak mantıklı mı?

### Agent
Evet — eski repo geçmişi altyapı bakım savaşını gösteriyor (güvenlik yamaları,
offline senkron düzeltmeleri). GitHub-omurga; auth/DB/hosting/audit-log yükünü
siler. Bedeli: gerçek zamanlılık polling'e düşer, çok kullanıcılılık GitHub
hesabı gerektirir. Kişisel + agent-odaklı kullanım için doğru karar.

### Kullanıcı
> Yeni repo mu, yoksa proje reposu içinde bir klasör mü?

### Agent
Ayrı repo önerildi ve kabul edildi: (1) token izolasyonu ancak böyle sağlanır,
(2) hub verisi main'de yaşar, kod branch akışıyla çakışmaz, (3) temiz commit
geçmişi = aktivite akışı, (4) çoklu projeye ölçeklenir. → K-002

### Kullanıcı
> App'te bir hook kurup ayrı repodaki değişikliklerin (diğer userlar tarafından)
> hemen yansıması sağlanabilir mi?

### Agent
Mobil app doğrudan webhook hedefi olamaz; "hemen" için GitHub webhook → küçük
stateless relay → push bildirimi zinciri gerekir. Alternatif: ETag'li polling
(30–60 sn, foreground). Öneri: önce polling, relay ihtiyaç doğunca. → K-003

### Kullanıcı
> App'te basit bir todo listesi oluşturup repoya aktarmak maliyetli mi?

### Agent
Hayır — Contents API ile görev ekleme tek PUT isteği; commit'i GitHub atar.
İncelikler: güncellemede SHA zorunlu (iyimser kilit), görev başına ayrı dosya
kullan. Asıl efor formatı doğru tanımlamakta. → K-004

### Kullanıcı
> Tamam, altyapıyı kuralım. Webhook 2. planda. Repo formatını belirleyelim;
> agent'a ve user'a sistemi açıklayan format + app planı (Flutter uygun).
> Agent şunları kayıt altına almalı: oturum kaydı (yazdığım ve cevapladığın her
> şey, oturum kapanana dek güncellenir), üretilen tüm rapor/plan/info dosyaları,
> çok detaylı yapılacaklar listesi (yapılanlar güncellenir, kalanlar devam eder),
> projenin evrimi tek dosyada aşama aşama, kurallar/skiller/dersler tek tek.
> User app'ten todo ekler → repoya aktarılır → agent user'ın isteğiyle ele alır.
> App'te todo bekleme + agent'ın eklediği her şey kategoriler halinde görünür.
> Ön çalışmayı yap; yeni repoyu açınca çalışmayı oraya taşırsın.

### Agent
Ön çalışma paketi üretildi: `SYSTEM.md` (format sözleşmesi 1.0),
`AGENT_PROTOCOL.md`, `BACKLOG.md` (Faz 0–6, B-001…B-063), `EVOLUTION.md`
(Aşama 0 kapalı, Aşama 1 aktif), `knowledge/` ilk kayıtları (R-001…R-004,
SK-001…SK-002, L-001…L-002), bu oturum kaydı ve `app-design/FLUTTER_APP.md`.
Sonraki adım: B-013 (kullanıcı hub reposunu açar).
