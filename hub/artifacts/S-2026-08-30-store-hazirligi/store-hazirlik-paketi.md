---
id: A-2026-08-30-002
session: S-2026-08-30-store-hazirligi
type: plan
title: "Store hazırlık paketi — ad adayları, politika, listing, Data Safety, görsel yol haritası"
created: 2026-08-30T14:20:00Z
---

# Store hazırlık paketi

T-020 kararı: **önce hazırlık, yükleme sonra.** Bu paket imzaya dokunmadan
ilerletilebilen her şeyi taşır; her bölüm yükleme günü doğrudan kullanılacak
biçimde yazıldı.

## 1. Mağaza adı adayları (Play çakışma kontrolü yapıldı)

Play araması ölçüldü ("takip hub", TR vitrini): birebir "Takip Hub" ya da
"Hub Takip" adlı uygulama **yok**; "takip" araması GPS/konum takip
uygulamalarıyla dolu — tek başına "Takip" hem jenerik hem yanlış çağrışım
(konum takibi) riski taşıyor.

| aday | gerekçe | risk |
|---|---|---|
| **Takip Hub** (önerilen) | Sistemin kendi dili ("hub" sözleşmenin çekirdek terimi); Play'de boş; TR+EN'de aynı yazılır | "Hub" İngilizce; TR kullanıcıya soğuk gelebilir |
| Takip — Proje Hub'ı | Jenerik "takip"i niteliyor; arama eşleşmesi iyi | Uzun; Console 30 karakter sınırına yakın |
| Ajanda değil Ajan Takip | Ayırt edici, espri | Fazla zeki; aramada bulunmaz |
| GitHub Görev Takibi | Ne yaptığını birebir söyler | **"GitHub" markası ad içinde risk** — Play politikası üçüncü taraf marka kullanımına bakar; önerilmez |
| Takip: Agent Hub | İki kitleye de konuşur | İki dilli karışım |

Öneri "Takip Hub"tı; **karar (2026-08-30, kullanıcı): ad "Takip" kalıyor.**
"Hub" seçeneği ölçülüp elendi (Play'de 35+ sonuçla aşırı kalabalık + sistemin
kendi sözlüğünde hub = kayıt reposu, terminoloji çarpışırdı). Console jenerik
adı reddederse yedek: "Takip Hub". Listing alt başlığı açıklamayı taşır
("GitHub üzerinde ajan-insan görev takibi").

**Paket adı kararı (aynı gün):** `us.gover.takip` **kalıyor** — ters
alan-adı geleneği (`gover.us` kullanıcının), teklik garantisi oradan.
Zorunluluk değil tercih; Play URL'sinde göründüğü söylendi, kullanıcı kabul
etti. İlk yüklemeyle sonsuza dek kilitleneceği bilinerek verildi.

## 2. Gizlilik politikası taslağı

Yayım yeri kararı: GitHub Pages (sekuvo-site kalıbı). **Repo açmak onaya
bağlı** — aşağıdaki metin hazır, onay gelince `takip-site` benzeri bir
repoya konur ve URL Console'a girilir.

### Taslak (TR)

> **Takip Hub — Gizlilik Politikası**
>
> Takip Hub, verilerinizi geliştiriciye ya da üçüncü taraf bir sunucuya
> **göndermez**. Uygulamanın kendi sunucusu yoktur.
>
> - **GitHub erişimi:** Uygulama, sizin sağladığınız kişisel erişim
>   anahtarıyla (token) **kendi** GitHub depolarınıza bağlanır. Bütün ağ
>   trafiği doğrudan cihazınız ile GitHub API arasındadır.
> - **Token saklama:** Anahtarınız yalnız cihazınızın güvenli deposunda
>   (Android Keystore destekli) tutulur; dosyaya, günlüğe ya da başka bir
>   sunucuya yazılmaz. Dışa aktarım yalnız sizin belirlediğiniz parolayla
>   şifrelenmiş yedek olarak yapılır.
> - **Çevrimdışı kopya:** Depolarınızın içeriği, çevrimdışı okuma için
>   yalnız cihazınızda önbelleğe alınır; uygulama içinden silinebilir.
> - **Toplanan veri: yok.** Analitik, reklam kimliği, kilitlenme raporu
>   dahil hiçbir veri toplanmaz.
> - **Hesap gerektirmez.** Uygulama hesabı yoktur; silinecek sunucu verisi
>   de yoktur — uygulamayı kaldırmak cihazdaki her şeyi kaldırır.
> - GitHub'ın kendi veri işleme koşulları kendi hesabınız için geçerlidir.
>
> İletişim: (yayım öncesi e-posta eklenecek — Console kişisel hesapta
> geliştirici e-postasını zaten yayımlar.)

*(EN çevirisi yayım reposuna birlikte konur; içerik birebir aynı olmalı —
Data Safety formu ile bu sayfa aynı şeyi söylemek zorunda, A-2026-08-29-001
§1.6.)*

## 3. Listing metinleri taslağı

**Kısa açıklama (80 krk sınırı):**
- TR: "GitHub üzerinde ajan-insan görev takibi: görevler, oturumlar, kararlar tek yerde."
- EN: "Agent-human task tracking on GitHub: tasks, sessions and decisions in one place."

**Uzun açıklama (taslak, TR):** çekirdek cümleler —
sunucusuz tasarım (veri sende, GitHub'ında); ajan oturumlarının kayıtları,
görev akışı (inbox → active → waiting → done), seçenekli sorulara telefondan
cevap; çevrimdışı okuma ve kuyruk; TR+EN. *(Tam metin yükleme öncesi
son halini alır; buradaki çekirdek yeter.)*

**Kategori:** Verimlilik. **İçerik derecelendirmesi:** herkes; anket
"kullanıcı etkileşimi yok, konum yok, satın alma yok" hattında.

## 4. Data Safety beyan taslağı

| form sorusu | cevap | dayanak |
|---|---|---|
| Veri topluyor mu? | **Hayır** | Geliştiriciye/3. tarafa hiçbir veri akmıyor; trafik kullanıcı↔GitHub |
| Veri paylaşıyor mu? | Hayır | Aynı |
| Şifreleme? | Aktarımda TLS (GitHub API); token cihazda güvenli depoda | SEC-001 |
| Silme talebi? | Hesap yok; kaldırma = tam silme | Politika §hesap |

Formda "collected" tanımı geliştiriciye/üçüncü tarafa **aktarım** demektir;
GitHub trafiği kullanıcının kendi hesabına erişim olduğu için "no collection"
beyanı savunulabilir — yine de politika sayfası bu ayrımı açıkça anlatıyor
(tutarlılık şartı).

## 5. Ekran görselleri — yol haritası (henüz çekilmedi)

Kural (A-2026-08-29-001 §1.4): **gerçek hub'la görsel çekilmez** — private
repo adları ve görev başlıkları görünür. Gerekenler:

1. **Demo hub reposu** — sentetik simhub içeriği bir GitHub reposuna konur
   (öneri: `afgover/takip-demo`, private yeter; app token'la okur).
   **Repo açmak kullanıcı onayına bağlı** — açılmadı.
2. Telefonda demo bağlantı + TR arayüz; çekilecek ekranlar: bekleyenler
   listesi, görev detayı (seçenekli soru), görev ağacı, ayarlar/veri.
   En az 2, önerilen 4-6 görsel (1080×2340, ≤2:1).
3. 512 ikon + 1024×500 tanıtım grafiği — uygulamanın mevcut ikonundan
   türetilir.
4. Copilot dersi kontrol listesi: her görselde ad/e-posta/gerçek repo adı
   taraması, yayına girmeden.

## 6. Yükleme günü kalanlar (bu pakette YOK, bilerek)

Keystore/upload key (T-010 — yüklemeden hemen önce), AAB derleme,
`versionCode` stratejisi (`0.1.0+2`), Console'da kapalı test şartının
kontrolü (kullanıcı girişi ister), bakım taahhüdünün resmen kabulü.
