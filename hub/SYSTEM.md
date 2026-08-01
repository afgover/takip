# SYSTEM.md — Taskr Hub Format Sözleşmesi

Bu doküman, hub reposundaki her dosyanın **nerede duracağını, nasıl adlanacağını
ve hangi şemaya uyacağını** tanımlar. Agent ve kullanıcı uygulaması bu sözleşmenin
dışına çıkmaz. Sözleşme değişiklikleri `EVOLUTION.md`'ye kaydedilir ve bu dosyanın
başındaki sürüm numarası artırılır.

**Sözleşme sürümü:** 1.4
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
                             # fikir — serbest değer de geçerli (kullanıcı tanımlı).
                             # App, seçim listesini varsayılanlar + mevcut
                             # görevlerde geçen kategorilerden türetir. (v1.1)
tags: []
session: none                # ele alındığı oturumun ID'si (agent doldurur)
result: none                 # tamamlanınca: sonucun 1 satır özeti veya artifact linki
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

Kullanıcı işi bitirdiğinde uygulamadaki **"Yaptım"** düğmesine basar; app
`tasks/inbox/`'a şu şemada bir bildirim görevi yazar:

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

Agent bu bildirimi gördüğünde asıl görevi `waiting/` → `done/` taşır (ya da iş
devam ediyorsa `active/`e alır) ve bildirim görevini `done/`a kapatır.
Bildirimin ayrı bir görev olmasının nedeni R-001: app'in yazma alanı tek
klasördür ve bu garanti derleme zamanı sabitidir.

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
system: sözleşme 1.1'e güncellendi
```

Uygulama, commit geçmişini bu önekler üzerinden **aktivite akışı** olarak gösterir.

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
