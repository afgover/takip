---
id: A-2026-08-04-001
session: S-2026-08-04-guvenlik-taramasi
type: analysis
title: "Bağımlılık, sır ve Android yapılandırma taraması (SEC-005)"
created: 2026-08-04T15:20:00Z
---

# Bağımlılık, sır ve Android yapılandırma taraması

SEC-005 / B-091 kapsamında koşulan taramanın tam çıktısı. Özet kayıt
`SECURITY.md` → SEC-008.

**Koşum tarihi:** 2026-08-04
**Ortam:** Flutter 3.35.4 (stable, 2025-09-16) · Dart 3.9.2 · macOS arm64

---

## 1. Bilinen zafiyet taraması (OSV)

`pubspec.lock`'taki **68 paketin tamamı** sürümüyle birlikte OSV
(<https://osv.dev>, `Pub` ekosistemi) toplu sorgu uç noktasına soruldu.

**Sonuç: 0 bulgu.** Hiçbir kilitli paket sürümü bilinen bir güvenlik
danışmanlığına denk gelmedi.

### Sonucun doğrulaması (neden "0" gerçekten temiz demek)

Boş bir sonuç, "hiçbir açık yok" kadar kolay "sorgu yanlış kurulmuş"
anlamına da gelir — bu ayrım yapılmadan yazılan bir temiz rapor, olmayan
bir güvence verir. Bu yüzden aynı uç noktaya, **bilinen açıkları olan**
sürümlerden oluşan bir kontrol grubu soruldu:

| Kontrol sorgusu | Yanıt |
|---|---|
| `archive 3.3.0` | GHSA-9v85-q87q-g4vg, GHSA-r285-q736-9v95 |
| `http 0.13.0` | GHSA-4rgh-jx4f-qfcq |
| `dio 4.0.0` | GHSA-9324-jv53-9cc8 |
| `pointycastle 3.0.0` | temiz |
| `encrypt 5.0.0` | temiz |

Kontrol grubu beklenen kayıtları döndürdüğüne göre ekosistem adı ve sorgu
biçimi doğru; projedeki 0 bulgu gerçek bir sonuçtur.

Ayrıca not: projedeki `dio` **5.11.0** sürümünde ve yukarıdaki
GHSA-9324-jv53-9cc8 (dio 4.x) kapsamının dışında.

**Sınır:** Tarama, tarandığı **anın** danışmanlık veritabanına göredir.
Yarın yayımlanacak bir danışmanlık bu sonucu geçersiz kılar — bu yüzden
tarama tek seferlik bir onay değil, tekrarlanması gereken bir iştir.

## 2. Sürüm güncelliği (`flutter pub outdated`)

Doğrudan bağımlılıklardan geride kalanlar:

| Paket | Kilitli | Son | Not |
|---|---|---|---|
| `flutter_secure_storage` | 9.2.4 | 10.3.1 | **ana sürüm farkı** — token'ı saklayan paket |
| `flutter_riverpod` | 2.6.1 | 3.4.2 | ana sürüm farkı; kırıcı değişiklikler var |
| `markdown` | 7.3.0 | 7.3.1 | yama |
| `shared_preferences` | 2.5.3 | 2.5.5 | yama |
| `flutter_lints` (dev) | 5.0.0 | 6.0.0 | ana sürüm farkı |

Geçişli bağımlılıklarda `js 0.6.7` **kullanımdan kaldırılmış** (discontinued)
olarak işaretli. Doğrudan bir bağımlılık değil; Flutter'ın test/web zinciri
üzerinden geliyor ve mobil derlemede çalışan bir kod yolu değil.

Bunların hiçbiri **bilinen bir açık** değildir (madde 1). Buradaki risk
dolaylıdır: bir danışmanlık yayımlandığında ana sürüm farkı, yamaya geçişi
"sürüm yükselt" olmaktan çıkarıp "kırıcı değişiklikleri karşıla"ya çevirir.
Özellikle `flutter_secure_storage` bu yüzden öne çıkıyor — token'ı tutan
paketin yamasının hızlı uygulanabilir olması gerekir.

## 3. SDK güncelliği

Flutter **3.35.4**, 2025-09-16 tarihli; tarama günü itibarıyla ~11 aylık.
TLS yığını (BoringSSL) dâhil ağ ve çizim katmanı motorun içindedir, yani
paket taraması bu yüzeyi hiç görmez. SDK'nın kendi güvenlik yamaları bu
projeye uygulanmış değil.

Bu bir açık kaydı değil (somut bir zafiyete bağlanmadı), ama düzenli
yükseltmenin bağımlılık yükseltmesi kadar güvenlik işi olduğunun kaydıdır.

## 4. Sır taraması

Çalışma ağacı (`lib/`, `android/`, `tool/`, `test/`, `hub/`) ve **git
geçmişinin tamamı** şu desenlere karşı tarandı: `ghp_*`, `github_pat_*`,
`gho_*`, AWS `AKIA*`, PEM özel anahtar blokları (`-----BEGIN ...`).

**Sonuç: eşleşme yok.** `.gitignore` ayrıca `*.keystore` ve `key.properties`
dosyalarını dışarıda tutuyor.

Bu, SEC-001'in ("token hiçbir dosyaya/commit'e/log'a yazılmaz") kod tarafında
tutulduğunun bağımsız doğrulamasıdır.

## 5. Android yapılandırması

| Kontrol | Durum |
|---|---|
| İzinler | Yalnız `INTERNET` — yer, kamera, depolama, rehber yok |
| `android:usesCleartextTraffic` | Tanımsız → hedef SDK 28+ varsayılanı: **düz metin HTTP kapalı** |
| `networkSecurityConfig` | Tanımsız → varsayılan (sistem CA'ları) |
| `queries` | Yalnız `ACTION_PROCESS_TEXT` (Flutter motorunun metin seçimi için) |
| `android:allowBackup` | **Tanımsız → varsayılan `true`** (bulgu, aşağıda) |
| Release imzası | **Debug anahtarı** (`signingConfigs.getByName("debug")`) (bulgu, aşağıda) |

### Bulgu A — Otomatik yedekleme açık, çevrimdışı kopya düz metin

`allowBackup` ayarlanmadığı için Android varsayılanı geçerli: uygulamanın
özel veri alanı **Auto Backup** ile kullanıcının Google hesabına çıkabilir.
Bu alanda SEC-007'de kayıtlı **şifresiz hub kopyası** duruyor
(`shared_preferences`, hub'ın bütün markdown içeriği).

SEC-007'de kabul edilen risk "cihaz ele geçerse okunabilir" idi. Otomatik
yedekleme bu sınırı genişletiyor: içerik cihazdan çıkıp buluta gidiyor ve
oradaki koruma artık Google hesabının güvenliğidir. Kabul edilen riskin
kapsamı, kabul edildiğinde bilinenden geniş.

**Token için durum farklı:** `flutter_secure_storage` Android'de
EncryptedSharedPreferences kullanıyor ve anahtar Keystore'da, dışa
aktarılamaz. Yedeğe düşen şifreli metin başka cihazda çözülemez — yani
otomatik yedekleme token'ı sızdırmıyor, ama işe de yaramıyor: cihaz
değişiminde token zaten geri gelmiyor. Bu yüzden yedeklemeyi kapatmanın
kullanıcıya maliyeti yok; bağlantıların taşınması için zaten parolayla
şifreli dışa aktarma var (B-055 / SEC-002).

Karşılığı: `android:allowBackup="false"` (ya da hub kopyasını dışarıda
bırakan `dataExtractionRules`). → SEC-009, B-100

### Bulgu B — Release derlemesi debug anahtarıyla imzalanıyor

`android/app/build.gradle.kts` release bloğu Flutter şablonundan geldiği gibi
duruyor ve **debug imza yapılandırmasını** kullanıyor. Debug anahtarı Android
SDK ile birlikte gelen, herkeste aynı olan bilinen bir anahtardır.

Bugün etkisi sınırlı: APK yalnız `tool/install.sh` ile geliştirici
cihazına kuruluyor. Ama B-097'nin planı "GitHub Releases'ta APK" diyor —
o adımda bu doğrudan bir güvenlik sorununa dönüşür: üçüncü biri aynı paket
adıyla, aynı bilinen anahtarla imzalı bir APK üretip **güncelleme olarak
kurulabilir** hâle getirebilir. Yayımlanan yapı kendi anahtarıyla
imzalanmalı, anahtar repoya girmemeli (`.gitignore` `*.keystore` ve
`key.properties`'i zaten dışarıda tutuyor). → SEC-010, B-101

## 6. Kapsam dışı

- **Statik kod analizi (SAST) yapılmadı.** `flutter analyze` bir lint aracıdır,
  güvenlik çözümleyicisi değil.
- **iOS yapılandırması** hiç incelenmedi; proje iOS'ta derlenmiyor (README).
- **Sunucu tarafı yok** (K-001) — inceleneceği bir arka uç bulunmuyor.
