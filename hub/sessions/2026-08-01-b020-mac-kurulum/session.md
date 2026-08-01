---
id: S-2026-08-01-b020-mac-kurulum
date: 2026-08-01
status: open
topics: [kurulum, flutter, android, b020, b015]
artifacts: []
tasks_touched: []
---

# Oturum: B-020 — Mac'te Flutter kurulumu ve ilk cihaz koşumu

## Özet
(Oturum kapanırken doldurulacak.)

## Kayıt

### Kullanıcı
> takip projesinde devam ediyoruz. Önce şu üç dosyayı oku:
>
> - hub/AGENT_PROTOCOL.md   (kayıt prosedürü — uyman zorunlu)
> - hub/artifacts/reference/kurulum-ve-devir.md   (devir notu, nerede kaldığımız)
> - hub/BACKLOG.md   (açık maddeler)
>
> Bugün B-020'yi yapıyoruz: Mac'te Flutter kurulumu, android/ klasörünün
> üretilmesi ve uygulamanın ilk kez cihazda çalıştırılması. Token'ı (B-015)
> ben üreteceğim, sırası gelince söyle.
>
> https://github.com/afgover/takip
>
> reposu

### Agent
Çalışma klasörü (`~/Desktop/takip`) boştu; repo `main`'den klonlandı. Üç dosya
okundu, `SYSTEM.md` (sürüm 1.2) ve hub yapısı kontrol edildi.
`tasks/inbox/` boş — yeni görev yok.

Ortam taraması sonucu **beklenenden iyi**: Flutter SDK ve Android Studio zaten
kurulu, ayrıca kurulum gerekmiyor.

| Bileşen | Durum |
|---|---|
| Flutter | 3.35.4 stable / Dart 3.9.2 — `~/development/flutter` |
| Android Studio | kurulu (`/Applications`) |
| Android SDK | `~/Library/Android/sdk` mevcut |
| Java | Temurin 25.0.2 LTS |
| Xcode | kurulu (bu aşamada gerekmiyor, K-009) |
| Homebrew | yok (Flutter zaten kurulu olduğu için gerekmedi) |
| Mimari / OS | arm64 / macOS 26.5.1 |

İki risk not edildi: (1) Flutter 3.35.4, `pubspec.lock`'un çözüldüğü 3.27.1 /
Dart 3.6'dan yeni — `pub get` lock'u güncelleyebilir, analiz/test kırılırsa ilk
şüpheli budur (devir notu §2.4). (2) Disk boş alanı düşük görünüyor
(~2.6 GB) — Gradle ilk derlemede bundan fazlasını indirebilir, `flutter doctor`
ile birlikte doğrulanacak.

`flutter doctor -v`: Android toolchain (SDK 36.1.0, lisanslar kabul edilmiş) ve
Android Studio 2025.3 yeşil. Tek uyarı CocoaPods eksikliği — iOS'a ait, K-009
gereği bu aşamada gerekmiyor. Bağlı cihazlar: **SM F731B** (gerçek telefon,
Android 16) ve `sdk gphone64 arm64` emülatörü.

Sürüm farkı riski `android/` üretilmeden önce izole edildi (analyze/test bu
klasöre ihtiyaç duymuyor):

- `flutter pub get` → 14 bağımlılık güncellendi, `pubspec.lock` değişti. Devir
  notu §2.4'ün öngördüğü normal durum.
- `flutter test` → **191 test geçti**, kırılma yok.
- `flutter analyze` → 2 `info`: `DropdownButtonFormField`'ın `value` parametresi
  Flutter 3.33 sonrası `initialValue` lehine deprecate edilmiş
  (`add_task_screen.dart:150` ve `:164`).

Deprecation, lock'un bu oturumda güncellenmesinin doğrudan sonucu olduğu için
B-020 kapsamında düzeltildi. Flutter kaynağı önce doğrulandı: `dropdown.dart`
parametreyi `initialValue: initialValue ?? value` diye forward ediyor (saf isim
değişikliği) ve `didUpdateWidget` değer değişimini hâlâ yakalıyor — yani
`setState` ile sürülen öncelik/kategori seçimi davranışı aynı kalıyor. Düzeltme
sonrası `flutter analyze` → **No issues found!**, feature testleri (57) geçiyor.

### Kullanıcı
> (soruya cevap) Paket adı: "Başka bir org gireceğim" · Disk: "Önce yer açayım"
> · Hedef cihaz: "SM F731B — gerçek telefon"

### Agent
`flutter create` iki koşula bağlandığı için duruldu: (1) org değeri kullanıcıdan
bekleniyor — nihai paket adı `<org>.takip` olacak, (2) kullanıcı diskte yer
açacak. İlk koşum hedefi gerçek telefon olarak belirlendi.

Beklerken bağımsız iş kapatıldı: deprecation düzeltmesi + güncellenen
`pubspec.lock` commit'lendi.
