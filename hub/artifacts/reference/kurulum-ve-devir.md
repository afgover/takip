---
id: A-2026-07-30-002
session: none
type: info
title: "Kurulum ve devir notu — Mac'te devam"
created: 2026-07-30T21:30:00Z
---

# Kurulum ve Devir Notu

Bu belge iki işi görür: **projenin nerede kaldığını** özetler ve **Mac'te
kurulumun** adımlarını verir. Yeni bir oturuma başlayan agent'ın ya da
kullanıcının önce okuması gereken dosya budur.

---

## 1. Bir bakışta durum (2026-07-30)

**Agent tarafında yapılacak iş kalmadı.** Uygulama uçtan uca çalışır durumda:
191 test geçiyor, `flutter analyze` temiz. Ama **hiçbir gerçek cihazda hiç
çalışmadı** — kalan her şey bu eşikte duruyor.

| Faz | Durum |
|---|---|
| Faz 0 — Karar & araştırma | ✅ |
| Faz 1 — Hub tasarımı | ✅ (B-015 hariç) |
| Faz 2 — Flutter iskeleti | ✅ (B-020 hariç) |
| Faz 3 — Todo döngüsü | ✅ (B-034'ün cihaz ayağı hariç) |
| Faz 4 — Hub tarayıcı | ✅ |
| Faz 5 — Cilalama | ✅ (B-052/B-053 kullanıcıda) |
| Faz 6 — 2. plan | bekliyor (B-060…B-064) |

**Uygulamada ne var:** onboarding (token doğrulamalı), görev ekleme, bekleyenler
ve tamamlananlar listeleri, görev detayı, hub tarayıcı (oturumlar, raporlar,
bilgi tabanı, yol haritası, aktivite akışı, sözleşme), offline kuyruk, ETag'li
yoklama, kalıcı önbellek, ayarlar, hata yönetimi.

**Mimari (K-001, K-012):** backend yok. Uygulama doğrudan `api.github.com` ile
konuşur; tüm veri `afgover/takip` reposunun `hub/` klasöründedir. Kodda başka
hiçbir ağ adresi yoktur.

**Kod nerede:** her şey `main`'de. Geliştirme branch'i
`claude/taskr-takip-repo-structure-jeghhb` idi ve `main`'e merge edildi; yeni
çalışma için `main`'den başlamak yeterli.

---

## 2. Mac'te kurulum (B-020)

### 2.1 Ön gereksinimler

```bash
# Flutter SDK (Apple Silicon)
brew install --cask flutter          # ya da flutter.dev'den indirip PATH'e ekle

# Android tarafı: Android Studio + SDK + platform tools
brew install --cask android-studio

flutter doctor                        # eksikleri söyler
flutter doctor --android-licenses     # lisansları kabul et
```

`flutter doctor` çıktısında **Android toolchain** ve bir **cihaz/emülatör**
satırının yeşil olması yeterli; iOS/Xcode kısmı şimdilik gerekmiyor (K-009:
kişisel aşamada hedef Android).

### 2.2 Projeyi al

```bash
git clone https://github.com/afgover/takip.git
cd takip
```

### 2.3 Platform klasörünü üret

`android/` klasörü repoda **yok** — iskelet SDK'sız bir ortamda yazıldığı için
hiç üretilmedi. Bir kez üretilecek:

```bash
flutter create . --platforms=android --org com.afgover
```

> ⚠️ **`--org` önemli.** Uygulama paket adını belirler (`com.afgover.takip`) ve
> sonradan değiştirmek uygulamayı yeniden kurmayı gerektirir. Başka bir alan
> adın varsa şimdi karar ver.

> ⚠️ **Komut sonrası `git diff` bak.** `flutter create` var olan `.gitignore`,
> `README.md` gibi dosyalara dokunabiliyor. `lib/` klasörüne dokunmaz, ama
> istemediğin değişiklikleri geri al:
> ```bash
> git status
> git checkout -- .gitignore README.md   # gerekiyorsa
> ```

### 2.4 Bağımlılıklar ve doğrulama

```bash
flutter pub get
flutter analyze     # "No issues found!" beklenir
flutter test        # 191 test geçmeli
```

> `pubspec.lock` repoda ve **Flutter 3.27.1 / Dart 3.6** ile çözülmüştü. Daha
> yeni bir Flutter kullanıyorsan `pub get` lock'u güncelleyebilir; bu normal,
> ama analiz veya testlerde bir kırılma olursa ilk şüpheli sürüm farkıdır.

### 2.5 Çalıştır

```bash
flutter devices     # cihaz/emülatör görünüyor mu
flutter run
```

Üretilen `android/` klasörünü commit'lemeyi unutma:

```bash
git add android/
git commit -m "build: android platform klasörü üretildi (B-020)"
```

---

## 3. Token (B-015)

GitHub → **Settings → Developer settings → Personal access tokens →
Fine-grained tokens → Generate new token**

| Alan | Değer |
|---|---|
| Repository access | **Only select repositories** → `afgover/takip` |
| Permissions → **Contents** | **Read and write** |
| Permissions → **Metadata** | **Read** (otomatik gelir) |

Aynı adımlar uygulamanın onboarding ekranındaki "Token nasıl alınır?"
bölümünde de yazılı.

> Token yalnızca cihazın güvenli deposunda (`flutter_secure_storage`) durur.
> **Hiçbir dosyaya, hiçbir commit'e yazma.** Repo tek kullanıcılı olsa da
> token kod+veri içeren bir repoya erişiyor (R-005).

Uygulama açılınca onboarding ekranı gelir: repo alanı `afgover/takip` olarak
dolu gelir, token'ı yapıştır, **Bağlan**. Uygulama kaydetmeden önce iki istek
atar — hub okunabiliyor mu ve token yazabiliyor mu (B-022, B-026). Hata
alırsan mesaj ne yapman gerektiğini söyler.

---

## 4. İlk gerçek döngü (B-034'ün cihaz ayağı)

Kurulum bittiğinde yapılacak test:

1. Telefondan **Ekle** sekmesiyle bir görev oluştur.
2. `hub/tasks/inbox/` altında dosyanın oluştuğunu GitHub'da gör.
3. Agent'a haber ver; görev `inbox → active → done` döngüsünden geçirilsin.
4. Uygulamada görevin önce "Ele alınıyor", sonra **Tamamlananlar**'da sonucuyla
   göründüğünü doğrula.

Bu tamamlandığında B-034 kapanır ve **Aşama 2** kapatılabilir.

---

## 5. Sonrası: bir hafta kullanım (B-052)

Sürtünme noktalarını **doğrudan uygulamadan** inbox'a görev olarak at. Bu hem
geri bildirimi toplar hem sistemi kullanır. O haftadan çıkanlar şunları
belirleyecek:

- **B-053/B-035** — revizyon turu
- **B-064** — "pro versiyon" değerlendirmesinin yeniden açılıp açılmayacağı
  (K-017: ertelendi; yeniden açma ölçütleri orada yazılı)
- **Faz 6** — webhook/push, GitHub App, arşivleme, çoklu proje

---

## 6. Açık uçlar (acil değil)

- **`taskr_takip` reposunun eski commit geçmişi.** Takip projesinin eski hub
  geçmişi oraya kopya olarak kalmış durumda; silinmesi izin katmanınca
  engellenmişti, kullanıcı onayıyla temizlenebilir. README'de hangi reponun
  geçerli olduğu yazılı, işlevsel bir sorun değil.
- **taskr'ın kendi hub iskeleti.** `taskr_takip` orijinal taskr projesi için
  rezerve edildi (K-013) ama hub iskeleti henüz kurulmadı.

---

## 7. Yeni oturuma başlayan agent için

Okuma sırası:

1. `hub/AGENT_PROTOCOL.md` — kayıt prosedürü (uyulması zorunlu)
2. `hub/SYSTEM.md` — format sözleşmesi (sürüm 1.2)
3. `hub/BACKLOG.md` — açık maddeler
4. `hub/EVOLUTION.md` — kararlar ve gerekçeleri (K-001…K-017)
5. `hub/knowledge/` — kurallar (R), skiller (SK), dersler (L)

Çalışma alışkanlıkları (öğrenilmiş dersler):

- **L-006:** SDK gerektiren iş yapılıyorsa SDK ortama kurulur ve **her
  oturumda** `flutter analyze` + `flutter test` çalıştırılır. "Sonra
  doğrularız" borcu faiziyle döner.
- **L-008:** `testWidgets` içinde gerçek async işi doğrudan `await` etme;
  `tester.runAsync` kullan, yoksa test sessizce asılır.
- **SYSTEM.md §8:** commit mesajı önekleri; ilgisiz değişiklikler aynı
  commit'e konmaz.
