---
id: S-2026-08-04-guvenlik-taramasi
date: 2026-08-04
status: closed
reconstructed: false
topics: [guvenlik, bagimlilik-taramasi, token-kapsami, sozlesme-1.12, isaretler]
artifacts:
  - artifacts/S-2026-08-04-guvenlik-taramasi/bagimlilik-ve-yapilandirma-taramasi.md
tasks_touched: [T-006, T-007, T-008]
---

# Oturum: Açık güvenlik işleri — SEC-005 ve SEC-006

## Özet
Gün ikiye bölündü: **açık güvenlik işleri** ve **kullanımdan gelen iki istek**.

**Güvenlik (B-091, B-092 — backlog'daki son iki agent maddesi).** Bağımlılık ve
zafiyet taraması ilk kez koşuldu: 68 paket OSV'ye soruldu, bilinen zafiyet yok.
"0 bulgu"yu sonuç olarak yazmadan önce sorgunun gerçekten çalıştığı, bilinen
açıkları olan sürümlerden kurulu bir kontrol grubuyla doğrulandı — doğrulanmamış
bir boş sonuç, olmayan bir güvence verir (L-035). Sır taraması çalışma ağacı ve
git geçmişinin tamamında temiz. Tarama iki bulgu üretti: Android otomatik
yedeklemesi cihazdaki şifresiz hub kopyasını buluta taşıyor (SEC-009) ve release
derlemesi debug anahtarıyla imzalanıyor (SEC-010 — B-097'nin APK adımının ön
koşulu). Token kapsamı denetimi eklendi: kapsam, erişim doğrulamasının aynı
yanıtından okunuyor, fazladan istek yok (SK-011); yorum tek yönlü ve uyarı
engellemiyor — çalışan bir token'ı reddetmek uygulamayı kullanılamaz hâle
getirirdi. Kapanamayan kısım ayrı kayıt oldu (SEC-012) ve ölçümü kullanıcıya
soruldu (T-006).

**Sözleşme 1.12 (T-007, T-008 — kullanıcının uygulamadan attığı iki görev).**
İkisi de aynı boşluğun yüzleriydi: sistem kullanıcıya **soru soramıyordu** ve
kullanıcı bir yeri **sonra bulmak üzere** işaretleyemiyordu. Seçenekli bekleme
(`options`/`multi` + serbest açıklama, cevap `waiting-answer` olarak inbox'a) ve
yer imi (`mark: bookmark`, hiçbir koşulda göreve dönüşmez) eklendi; bütün
repolardaki işaretler tek listede toplandı ve oradan kaydın kendi reposundaki
belgeye gidiliyor. Yer imi ancak sonradan bulunabiliyorsa işe yarar.

Uygulama sırasında sessiz bir veri kaybı yakalandı: bir dalın koşulu genişleyince
gövdesinin yazılmamış varsayımı yanlışa döndü ve yer imine yazılan not
kaydedilmiyordu (L-036). 350 → **397 test**, analyze temiz.

Geriye kalan açık işler kullanıcıya bağlı (B-097 public karar, B-052 kullanım)
ya da bu oturumun ürettiği yeni maddeler (B-100 yedekleme, B-101 imza, B-102
tarama tekrarı, B-103 token genişliği).

## Kayıt

### Kullanıcı
> repodaki gorevlerden devam et

### Agent
Açılış kontrolü: `tasks/inbox/` boş, `active/` ve `waiting/` boş — bekleyen
kullanıcı görevi yok. Sözleşme §10 kontrolü gereksiz: bu repo ana kopyanın
kendisi (1.11).

`BACKLOG.md`'de agent'ın tek başına ilerletebileceği iki açık madde kaldı,
ikisi de güvenlik: **B-091** (SEC-005 bağımlılık/zafiyet taraması) ve
**B-092** (SEC-006 token kapsamı doğrulaması). Diğer açık maddeler ya
kullanıcıya bağlı (B-052 bir haftalık kullanım, B-097 public karar,
B-098 store) ya da 2. plana alınmış Faz 6 işleri. Sıra: B-091 → B-092.

### Agent — B-091 (SEC-005 taraması)
Tarama koşuldu, tam çıktı
[artifact A-2026-08-04-001](../../artifacts/S-2026-08-04-guvenlik-taramasi/bagimlilik-ve-yapilandirma-taramasi.md)'de,
özeti SEC-008'de.

**Zafiyet:** `pubspec.lock`'taki 68 paketin tamamı OSV'ye (Pub ekosistemi)
soruldu → **bilinen zafiyet yok**. Bunu "temiz" diye yazmadan önce sorgunun
gerçekten çalıştığı doğrulandı: bilinen açıkları olan sürümlerden (archive
3.3.0, http 0.13.0, dio 4.0.0) kurulu bir kontrol grubu beklenen GHSA
kayıtlarını döndürdü. Doğrulanmamış bir "0 bulgu", olmayan bir güvence verir.

**Sır:** çalışma ağacı ve **git geçmişinin tamamı** token/anahtar desenlerine
karşı tarandı → eşleşme yok. SEC-001'in bağımsız doğrulaması.

**İki yeni bulgu:**
- **SEC-009** — `allowBackup` tanımlı değil, Android varsayılanı `true`:
  cihazdaki **şifresiz hub kopyası** (SEC-007) Google hesabına çıkabiliyor.
  SEC-007 riski "cihaz ele geçerse" diye kabul edilmişti; kapsamı kabul
  edildiğinden genişmiş. Token yedekten zaten geri gelmiyor (Keystore anahtarı
  dışa aktarılamaz), yani yedeklemeyi kapatmanın maliyeti yok. → B-100
- **SEC-010** — release derlemesi Flutter şablonundan gelen **debug
  anahtarıyla** imzalanıyor. Bugün etkisi sınırlı (APK sadece kendi cihaza
  kuruluyor) ama B-097'nin "Releases'ta APK" adımının ön koşulu. → B-101

Ayrıca SEC-011 açıldı: tarama koştuğu günün veritabanına göredir; tekrar
aralığına karar verilmedikçe "taradık" cümlesi zamanla sessizce yanlışa döner.
→ B-102

Ders çıktı: **boş tarama sonucu doğrulanmadan "temiz" sayılmaz** (L-035).

### Agent — B-092 (SEC-006 token kapsamı)
Sorunun zor kısmı B-026'da bulunmuştu: GitHub'da bir token'ın izinlerini soran
uç nokta **yok** (L-009). Aynı ruhta cevap verildi — GitHub'ın kendiliğinden
söylediğine bakmak.

**İki belgelenmiş sinyal, ikisi de bedava:**
- `X-OAuth-Scopes` yanıt başlığı: klasik (OAuth) token'larda GitHub
  yetkilendirilmiş scope'ları her kimlikli yanıtta bildiriyor. Erişim
  doğrulaması zaten bir istek atıyor; kapsam **o yanıttan** okunuyor, fazladan
  çağrı yok. Fine-grained token'da başlık hiç gelmiyor — yokluğu da bilgi.
- Token öneki: `ghp_` klasik, `github_pat_` fine-grained (GitHub'ın
  belgelediği önekler; ikisi de doğrulandı).

**Yorum tek yönlü** (B-026'daki kural): sinyaller yalnız "kapsam geniş"
diyebilir, "dar" diyemez. Bilinmeyen, geniş sayılmıyor — böylece kontrol
yanlış alarm veremez. Yanlış alarm verseydi kullanıcı ilk seferden sonra
uyarıyı okumaz olurdu.

**Uyarı engellemiyor.** Çalışan bir token'ı reddetmek, elinde klasik token
olan kullanıcıya uygulamayı tümden kapatırdı; güvenlik kontrolü kullanıcıyı
işini yapamaz hâle getirirse sonuç daha güvenli değil, kontrolsüz olur. Onay
kutusu kullanıcı **hâlâ token alanının başındayken** çıkıyor: "Vazgeç" hiçbir
şey kaydetmiyor ve dar bir token yapıştırmak tek hareket uzakta. Uyarı
sırasında ilerleme göstergesi durduruluyor — ağ işi bitmiştir, beklenen şey
kullanıcının cevabıdır.

`lib/hub/token_scope.dart` (saf mantık) + `ContentsApi.probePath` (başlığı
taşır, yorumlamaz — katman ayrımı korundu) + onboarding ve bağlantı
düzenlemede ortak onay kutusu. **365 test** (15 yeni), analyze temiz. → SK-011

**Kapanmayan kısım dürüstçe ayrıldı:** "All repositories" ile üretilmiş bir
fine-grained token da hesabın tamamını kapsar ve bu kontrol onu göremez.
Ölçülebilir mi bilinmiyor (`GET /user/repos`'un fine-grained davranışı
belgelenmemiş) ve buraya belgelenmemiş bir davranışa dayanan tahmin konmadı —
B-026'da tam olarak bu hata yapılmıştı. Ölçüm gerçek bir token gerektiriyor,
token agent'a verilmez (SEC-001): **T-006** `waiting/`e kondu, kullanıcıdan
yalnız bir sayı isteniyor. → SEC-012, B-103

### Agent — inbox'a iki yeni görev düştü (oturum sürerken)
Push sırasında uzakta iki commit çıktı: kullanıcı bu oturum sürerken
uygulamadan iki görev eklemiş (`05e0221`, `618c821`). Rebase'lendi, hepsi
push'landı.

- `2026-08-04-gorev-aksiyon.md` — `waiting/` görevlerinde tek seçenek
  ("Yapıldı") var; agent seçenekleri çoğaltabilsin, kullanıcı aralarından
  seçsin (gerekirse çoklu), cevaplanınca soru kapansın.
- `2026-08-04-bookmark-ekleme.md` — işaret türlerine **bookmark** eklensin;
  bütün annotasyonlar tek listede toplansın ve oradan ilgili belgeye
  gidilebilsin.

İkisi de ele alınmadı (ID atanmadı, `active/`e taşınmadı): sözleşme gereği
inbox raporlanır, kullanıcı yönlendirmeden işlenmez. İkisi de sözleşmeye
dokunuyor — biri `waiting/` şemasına seçenek alanı, diğeri `mark` kümesine
yeni bir tür ekler.

### Kullanıcı
> Inbox'taki iki görev (sıradaki iş seçimi)

### Agent
İkisi de `active/`e alındı (T-007, T-008). Sözleşme değişikliği gerektirdikleri
için önce iki tasarım kararı soruldu; kullanıcı ikisinde de öneriyi seçti:
**(1)** seçenekli cevaba **her zaman** isteğe bağlı serbest metin eşlik etsin,
**(2)** yer imi **her zaman** `notes/`a gitsin (notlu olsa bile).

### Agent — T-007 · Seçenekli bekleme (sözleşme 1.12, B-104)
Boşluk şuydu: `waiting/` 1.4'ten beri var ama kullanıcının tek cevabı
"Yaptım"dı. Agent bir *karar* sorduğunda karşılığı yoktu; cevap sohbette
kalıyordu — yani `waiting/`in var oluş sebebine (sohbet kapanır, kayıt kalır)
aykırı bir yerde birikiyordu.

Agent artık göreve `options: [...]` (+ `multi`) yazıyor. App seçenekleri
gösteriyor, seçimin yanına açıklama alıyor, cevabı `waiting-answer` etiketiyle
`inbox/`a yazıyor (R-001 değişmedi — app asıl dosyayı taşımıyor).

Üç kural kodda karşılığını buldu: seçenek varsa "Yaptım" **gösterilmiyor**
(agent soru sordu, cevabı "yaptım" değil); seçenek yoksa davranış 1.11'deki
gibi kalıyor (eski görevler bozulmadı); cevaplanan soru kapanıyor — bir görev
= bir soru, aksi hâlde agent'ın kuyruğunda hangisinin geçerli olduğu belirsiz
iki kayıt kalırdı. `isQuestion` ayrıca `waiting/` şartı arıyor: başka klasörde
`options` bulunsa bile o iş kullanıcıyı beklemiyordur.

### Agent — T-008 · Yer imi + işaretler listesi (sözleşme 1.12, B-105)
`mark: bookmark` (mavi) eklendi ve **ilk defa göreve dönüşmeyen** bir işaret
oldu (R-007). B-099'da ayrımı notun varlığı yapıyordu; yer iminde niyet zaten
adında.

Asıl iş işaretin kendisi değil **listesi**: Tarayıcı → İşaretler bütün bağlı
repolardaki işaretleri (görev **ve** not) tek listede topluyor, renge göre
süzüyor, dokununca kaydın **kendi** reposundaki belgeyi açıyor. Liste çok
kaynaklı olduğu için açılan yol da baştan çok kaynaklı kuruldu
(`docContentForProvider`) — L-031/L-034'ün üçüncü tekrarı, bu sefer hata
yapılmadan.

**Yakalanan sessiz hata:** notsuz dal `note` parametresini hiç geçirmiyordu —
gerek yoktu, çünkü oraya yalnız not boşken giriliyordu. Yer imi o dalın
koşulunu genişletince kullanıcının yazdığı not sessizce kayboluyordu. Hiçbir
şey hata vermedi; test yakaladı. → L-036

Ayrıca sözleşme uyum testi eklendi: her `TaskMark` değeri `SYSTEM.md`'de
geçiyor mu (K-031'in dersinin otomatiği).

**397 test** (26 yeni), analyze temiz. Kurulum talimatı ve README de 1.12'ye
çekildi; README'deki "uygulama token kapsamını doğrulamıyor" cümlesi artık
yanlış olduğu için SEC-012'ye göre düzeltildi. T-006 da 1.12'nin kendi
özelliğiyle yeniden yazıldı: kullanıcının cevabı artık üç seçenekten biri.
