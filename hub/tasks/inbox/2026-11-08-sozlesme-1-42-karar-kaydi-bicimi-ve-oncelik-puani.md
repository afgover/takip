---
id: pending
title: "Sözleşme 1.42: karar kaydı biçimi ve öncelik puanı"
created_by: user
created: "2026-11-08T22:14:38Z"
updated: "2026-11-08T22:14:38Z"
priority: high
category: gelistirme
tags: [sozlesme, karar]
session: none
result: none
author: afgover
via: asistan
---

# Sözleşme 1.42: karar kaydı biçimi ve öncelik puanı

## İstek
Bekleyen kararlar (`tasks/waiting/`, `category: karar`) bugün serbest
biçimde yazılıyor; önemi, son tarihi, neyi durdurduğu ve geri alınıp
alınamayacağı kayıtta yok, bu yüzden birden çok hub'daki kararları tek bir
sırayla göstermek mümkün değil. Öneri, sözleşme 1.42'ye geriye uyumlu bir
karar kaydı biçimi (zorunlu `recommended`, `importance`, `blocks`,
`reversible`, `asked_by` alanları, seçenek kartlı gövde, biçim denetimi),
önem ve son tarihten türeyen bir öncelik puanı, ek bilgi isteme akışı ve
eski kararlar için bir göç maddesi (G-002) eklemek. Önerinin tamamı aşağıda.

## Öneri metni

Bu metin takip'in kendi oturumunda sözleşmeye işlenmek üzere önerilir.
Tüm alanlar geriye uyumludur: `options` düz liste kalır, eski uygulama yeni
alanları görmezden gelip çalışır.

### 1. Karar kaydı

Karar, `tasks/waiting/` altında `category: karar` olan bir görevdir.

| Alan | Zorunlu | Anlamı |
|---|---|---|
| `category: karar` | evet | Dosyayı karar destesine sokar |
| `options` | evet | Seçenek adları, en çok 4 (v1.12 alanı) |
| `recommended` | evet | Ajanın önerdiği seçeneğin adı (listedeki metin) |
| `importance` | evet | `kritik` \| `yuksek` \| `orta` \| `dusuk` |
| `due` | hayır | Dışarıdan konmuş kesin tarih (v1.41 alanı) |
| `blocks` | evet | Bu karar gelmeden duran işler: görev kimlikleri, `proje` ya da `yok` |
| `reversible` | evet | `evet` \| `zor` \| `hayir` |
| `for` | evet | Kararı verecek kişi (v1.15 alanı) |
| `involves` | hayır | Etkilenen ya da görüşü alınacak kişiler ve ajanlar |
| `asked_by` | evet | Soruyu açan ajan (`ajan:<ad>`) ya da kişi |
| `effort` | hayır | Cevap için tahmini süre: `30sn` \| `5dk` \| `masa` |

`priority` alanı karar kayıtlarında `importance`'tan türetilir
(kritik→urgent, yuksek→high, orta→normal, dusuk→low); eski okuyucular için
yazılmaya devam eder.

#### Gövde

```markdown
# <başlık>

## Soru
<tek cümle, soru işaretiyle>

## Bağlam
<ne oldu, neden şimdi soruluyor; en çok beş satır>

## Seçenekler

### <options'taki ad, birebir>
- **Ne olur:** ...
- **Maliyet:** ... (emek, para, süre)
- **Risk:** ...
- **Geri alınır mı:** ...
- **Kimi etkiler:** ...

(her seçenek için bir kart)

## Öneri
<recommended> : <tek paragraf gerekçe>

## Kaynaklar
- <belge, PR, log bağlantıları> (isteğe bağlı)

## Ek bilgi
### <YYYY-MM-DD HH:MM> — <istenen>
<ajanın cevabı> (yalnız ek bilgi istendiğinde eklenir)
```

#### Önem tanımları

- **kritik:** güvenlik, para kaybı, canlı sistem ya da yasal süre.
- **yuksek:** bir projenin ana yolu ya da dış taraf (mağaza, müşteri) bekliyor.
- **orta:** bir iş duruyor ama proje yürüyor.
- **dusuk:** tercih, iyileştirme; beklese de olur.

#### Biçim denetimi

Zorunlu alanı, `Soru`/`Bağlam`/`Öneri` bölümü ya da her seçenek için kartı
eksik olan karar commit'lenmez (ajan kendi kontrol listesinde çalıştırır;
takip'in biçim denetimi aracı bu kuralı içerir).

#### Ajanın kendi karar vermesi

`reversible: evet` ve `importance: dusuk` olan konularda ajan soru açmaz;
kendisi karar verir ve kararı `notes/`a (`tags: [ajan-karari]`) yazar. Brifing
bunları "verdiğim kararlar" olarak gösterir; kullanıcı itiraz ederse ajan geri
alır.

### 2. Öncelik puanı ve son tarih

Etkin son tarih = `due` ile `created + süre(importance)`'tan erken olanı.

| Önem | Süre | W |
|---|---|---|
| kritik | 2 gün | 8 |
| yuksek | 7 gün | 4 |
| orta | 14 gün | 2 |
| dusuk | 30 gün | 1 |

```
P = W × U × B × Y
U = 1 + 3 × clamp(1 − kalan_gün / süre, 0, 1.5)
B = 1 (blocks: yok) | 1.5 (görev kimlikleri) | 2 (proje)
Y = 1 + min(yaş_gün / 60, 0.5)
```

Günlük deste: puana göre ilk 5 karar; `kritik` olanlar sınırdan bağımsız
destededir. Yeni alanları taşımayan eski kararlar `importance: orta`,
`blocks: yok` sayılır ve saatleri geçiş gününden başlar.

### 3. Ek bilgi isteme

Uygulama (ya da asistan katmanı, §17) inbox'a `tags: [waiting-info]` ile yazar:

```markdown
## İstek
`tasks/waiting/<dosya>.md` (T-00X) kararı için ek bilgi istendi.

- **Repo:** `afgover/<proje>_takip`
- **İstenen:** <kullanıcının sorusu>
```

Ajan karar dosyasına tarihli bir `## Ek bilgi` girdisi ekler, gerekirse
seçenek kartlarını günceller; karar `waiting/`te kalır. Bildirim görevi
`done/`a taşınır.

### 4. Göç rehberi (G-002 önerisi)

Proje ajanı, sözleşmeyi 1.42'ye yükselttiği ilk oturumda `tasks/waiting/`
içindeki kararları gözden geçirir: geçerliliğini yitirenleri kapatır,
aynı konuyu soranları birleştirir, kalanları yeni biçime çevirir. Asistan
katmanı bu işi başka hub'larda yapmaz (§17).
