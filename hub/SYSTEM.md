# SYSTEM.md — Taskr Hub Format Sözleşmesi

Bu doküman, hub reposundaki her dosyanın **nerede duracağını, nasıl adlanacağını
ve hangi şemaya uyacağını** tanımlar. Agent ve kullanıcı uygulaması bu sözleşmenin
dışına çıkmaz. Sözleşme değişiklikleri `EVOLUTION.md`'ye kaydedilir ve bu dosyanın
başındaki sürüm numarası artırılır.

**Sözleşme sürümü:** 1.21
**Ana kopya (master):** `afgover/takip` → `hub/SYSTEM.md` (tr, **kanonik**) ·
`hub/SYSTEM.en.md` (en)
(bkz. §10 — her hub kendi kopyasını, kendi dilindeki varyanttan günceller)
**Zaman biçimi:** her yerde ISO 8601, UTC (`2026-07-30T14:05:00Z`)
**Hub dili:** tr
**Dil kuralı:** alan adları (frontmatter anahtarları) her zaman İngilizce; her
şeyin dili **hub dilidir**
**Dosya adları:** küçük harf, Türkçe karakter yok, boşluk yerine tire (`gorev-adi`)

> **Bir hub'ın tek dili vardır (v1.19).** Dil, hub kurulurken seçilir ve
> `**Hub dili:**` alanında yazılır. Üç şey birden onu izler:
>
> 1. **Sözleşme ve protokol** — agent referansı buradan aldığı için, hub dili
>    ne ise `SYSTEM.md` ve `AGENT_PROTOCOL.md` o dildedir.
> 2. **Uygulama arayüzü** — aktif hub'ın diline göre çizilir.
> 3. **Sonradan üretilen kayıtlar** — gövde başlıkları dâhil (aşağıdaki tablo).
>
> Dil sonradan değiştirilebilir ama **geriye dönük bir şey yapmaz**: eski
> kayıtlar yazıldıkları dilde kalır. Bu kabul edilmiş bir durumdur, hata değil
> — dil değiştirmek kurulum anına ait bir karardır.
>
> ~~v1.18: arayüz dili ile kayıt dili birbirinden bağımsızdır; gövde başlıkları
> Türkçe sabittir.~~ Geçersiz: tutarlılığı şemayı Türkçe'ye sabitleyerek
> sağlamak, İngilizce çalışan birine Türkçe başlıklı kayıtlar yazdırırdı ve
> dil seçeneğinin varlık sebebiyle (yöntemin başka dilleri konuşanlara da
> açılması) çelişirdi. Tutarlılık artık **hub başına tek dil** ile sağlanıyor.
>
> **Gövde başlıkları dile göre:**
>
> | Alan | tr | en |
> |---|---|---|
> | İstek | `## İstek` | `## Request` |
> | Notlar | `## Notlar` | `## Notes` |
> | Nerede | `## Nerede` | `## Where` |
> | Alıntı | `## Alıntı` | `## Quote` |
>
> **Ayrıştırıcı hepsini tanır.** Hub'ın ilan ettiği dille sınırlanmaz: dil
> alanı eklenmeden önce yazılmış kayıtlar, elle düzenlenmiş dosyalar ve dil
> değiştirilmiş hub'lar var. Bir kümeyi kabul etmenin maliyeti yok, dar
> kabulün maliyeti okunamayan kayıt.
>
> `**Hub dili:**` yazılmamışsa **`tr`** varsayılır — bu, alan eklenmeden
> önceki bütün hub'ların gerçek durumu.
>
> **Gövde içi alan adları da aynı kurala tabi:** `Seçim`/`Choice`,
> `Açıklama`/`Explanation`, `Dosya`/`File`, `Bölüm`/`Section`,
> `Tür`/`Type`, `Durum`/`Status`.


> **Hub kökü (v1.3, K-020):** Bu sözleşmedeki tüm yollar hub köküne görelidir
> ve hub kökü **her zaman** reponun içindeki **`hub/`** klasörüdür — istisnasız.
>
> - Her proje için ayrı bir takip reposu açılır: **`<proje>_takip`**
>   (örn. `financer_takip`), hub içeriği o reponun `hub/` klasörüne kurulur.
> - `takip` projesi kendi hub'ını kendi reposunda barındırır (K-012); yapı
>   aynıdır, `takip/hub/`.
>
> ~~v1.2: diğer projeler için hub, `<proje>_takip` reposunun köküdür.~~
> Geçersiz: uygulama hub kökünü `hub/` diye sabit tutuyor ve bağlantı başına
> ayarlanamıyor; kök yerleşimli bir repo onboarding'de reddedilirdi. Tek kural
> her repoda geçerli olsun diye sözleşme uygulamaya uyduruldu (K-020).

---

## 1. Kök dosyalar

| Dosya | Amaç | Kim yazar |
|---|---|---|
| `SYSTEM.md` | Bu sözleşme | agent (kullanıcı onayıyla) |
| `AGENT_PROTOCOL.md` | Agent'ın kayıt prosedürü | agent (kullanıcı onayıyla) |
| `BACKLOG.md` | Yapılacak işler listesi — tek doğru kaynak | agent |
| `EVOLUTION.md` | Projenin aşama aşama evrimi | agent |
| `SECURITY.md` | Güvenlik logu — taramalar, önlemler, açıklar (§12) | agent |

## 2. `sessions/` — oturum kayıtları

Her çalışma oturumu için **bir klasör**:

```
sessions/<YYYY-MM-DD>-<slug>/
  session.md          # oturumun tam kaydı
```

`session.md` şeması:

```markdown
---
id: S-2026-07-30-altyapi-tasarimi
date: 2026-07-30
status: open            # open | closed
reconstructed: false    # (v1.6) opsiyonel; true = sıkıştırma sonrası geriye
                        # dönük yazıldı
author: afgover         # (v1.15) oturumu kimin yürüttüğü
topics: [mimari, github-api]
artifacts:              # bu oturumda üretilen dosyaların yolları
  - artifacts/S-2026-07-30-altyapi-tasarimi/rapor.md
tasks_touched: [T-001, T-002]   # bu oturumda ele alınan görev ID'leri
---

# Oturum: <başlık>

## Özet
(Oturum kapanırken agent tarafından yazılır: ne konuşuldu, ne kararlaştırıldı,
ne üretildi — 5-10 satır.)

## Kayıt

### [14:05] Kullanıcı
> (kullanıcının mesajı — kısaltılmadan, anlamı bozulmadan)

### [14:07] Agent
(agentın cevabının özü: verilen kararlar, bulgular, yapılan işler. Uzun kod/rapor
çıktıları buraya değil `artifacts/`e gider, buradan link verilir.)
```

Kurallar:
- Oturum **açılır açılmaz** dosya oluşturulur (`status: open`).
- Her kullanıcı mesajı ve her agent cevabı, **cevap verildiği anda** dosyaya eklenir;
  oturum sonuna bırakılmaz.
- Oturum kapanırken `status: closed` yapılır ve `## Özet` doldurulur.
- Bir oturum dosyası kapandıktan sonra değiştirilmez (düzeltme gerekirse yeni
  oturumdan link verilir).
- **(v1.6) Yeniden kurulmuş oturum.** Bir oturum bağlam sıkıştırması yüzünden
  gerçek zamanlı kaydedilemediyse geriye dönük yazılabilir; ama o zaman
  frontmatter'a `reconstructed: true` konur. Bu, "kayıt dışı iş yok" kuralının
  istisnası **değil** — kaydın nasıl üretildiğini dürüstçe işaretlemek içindir:
  geriye dönük yazılmış bir kayıt, gerçek zamanlı kaydın taşıdığı zaman damgası
  doğruluğunu iddia edemez. Zaman damgaları atlanabilir ya da yaklaşık verilir.
  *(Kural `financer_takip`'te doğdu, ana kopyaya oradan alındı — K-025.)*
- **(v1.20) Aynı anda yalnız bir oturum açık olabilir**, o da en yeni tarihli
  olan. Yeni bir oturum açarken daha eski bir oturum `open` duruyorsa önce o
  kapatılır: özeti kendi kaydından türetilir ve `## Özet` içinde **türetildiği
  belirtilir** (yeni bilgi eklenmez).
  Kural, bir oturumun dokuz gün açık kalmasından sonra kondu (L-042). Özeti
  olmayan oturum arayan için yok demektir — sonraki agent oturumları tarar,
  özete bakar, "burada bir şey yok" der. O oturum projenin kurucu kararlarını
  taşıyordu.

## 3. `artifacts/` — üretilen dosyalar

Oturumlarda üretilen her rapor, plan, analiz, info dosyası buraya kaydedilir:

```
artifacts/<session-id>/<dosya-adi>.md
```

Her artifact dosyasının başında frontmatter bulunur:

```markdown
---
id: A-2026-07-30-001
session: S-2026-07-30-altyapi-tasarimi
type: report            # report | plan | info | analysis | design
title: "GitHub izin modeli araştırması"
created: 2026-07-30T14:20:00Z
---
```

Oturumdan bağımsız, kalıcı referans dokümanlar (mimari kararlar gibi)
`artifacts/reference/` altına konur; frontmatter'da `session: none` yazılır.

## 4. `tasks/` — görevler

**Durum = klasör.** Görev dosyası yaşam döngüsü boyunca klasör değiştirir:

```
tasks/inbox/     # yeni: kullanıcı (app) veya agent ekledi, henüz ele alınmadı
tasks/active/    # agent ele aldı, üzerinde çalışılıyor
tasks/waiting/   # agent kullanıcıyı bekliyor — top kullanıcıda (v1.4)
tasks/done/      # tamamlandı (arşiv — silinmez)
```

> **`waiting/` neden var (v1.4, K-022):** Sözleşme 1.3'e kadar sistem yalnız
> **kullanıcı → agent** yönünü modelliyordu; `inbox` ve `active`'in ikisi de
> "agent ele alacak" demekti. Agent'ın kullanıcıdan beklediği işler (token
> üret, cihazı bağla, karar ver, onayla) yalnızca `BACKLOG.md`'de `(user)`
> etiketiyle duruyordu ve uygulamada hiçbir yerde görünmüyordu — kullanıcı
> ancak sohbette söylenirse haberdar oluyordu. `waiting/`, bu yönü de
> klasörle temsil eder ve "durum = klasör" ilkesini korur.
>
> Ölçek ayrımı: `waiting/` **somut ve kısa vadeli** işler içindir ("token
> üret"). Yol haritası ölçeğindeki kullanıcı işleri (`(user)` maddeleri,
> örn. "bir hafta gerçek kullanım") `BACKLOG.md`'de kalır.

Dosya adı: `<YYYY-MM-DD>-<slug>.md` (örn. `2026-07-30-market-listesi.md`).

Görev şeması:

```markdown
---
id: T-001                    # benzersiz, artan; agent atar. App geçici olarak
                             # id: pending yazar, agent ilk işleyişte gerçek ID verir.
title: "Market listesi hazırla"
created_by: user             # user | agent
created: 2026-07-30T14:05:00Z
updated: 2026-07-30T16:00:00Z
priority: normal             # low | normal | high | urgent
category: gorev              # varsayılanlar: gorev, arastirma, gelistirme, hata,
                             # fikir, yorum, duzeltme, tartisma (son üçü v1.5) —
                             # serbest değer de geçerli (kullanıcı tanımlı).
                             # App, seçim listesini varsayılanlar + mevcut
                             # görevlerde geçen kategorilerden türetir. (v1.1)
tags: []
session: none                # ele alındığı oturumun ID'si (agent doldurur)
result: none                 # tamamlanınca: sonucun 1 satır özeti veya artifact linki
author: afgover              # (v1.15) kaydı oluşturan GitHub hesabı
for: mehmet                  # (v1.15) yalnız waiting/: kimden bekleniyor
assignee: afgover            # (v1.15) active/'e alan kişi

# --- Bağlam alanları (v1.5) — yalnızca bir belgeden seçilerek üretilmiş
# kayıtlarda bulunur; normal görevlerde hiç yazılmaz. Üçü birlikte anlamlıdır.
source: hub/sessions/2026-08-01-x/session.md   # kaydın bağlı olduğu belge
quote: "işaretlenen metnin tamamı"             # o belgeden birebir alıntı
mark: highlight              # highlight (sarı) | underline (kırmızı) |
                             # comment (yeşil, v1.8) | bookmark (mavi, v1.12)
                             # — belgede nasıl çizilecek
---

# <başlık>

## İstek
(Kullanıcının/agentın görev tanımı.)

## Notlar
(Agent'ın çalışma notları — durum güncellemeleri tarihli satırlar halinde eklenir.)
```

Kurallar:
- **App yalnızca `tasks/inbox/`'a yazar**; başka klasöre dokunmaz. Bu, v1.4'te
  de değişmedi: kullanıcı bekleyen bir işi bitirdiğinde app o dosyayı
  taşımaz, **inbox'a bir bildirim görevi** yazar (aşağıya bakın).
- **(v1.7) App, `inbox/`'ta duran ve kendi yazdığı bir kaydı silebilir.**
  Yalnız oradaki: agent kaydı `active/`e almışsa app ona dokunamaz — o iş
  artık ele alınmıştır ve sessizce yok etmek agent'ın çalışmasını çöpe atardı.
  Bu, R-001'in yumuşatılması değil sınırının aynı kalmasıdır: app'in
  dokunduğu tek klasör hâlâ `inbox/`. Gerekçe: kullanıcı yanlışlıkla koyduğu
  bir işareti geri alabilmeli; bunun için agent'a görev açmak, tek dokunuşluk
  bir hatayı iki tarafın işine çevirirdi (K-026).
- Klasörler arası taşımayı yalnızca agent yapar
  (`inbox → active → waiting → active → done`; sıra bunlarla sınırlı değil,
  ama her geçişi agent yapar).
- Taşıma = eski yolu silme + yeni yola yazma (Contents API'de iki çağrı);
  commit mesajı: `task(T-001): active → done`.
- `done/` içindeki dosyalar silinmez; yılda bir `done/arsiv-<yil>/` altına
  toplanabilir.

### Kimlik (v1.15)

Tek kullanıcılı hub'da "kim" sorusunun cevabı belliydi ve şemada yeri yoktu.
Birkaç kişi aynı hub'ı kullandığında bu boşluk karmaşanın asıl kaynağı olur:
`created_by` bir **rol**dur (`user`/`agent`), kimlik değil.

| Alan | Nerede | Anlamı |
|---|---|---|
| `author` | görev, not, oturum | Kaydı oluşturan GitHub hesabı |
| `for` | yalnız `waiting/` | İşin **kimden** beklendiği |
| `assignee` | `active/` | İşi üstlenen kişi |

Kurallar:

- **Üçü de isteğe bağlıdır ve yokluğu hata değildir.** Tek kullanıcılı dönemde
  yazılmış her kayıtta yoklar; geriye dönük doldurulmazlar. Yokluk
  "bilinmiyor" demektir.
- `for` yazılmamış bir `waiting/` görevi **herkesi** bekler. Aksi hâlde eski
  görevler kimsenin görmediği bir kuyruğa düşerdi.
- `assignee`, `inbox/` → `active/` taşımasıyla **aynı anda** yazılır. Taşıma
  zaten atomik olduğu için ayrı bir kilit gerekmez: aynı dosyayı iki kişinin
  taşıması git'te çakışmadır.
- Uygulama `author`ı token'ın sahibinden okur (`/user` → `login`) ve **hangi
  repoya yazıyorsa o bağlantının** kimliğini kullanır. Okunamazsa alan hiç
  yazılmaz — çalışan bir bağlantı kimlik yüzünden reddedilmez.
- Aynı token'ı iki kişi paylaşırsa kimlikler tek kişiye çöker. Bu, herkesin
  kendi token'ını üretmesi için ayrı bir gerekçedir (R-005).

### ID'ler ve eşzamanlılık (v1.15)

Bütün ID'ler (`T-`, `B-`, `L-`, `SK-`, `R-`, `SEC-`, `K-`, `A-`) tekil
sayaçtır. İki agent aynı anda çalışırsa ikisi de aynı numarayı seçer ve
dosyalar farklı olduğu için **git bunu çakışma saymaz**: hiçbir şey hata
vermez, iki kayıt aynı ID'yi taşır.

Sözleşme bu çakışmayı imkânsız kılmaz — ID biçimini değiştirmek (kullanıcı
öneki, rastgele ID) bugüne kadarki yüzlerce atfı ikinci sınıfa düşürürdü.
Bunun yerine **görünür** kılar:

- Agent ID atamadan hemen önce `git pull --rebase` yapar, attıktan hemen sonra
  push eder (`AGENT_PROTOCOL.md`).
- Hub'ı okuyan bir test tekrarlı ID tanımını yakalar; düzeltmesi birini yeniden
  numaralandırmaktır.

### `waiting/` kullanımı

**Agent, bir görevi ancak kullanıcıdan somut bir şey beklerken `waiting/`e
taşır** ve `## Notlar`a ne beklediğini tek satırda yazar. Beklenen şey
belirsizse görev `active/`te kalır — "belki kullanıcı bir şey yapar" durumu
`waiting/` değildir.

#### Seçenekli bekleme (v1.12)

Bekleyen her iş "yap ve haber ver" değildir; çoğu zaman agent'ın beklediği şey
bir **karar**dır ("hangisini yapalım?"). Sözleşme 1.11'e kadar kullanıcının
tek cevabı "Yaptım" düğmesiydi ve bir soruya verilecek karşılığı yoktu —
kullanıcı ya sohbete dönmek zorunda kalıyordu ya da cevap hiç kaydedilmiyordu.

Agent, `waiting/` görevine iki alan ekleyerek seçenek sunar:

```yaml
options: ["Fine-grained token üreteceğim", "Klasikle devam", "Sonra bakalım"]
multi: false                 # true → birden çok seçenek işaretlenebilir
```

Kurallar:

- `options` **agent tarafından** yazılır; app bu alanı değiştirmez.
- `options` yoksa davranış 1.11'deki gibidir: tek bir "Yaptım" düğmesi.
  Eski görevler olduğu gibi çalışmaya devam eder.
- `options` varsa "Yaptım" **gösterilmez**: agent bir soru sormuştur, cevabı
  "yaptım" değil seçimdir.
- Kullanıcı seçimin yanına **her zaman** isteğe bağlı bir açıklama
  yazabilir ("Hayır, çünkü…"). Seçenek listesi cevabı makinece okunur
  kılar, serbest metin ise listede olmayan durumu söyleyebilmek içindir;
  ikisi birbirinin yerine geçmez.
- Cevap verildiğinde soru **kapanır**: app aynı görev için ikinci bir cevap
  göndermez. Konuşmanın devamı gerekiyorsa agent yeni bir `waiting/` görevi
  açar — bir görev = bir soru.

Kullanıcı işi bitirdiğinde (ya da soruyu cevapladığında) app `tasks/inbox/`'a
şu şemada bir bildirim görevi yazar:

```markdown
---
id: pending
title: "<orijinal başlık> — yapıldı"
created_by: user
category: gorev
tags: [waiting-done]
...
---

## İstek
`tasks/waiting/<dosya>.md` (T-00X) görevinde beklenen iş yapıldı.
```

Seçenekli bir soruya cevap verildiğinde aynı şema, `tags: [waiting-answer]`
ve başlıkta "— cevaplandı" ile gider; gövde seçimi ve varsa açıklamayı taşır:

```markdown
## İstek
`tasks/waiting/<dosya>.md` (T-00X) görevindeki soru cevaplandı.

- **Seçim:** Fine-grained token üreteceğim
- **Açıklama:** Bu hafta içinde üretirim.
```

Agent bu bildirimi gördüğünde asıl görevi `waiting/` → `done/` taşır (ya da iş
devam ediyorsa `active/`e alır) ve bildirim görevini `done/`a kapatır.
Bildirimin ayrı bir görev olmasının nedeni R-001: app'in yazma alanı tek
klasördür ve bu garanti derleme zamanı sabitidir.

### Belgeden seçilerek üretilen kayıtlar (v1.5, K-023)

Kullanıcı uygulamada herhangi bir belgede (oturum, rapor, bilgi tabanı, görev,
yol haritası) bir metin seçip **kayıt oluşturabilir**. Oluşan şey yine normal
bir görevdir — R-001 gereği `tasks/inbox/`'a yazılır — ama üç ek alan taşır:

| Alan | Anlamı |
|---|---|
| `source` | Kaydın bağlı olduğu belgenin hub içindeki yolu |
| `quote` | O belgeden **birebir** alıntı; işaretin yeri bununla bulunur |
| `mark` | `highlight` (sarı), `underline` (kırmızı), `comment` (yeşil) veya `bookmark` (mavi, v1.12) |

`category` kaydın **ne olduğunu** söyler: `gorev` (yapılacak iş), `yorum`,
`duzeltme` (yanlış olduğu düşünülen yer), `tartisma` (açık soru) ya da serbest
bir değer.

**İşaret kayıttan türer, ayrıca saklanmaz.** Uygulama bir belgeyi çizerken o
belgeyi `source` alan kayıtları bulur ve `quote` metnini belgede işaretler.
Böylece işaret ile kayıt hiçbir zaman ayrışamaz: kayıt silinirse işaret de
gider, kayıt başka cihazda görünürse işaret de görünür.

Kurallar:
- `quote` belgede bulunamazsa işaret çizilmez; **kayıt yine geçerlidir** ve
  listelerde görünür. Belge değişmiş olabilir — bu beklenen bir durumdur.
- Aynı belgede birden çok kayıt olabilir; her biri kendi `quote`'unu işaretler.
- Agent bu kayıtları normal görev gibi ele alır: ID atar, `active`'e taşır,
  `result` yazar. `duzeltme` kayıtlarında düzeltme yapıldıysa `source`
  belgesinin kendisi de güncellenir.

**Not, görev değildir (v1.9).** Kullanıcı aynı menüden "Not ekle" derse kayıt
`tasks/` altına **girmez**, `notes/`a yazılır (§11). Ayrım kullanıcının
niyetidir: görev "sen şunu yap", not "ben bunu hatırlayayım". İkisini aynı
klasöre koymak, kullanıcının kendine yazdığı her satırı agent'ın iş kuyruğuna
sokuyordu.

**Yer imi hiçbir koşulda görev değildir (v1.12).** `mark: bookmark` taşıyan
kayıt, not yazılmış olsa bile `notes/`a gider. Diğer işaretlerde ayrımı notun
varlığı yapar (notsuz → `notes/`, notlu → `tasks/inbox/`, bkz. §11 ve B-099);
yer iminde niyet zaten adında: "burayı sonra bulayım". Bir yer imine düşülen
not, agent'a verilmiş bir iş değil, kullanıcının kendine bıraktığı işarettir.

## 5. `knowledge/` — bilgi tabanı

Üç canlı dosya; her kayıt tek tek, ID'li ve tarihli eklenir, silinmez
(geçersizleşen kayıt `~~üstü çizilir~~` ve nedeni yazılır):

- `knowledge/rules.md` — **Kurallar** (`R-001`, `R-002`...): projede uyulacak
  kalıcı kurallar. Örn. "R-001: App yalnızca tasks/inbox/'a yazar."
- `knowledge/skills.md` — **Skiller** (`SK-001`...): agent'ın bu projede edindiği,
  tekrar kullanılabilir yetenekler/prosedürler. Örn. "SK-001: Contents API ile
  SHA kontrollü dosya güncelleme."
- `knowledge/lessons.md` — **Çıkarılan dersler** (`L-001`...): yapılan hatalar ve
  öğrenilenler. Örn. "L-001: Tek büyük JSON dosyası eşzamanlı yazmada çakışır;
  dosya-başına-kayıt kullan."

Kayıt biçimi (üç dosyada da aynı):

```markdown
## R-001 — App'in yazma alanı tek: tasks/inbox/
- **Tarih:** 2026-07-30
- **Kaynak:** S-2026-07-30-altyapi-tasarimi
- **Açıklama:** ...
```

## 6. `BACKLOG.md` — yapılacak işler

- Fazlara bölünmüş, ID'li (`B-001`...) onay kutulu liste.
- **Tamamlanan iş silinmez**: kutusu işaretlenir, tarih ve varsa artifact/commit
  linki eklenir, listede kalır. Yapılacaklar listede devam eder.
- Yeni iş her zaman ilgili faza ID sırasıyla eklenir; faz bittiğinde faz başlığına
  ✅ ve bitiş tarihi yazılır.
- Ayrıntılı biçim `BACKLOG.md`'nin başında tanımlıdır.

## 7. `EVOLUTION.md` — projenin evrimi

- Proje **aşamalar** (Aşama 0, 1, 2...) halinde ilerler; her aşama bu dosyada bir
  bölümdür: hedef, verilen kararlar, sonuç, tarih aralığı.
- Aktif aşamanın bölümü **sürekli güncellenir**; aşama kapanınca bölümün başına
  ✅ konur ve bir sonraki aşama açılır.
- Sözleşme (bu dosya) değişiklikleri de burada "karar" olarak kayda geçer.

## 8. Commit mesajı kuralları

Hub'daki her commit, ne olduğunu tek satırda söyler:

```
session(S-...): oturum açıldı / kayıt güncellendi / oturum kapandı
task(T-001): inbox'a eklendi / active → done / not eklendi
artifact(A-...): <başlık> eklendi
backlog: B-014 tamamlandı
evolution: Aşama 1 kapandı
knowledge: L-003 eklendi
note: eklendi / silindi (app)          # (v1.11) notes/ — kullanıcının notu
security: SEC-005 eklendi / SEC-002 kapatıldı   # (v1.11) SECURITY.md
system: sözleşme 1.1'e güncellendi
```

Uygulama, commit geçmişini bu önekler üzerinden **aktivite akışı** olarak gösterir.
Listede olmayan bir önek "kod commit'i" sayılır ve akışta öyle görünür; bu
yüzden yeni bir kayıt türü eklenirken öneki **buraya da** yazılır. `notes/`
(1.9) ve `SECURITY.md` (1.10) eklenirken bu atlanmıştı: kullanıcının kendi
notu akışta "kod" olarak görünüyordu (v1.11 düzeltmesi).

## 9. Kategoriler (uygulama görünümü)

Uygulamanın "göz atma" ekranı şu kategorileri klasörlerden türetir:

| Kategori | Kaynak |
|---|---|
| Bekleyen görevler | `tasks/inbox/` + `tasks/active/` + `tasks/waiting/` |
| Tamamlananlar | `tasks/done/` |
| Oturumlar | `sessions/` |
| Raporlar & Planlar | `artifacts/` (frontmatter `type`'a göre alt filtre) |
| Bilgi tabanı | `knowledge/` |
| Yol haritası | `BACKLOG.md`, `EVOLUTION.md` |

## 10. Sözleşme sürümü ve güncelleme (v1.5, K-024)

Bu dosyanın **ana kopyası** `afgover/takip` reposundaki `hub/SYSTEM.md`'dir.
Diğer projelerin hub'larındaki kopyalar ondan türer ve **geriden gelebilir**.

Geriden gelen bir kopya sessiz bir tuzaktır: agent kendi hub'ındaki sözleşmeyi
okur, orada olmayan bir klasörü (örn. `tasks/waiting/`) bilmez ve sözleşmenin
son hâlinin öngördüğü davranışı hiç göstermez. Bu gerçekten yaşandı —
`financer_takip` 1.3'te kalmışken `waiting/` klasörünü kullanıyordu, yani
kullandığı klasörü kendi sözleşmesi tanımlamıyordu (L-020).

### Dil varyantları (v1.21)

Ana kopya iki dosyada durur ve **her hub kendi diline uyan varyantı** çeker:

| Hub dili | Çekilecek ana kopya |
|---|---|
| `tr` | `hub/SYSTEM.md`, `hub/AGENT_PROTOCOL.md` |
| `en` | `hub/SYSTEM.en.md`, `hub/AGENT_PROTOCOL.en.md` |

Hangi varyantı çekerse çeksin, hub onu **kendi** `hub/SYSTEM.md` ve
`hub/AGENT_PROTOCOL.md` dosyasına yazar. Hub içindeki dosya adı dil eki
taşımaz — varyantlar yalnız ana kopyada yan yana durur. Böylece bu
sözleşmedeki her yol her dilde aynı kalıyor ve dosyayı bulmak için dili
bilmek gerekmiyor (uygulama `hub/SYSTEM.md` okur).

Türkçe dosya **kanoniktir**: iki varyant çelişirse doğru olan Türkçe olandır,
İngilizcede bir çeviri hatası var demektir. Ona göre davranmak yerine bildir ve
ana kopyada düzelt. İki **bağlayıcı** kopya sessizce ayrışır — bu proje tam
olarak onu yaşadı (L-022).

### Kural dizisi

Her agent, **her oturum açılışında** şunu yapar:

1. Kendi hub'ındaki `hub/SYSTEM.md`'nin ilk satırlarındaki **Sözleşme
   sürümü**nü ve `**Hub dili:**` alanını oku.
2. Ana kopyayla karşılaştır. Tek komut, hem sürümü hem içeriği kapsar (v1.17);
   dosyayı hub'ının diline göre seç (v1.21):

   ```bash
   # Hub dili: tr
   curl -fsSL https://raw.githubusercontent.com/afgover/takip/main/hub/SYSTEM.md \
     -o /tmp/SYSTEM.master.md && diff /tmp/SYSTEM.master.md hub/SYSTEM.md

   # Hub dili: en
   curl -fsSL https://raw.githubusercontent.com/afgover/takip/main/hub/SYSTEM.en.md \
     -o /tmp/SYSTEM.master.md && diff /tmp/SYSTEM.master.md hub/SYSTEM.md
   ```

   - `diff` boşsa: kopyan ana kopyayla **birebir aynı**, yapılacak bir şey yok.
   - `diff` doluysa: aşağıdaki 4/5/6 maddelerine göre davran (sürümler farklı
     mı, yoksa sürüm aynı içerik farklı mı — ikincisi ayrışmadır).
   - **`curl` başarısız olursa kontrol KOŞMADI.** Bunu "güncelim" diye yorumlama
     ve kaydına "sözleşme kontrol edildi" yazma. Ana kopya `afgover/takip`
     public olana kadar bu istek 404 döner; ölçüldü (2026-08-06).
     Ağ yoksa ya da adres değiştiyse de aynı. Koşmayan bir kontrol, geçmiş bir
     kontrol değildir (L-035'in aynı kuralı).

   `afgover/takip`'in **kendi** agent'ı bu adımı atlar: o repo ana kopyanın
   kendisidir.
3. **Sürümler aynıysa** bir şey yapma.
4. **Kendi kopyan geridyse:**
   - Ana kopyayı olduğu gibi al, `hub/SYSTEM.md`'nin üzerine yaz.
   - `hub/AGENT_PROTOCOL.md`'yi de aynı şekilde tazele (o da ana kopyadan, aynı
     dil varyantından gelir).
   - Yeni sürümün getirdiği klasörler yoksa oluştur (örn. `tasks/waiting/`).
   - Commit: `system: sözleşme <eski> → <yeni> güncellendi`
   - `EVOLUTION.md`'ye tek satır not düş: hangi sürümden hangisine geçildi.
   - Kullanıcıya **ne değiştiğini** bir cümleyle söyle.
5. **Kendi kopyan ileriyse** (ana kopyadan yeni): üzerine yazma. Bu, ana kopya
   güncellenmeden yapılmış yerel bir değişiklik demektir; kullanıcıya bildir ve
   değişikliğin ana kopyaya taşınmasını öner.
6. **Sürümler eşit ama içerik farklıysa (ayrışma):** en tehlikeli durum budur
   ve yalnız sürüm numarasına bakan bir kontrol onu **göremez**. İki hub aynı
   numarayı farklı değişikliklerle almış demektir. Üzerine yazma; farkı
   kullanıcıya göster, yerel eklemeyi ana kopyaya taşı, ana kopyanın sürümünü
   artır ve sonra güncelle. Gerçekten yaşandı: `financer_takip` 1.4'ü
   "`reconstructed` alanı", ana kopya 1.4'ü "`tasks/waiting/`" için kullanmıştı
   (L-022). **Bu yüzden sürüm karşılaştırması yeterli değil; güncellemeden önce
   içerik de karşılaştırılır.**

Sözleşmeyi **yalnızca ana kopyada** değiştir. Bir projede yeni bir ihtiyaç
çıkarsa önce kullanıcıya öner, onaylanırsa `afgover/takip`'te sürümü artır;
diğer hub'lar bir sonraki oturumlarında kendiliğinden yakalar.

> **`AGENT_PROTOCOL.md` değişikliği de sürüm artırır (v1.14).** Yayılma
> mekanizması yalnız bu dosyanın sürüm numarasına bakıyor (adım 2); protokol
> tek başına değiştirilirse diğer hub'lar onu **hiç** almaz ve bunu fark eden
> bir kontrol yoktur. Bu yüzden protokole yazılan her yeni kural için de sürüm
> artırılır — değişiklik `SYSTEM.md`'de bir satır bile olmasa.

> **Uygulama tarafı:** app her bağlantının sözleşme sürümünü okur ve ana
> kopyadan geride kalanı **Ayarlar → Repolar**'da işaretler. Böylece geriden
> gelen bir hub, agent fark etmese bile kullanıcıya görünür.

## 11. `notes/` — kullanıcının kendi notları (v1.9)

Kullanıcının **kendisi için** aldığı notlar. Görev değildirler: iş kuyruğunda
görünmezler, ID almazlar, `active`/`done` diye bir durumları yoktur.

```
notes/
  <login>/                        # (v1.15) sahibinin GitHub hesabı
    2026-08-03-vulkan-arka-uc.md
  2026-08-03-eski-not.md          # v1.15 öncesi: düz, geçerliliğini korur
```

Dosya adı görevlerle aynı biçimde: `<YYYY-MM-DD>-<slug>.md`.

**Sahiplik klasörden okunur (v1.15).** Notlar birden çok kişide karışmasın
diye her kullanıcının kendi alt klasörü var. Ayrımın alanla değil **klasörle**
yapılması bilinçli: "agent notlara dokunmaz" kuralı böylece yapısal kalıyor —
sahibi anlamak için dosyayı açıp alan okumak gerekmiyor.
`tasks/inbox/` bilerek bölünmedi: o ortak iş kuyruğudur ve bölünmesi işi
gizlerdi.

**Not kişiseldir; paylaşım yolu görevdir (v1.16).** Uygulama bir belgeyi
çizerken **yalnız kendi** notlarını işaretler; başkasının notu ne belgede ne
işaretler listesinde görünür. Paylaşmak isteyen görev açar — `gorev`,
`duzeltme` ya da `tartisma`. Ayrım niyettir ve zaten §4'te tanımlı: not "ben
bunu hatırlayayım", görev "sen şunu yap", tartışma "bunu konuşalım".
Gerekçe 1.9'un (K-029) devamı: herkesin notunu herkesin görmesi, notu
"kendine yazılan şey" olmaktan çıkarır — kullanıcı kendine not alırken
başkalarına bir şey söylemiş olmak istemiyor.

Süzme **iki durumda yapılmaz**, ikisi de bilerek:
- Kimlik bilinmiyorsa: süzmek her şeyi gizlerdi.
- Not düz `notes/` altındaysa (v1.15 öncesi): sahibi bilinmiyor, gizlemek var
  olan notları sessizce yok ederdi.

App tarafında R-001'in garantisi korunuyor: uygulama hâlâ yol vermiyor,
klasörü kapalı bir kümeden seçiyor ve kullanıcı adını bir **ad** olarak
veriyor; ad, yol parçası hâline gelmeden önce yalnız harf/rakam/tireye
indirgeniyor.

```markdown
---
title: Impeller Vulkan arka ucu
created_by: user
created: 2026-08-03T09:10:00Z
updated: 2026-08-03T09:10:00Z
source: hub/sessions/2026-08-03-sifirdan-cozum/session.md
quote: Using the Impeller rendering backend
mark: comment
---

Buna sonra bakayım.
```

`source`/`quote`/`mark` alanları §4'teki seçim kayıtlarıyla aynı anlamdadır ve
aynı işi görür: uygulama belgeyi çizerken notu da bulur ve alıntıyı `mark`'ın
rengiyle işaretler. Yani not da işaretini kendisi taşır, işaret ayrıca
saklanmaz. Belgeden seçilmeden alınan bir notta bu üç alan olmayabilir.

**Yer imleri (v1.12) burada durur.** `mark: bookmark` taşıyan kayıt her zaman
`notes/`a yazılır — notlu da olsa (§4). Uygulama **aktif repodaki** bütün
işaretleri (görev ve not) tek bir listede toplar ve oradan kaydın bağlı olduğu
belgeye gidilir; yer iminin işi tam olarak budur.

> **v1.13 düzeltmesi.** 1.12'de bu liste *bütün* bağlantıları birleştiriyordu.
> Kullanımın ilk saatinde ters teptiği görüldü: işaret bir belgedeki **yeri**
> hatırlatır, belge de bir projeye aittir — hepsi tek listede olunca ekran bir
> bağlam yığınına döner. Liste artık aktif repoya ait ve hangi repo olduğu
> ekranda yazar; başka projeye bakmak için repo değiştirilir.
> `tasks/` listeleri bilinçli olarak istisnadır: orada soru "hangi projede
> olursa olsun **bende** bekleyen ne var" olduğu için birleşik kalır.

**Agent kuralları:**
- Notlar kullanıcınındır. Agent onları **iş saymaz**: ID atamaz, taşımaz,
  `result` yazmaz, "yapıldı" demez.
- Agent notları **okuyabilir** ve bağlam olarak kullanabilir ("kullanıcı burada
  şunu not almış"). Bir notu işe çevirmek gerekiyorsa bunu kullanıcı söyler;
  agent kendiliğinden görev açmaz.
- Agent bir notu silmez ve düzenlemez. Kullanıcı uygulamadan siler.
- Bir not gerçekten iş içeriyorsa agent bunu **sorar** (gerekirse
  `tasks/waiting/`e bir soru açar), kendisi karar vermez.

**App kuralları:** R-001'in yazma alanı v1.9'da ikiye çıktı — `tasks/inbox/`
ve `notes/`. İkisi de yapısal olarak kapalı: app yol değil dosya adı verir,
klasörü seçemez.

## 12. `SECURITY.md` — güvenlik logu (v1.10)

Projenin güvenliğine dair **yapılan ve yapılması gereken her şey** tek bir
canlı dosyada, ID'li kayıtlar hâlinde tutulur. Amaç: "bu konuda ne yapmıştık"
sorusunun cevabı oturum kayıtlarına dağılmasın, tek yerden okunabilsin.

Kayıt biçimi `knowledge/` ile aynı (§5), iki ek alanla:

```markdown
## SEC-001 — Token yalnızca cihazın güvenli deposunda
- **Tarih:** 2026-08-03
- **Tür:** onlem
- **Durum:** kapali
- **Kaynak:** S-2026-08-01-token-kaliciligi
- **Açıklama:** Token `flutter_secure_storage`'da tutulur; dosyaya, commit'e
  ve log'a hiçbir koşulda yazılmaz.
```

| Alan | Değerler | Anlamı |
|---|---|---|
| `Tür` | `tarama` | Yapılan denetim/tarama ve bulguları |
| | `onlem` | Alınan koruma, sertleştirme, kural |
| | `acik` | Bilinen zafiyet ya da riskli davranış |
| | `yapilacak` | Yapılması gereken güvenlik işi |
| `Durum` | `acik` | Henüz kapanmadı — ekranda öne alınır |
| | `kapali` | Tamamlandı ya da giderildi |

Türkçe karakter kullanılmaz (dosya adı kuralıyla aynı gerekçe); ekranda
okunabilir karşılıkları gösterilir.

**Agent kuralları:**
- Güvenlikle ilgili **her** iş buraya kayıt düşer: bağımlılık taraması, izin
  değişikliği, token/kimlik dokunuşu, veri saklama kararı, bulunan bir açık.
  Yalnız oturum kaydına yazmak yetmez — güvenlik geçmişi tek yerden okunabilir
  olmalı.
- **(v1.14) `tarama` kayıtlarının tarihi bir tetikleyicidir.** Agent her oturum
  açılışında son `tarama` kaydına bakar; 30 günden eskiyse taramayı yeniler
  (`AGENT_PROTOCOL.md` madde 4). Tarama koştuğu günün danışmanlık veritabanına
  göredir, dolayısıyla tek seferlik bir onay değildir. Tetikleyicinin ayrı bir
  takvimde değil **kaydın kendisinde** olması bilinçli: unutulduğunda da
  görünür kalır, ve hatırlatmayı ayakta tutacak ikinci bir sistem gerekmez.
- Bir `acik` kaydı giderildiğinde **silinmez**: `Durum` `kapali` yapılır ve
  altına nasıl giderildiği yazılır. Geçersizleşen kayıt R-004'teki gibi
  `~~üstü çizilir~~` ve nedeni yazılır.
- `yapilacak` kayıtları aynı zamanda `BACKLOG.md`'ye de girer; burada güvenlik
  bağlamıyla, orada iş sırasıyla durur. İkisi çelişirse doğru kaynak
  `BACKLOG.md`'dir.
- **Sır yazılmaz.** Token, parola, anahtar, özel URL — hiçbiri bu dosyaya
  (ya da başka bir hub dosyasına) yazılmaz. Kayıt "neyin korunduğunu" anlatır,
  korunan şeyin kendisini değil.
- Kullanıcı uygulamada bu logu **Tarayıcı → Security** altında görür.
