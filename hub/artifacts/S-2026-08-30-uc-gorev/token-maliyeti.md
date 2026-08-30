---
id: A-2026-08-30-001
session: S-2026-08-30-uc-gorev
type: analysis
title: "Hub'ın token/bağlam maliyeti — ölçüm, A/B simülasyonu, azaltma seçenekleri"
created: 2026-08-30T03:10:00Z
---

# Hub'ın token/bağlam maliyeti (T-023)

## Ölçülebilenin sınırı — baştan

Git geçmişi *içerik* kaydeder, token harcamasını kaydetmez. "Geçmiş repoların
toplam token kullanımı" doğrudan okunamaz; okunabilenler şunlar ve bu çalışma
onlara dayanır: dosya boyutları ve büyüme hızı, oturum sayıları, ve **bugün
koşulan kontrollü simülasyonun gerçek token sayımları**.

## 1. A/B simülasyonu — ana sonuç

Aynı iş, aynı model, aynı gün; tek fark hub protokolü:

| koşum | iş | protokol | token | araç çağrısı |
|---|---|---|---|---|
| B2 — hub'sız | README'ye satır ekle | — | 38.505 | 2 |
| **A2 — hub'lı** | README'ye satır ekle | ✓ tam (oturum kaydı, kontroller, 3 commit) | **49.110** | 11 |
| B1 — hub'sız | "B-002 ne durumda" | — | 38.667 | 3 |
| A1 — hub'lı | "B-002 ne durumda" | **kendisi atladı** | 38.724 | 3 |

**Kontrollü fark: oturum başına ≈ +10.6k token (+%28), en küçük işte.**
Ek maliyetin kaynağı dosya okumak değil, protokolün gerektirdiği **ek
turlar**: her araç çağrısı bağlamın tamamını yeniden taşır; A2'nin 11
çağrısına karşılık B2'nin 2 çağrısı var. Taban ~38.5k'nın neredeyse tamamı
harness'in kendisi (sistem promptu + araç tanımları) — hub'ın küçük
dosyalarını okumak ölçülür fark yaratmıyor.

İkinci veri kümesi (2026-08-28, farklı model, kontrolsüz ama tutarlı):
protokolü tam koşan yedi ajan küçük işler için 54.7k–95.1k harcadı —
zengin açılış (curl, tarama kontrolü, waiting görevi) turu çoğalttıkça
maliyet tabanın ~2.5 katına kadar çıkıyor.

**Yan bulgu:** A1 protokolü kendiliğinden atladı (git'te iz yok). Uyum
değişkenliği token ölçümünde de görünüyor — maliyet, protokole *uyulduğu
oranda* ödeniyor. Repoların hiçbirinde ajanı prosedüre bağlayan bir
`CLAUDE.md` yok (A-2026-08-28-001'in bulgusu); uyum stabilleşirse maliyet de
öngörülebilirleşir. İkisi aynı kararın iki yüzü.

## 2. Okuma yükü ve büyüme — riskin adresi

Çekirdek hub dosyaları (sözleşme + backlog + plan + güvenlik + evolution +
knowledge), tahmini token (bayt/4):

| hub | çekirdek | oturum sayısı | büyüme |
|---|---|---|---|
| takip | ~82k | 65 | ~309 KB/ay |
| Copilot_takip | ~132k | 36 | ~565 KB/ay |
| din_takip | ~115k | 93 | ~506 KB/ay |
| datasources_takip | ~120k | 18 | ~513 KB/ay |
| diğer altı | 25k–70k | 9–34 | 140–435 KB/ay |

"Silme yok" kuralı gereği bu büyüme **tek yönlü**. Bugünkü davranış maliyeti
sınırlıyor: ajanlar seçici okuyor (grep/tail), sözleşme kontrolü `curl`+`diff`
ile bağlama hiç girmeden kabukta çözülüyor (iyi tasarım), ve `takip`in
oturum kayıtları ortalama ~1.5 KB (ucuz). Risk, **tamamı okunan** dosyalarda:
`BACKLOG.md` tek başına ~17.5k token ve protokol "bak" diyor — tamamını
okuyan bir ajan, açılış maliyetini tek dosyayla ikiye katlar.

## 3. Bağlam daralması etkileşimi

Sabit oturum yükü F, çalışma penceresinden düşer: F büyüdükçe sıkıştırma
erken gelir ve sıkıştırma bu hub'larda ölçülmüş bir kayıp üretir
(318 oturumun %25'i `reconstructed`, A-2026-08-28-001 §G). Yani hub'ın
maliyeti iki katmanlı: doğrudan token + erken sıkıştırmanın kayıp riski.
`hub-guard` (P-017) ikinci katmanı hedefliyor.

Karşı kefe — ölçülemedi ama kayda değer: oturum kayıtları ve özetler,
**sonraki** oturumların bağlamı sıfırdan türetme maliyetini düşürür. Hub'sız
bir projede yeni oturum geçmişi koddan/commit'ten kazıyarak öğrenir; hub'lı
projede `## Özet` okur. Bu tasarruf token sayımıyla ölçülmedi (iki uzun
vadeli ikiz proje gerekirdi) ve bu çalışma onu iddia olarak değil açık soru
olarak bırakıyor.

## 4. Geçmişe dönük kaba tahmin

318 oturum × oturum başına 10k–57k ek yük ≈ **3M–18M token** birikmiş hub
ek maliyeti (tüm repolar, tüm zamanlar). Aralık bilinçli geniş: yük protokole
uyum oranına ve işin büyüklüğüne göre değişiyor; büyük oturumlarda sabit yük
oransal olarak küçülür (amortisman), küçük oturumlarda işin kendisinden
pahalı olabilir — A2'de %28'di, "tek cümlelik soru"da %40'a çıkabilirdi.

## 5. Azaltma seçenekleri — öneri, karar değil (R-008)

Kaldıraç sırasıyla:

1. **Turu azalt, dosyayı değil.** En pahalı şey ek araç çağrısı. Madde 4b'nin
   kalıbı doğru: çok kontrolü tek script'e topla (`audit.sh` bir çağrıda
   dokuz kontrol koşuyor). Açılışın diğer adımları da benzer biçimde tek
   birleşik komuta inebilir.
2. **BACKLOG'un tamamını okutma.** "Yarım kalmışları hatırla" için açık
   maddeler `grep '\- \[ \]'` ile çıkar — 17.5k token yerine birkaç yüz.
   Protokole tek cümlelik bir yöntem notu yeter.
3. **Arşivleme zaten backlog'da:** B-062 (`done/` yıllık arşiv). Büyüme tek
   yönlü olduğu için bu, uzun vadede okuma yükünü sınırlayan tek yapısal
   önlem; kapsamı kapanmış fazlara/planlara genişletilebilir.
4. **Uyumu stabilize et:** protokol atlanınca maliyet düşüyor ama kayıt da
   tutulmuyor — ucuzluk değil, sessiz borç (%25 `reconstructed`'ın kaynağı).
   Tek satırlık bir `CLAUDE.md` işaretçisi hem uyumu hem maliyet
   öngörülebilirliğini düzeltir; repo başına karar kullanıcının.

Sonuç tek cümlede: **hub'ın bedeli küçük işte oturum başına ~%28 ve kaynağı
tur sayısı; büyüme riski `BACKLOG` gibi tamamı okunan dosyalarda; en güçlü
kaldıraç dosya küçültmek değil, tur birleştirmek.**

---

# Ek (2026-08-30, S-2026-08-30-karsi-olgu): öneri riskleri ve karşı-olgu

## 6. Dört önerinin olası negatif etkileri

Kullanıcı dört öneriyi yerinde buldu ve **uygulamadan önce** risklerini istedi.
Tek tek, uygulama (app) tarafına dokunanlar ayrıca işaretli:

**Ö1 — açılış kontrollerini tek komuta birleştirmek.**
- *Kara kutu riski:* model kontrollerin çıktısını görür, sürecini görmez.
  Script bir kontrolü sessizce atlarsa ya da yanlış ölçerse model fark edemez —
  `audit.sh`'ın kendi geçmişi kanıt: ilk koşumu 120 bulgunun çoğu aracın
  kendi hatasıydı. Birleştirme, hata yüzeyini modelden script'e taşır;
  script'in testi ve bakımı **kalıcı yük** olur.
- *L-035 riski:* "koştu" sanılan koşmayan kontrol. Bekçideki kural burada da
  şart: koşamayan kontrol "koştu" yazılmaz.
- *Esneklik kaybı:* bugün ajan bağlama göre derinleşiyor (şüphelendiğinde
  dosyaya iniyor). Tek komut bunu ortadan kaldırmaz ama caydırır; anomalide
  model yine dosyaya iner ve tasarrufun bir kısmı geri ödenir.
- *App etkisi:* yok (ajan tarafı).

**Ö2 — BACKLOG'u grep'le okumak.**
- *En ciddi risk — gövde körlüğü:* açık madde satırı, maddenin gövdesindeki
  gerekçeyi ve ön koşulları taşımaz. Somut örnek bu repodan: B-098'in
  "ön koşulu B-097 ve gerçek talep" cümlesi **gövdede** — grep'le bakan bir
  ajan store işine ön koşulsuz başlardı. Tasarruf 17k token, bedeli yanlış
  işe girmek olabilir; asimetrik bir takas.
- *Sessiz boşalma:* format değişirse desen boş döner ve "açık iş yok" gibi
  görünür — denetçiye "grep sonucu ile işaretsiz madde sayısı eşit mi"
  kontrolü eklenmeden uygulanmamalı.
- *App etkisi:* yok; ama protokole yazılırsa sözleşme sürümü artar → sürüm
  tutarlılık testi ve iki README dokunuşu (mekanik, küçük).

**Ö3 — arşivleme (B-062 genişletmesi).**
- *App etkisi — en dokunanı bu:* §15 ID bağlantıları ve uygulamanın bağlantı
  çözücüsü (P-001.8) arşiv yolunu bilmiyor; `done/2025/...` gibi bir yapıya
  taşınan dosyaya işaret eden her bağlantı **uygulamada kırılır**. Tarayıcı
  ekranları, görev sayaçları ve `audit.sh`'ın zincir kurucusu da arşiv
  dizinini tanımalı. Yani Ö3 bir temizlik değil, **şema değişikliği**:
  sözleşme sürümü + ayrıştırıcı + testler + göç kuralı ister.
- *Görünürlük bedeli:* "silme yok"un amacı geçmişin okunabilirliği; arşiv
  fiilen görünürlüğü azaltır. Eski kararı arayan ajan iki yerde arar ya da
  hiç bulamaz.
- *Kazancı sınırlı:* açılışta zaten kimse `done/` okumuyor — arşivin
  düşürdüğü maliyet, tamamı okunan dosyalarınki değil. Önce Ö2 tarzı seçici
  okuma denenmeli; Ö3 ancak dosyalar fiziksel olarak hantallaşınca değer.

**Ö4 — `CLAUDE.md` işaretçisi.**
- *Bilinçli maliyet artışı:* uyum stabilleşince atlanan protokoller de
  koşar — A1'in 38.7k'sı 49–95k sınıfına çıkar. Bu bir hata değil, tercihin
  kendisi; ama "token azaltma" çalışmasının önerisi olarak paradoksal
  durduğu açıkça söylenmeli: Ö4 maliyeti *azaltmaz*, **öngörülebilir** yapar
  ve sessiz borcu (kayıtsız iş) kapatır.
- *Çift kaynak riski (L-022):* içerik taşıyan bir CLAUDE.md protokolle
  ayrışır. Tek satır işaretçiden uzunu yazılmamalı.
- *Dağıtım yükü:* 10 repo × 1 dosya; hub-guard'la aynı bayatlama sorusu —
  `audit.sh` §10 kalıbı buraya da gerekir.
- *App etkisi:* yok.

**Kesişen not:** Ö1/Ö2/Ö4 protokol-yalnız değişiklikler bile olsa, prosedür
dosyası değişince diğer hub'lar farkı ancak sözleşme sürümü artarsa görür
(P-015'te ölçülen ders) — yani her biri küçük de olsa bir sürüm artışı ve
onun mekanik zinciri (constants, README'ler, testler) demek.

## 7. Karşı-olgu: hub olmasaydı ne kaybederdik?

### 7a. Deney — bağlam yeniden üretimi

Aynı soru ("son durum ne, yarım iş var mı?"), üç koşullu:

| koşum | token | sonuç |
|---|---|---|
| C2 — hub'lı takip | 48.7k | **Eksiksiz ve doğru:** bekleyen iki karar, pilot tarihi, açık plan, backlog — hepsi karar-hazır |
| C1 — hub silinmiş ama git tarihi duran kopya | 43.6k | **GEÇERSİZ:** ajan hub'ı `HEAD~1`'den okudu — silme yetmiyor, tarih de kayıttır |
| C1b — hub'sız + tarihsiz kopya | 42.0k | **"Kesin cevap verilemez":** kod temiz dedi, yarım iş listesi *çıkaramadı* |

Ana sonuç beklenenin tersi: **hub'sız durum sorgusu daha ucuz değil —
maliyet aynı (±%14), değer farkı radikal.** Hub'sız dünyada bu sorunun
cevabı ya yoktur ya kullanıcının hafızasındadır; her oturum ya durumu
yeniden kazır ya kullanıcıya sorar. C1'in başarısızlığı da kendi başına
bulgu: kayıt bir kez var olduktan sonra ajan onu bulur — değerin kaynağı
dosyanın adresi değil, kaydın **var olması**.
*(Yöntem notu: C1b'nin özetinde ana repoya bir bakış izi var — talimat
ihlali küçük ama kayda geçirildi; "cevap veremem" sonucu kendi dizininden
türedi ve geçerli.)*

### 7b. Sayılabilir envanter — hub'ın belgeli önledikleri

Bu repoların kayıtlarından, yorumsuz sayım:

- **17** gerçek hata düzeltme olayı (`fix(...)` commit'leri, yalnız takip).
- **53** ders kaydı (takip); **21'i doğrudan test dosyalarına bağlı** (25
  testte `L-0xx` atfı) — o hata sınıfları artık *mekanik olarak* tekrarlanamaz.
- **5** kullanıcı kararı taşıyan kapanmış bekleme görevi — hub'sız dünyada bu
  kararlar sohbet geçmişinde kalır ve kaybolur (madde 9'un varlık sebebi).
- **3** cevap 17 gün sıkışmışken kayıt sayesinde **kurtarıldı** (L-053) —
  hub'sız eşdeğerinde kalıcı kayıptı.
- **80** oturum sıkıştırma sonrası kayıttan yeniden kurulabildi
  (`reconstructed`) — hub'sız eşdeğerinde o bağlam yoktur.

### 7c. Hesap — açık varsayımlarla

Nokta tahmin değil, aralık; varsayımlar satır satır:

**Hub'ın maliyeti (ölçülü):** takip, ~6 hafta, 65 oturum × ~10.6k =
**~0.7M token** ek yük. On repo, tüm zamanlar: 3M–18M (bölüm 4).

**Hub'sız dünyanın ek maliyeti (tahmin):**
1. *Bağlam yeniden üretimi / kullanıcıya sorma:* oturum başına 0–40k token
   arası (C1b kazamadı; kazabilse görünür maliyet) **ya da** kullanıcıdan
   cevap turu. 318 oturumun yarısında gerekseydi: ~1.6M–6M token *veya*
   ~150 kullanıcı sorusu. Asıl bedel token değil **senin zamanın**: sıkışan
   üç cevabın ölçülmüş gecikmesi 17 gündü.
2. *Ders sınıflarının tekrarı:* teste bağlanmış 21 sınıftan yalnız **5–10**'u
   birer kez tekrar etseydi, tekrar başına düzeltme 100k–500k token (ölçülen
   taban: en küçük protokollü iş 49k; B-130 tipi teşhisler saatler ve süit
   20+ dakikaya çıkmıştı) → **0.5M–5M token** + her tekrar bir oturum kaybı.
3. *Kaybolan kararların yeniden tartışılması:* 5 karar × bir tur ≈ küçük
   token, büyük takvim maliyeti.

**Başabaş cümlesi:** takip'te hub'ın 6 haftalık bedeli ~0.7M token; bunu
geri ödemesi için **2–7 orta boy hata tekrarını ya da ~35 durum sorusunu**
önlemesi yeterli. Kayıtların belgelediği (21 test-bağlı sınıf, 3 kurtarılan
cevap, 80 yeniden kurulan oturum) bu eşiğin üzerinde. Sonuç aralıklı ama
yönü net: **hub, token cinsinden bile kendini ödüyor görünüyor; kesin
kanıt iki ikiz proje ister ve bu çalışma o iddiayı kurmuyor.** Zaman
cinsinden ise fark tartışmasız: kaybolan karar/cevap sınıfının ölçülmüş
maliyeti gün-hafta mertebesi.

---

# 8. Sonuç

Çalışmanın tamamı tek tabloda:

| soru | ölçülen cevap |
|---|---|
| Hub bir oturuma kaça mal oluyor? | Küçük işte **+10.6k token (+%28)**; zengin açılışta tabanın ~2.5 katına kadar. Kaynak dosya okumak değil, **tur sayısı** |
| Maliyet nereden büyüyor? | Tamamı okunan dosyalardan (`BACKLOG` ~17.5k) ve tur çoğaltan protokol adımlarından; çekirdek 25k–132k token/repo, tek yönlü ~140–565 KB/ay |
| Geçmiş toplam? | 318 oturum × 10–57k ≈ **3M–18M token** (geniş aralık, uyum oranına bağlı) |
| Bağlamı daraltıyor mu? | Evet: sabit yük sıkıştırmayı öne çeker; %25 `reconstructed` bu zincirin ucu. `hub-guard` (P-017) bu katmanın önlemi |
| Hub olmasaydı? | Aynı durum sorgusu **aynı paraya "cevap veremem"** döndürüyor (42.0k'ya karşı 48.7k). Kayıtların belgeledikleri: 21 hata sınıfı teste bağlanıp mekanik olarak kapatıldı, 3 kayıp cevap kurtarıldı, 80 oturum sıkıştırma sonrası yeniden kurulabildi, 5 karar kalıcılaştı |
| Kendini ödüyor mu? | 6 haftalık bedel ~0.7M token; başabaş için 2–7 hata tekrarı ya da ~35 durum sorusu önlemek yeterli — belgelenen bunun üstünde. **Token cinsinden bile ödüyor görünüyor; zaman cinsinden fark tartışmasız** (kaybolan cevabın ölçülmüş bedeli 17 gündü). Kesin kanıt ikiz proje ister; bu çalışma iddiayı o sınırla kurar |

**Karar bekleyen:** dört azaltma önerisi (§5) risk analiziyle (§6) birlikte
duruyor; kullanıcı kararıyla uygulanacak. Çalışmanın önerdiği sıra:
**Ö1 (tur birleştirme) → Ö4 (CLAUDE.md, bilinçli maliyet artışıyla) →
Ö2 (ancak sayım denetimiyle) → Ö3 (şimdilik hiç)**.

Tek cümlelik özet: **hub, oturum başına ~%28 token vergisi alan ama
karşılığında projenin hafızasını tek güvenilir kopya olarak tutan bir
sistemdir; vergiyi düşürmenin yolu dosyaları küçültmek değil, turları
birleştirmektir — ve verginin kalkması, ölçtüğümüz kadarıyla, tasarruf
değil kayıptır.**

> **Uygulama notu (2026-08-30, S-2026-08-30-oneri-uygulamasi):** kullanıcı
> kararıyla Ö1 + Ö4 + Ö2 uygulandı (sözleşme **1.28**, `tool/acilis.sh`,
> `CLAUDE.md`); **Ö3 uygulanmadı** — §6'daki gerekçeyle. §6'daki riskler
> uygulamada karşılandı: KOŞMADI kuralı, sayım denetimi, gövde-okuma kuralı,
> tek satır işaretçi.
