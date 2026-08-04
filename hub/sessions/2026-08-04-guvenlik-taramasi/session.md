---
id: S-2026-08-04-guvenlik-taramasi
date: 2026-08-04
status: open
reconstructed: false
topics: [guvenlik, bagimlilik-taramasi, token-kapsami]
artifacts:
  - artifacts/S-2026-08-04-guvenlik-taramasi/bagimlilik-ve-yapilandirma-taramasi.md
tasks_touched: [T-006]
---

# Oturum: Açık güvenlik işleri — SEC-005 ve SEC-006

## Özet
(oturum kapanışında yazılacak)

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
