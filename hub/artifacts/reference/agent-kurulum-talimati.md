---
id: A-2026-08-01-101
session: none
type: info
title: "Agent kurulum talimatı — hub'ı kur, geçmişi topla, protokole göre çalış"
created: 2026-08-01T00:00:00Z
updated: 2026-08-04T00:00:00Z
contract: "1.12"
---

# Agent Kurulum Talimatı

Bu belge **agent'a verilir**. Bir projeyi takip sistemine bağlarken kullanıcı
bunu olduğu gibi yapıştırır; agent gerisini buradan yapar.

Kanonik sürüm bu dosyadır (`afgover/takip` reposunda). Masaüstündeki kopya
kolaylık içindir ve zamanla bayatlar; şüphede kalınırsa bu dosya esas alınır.

**Bu belge sözleşme sürümü 1.12'ye göre yazıldı.** Sözleşmenin kendisi daha
yeniyse o kazanır — bkz. §1.

---

## Sana verilen görev

`<owner>/<proje>_takip` reposunda bir **takip hub'ı** kuracaksın ve bundan
sonra o projedeki her çalışmanı oraya kaydedeceksin.

Hub, projenin hafızasıdır: oturum kayıtları, görevler, kararlar, çıkarılan
dersler, güvenlik geçmişi ve yol haritası orada durur. Kullanıcı bunu
telefonundaki uygulamadan okur ve sana oradan görev atar. **Hub'a yansımayan
hiçbir çalışma "yapılmış" sayılmaz.**

İki durumdan birindesin:

- **A — Sıfırdan proje.** Ortada henüz iş yok. §1 → §2 → §5'e geç.
- **B — Geçmişi olan proje.** Proje aylardır sürüyor; kodu, commit'leri,
  belgeleri, belki eski sohbetleri var. §1 → §2 → **§3 (geçmişi topla)** → §5.

B durumunda §3'ü **atlamak yok**. Hub'ı boş kurup "bundan sonrasını
kaydederim" demek, projenin bugüne kadarki bütün kararlarını kayıp saymaktır;
kullanıcı ilk "bunu neden böyle yapmıştık" sorusunda karşılığını alamaz.

---

## 1. Sözleşmeyi al ve sürümünü kontrol et

İki dosya projeden projeye değişmez, ana kopyadan **olduğu gibi** kopyalanır:

```
https://raw.githubusercontent.com/afgover/takip/main/hub/SYSTEM.md
https://raw.githubusercontent.com/afgover/takip/main/hub/AGENT_PROTOCOL.md
```

- `SYSTEM.md` — hangi dosya nerede durur, nasıl adlanır, hangi şemaya uyar
- `AGENT_PROTOCOL.md` — ne zaman ne kaydedersin

İkisini de **baştan sona oku.** Bu belge özettir, sözleşmenin yerine geçmez.

### Her oturum açılışında: sürümü karşılaştır

Kopyalar zamanla **geriden gelir** ve bu sessiz bir tuzaktır: kendi hub'ındaki
sözleşmeyi okursun, orada olmayan bir klasörü bilmezsin ve son sürümün
öngördüğü davranışı hiç göstermezsin. Gerçekten yaşandı — bir hub 1.3'te
kalmışken 1.4'ün klasörünü kullanıyordu, yani kullandığı klasörü kendi
sözleşmesi tanımlamıyordu.

Her oturum açılışında:

1. Kendi `hub/SYSTEM.md`'ndeki **Sözleşme sürümü**nü oku.
2. Ana kopyadakiyle karşılaştır.
3. **Aynıysa** devam et.
4. **Geridesen:** ana kopyayı `SYSTEM.md` ve `AGENT_PROTOCOL.md` üzerine yaz,
   yeni sürümün getirdiği klasör/dosyaları oluştur, commit et
   (`system: sözleşme 1.6 → 1.12 güncellendi`), `EVOLUTION.md`'ye tek satır not
   düş ve kullanıcıya **ne değiştiğini** bir cümleyle söyle.
5. **İleridesen:** üzerine yazma. Ana kopya güncellenmeden yapılmış yerel bir
   değişiklik var demektir; kullanıcıya bildir ve ana kopyaya taşınmasını öner.
6. **Sürümler eşit ama içerik farklıysa (ayrışma):** en tehlikeli durum budur
   ve yalnız numaraya bakan bir kontrol onu **göremez**. İki hub aynı numarayı
   farklı değişikliklerle almış demektir. Üzerine yazma; farkı kullanıcıya
   göster, yerel eklemeyi ana kopyaya taşı, ana kopyanın sürümünü artır, sonra
   güncelle. Bu da gerçekten yaşandı (L-022).

Sözleşmeyi **yalnızca ana kopyada** değiştir. Yeni bir ihtiyaç çıkarsa önce
kullanıcıya öner; onaylanırsa `afgover/takip`'te sürüm artar, diğer hub'lar bir
sonraki oturumlarında yakalar.

---

## 2. İskeleti kur

Hub kökü **her zaman** reponun içindeki `hub/` klasörüdür — istisnasız (K-020).
Repo köküne kurma; uygulama `hub/` arar ve bulamazsa repoyu hiç eklemez.

```
hub/
  SYSTEM.md              # kopyalanır, değiştirilmez
  AGENT_PROTOCOL.md      # kopyalanır, değiştirilmez
  BACKLOG.md             # projeye özgü; faz iskeletiyle başlar
  EVOLUTION.md           # projeye özgü; "Aşama 0" açık olarak başlar
  SECURITY.md            # güvenlik logu (§7)
  sessions/README.md
  artifacts/README.md
  notes/README.md        # kullanıcının kendi notları — senin işin değil (§6)
  tasks/inbox/README.md
  tasks/active/README.md
  tasks/waiting/README.md
  tasks/done/README.md
  knowledge/rules.md
  knowledge/skills.md
  knowledge/lessons.md
```

`README.md` dosyaları klasörün ne işe yaradığını bir paragrafta anlatır; git
boş klasör tutmadığı için ayrıca gereklidir.

`knowledge/` dosyaları başlıkla ve boş kayıt listesiyle başlar. İlk kayıt
**gerçek** bir kural/skill/ders çıktığında eklenir — dolu görünsün diye
uydurulmaz.

Commit: `system: hub iskeleti kuruldu (sözleşme 1.12)`

---

## 3. Geçmişi topla (yalnız B durumu)

Amaç: projenin bugüne kadarki hikâyesini **kanıta dayalı** biçimde hub'a
taşımak. Roman yazmak değil — kaynağı gösterilebilen şeyi kaydetmek.

### 3.1 Önce oku, sonra yaz

Sırayla tara ve not al:

| Kaynak | Ne çıkarırsın |
|---|---|
| `git log --reverse` (kod reposu) | Ne zaman ne yapıldı; dönemler, kilometre taşları |
| Etiketler/sürümler (`git tag`) | Aşama sınırları — `EVOLUTION.md` bölümleri |
| `README`, `CHANGELOG`, `docs/`, ADR'ler | Kararlar ve gerekçeleri |
| Açık/kapalı issue ve PR'lar | Yapılacaklar ve tartışılmış konular |
| Kodda `TODO`/`FIXME` | `BACKLOG.md` maddeleri |
| Bağımlılık ve yapılandırma dosyaları | Kısıtlar, güvenlik yüzeyi |
| Kullanıcının verdiği eski sohbet/notlar | Kararların **gerekçesi** — en değerli kaynak |

Kullanıcıda eski sohbet dökümü, toplantı notu ya da eski bir takip sistemi
varsa **iste**. Bunlar olmadan "ne yapıldı" çıkar ama "neden öyle yapıldı"
çıkmaz; asıl kaybolan da odur.

### 3.2 Geriye dönük oturumları yaz

Geçmişi **birkaç kaba oturuma** böl — dönem başına bir tane (bir sürüm, bir
kilometre taşı, bir ay). Her commit için oturum uydurma; oturum bir çalışma
oturumudur, commit değildir.

Her geriye dönük oturum dosyasında frontmatter'a **`reconstructed: true`**
konur (sözleşme 1.6):

```markdown
---
id: S-2026-05-10-ilk-surum
date: 2026-05-10
status: closed
reconstructed: true
topics: [kurulum, veritabani]
artifacts: []
tasks_touched: []
---
```

Bu, "kayıt dışı iş yok" kuralının istisnası **değil**; kaydın nasıl
üretildiğini dürüstçe işaretlemek içindir. Geriye dönük yazılmış bir kayıt,
gerçek zamanlı kaydın taşıdığı zaman damgası doğruluğunu iddia edemez.

Kurallar:

- **Zaman damgası uydurma.** Tarih commit'ten geliyorsa onu kullan; saat
  bilinmiyorsa saat yazma.
- **Kaynağı göster.** Her iddianın yanına nereden geldiğini yaz:
  `(kaynak: commit a1b2c3d)`, `(kaynak: README, 2026-04 sürümü)`.
- **Boşluğu boşluk olarak yaz.** "Bu kararın gerekçesi kayıtlarda yok" cümlesi,
  uydurulmuş bir gerekçeden kıyasla iyidir. Gerekçe kullanıcıda olabilir —
  o zaman §3.5.
- **`## Kayıt` bölümünü zorlamadan bırak.** Gerçek diyalog yoksa oraya sahte
  replik yazma; `## Özet` yeter.

### 3.3 `EVOLUTION.md`'yi geriye dönük kur

Projeyi aşamalara böl (Aşama 0, 1, 2...). Her aşama: hedef, verilen kararlar,
sonuç, tarih aralığı. Kapanmış aşamaların başına ✅ koy, bugünkü aşamayı açık
bırak. Kararları `K-001`, `K-002`... diye numaralandır ve kaynağını yaz.

### 3.4 `BACKLOG.md`'yi geriye dönük kur

- Biten işler **silinmez**: kutusu işaretli, tarihi yazılı olarak listede
  durur. Geçmişten çıkardıklarını `[x]` olarak ekle.
- Açık işler: issue'lar, `TODO`'lar, README'deki "yapılacaklar", kullanıcının
  söyledikleri.
- Emin olmadığın maddeyi **açık soru** olarak ekleme; §3.5'e koy.

### 3.5 Bilmediklerini `waiting/`e koy

Geçmişi toplarken kaçınılmaz olarak cevabı yalnız kullanıcıda olan sorular
çıkar. Bunları sohbette sorup geçme — **her biri bir `waiting/` görevidir.**
Sohbet kapanır, kullanıcının telefonunda hiçbir iz kalmaz.

Tek bir "sorularım var" görevi açma; her soru ayrı görev olsun ki kullanıcı
teker teker kapatabilsin.

### 3.6 `knowledge/` ve `SECURITY.md`'yi geriye dönük doldur

- Geçmişte tekrarlanmış bir hata varsa `lessons.md`'ye ders olarak yaz
  (kaynağı: hangi commit/PR).
- Projede fiilen uyulan bir kural varsa `rules.md`'ye yaz.
- Güvenlikle ilgili geçmişte alınmış her önlem `SECURITY.md`'ye `onlem`
  kaydı olur (§7). **Hiç bilgi yoksa** bunu bir `yapilacak` kaydı yap:
  "geçmiş güvenlik kararları taranmadı".

### 3.7 Kullanıcıya özet ver

Geçmiş toplama bittiğinde tek mesajda söyle: kaç oturum yeniden kuruldu, kaç
backlog maddesi çıktı, hangi sorular `waiting/`te bekliyor, neyi
bulamadın. Kullanıcı neyin kayıt altına alındığını bilmeli.

Commit'ler: `session(S-...): geriye dönük kaydedildi (reconstructed)`

---

## 4. Oturum döngüsü

Her çalışma oturumu için, **istisnasız**:

**Açılışta**

1. `sessions/<tarih>-<slug>/session.md` dosyasını `status: open` ile aç —
   ilk kullanıcı mesajından hemen sonra, sonuna bırakma.
2. Sözleşme sürümünü kontrol et (§1).
3. `tasks/inbox/`e bak: yeni görev var mı? ID ata, ele alacaklarını
   `active/`e taşı.
4. `BACKLOG.md`'ye bak: yarım kalmış iş var mı?

**Boyunca**

5. **Her kullanıcı mesajını ve her cevabını anında** `session.md`'ye ekle.
   Kullanıcı mesajları kısaltılmadan; senin cevapların karar/bulgu odaklı
   özetlenerek.
6. Ürettiğin her rapor/plan/analiz `artifacts/` altına, frontmatter'ıyla.
7. Kural, skill ya da ders çıktığı **anda** `knowledge/`a yaz. "Sonra
   yazarım" yok.
8. Backlog maddesi bitince **anında** işaretle.
9. Güvenliğe dokunan her iş `SECURITY.md`'ye kayıt düşer (§7).

**Kapanışta**

10. `## Özet`i doldur, `status: closed` yap.
11. `EVOLUTION.md`'de aktif aşamayı güncelle.
12. Tutarlılık kontrolü: bu oturumda üretilen her dosya `session.md`'den
    erişilebiliyor mu?
13. **Push'la.** Push'lanmamış kayıt, yapılmamış kayıttır.

---

## 5. Görev döngüsü — durum = klasör

```
tasks/inbox/     kullanıcı (uygulamadan) ya da sen ekledin, henüz ele alınmadı
tasks/active/    sen ele aldın, üzerinde çalışıyorsun
tasks/waiting/   sen KULLANICIYI bekliyorsun — top onda
tasks/done/      bitti (arşiv, silinmez)
```

Dosyayı klasörler arasında **yalnız sen** taşırsın. Taşıma = eski yolu sil +
yeni yola yaz; commit mesajı `task(T-001): active → done`.

Uygulamanın yazdığı görevde `id: pending` olur — **ID'yi sen atarsın**, ilk
ele alışta sıradaki `T-00X`'i verirsin.

### `waiting/` — en çok atlanan kısım

**Kullanıcının bir şey yapması gerekiyorsa görev aç ve `waiting/`e koy.**
Sohbette söylemek yeterli değildir. Bu sistem tam olarak bu yüzden var
(K-022, L-018).

Kural: *"kullanıcı yapmadan ilerleyemiyorsam, bu bir `waiting/` görevidir."*

Beklediğin şeyi `## Notlar`a **tek satırda ve yapılabilir biçimde** yaz:

> Beklenen: GitHub'da fine-grained token üret — Contents: Read and write.

Belirsiz beklentiler (`belki bir gün bakar`) `waiting/`e konmaz; o görev
`active/`te kalır.

Kullanıcı uygulamadan **"Yaptım"** dediğinde `inbox/`a `waiting-done` etiketli
bir bildirim görevi düşer. Onu görünce asıl görevi `waiting/`ten çıkar (`done/`
ya da iş sürüyorsa `active/`) ve bildirimi kapat.

**Soru soruyorsan seçenek ver (v1.12).** Beklediğin şey bir iş değil bir
*karar*sa, görevin frontmatter'ına seçenekleri yaz:

```yaml
options: ["Fine-grained token üreteceğim", "Klasikle devam", "Sonra bakalım"]
multi: false                 # true → kullanıcı birden çok işaretleyebilir
```

Uygulama o zaman "Yaptım" yerine seçenekleri gösterir; kullanıcı seçer,
isterse yanına açıklama yazar. Cevap `inbox/`a `waiting-answer` etiketiyle
düşer ve gövdesinde **Seçim** (varsa **Açıklama**) satırını taşır.

İki kural: seçenek yazmazsan davranış eskisi gibi kalır ("Yaptım"), ve
**bir görev = bir soru** — cevaplanan soru kapanır, konuşmanın devamı
gerekiyorsa yeni bir `waiting/` görevi aç. Sorunu sohbette sorup geçme;
sohbet kapanır, `waiting/` kapanmaz.

---

## 6. Uygulamadan gelenler

Uygulama hub'da **yalnız iki yere** yazar (R-001, sözleşme 1.9):
`tasks/inbox/` ve `notes/`. Başka hiçbir klasöre dokunmaz, dosya taşımaz.
Tek istisna: kullanıcı kendi yazdığı ve hâlâ `inbox/`ta duran bir kaydı
silebilir (1.7) — sen `active/`e almışsan silinemez.

### Belgeden seçilerek gelen kayıtlar

Kullanıcı uygulamada herhangi bir belgede metin seçip kayıt oluşturabiliyor.
Bu kayıtlar `inbox/`a normal görev olarak düşer ama üç ek alan taşır:
`source` (hangi belge), `quote` (birebir alıntı), `mark`
(sarı/kırmızı/yeşil/mavi).
Gövdesinde ayrıca **nerede** olduğu yazar: repo, dosya yolu, bölüm başlığı —
alıntıyı bütün hub'da aramak zorunda kalma.

`category` ne olduğunu söyler ve **nasıl ele alacağını belirler**:

| Kategori | Senden beklenen |
|---|---|
| `gorev` | İşi yap |
| `yorum` | Not olarak dikkate al; genelde yapılacak iş yoktur |
| `duzeltme` | Alıntılanan yer yanlış — **`source` belgesini düzelt**, sonra kaydı kapat |
| `tartisma` | Açık soru — cevabını yaz, gerekiyorsa `waiting/` ile kullanıcıya dön |

İşaret ayrıca saklanmaz, kayıttan türer: kaydı `done/`a taşırsan işaret de
belgeden kalkar. Bu yüzden bir `duzeltme` kaydını kapatmadan önce düzeltmeyi
gerçekten yapmış ol.

### `notes/` — kullanıcının kendi notları (v1.9)

Kullanıcı aynı menüden **"Not ekle"** derse kayıt `tasks/` altına **girmez**,
`notes/`a yazılır ve alıntı yeşil işaretlenir.

**Yer imi (v1.12, `mark: bookmark`) her zaman burada durur** — not yazılmış
olsa bile göreve dönüşmez. "Burayı sonra bulayım" demek sana iş vermek
değildir. Kullanıcı bütün işaretlerini uygulamada tek listede görüyor ve
oradan belgeye gidiyor.

**Bu klasör senin işin değil.** ID atama, taşıma, `result` yazma, "yapıldı"
deme, silme, düzenleme — hiçbiri. Bağlam olarak okuyabilir ve oturum kaydında
buna dayanabilirsin. Bir not gerçekten iş içeriyorsa kendiliğinden görev açma:
kullanıcıya sor, gerekirse `waiting/`e bir soru koy.

Ayrım kullanıcının niyeti: görev "sen şunu yap", not "ben bunu hatırlayayım".

---

## 7. `SECURITY.md` — güvenlik logu (v1.10)

Güvenlikle ilgili **her** iş buraya ID'li bir kayıt olarak düşer: yapılan
taramalar, alınan önlemler, bilinen açıklar, yapılacak güvenlik işleri.
Biçim `knowledge/` ile aynı, iki ek alanla:

```markdown
## SEC-001 — Kısa başlık
- **Tarih:** 2026-08-03
- **Tür:** tarama | onlem | acik | yapilacak
- **Durum:** acik | kapali
- **Kaynak:** S-2026-08-03-...
- **Açıklama:** ...
```

Kurallar:

- Bağımlılık taraması, izin değişikliği, token/kimlik dokunuşu, veri saklama
  kararı, bulunan bir açık — hepsi kayıt olur. Yalnız oturum kaydına yazmak
  yetmez: "bu konuda ne yapmıştık" sorusunun cevabı oturumlara dağılmamalı.
- Giderilen bir açık **silinmez**: `Durum: kapali` yapılır ve nasıl giderildiği
  yazılır.
- `yapilacak` kayıtları `BACKLOG.md`'ye de girer; ikisi çelişirse doğru kaynak
  `BACKLOG.md`'dir.
- **Sır yazılmaz.** Token, parola, anahtar, özel URL — hiçbiri hub'ın hiçbir
  dosyasına yazılmaz. Kayıt neyin korunduğunu anlatır, korunan şeyin kendisini
  değil.

Kullanıcı bunu uygulamada **Tarayıcı → Security** altında görür; açık kayıtlar
üstte listelenir.

---

## 8. Commit mesajları

```
session(S-...): oturum açıldı / kayıt güncellendi / oturum kapandı
session(S-...): geriye dönük kaydedildi (reconstructed)
task(T-001): inbox'a eklendi / active → waiting / active → done
artifact(A-...): <başlık> eklendi
backlog: B-014 tamamlandı
evolution: Aşama 1 kapandı
knowledge: L-003 eklendi
note: eklendi / silindi (app)
security: SEC-005 eklendi / SEC-002 kapatıldı
system: sözleşme 1.6 → 1.12 güncellendi
```

İlgisiz değişiklikler aynı commit'e konmaz. Uygulama commit geçmişini bu
öneklerden okuyup kullanıcıya aktivite akışı olarak gösterir. **Önek uydurma:**
listede olmayan bir önek "kod commit'i" sayılır ve akışta öyle görünür. Yeni
bir kayıt türü gerekiyorsa öneki önce sözleşme §8'e eklenir.

---

## 9. Değişmez kurallar

- **Kayıt dışı iş yok.** Hub'a push'lanmamış kayıt, yapılmamış kayıttır.
- **Silme yok.** Oturum, artifact, `done/` görev, knowledge ve güvenlik
  kayıtları silinmez; geçersizleşen kayıt `~~üstü çizilir~~` ve nedeni yazılır.
- **Sözleşmeye sadakat.** `SYSTEM.md` şemasının dışında dosya/format icat etme.
  Değişiklik gerekiyorsa **önce kullanıcıya öner**; onaylanırsa ana kopyada
  sürümü artır ve `EVOLUTION.md`'ye karar olarak yaz.
- **Token asla dosyaya yazılmaz** (R-005). Kullanıcının token'ı yalnız
  telefonun güvenli deposunda durur; commit'e, log'a, artifact'e girmez.
  Kullanıcı sana token'ını verirse **kullanma ve kaydetme** — uygulamaya kendi
  girmesi gerektiğini söyle.
- **Uydurma yok.** Bilmediğin bir tarihi, gerekçeyi ya da sonucu yazma;
  bilinmediğini yaz. Geriye dönük kayıtta bu kural iki kat geçerli.

---

## 10. İlk oturumda kullanıcıdan öğrenmen gerekenler

İskeleti kurduktan (ve B durumundaysan geçmişi topladıktan) sonra projeyi tanı
ve `EVOLUTION.md` Aşama 0 ile `BACKLOG.md`'ye yaz — bir daha sorulmasın diye:

- Proje ne yapıyor, kime hitap ediyor?
- Bugün nerede duruyor (çalışan bir şey var mı, nerede)?
- İlk hedef ne, neyi başarınca "oldu" denecek?
- Bilinen kısıtlar neler (teknoloji, süre, bütçe, bağımlılık)?
- Güvenlik açısından bilinen bir hassasiyet var mı (kişisel veri, ödeme,
  kimlik doğrulama)?

Cevap bekliyorsan o bir `waiting/` görevidir; çekinme.

---

## 11. Bitirmeden önce kontrol listesi

- [ ] `hub/SYSTEM.md` ve `AGENT_PROTOCOL.md` ana kopyayla aynı sürümde
- [ ] İskeletteki bütün klasörler var (`notes/` ve `SECURITY.md` dahil)
- [ ] B durumunda: geçmiş oturumlar `reconstructed: true` ile yazıldı
- [ ] B durumunda: cevabı kullanıcıda olan her soru ayrı bir `waiting/` görevi
- [ ] `EVOLUTION.md`'de bir aşama açık
- [ ] `BACKLOG.md`'de en az bir sıradaki iş var
- [ ] `SECURITY.md` açıldı (bilgi yoksa bile bir `yapilacak` kaydıyla)
- [ ] Bu oturumun `session.md`'si `status: closed`
- [ ] Her şey push'landı
- [ ] Kullanıcıya ne kurulduğu ve neyin beklendiği tek mesajda söylendi
