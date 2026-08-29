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
