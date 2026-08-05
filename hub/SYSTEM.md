# SYSTEM.md — Taskr Hub Format Sözleşmesi

Bu doküman, hub reposundaki her dosyanın **nerede duracağını, nasıl adlanacağını
ve hangi şemaya uyacağını** tanımlar. Agent ve kullanıcı uygulaması bu sözleşmenin
dışına çıkmaz. Sözleşme değişiklikleri `EVOLUTION.md`'ye kaydedilir ve bu dosyanın
başındaki sürüm numarası artırılır.

**Sözleşme sürümü:** 1.14
**Ana kopya (master):** `afgover/takip` → `hub/SYSTEM.md`
(bkz. §10 — her hub kendi kopyasını buradan günceller)
**Zaman biçimi:** her yerde ISO 8601, UTC (`2026-07-30T14:05:00Z`)
**Dil:** doküman içerikleri Türkçe; alan adları (frontmatter anahtarları) İngilizce
**Dosya adları:** küçük harf, Türkçe karakter yok, boşluk yerine tire (`gorev-adi`)

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

### Kural dizisi

Her agent, **her oturum açılışında** şunu yapar:

1. Kendi hub'ındaki `hub/SYSTEM.md`'nin ilk satırlarındaki
   **Sözleşme sürümü**nü oku.
2. Ana kopyanınkiyle karşılaştır:
   `https://raw.githubusercontent.com/afgover/takip/main/hub/SYSTEM.md`
3. **Sürümler aynıysa** bir şey yapma.
4. **Kendi kopyan geridyse:**
   - Ana kopyayı olduğu gibi al, `hub/SYSTEM.md`'nin üzerine yaz.
   - `hub/AGENT_PROTOCOL.md`'yi de aynı şekilde tazele (o da ana kopyadan gelir).
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
  2026-08-03-vulkan-arka-uc.md
```

Dosya adı görevlerle aynı biçimde: `<YYYY-MM-DD>-<slug>.md`.

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
