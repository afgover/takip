---
id: S-2026-08-15-gorev-agaci-tesviki
date: 2026-08-15
status: open
reconstructed: false
author: afgover
topics: [plan-agaci, sozlesme, tesvik, coklu-hub]
artifacts: []
tasks_touched: []
---

# Oturum: Görev ağacı neden boş — agent'ı teşvik etme

## Özet
(oturum açık)

## Kayıt

### Kullanıcı
> görev ağacını hiç bi repo doldurmamış, tam olarak anlaşılmıyor sanıyorum

### Agent — ölçüm: `takip`'te ağaç dolu, sorun başka yerde

Gerçek `PLAN.md` ayrıştırıcıdan geçirildi: **3 plan, 27 adım**, hepsi
ayrıştırılıyor. Yani `takip`'te veri var. Ölçüm iki başka şey gösterdi:

1. **Üç planın da durumu `tamamlandi`.** Ağacın işi yarım kalanı görünür
   kılmak; şu an görünür yarım iş yok, ekran üç kapalı planı listeliyor.
2. **Adım satırları paragrafa dönüşmüş.** Sözleşme "ağacın değeri
   seyrekliğinde" diyor ama bunu **plan sayısı** için söylüyor; adım satırının
   uzunluğuna dair bir sınır yok. P-003'ün adımlarına gerekçe sıkıştırıldığı
   için telefonda ağaç değil duvar görünüyor.

**Ayrıca gerçek bir ayrıştırıcı hatası bulundu** → [B-133](../../BACKLOG.md#B-133):
adım satırı alt satıra sarktığında devam satırı `title`'a ekleniyor ve `·`
ayracı bir daha aranmıyor. Dokuz adımda tamamlanma tarihi ya kayıp ya
başlığın içine gömülü.

### Kullanıcı
> düzeltiyorum, sadece copilot ağacı doldurmuş, diğerleri plan süreçleri
> içermesine rağmen ağaçları boş, agentı geçmiş planları da ekleyecek
> şekilde teşvik edebiliriz

### Agent — doktrin gerilimi işaretlendi

Öneri, hub'da **yazılı olan** bir doktrinle çelişiyor; karar verilmeden önce
gerilim kullanıcıya gösterildi. Ayrıntı aşağıda, kullanıcı kararı bekleniyor.

Kullanıcı kararı: **türetme serbest ama işaretli**, ve `takip`'in geçmişi de
doldurulacak. Plan [P-004](../../PLAN.md) *uygulamadan önce* yazıldı.

### Agent — sözleşme 1.26

Boşluğun teşhisi şu oldu: 1.25 adımları yalnız "uygulanmadan önce" yazdırıyor
ve geç fark eden agent'a **hiçbir yol bırakmıyordu** — uydur (yasak) ya da
atla. Hepsi atladı. Kural, tam da doldurmak istediği ağacı boşaltıyordu.

Çözüm **uydurma** ile **türetme**yi ayırmak:

| Ne yapıldı | Ağaca girer mi |
|---|---|
| Adımlar bir kayıttan **türetildi** | ✅ `Türetilmiş: true` |
| Adımlar **hatırlanmıyor**, akla yatkın diye yazıldı | ✗ yazılmaz |

Kalıp yeni değil: oturumlarda `reconstructed: true` (v1.6) ve sonradan yazılan
özetlerin türetilme notu aynı ayrımı zaten taşıyordu.

**Aynı ölçümden çıkan iki ek kural:**
- **Adım satırı kısadır** — gerekçe bağlantı verilen kayda gider. Ölçüm
  somuttu: P-003'ün adımları telefonda ağaç değil duvar görünüyordu.
- **Geriye dönük plan kapalıların arasına tarih sırasıyla girer**, üste değil.
  Yoksa altı ay önceki bir iş, bugün yarım kalanın üstünü örterdi — "yeni plan
  en üste" kuralının önlemek istediği şeyin ta kendisi.

[R-008](../../knowledge/rules.md#R-008) korundu: yeni alan opsiyonel, yokluğu
"önceden yazılmış" demek. Eski hub'lar dokunulmadan geçerli.

Uygulama tarafı: `Plan.reconstructed` (alan adı iki dilde de okunuyor) ve
kartta ayrı etiket. Sürüm dört yerde eşitlendi (`SYSTEM.md`, `SYSTEM.en.md`,
`constants.dart`, iki README) — ikisi zaten testle bağlıydı.

### Agent — `takip`'in geçmişi dolduruldu

Dört plan oturum kayıtlarından **türetildi**; hepsi `Türetilmiş: true`:

- [P-005](../../PLAN.md) — görev kapsamı (2026-08-15). Kuralı doğuran vakanın
  kendisi: o oturumda ağaç atlanmıştı.
- [P-006](../../PLAN.md) — çoklu hub'da bildirimin yanlış repoya düşmesi (08-12)
- [P-007](../../PLAN.md) — i18n, 337 metin ve sözleşmenin İngilizcesi (08-08)
- [P-008](../../PLAN.md) — güvenlik katmanı, ilk tarama (08-04)

53 oturumun hepsi doldurulmadı: §14 ağaca yalnız üç ya da daha fazla adımlı
işi alıyor ve "ağacın değeri seyrekliğinde" diyor. Seçilenler, adımları
kayıttan gerçekten okunabilen çok adımlı işler.

**Ölçüm:** `flutter analyze` temiz, **581 test** (575 + 6).

### Kullanıcı
> push et, b133ü de yap

### Agent — B-133: sarkan satır düzeltildi

Plan [P-009](../../PLAN.md) önce yazıldı (dört adım, §14 eşiğinin üstünde).

**Hata:** devam satırı koşulsuz `title`'a ekleniyor ve `·` ayracı bir daha
aranmıyordu. İki ayrı hâlde tarih kayboluyordu — ayraç satır sonunda kalıp
tarih alt satıra düştüğünde, ve ayraç ilk kez devam satırında geçtiğinde.

**Düzeltme** (`_extend`): devam satırının nereye gideceği, ayracın o ana kadar
görülüp görülmediğine bakıyor. Not zaten açıksa satır **nota** ekleniyor;
değilse başlığa ekleniyor ama ayraç **yeniden aranıyor**. Buna bağlı olarak
`_parseStep` artık boş notu `null`'a çevirmiyor: "ayraç vardı ama arkası boştu"
ile "ayraç hiç yoktu" ayrı durumlar ve ayrımı devam satırı kullanıyor.
Normalleştirme ayrıştırma bitince (`_close`) yapılıyor, yani dışarıya "not yok"
tek biçimde görünüyor.

**Ölçüm ilk sayımı düzeltti.** Backlog'a "dokuz adım" yazmıştım; o sayı gözle
çıkarılmıştı. Ayrıştırıcı iki sürümde koşturulunca gerçek sayı **19** çıktı:
tamamlanmış 60 adımın 19'unda not yoktu, düzeltmeden sonra 0. Ders, bugünkü
L-044'ün tekrarı — kaba bir ölçüt (gözle bakmak) ölçtüğünü sandığı şeyi
ölçmüyor. Sayı backlog'da düzeltildi.

Regresyon testleri hatanın kendisini kuruyor; ayrıca gerçek `PLAN.md` üzerinde
tek bir adımın başlığında `✅` kalmadığı sınanıyor — devam satırı yanlış yere
eklenirse bu test düşer.

**İkinci soru (adım uzunluğu)** sözleşme 1.26 §14/7 ile kurala bağlandı.
Mevcut uzun adımlar **kısaltılmadı**: kayıt silinmez (R-004) ve gerekçeleri
zaten bağlantı verilen oturum kayıtlarında duruyor. Kural bundan sonrası için.

**Ölçüm:** `flutter analyze` temiz, **586 test** (581 + 5).
