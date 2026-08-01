---
id: A-2026-08-01-005
session: none
type: plan
title: "🚀 App Store & Play Store Yayınlama Yol Haritası"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/project_docs/MARKET_ROADMAP.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# 🚀 App Store & Play Store Yayınlama Yol Haritası

Uygulamanın genel özellikleri tamamlandığına göre, profesyonel bir yayınlama süreci için izlemen gereken adımlar aşağıdadır. Bu süreçte en kritik araç **EAS (Expo Application Services)** olacaktır.

---

## 1. Hazırlık ve Parlatma (Stabilizasyon)
Market kaydından önce uygulamanın kurumsal bir görünüme kavuşması gerekir.

- [x] **app.json Güncelleme:** `name`, `slug`, `version` bilgileri kontrol edildi.
- [ ] **Asset Hazırlığı:** `assets/` klasöründeki ikon (`icon.png`), açılış ekranı (`splash.png`) ve adaptif Android ikonlarını kendi tasarımınla değiştir.
- [ ] **Bundle IDs:** `app.json` içinde `bundleIdentifier` (iOS) ve `package` (Android) isimlerini kalıcı hale getir (Örn: `com.sirketin.uygulaman`).
- [ ] **Error Boundary:** Uygulama çöktüğünde beyaz ekran yerine "Bir hata oluştu" diyen şık bir ekran ekle.
- [ ] **Performans Kontrolü:** `useEffect` loop'ları veya gereksiz render'ları `console.log` temizliği ile kontrol et.

---

## 2. Geliştirici Hesapları
Apple ve Google politikaları gereği bireysel veya kurumsal hesap açman şarttır.

- [ ] **Apple Developer Program:** Yıllık $99 ödeyerek kayıt ol. (Onay süreci 1-3 gün sürebilir).
- [ ] **Google Play Console:** Tek seferlik $25 ödeyerek kayıt ol.

---

## 3. iOS Sistemi Entegrasyonu (Teknik Adımlar)
Expo Go'dan çıkıp gerçek bir uygulama (`development build`) gibi davranmaya başlama süreci.

- [ ] **EAS CLI Kurulumu:** `npm install -g eas-cli` ile bilgisayarına kur.
- [ ] **EAS Build Konfigürasyonu:** `eas build:configure` komutuyla projeyi bağla.
- [ ] **Push Notifications:** 
    - Apple Developer portalından `Push Notification Key (.p8)` dosyası al.
    - `eas credentials` ile bu anahtarı Expo sunucularına ilet.
- [ ] **Hukuki Metinler:** Uygulama içine veya bir web sitesine `Privacy Policy` ve `Terms of Service` sayfaları ekle (Market kaydı için zorunludur).

---

## 4. App Store Connect Kaydı ve Test
Kodun Apple sunucularına gönderilme aşaması.

- [ ] **Build Alma:** `eas build --platform ios` komutuyla `.ipa` dosyanı oluştur (Bulutta oluşur).
- [ ] **Transporter:** Mac'ine `Transporter` uygulamasını indir ve oluşan `.ipa` dosyasını App Store Connect'e yükle.
- [ ] **TestFlight:** Uygulamanı gerçek kullanıcılara (veya kendine) markete çıkmadan önce davet usulü gönder ve test et.

---

## 5. Market Formlarını Doldurma ve İnceleme (Review)
Bu aşama genellikle en çok vakit alan (ve reddedilebileceğiniz) kısımdır.

- [ ] **Ekran Görüntüleri:** iPhone 13/14 Pro ve iPad için 6.5" ve 5.5" boyutlarında profesyonel ekran görüntüleri hazırla.
- [ ] **Metadata:** Uygulama açıklaması, anahtar kelimeler ve destek URL'lerini gir.
- [ ] **App Review Information:** Eğer test etmek için login gerekiyorsa, Apple inceleme ekibi için bir `test@example.com` hesabı ve şifresi tanımla.
- [ ] **Gönderim:** "Review for App Store" butonuna bas. (İnceleme süreci 24-48 saat sürer).

---

## 💡 Kritik Tavsiyeler
1. **İkon Boyutları:** `icon.png` dosyan mutlaka `1024x1024` ve transparanlık içermeyen bir kare olmalı.
2. **Reddetme Riski:** Apple, "Çok basit veya web sitesi gibi görünen" uygulamaları reddedebilir. Bizim yaptığımız "Tag paylaşımı" ve "Gerçek zamanlı arkadaşlık" gibi özellikler uygulamanın "Native" gücünü kanıtladığı için avantajlıdır.
3. **Android İçin:** Android süreci daha esnektir ancak Google artık yeni hesaplar için 20 kişilik bir 14 günlük kapalı test süreci zorunlu kılıyor.

---

> [!NOTE]
> Bu doküman `.gemini/project_docs/MARKET_ROADMAP.md` altında saklanmaktadır. İstediğin zaman adımları buradan takip edebilirsin.
