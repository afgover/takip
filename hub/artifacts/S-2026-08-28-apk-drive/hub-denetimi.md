---
id: A-2026-08-28-001
session: S-2026-08-28-apk-drive
type: analysis
title: "10 hub'ın mekanik denetimi — sözleşme uygulanıyor mu?"
created: 2026-08-28T13:40:00Z
---

# 10 hub'ın mekanik denetimi

Kapsam: `takip` + 9 hub reposu (`fastpdfreader_takip` boş, denetlenemedi).
Araç: [`tool/audit.sh`](../../../tool/audit.sh). Yöntem ve gerekçe:
[P-014](../../PLAN.md#P-014).

## Yöntem: neden yalnız mekanik kanıt

Kayıtları yazan taraf, denetlenen tarafın kendisi. "Yapıldı" cümlesi
yapıldığının değil, **o cümlenin yazıldığının** kanıtıdır; sessizce atlanan
bir adım ise hiç iz bırakmaz ve "yapıldı, söylenecek bir şey yoktu"la birebir
aynı görünür. Bu yüzden buradaki hiçbir bulgu düzyazıdan çıkarılmadı. Kanıt
yalnız git grafiği ve zaman damgaları, dosya yolları, frontmatter alanları,
klasör geçişleri ve ID dizileri.

**Denetçinin kendisi de denetlendi.** İlk koşum 120 bulgu verdi; tek tek
bakıldığında dördü denetçinin kendi hatasıydı ve düzeltildi: dosya
başlığındaki *format örneği* ID sayılıyordu; `git log --follow` görev
taşımasını kaçırıyordu (taşıma sırasında dosya adı da değişiyor); `author`
alanı sözleşmeye girmeden önceki oturumlar suçlanıyordu ([R-008](../../knowledge/rules.md#R-008));
ve tek bir "gecikme" sayısı iki ayrı mekanizmayı birbirine karıştırıyordu.
Doğrulanan 120 bulgunun **çoğu eledi kendini** — denetim yazarken de kural
aynı: ölçüm, ölçen aracın doğruluğundan bağımsız değildir ([L-035](../../knowledge/lessons.md#L-035)).

Bir bulgu daha rapora **girmedi**: "aynı bildirim iki hub'da" diye görünen
vaka, dosyalar açılınca iki farklı tarihte sorulmuş iki ayrı soru çıktı.

## Bulgular

### 1. ID çakışması gerçek ve tekrar ediyor
Aynı `T-` numarası birden çok görevde: `din_takip` 3 (T-025, T-026, T-027 —
T-026 üç ayrı işte: hub kurulumu, HathiTrust turu, muallak-cezm),
`Copilot_takip` 4 (T-022, T-024, T-049, T-054), `financer_takip` 1.
`Copilot_takip`'te ayrıca `L-032` iki kez tanımlanmış.

Sözleşme bu riski **biliyor** ve önlemini yazıyor (ID vermeden önce
`git pull --rebase`, numarayı hafızadan değil dosyadaki en büyükten türet).
Ölçüm, önlemin yetmediğini gösteriyor: çakışan kayıtlar günler ayrı
(T-026 → 08-03, 08-04, 08-21), yani eşzamanlılık değil **sayaç okumama**
sorunu. Kural doğru, ama hiçbir şey onu **zorlamıyor**.

### 2. `id: pending` kapanışa kadar yaşıyor
`Copilot_takip`'te **6 görev** `done/`a `id: pending` ile ulaşmış. Bu değeri
app bilerek yazıyor ([`lib/hub/task_repo.dart:73`](../../../lib/hub/task_repo.dart):
"ID'yi agent ilk işleyişte atar"), yani tasarım bir agent adımına
dayanıyor — ve o adım güvenilir biçimde koşmuyor. Sonucu: o görevlere
hiçbir kayıttan bağlantı verilemez ve denetimde hepsi tek bir "görev" gibi
görünür.

### 3. Yanlış hub'a düşmüş beş bildirim 17 gündür duruyor
`financer_takip/inbox/` içinde 2026-08-11 tarihli beş "…yapıldı / …cevaplandı"
bildirimi bekliyor. İçerikleri financer'a ait değil: biri
`hub/tasks/waiting/2026-08-03-proje-aktif-mi.md` görevine işaret ediyor ve o
görev **`goverco_takip`**'te (şu an `done/`).

Bu, [L-045](../../knowledge/lessons.md#L-045) / B-126'nın izlediği kusurun
kalıntısı — kusur 2026-08-12'de kapatıldı, ama **kapanmadan önce yanlış yere
düşmüş olanlar orada kaldı.** Zarar sınırlı (asıl görev başka yoldan kapanmış),
ama mekanizma açık: bir görevin *yanlış hub'da* olduğunu fark eden hiçbir
kontrol yok. Prosedür madde 2 "inbox'ı kullanıcıya raporla" diyor; 17 gün
boyunca ya raporlanmadı ya raporlandı ve düşürüldü.

### 4. Kapanış disiplini: en zayıf halka
- **Açık kalmış oturum:** `Copilot_takip` 3 (7, 7 ve 8 günlük),
  `datasources_takip` 2, `power_takip` 1. [L-042](../../knowledge/lessons.md#L-042)
  tam bunun için yazılmıştı ve tekrarlıyor.
- **`closed` ama `## Özet` boş:** `Copilot_takip` 7, `din_takip` 4. Doğrulandı:
  bölüm gerçekten sıfır satır.
- **`result` boş kapanan görev:** `Copilot_takip` 6, `din_takip` 5. Görev
  kapanmış ama "ne oldu" hiçbir yerde yazmıyor.

### 5. `din_takip`'te hiç `tarama` kaydı yok
92 oturum, sıfır tarama. Prosedür madde 4 her oturum açılışında son `tarama`
kaydına bakmayı ve 30 günden eskiyse yenilemeyi şart koşuyor; kayıt hiç
yoksa madde "ya da hiç yoksa" diyerek zaten taramayı istiyor. 92 oturumun
hiçbirinde koşmamış.

### 6. Saat anomalisi bu oturuma özgü değil
Kaydın tarihi kendi commit'inden **ileride** olan iki vaka: bu oturum
([L-052](../../knowledge/lessons.md#L-052)) ve `din_takip`'te
`2026-08-16-tehzib-kapsama` (kayıt 08-16, commit 08-15). İkincisi bu oturumdan
12 gün önce olmuş ve fark edilmemiş.

### 7. Kayıt anlık değil toplu yazılmış
`goverco_takip` 2, `taskr_takip` 1 oturumda bütün kayıt satırları tek
commit'te doğmuş — madde 4 "oturum sonuna biriktirme" diyor.
`reconstructed: true` taşıyanlar bu sayıma girmedi (dürüstçe işaretlenmiş).

### 8. Gecikme: iki ayrı sayı, iki ayrı hikâye
Tek bir "gecikme" rakamı yanıltıcı olduğu için ikiye ayrıldı.

| hub | kullanıcı → GitHub (ortanca/en uzun) | GitHub → ajanın ilk dokunuşu |
|---|---|---|
| takip | 1.4 / 6.0 sa | 0.0 / 9.1 sa |
| Copilot_takip | 1.5 / 20.5 sa | 9.1 sa |
| financer_takip | 6.6 / 7.4 sa | — |
| datasources_takip | 14.8 sa | — |
| goverco_takip | 15.1 sa | — |
| taskr_takip | 21.0 sa | 2.8 sa |

**Yorum, sayının taşıdığı kadar:** `takip` ve `Copilot_takip` dışındaki
ölçümler tek haneli örneklem üzerinden, ortanca oradan güvenilir değil.
Söylenebilecek olan: `takip`te ajan görevi **gördüğü anda** işliyor (ortanca
0.0 sa) ve asıl bekleme kullanıcı → GitHub tarafında. Bu beklemenin bir kısmı
tasarım gereği — çevrimdışı kuyruk toplu boşalıyor (2026-08-10'da dört görev
4 saniye içinde düştü). İş akışını bozan gecikme burada değil, **kimsenin
inbox'a bakmadığı** vakalarda (bulgu 3).

### 9. `money_takip` sıfır bulgu
Denetimden temiz çıkan tek hub. Yöntemin izlenebilir olduğunun kanıtı:
bulguların hiçbiri "sözleşme uygulanamaz" demiyor.

## Ölçülemeyenler

Bu denetim **iz bırakan** her şeyi ölçtü. Ölçemedikleri, tam da simülasyonun
konusu: ajan inbox'a baktı da boş mu buldu, yoksa hiç bakmadı mı; sözleşmenin
bir maddesini yanlış mı anladı; hiç yaşanmamış bir durumda (eşzamanlı iki ajan,
çevrimdışı çakışma) ne yapardı. Bunlar kayıtta yok, çünkü olmayan şey iz
bırakmaz.
