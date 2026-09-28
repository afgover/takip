---
id: A-2026-09-28-001
session: S-2026-09-28-agentmemory-kiyas
type: analysis
title: "agentmemory ile takip hub'ı: kıyas"
created: 2026-09-28T09:05:00Z
---

# agentmemory ile takip hub'ı: kıyas

## Özet

agentmemory bir **geri çağırma motoru**: her araç kullanımını otomatik
yakalayıp indeksliyor, oturum başında en ilgili ~2000 tokenı enjekte ediyor.
takip bir **iş defteri**: karar, görev ve dersi insanın okuduğu markdown'da,
git üzerinde, denetlenebilir tutuyor. Örtüşme yalnız "geçmişi hatırla"da.
Öneri: benimseme yok; üç fikir alınabilir, en değerlisi hub içi arama.

## Kapsam ve yöntem

- İncelenen: `rohitg00/agentmemory`, commit `c314c7b`, sürüm 0.9.29
  (2026-09-28). Salt okunur klon; kod çalıştırılmadı, benchmark yeniden
  koşulmadı.
- Okunan: README'nin mimari, iddia ve rakip bölümleri; benchmark raporları
  (LongMemEval, gerçek gömme değerlendirmesi); motor yapılandırması;
  gizlilik filtresi; test dizini.
- İddialar projenin kendi kaynak dosyalarına karşı sınandı. Bağımsız ölçüm
  yapılmadı: [DOGRULANMALI] sayıları yeniden üretmek ayrı bir iş.

## agentmemory nedir

TypeScript ile yazılmış, Apache-2.0 lisanslı, ~29 bin yıldızlı bir "kodlama
ajanı hafızası". Claude Code, Codex, Copilot CLI, Cursor ve MCP konuşan her
istemciye eklenti ya da sunucu olarak bağlanıyor.

### Mimari

Hat üç kancada çalışıyor:

1. **Araç kullanımından sonra:** gözlem 5 dakikalık pencerede SHA-256 ile
   tekilleştirilir, gizlilik filtresinden geçer, ham hâliyle saklanır,
   sıkıştırılır ve BM25 indeksine (sağlayıcı varsa vektöre de) girer.
2. **Oturum sonunda:** oturum özetlenir; açıksa bilgi grafiği çıkarılır.
3. **Oturum başında:** proje profili yüklenir; BM25, vektör ve graf
   sonuçları RRF ile birleştirilir ve 2000 token bütçeyle konuşmaya
   enjekte edilir.

Hafıza dört katmanlı: çalışma, epizodik, anlamsal, prosedürel. Kayıtlar
zamanla zayıflıyor, sık erişilen güçleniyor, çelişen kayıt yerine geçene
bağlanıyor. Kaydın kaynağı (kullanıcı, ajan, araç, içe aktarma) yazım
anında damgalanıyor.

Depo yerel: `~/.agentmemory` altında dosya tabanlı anahtar-değer deposu.
Onu ayrı bir motor süreci (`iii` engine, sürümü sabitlenmiş ikili dosya)
yönetiyor; 3111-3113 portlarını kullanıyor, izleyici arayüzü 3113'te.

Not: depodaki `DESIGN.md` mimari belgesi değil, sitenin görsel tasarım
sistemi.

### İddialar ve doğrulama

Hüküm sütunu: [TAMAM] iddia kaynağıyla tutarlı, [RISK] manşet kaynağından
geniş.

| İddia | Kaynakta bulunan | Hüküm |
|---|---|---|
| %95,2 R@5 (LongMemEval-S) | Geri getirme; QA doğruluğu değil | [TAMAM] |
| "#1 kalıcı hafıza" | Kendi tablosunda MemPalace %96,6 | [RISK] |
| %92 daha az token | Eski sentetik set, 240 gözlem | [RISK] |
| 1.674+ test | 182 dosya, ~1.880 test | [TAMAM] |
| Sıfır harici veritabanı | Doğru; ama motor süreci şart | [TAMAM] |

- **R@5:** "ilgili oturum ilk 5 sonuçta var mı" ölçüsü. Projenin kendi
  raporu bunun soru-cevap doğruluğu olmadığını açıkça yazıyor. Vektörün
  BM25'e katkısı +9 puan (%86,2'den %95,2'ye).
- **"#1":** Aynı rapor, yalnız vektör kullanan MemPalace'ı %96,6 ile önde
  gösteriyor. Manşet kendi tablosundan geniş.
- **%92:** v0.6.0'ın 240 gözlemli, 20 sorulu sentetik setinden. Oran "her
  şeyi yükle" ile "top-K bütçe" arasındaki fark, yani ölçülmüş bir kazançtan
  çok bütçe ayarının kendisi. Aynı sette R@5 %43,8.
- **Kendi derlemi** (15 oturumluk kodlama seti): grep R@5 0,967, hibrit
  1,000. Yazar setin küçük olduğunu kendisi not ediyor.

## Aynı problemi mi çözüyorlar

Kısmen. İki sistemin merkezindeki soru farklı:

- **agentmemory:** "Ajan bu projede daha önce ne gördü?" Hedef, bağlamın
  yeniden anlatılmaması. Kaydı makine yazıyor, makine okuyor.
- **takip:** "Ne kararlaştırıldı, kim neyi bekliyor, sözleşme uygulanıyor
  mu?" Hedef hesap verilebilirlik ve insanla ajan arasında iş devri. Kaydı
  ajan yazıyor, insan telefonda okuyor.

Örtüşme "geçmişi hatırlama" ekseninde: takip'in ders, kural ve oturum
kayıtları agentmemory'nin anlamsal ve epizodik katmanlarına karşılık
geliyor.

## Eksen eksen kıyas

| Eksen | agentmemory | takip |
|---|---|---|
| Yakalama | Otomatik, her araç kullanımı | Ajan yazar, prosedürle |
| Seçicilik | Hepsini al, sonra süz | Karar ve bulgu özeti |
| Depo | Yerel depo, motor süreci | Git üzerinde markdown |
| Sürümleme | İsteğe bağlı git anlık kopyası | Her kayıt bir commit |
| Geri çağırma | BM25, vektör, graf; top-K | Açılış özeti ve grep |
| Okuyucu | Ajan; yerel izleyici | İnsan (telefon) ve ajan |
| Doğrulama | Kaynak damgası, sürüm zinciri | Kaydın dışından denetim |
| Çoklu ajan | Ajan kimliği, kira, sinyal | Çoklu hub, ortak sözleşme |
| İşletme | Node, motor, üç port | Bash ve git, süreç yok |
| Gizlilik | Anahtar filtresi, yerel | Public repo, güvenlik kaydı |

### Yakalamanın bedeli iki yönlü

agentmemory hiçbir şeyi unutmuyor ama her şeyi saklıyor: kullanıcı
istemleri ve araç çıktıları filtreden geçip yerel depoya giriyor. Filtre
40 satırlık bir kalıp listesi; bilinen anahtar ve token biçimlerini
siliyor, e-posta, ad ya da telefon gibi kişisel veriyi tanımıyor.

takip'te yakalama ajanın disiplinine bağlı ve bu disiplin ölçülüp eksik
bulundu: [B-144](../../BACKLOG.md#B-144) ritim kuralında %59 ihlal
kaydediyor (ölçüm A-2026-09-12-001), [L-059](../../knowledge/lessons.md#L-059)
"anında ekle" kuralının art arda iki oturumda çiğnendiğini kaydetti.
Karşılığında kayıt seçici: ham çıktı değil karar ve bulgu yazılıyor. Bu,
public bir repoda tutulabilmesinin ön koşulu.

### Geri çağırma takip'in zayıf yanı

takip yazmakta güçlü, geri okumakta zayıf.
[B-145](../../BACKLOG.md#B-145)'e göre artifact'ların %50-67'si doğduğu
günden sonra hiçbir kayıtta anılmıyor. Ders dosyası 68 KB, BACKLOG 73 KB;
ajan bunları açılış özeti ve grep'le tarıyor, sıralı bir arama yok.
agentmemory'nin çözdüğü problem tam olarak bu boşluk.

### Doğruluğun kaynağı

agentmemory'de hafıza, sıkıştırılmış bir türev; yanlış, zayıflama ve
çelişki tespitiyle ayıklanıyor. takip'te kaydın kendisi kaynak ve denetim
onu kaydın dışından (git zaman damgası, dosya durumu) sınıyor.
[L-052](../../knowledge/lessons.md#L-052)'nin ilkesi: bir belgeyi kendi
iddiasıyla doğrulamak, doğrulamak değildir.

### İşletme yükü

agentmemory bir servis: Node süreci, sürümü sabitlenmiş harici bir motor
ikilisi, üç port, isteğe bağlı LLM anahtarları. Motor yapılandırmasındaki
bir yorum, günlük dosyasının bir kullanıcıda birkaç günde 137 GB'a
ulaştığı bir olayı anlatıyor (#519). takip'in
[K-001](../../EVOLUTION.md) kararı bunun tersi: backend işletmek yerine
omurga olarak GitHub.

## Alınabilecekler

1. **Hub içi arama** (B-145 ile birlikte). Servis kurmadan: oturum,
   knowledge, artifact ve BACKLOG üzerinde sıralı sonuç veren tek bir
   script. Açılışta değil, ajan bir konuya girerken koşulur ("bu konuda ne
   yapmıştık"). agentmemory'nin kendi ölçümüne göre BM25 tek başına %86,2
   isabet veriyor; boşluğun çoğu vektörsüz kapanabilir. [KARAR]
2. **Oturum ritmi için kanca** (B-144 d ile birlikte). agentmemory'nin
   hattı hatırlamaya değil kancaya dayanıyor.
   takip'te karşılığı: Claude Code'un Stop ya da PreCompact kancasında
   açık oturumun son yanıttan beri kayıt alıp almadığını soran bir kontrol.
   Kanca Claude Code'a özgü; öbür ajanlar için prosedür geçerli kalır.
   [KARAR]
3. **Yerine geçme alanı.** agentmemory eski sürümü aramadan çıkarıp sürüm
   zincirinde tutuyor. takip'te ders ve kurallar için "Yerine geçen" alanı,
   eskimiş bir dersin okunup uygulanmasını önler. Sözleşme değişikliği
   gerektirir; alan isteğe bağlı girer
   ([R-008](../../knowledge/rules.md#R-008)). [KARAR]

## Alınmaması gerekenler

- **Otomatik ham yakalama.** Repo public; istem ve araç çıktısını olduğu
  gibi yazmak, [SEC-017](../../SECURITY.md#SEC-017)'de ayıklanan kişisel
  veri sorununu büyütür. [RISK]
- **Servis ve motor bağımlılığı.** K-001'in gerekçesiyle çelişir; telefon
  uygulaması yine GitHub'dan okuyacağı için kazancı da yok. [RISK]
- **Sıkıştırılmış hafızayı kaynak saymak.** Denetim, kaydın kendisini
  kaynak alıyor; türev metin ancak yardımcı bir dizin olabilir.

## Yan yana kullanım

agentmemory takip'in yerine geçmez, yanına eklenebilir: yerelde, ajanın
geri çağırma katmanı olarak. Bedeli, konuşma içeriğinin hub dışında,
denetimsiz ikinci bir depoda birikmesi. Karar kullanıcının; bu belge
benimsemeyi önermiyor. [KARAR]
