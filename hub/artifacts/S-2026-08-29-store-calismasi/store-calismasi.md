---
id: A-2026-08-29-001
session: S-2026-08-29-store-calismasi
type: analysis
title: "Store çalışması — Play yolu, iOS değerlendirmesi, karar listesi"
created: 2026-08-29T12:50:00Z
---

# Store çalışması

B-098 "gerçek talep" bekliyordu; talep 2026-08-29'da kullanıcıdan geldi.
Bu çalışma yolu ölçer, adımları sıralar ve kararları ayırır. Kaynaklar:
bu reponun kendi ölçümleri + `Copilot_takip`'in mağaza birikimi
(`store-basvuru-ve-hukuki-risk-raporu.md`, bugünkü Play Console oturumu,
Sekuvo emsali).

## 0. Ölçülen mevcut durum

| eksen | durum |
|---|---|
| Platform | **Yalnız Android** — `ios/` iskeleti hiç yok |
| Paket adı | `us.gover.takip` — mağazaya girdiği an **sonsuza dek sabitlenir** |
| Sürüm | `0.1.0`, build numarası yok → `versionCode` hep 1; mağaza her yüklemede artış ister |
| İmza | Debug anahtarı (SEC-010); `key.properties` konduğu an release imza hazır (Gradle bağlı) |
| İzinler | Tek: `INTERNET` — mağaza açısından temiz |
| Veri akışı | Token cihazın güvenli deposunda; **geliştiriciye/sunucuya hiçbir veri akmıyor**, istekler kullanıcının kendi GitHub hesabına |
| Play hesabı | **Var ve canlı** — bugün Copilot uygulaması oluşturuldu, Sekuvo yayında |
| i18n | TR + EN hazır (1.21 döneminde tamamlandı) |
| Testler | 622, `flutter analyze` temiz |

## 1. Google Play yolu — günler mertebesi

Sıra bilinçli: imza her şeyden önce, çünkü ilk yüklemeden sonra değiştirilemez.

1. **İmza (T-010 — tetikleyici resmen geldi).** SEC-015 tetikleyiciyi
   "üçüncü kişiye/halka verilme" diye daraltmıştı; mağaza tam olarak bu.
   Üretilecek şey Play App Signing modelinde **upload key**: imzayı Google
   yönetir, upload anahtarı kaybolursa kurtarılabilir — anahtar kaybı riskini
   Google tarafına taşıdığı için önerilen mod bu. Üretim kullanıcıda (parola).
   *Bilinen bedel (SEC-015'te yazılıydı):* telefondaki debug imzalı kurulum
   mağaza sürümüyle güncellenemez — geçiş günü bir kez kaldır-kur, token'lar
   yeniden girilir.
2. **Sürüm stratejisi.** `pubspec.yaml` → `version: 0.1.0+2` biçimine; her
   mağaza yüklemesinde `+N` artar. Tek satır, ama unutulursa yükleme reddedilir.
3. **AAB.** Mağaza APK değil bundle ister: `flutter build appbundle`.
4. **Ekran görüntüleri — Copilot'un dersi burada kritik.** Copilot'ta
   "bu ekranda kişisel bilgi yok" varsayımı yanlış çıktı (pilotun gerçek adı
   göründü). `takip`in ekranları hub içeriği gösterir: private repo adları,
   görev başlıkları, oturum özetleri. **Gerçek hub'la ekran görüntüsü
   çekilmez.** Çözüm elimizde: simülasyon için kurulan sentetik hub (simhub)
   demo bağlantı olarak eklenir, görüntüler ondan çekilir.
5. **Gizlilik politikası sayfası (zorunlu URL).** Emsal: `sekuvo-site`
   (public repo + Pages). İçerik bu uygulamada kısa ve dürüst: veri
   geliştiriciye akmaz, token cihazda, üçüncü taraf yalnız GitHub API
   (kullanıcının kendi hesabı). B-098 "gover.us'ta barındırılır" demişti —
   iki seçenek de açık, karar listesinde.
6. **Data Safety formu.** Copilot raporunun en kritik uyarısı: **beyan ↔
   gerçek akış tutarlılığı** — geri çevrilmelerin bir numaralı sebebi.
   `takip`in gerçeği "geliştirici veri toplamıyor"a izin veriyor; form
   doldurulurken GitHub API trafiğinin "kullanıcının kendi hesabına erişim"
   olduğu açıklamasıyla hizalanır. Politika sayfası ve form **birebir aynı**
   şeyi söylemeli.
7. **Listing.** Ad kontrolü ("Takip" jenerik — mağazada ayırt edici ad
   gerekebilir), TR+EN açıklama, 512 ikon, 1024×500 tanıtım grafiği,
   içerik derecelendirme anketi, kategori (Verimlilik).
8. **Kapalı test şartı.** Kişisel hesaplarda üretim öncesi 12 test
   kullanıcısı / 14 gün şartı olabilir; hesabın tabi olup olmadığı **Console'dan
   okunur** (Copilot raporu da aynı yere işaret ediyor). Sekuvo yayına
   çıktıysa şart ya yok ya aşılmış — Console teyidi karar listesinde.

## 2. B-098'in eski ön koşulları — bugünkü durum

- **B-061 (GitHub App/OAuth):** mağaza için **bloker değil**. PAT modeli
  mağaza kullanıcısı için zahmetli bir onboarding ama çalışıyor; App'e geçiş
  ölçek/UX konusu, Faz 6'da kalır.
- **SEC-006:** kapalı ✓ (token kapsam ölçümü P-003 ile geldi).
- **i18n:** hazır ✓.
- **iOS:** aşağıda, ayrı.

## 3. iOS — haftalar mertebesi, ertelenmesi önerilir

`ios/` iskeleti hiç yok; sıfırdan eklenir (`flutter create .`), Apple hesabı
mevcut (Copilot kaydı) ama yol uzun: PrivacyInfo.xcprivacy, App Store
incelemesi, TestFlight. Copilot aynı kararı verdi ("bilinçli ertelendi").
Öneri: **Play önce; iOS gerçek talep gelirse** — B-098'in kendi çizgisi.

## 4. Sürekli maliyet — çalışmanın en önemli cümlesi

B-098'in "asıl maliyet hesap ücreti değil, bakım taahhüdü" cümlesi bugün de
doğru ve artık somut: Play her yıl **targetSdk yükseltmesi** ister; bu,
B-138'in bilinçli ertelediği major geçişleri takvime bağlar (tetikleyici (c)
fiilen her yıl gelir). Mağazaya çıkmak, "bittiğinde biten" bir iş değil,
yıllık bakım aboneliğidir — karar bunu bilerek verilmeli.

## 5. Kullanıcı kararları (T-020)

1. Play'e çıkalım mı — yıllık bakım taahhüdü kabul mü?
2. Keystore/upload key şimdi üretilsin mi? (T-010; parola sende)
3. Politika sayfası nerede: gover.us mu, `takip-site` benzeri Pages mi?
4. Mağaza adı ne olsun? ("Takip" muhtemelen yetmez)
5. Console'da kapalı test şartı görünüyor mu? (senin hesabınla bakılacak)
