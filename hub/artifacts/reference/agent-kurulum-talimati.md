---
id: A-2026-08-01-101
session: none
type: info
title: "Agent kurulum talimatı — hub iskeletini kur ve protokole göre çalış"
created: 2026-08-01T00:00:00Z
---

# Agent Kurulum Talimatı

Bu belge **agent'a verilir**. Yeni bir projeyi takip sistemine bağlarken
kullanıcı bunu olduğu gibi yapıştırır; agent gerisini buradan yapar.

Kanonik sürüm bu dosyadır (`takip` reposunda). Masaüstündeki kopya
kolaylık içindir ve zamanla bayatlayabilir; şüphede kalınırsa bu dosya
esas alınır.

---

## Sana verilen görev

`<owner>/<proje>_takip` reposunda bir **takip hub'ı** kuracaksın ve bundan
sonra o projedeki her çalışmanı oraya kaydedeceksin.

Hub, projenin hafızasıdır: oturum kayıtları, görevler, kararlar, çıkarılan
dersler ve yol haritası orada durur. Kullanıcı bunu telefonundaki uygulamadan
okur ve sana oradan görev atar. **Hub'a yansımayan hiçbir çalışma "yapılmış"
sayılmaz.**

## 1. Sözleşmeyi al

İki dosya projeden projeye değişmez, `takip` reposundan **olduğu gibi**
kopyalanır:

```
https://raw.githubusercontent.com/afgover/takip/main/hub/SYSTEM.md
https://raw.githubusercontent.com/afgover/takip/main/hub/AGENT_PROTOCOL.md
```

- `SYSTEM.md` — hangi dosya nerede durur, nasıl adlanır, hangi şemaya uyar
- `AGENT_PROTOCOL.md` — ne zaman ne kaydedersin

İkisini de **baştan sona oku.** Aşağıdakiler özettir, sözleşmenin yerine
geçmez.

## 2. İskeleti kur

Hub kökü **her zaman** reponun içindeki `hub/` klasörüdür — istisnasız
(K-020). Repo kökine kurma; uygulama `hub/` arar ve bulamazsa repoyu hiç
eklemez.

```
hub/
  SYSTEM.md              # kopyalanır, değiştirilmez
  AGENT_PROTOCOL.md      # kopyalanır, değiştirilmez
  BACKLOG.md             # projeye özgü; boş faz iskeletiyle başlar
  EVOLUTION.md           # projeye özgü; "Aşama 0" açık olarak başlar
  sessions/README.md
  artifacts/README.md
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

`knowledge/` dosyaları başlıkla ve boş kayıt listesiyle başlar; ilk kayıt
gerçek bir kural/skill/ders çıktığında eklenir — doldurmak için uydurulmaz.

## 3. Görev döngüsü — durum = klasör

```
tasks/inbox/     kullanıcı (uygulamadan) ya da sen ekledin, henüz ele alınmadı
tasks/active/    sen ele aldın, üzerinde çalışıyorsun
tasks/waiting/   sen KULLANICIYI bekliyorsun — top onda
tasks/done/      bitti (arşiv, silinmez)
```

Dosyayı klasörler arasında **yalnız sen** taşırsın. Taşıma = eski yolu sil +
yeni yola yaz; commit mesajı `task(T-001): active → done`.

### `waiting/` — en çok atlanan kısım

**Kullanıcının bir şey yapması gerekiyorsa görev aç ve `waiting/`e koy.**
Sohbette söylemek yeterli değildir: sohbet kapanır, kullanıcının telefonunda
hiçbir iz kalmaz. Bu sistem tam olarak bu yüzden var (K-022, L-018).

Kural: *"kullanıcı yapmadan ilerleyemiyorsam, bu bir `waiting/` görevidir."*

Beklediğin şeyi `## Notlar`a **tek satırda ve yapılabilir biçimde** yaz:

> Beklenen: GitHub'da fine-grained token üret — Contents: Read and write.

Belirsiz beklentiler (`belki bir gün bakar`) `waiting/`e konmaz; o görev
`active/`te kalır.

Kullanıcı uygulamadan **"Yaptım"** dediğinde `inbox/`a `waiting-done`
etiketli bir bildirim görevi düşer. Onu görünce asıl görevi `waiting/`ten
çıkar (`done/` ya da iş sürüyorsa `active/`) ve bildirimi kapat.

### Uygulamanın sınırı

Uygulama **yalnızca `tasks/inbox/`'a yazar** (R-001). Başka hiçbir klasöre
dokunmaz, dosya taşımaz, silmez. Kullanıcıdan gelen her şey inbox'a düşer;
gerisi sende.

Uygulamanın yazdığı görevde `id: pending` olur — **ID'yi sen atarsın**, ilk
ele alışta sıradaki `T-00X`'i verirsin.

## 4. Kayıt disiplini

`AGENT_PROTOCOL.md`'nin tamamı bağlayıcıdır. En sık atlanan dördü:

1. **Oturum dosyasını ilk mesajdan hemen sonra aç** (`status: open`), sonuna
   bırakma.
2. **Her kullanıcı mesajını ve her cevabını anında ekle.** Kullanıcı mesajları
   kısaltılmadan; senin cevapların karar/bulgu odaklı özetlenerek.
3. **Ürettiğin her rapor/plan/analiz `artifacts/` altına**, frontmatter'ıyla.
4. **Kural, skill ya da ders çıktığı anda `knowledge/`a yaz.** "Sonra yazarım"
   yok.

Oturumu kapatırken `## Özet`i doldur, `status: closed` yap, `EVOLUTION.md`'de
aşamayı güncelle ve **push'la**.

## 5. Commit mesajları

```
session(S-...): oturum açıldı / kayıt güncellendi / oturum kapandı
task(T-001): inbox'a eklendi / active → waiting / active → done
artifact(A-...): <başlık> eklendi
backlog: B-014 tamamlandı
evolution: Aşama 1 kapandı
knowledge: L-003 eklendi
system: sözleşme 1.5'e güncellendi
```

İlgisiz değişiklikler aynı commit'e konmaz. Uygulama commit geçmişini bu
öneklerden okuyup kullanıcıya aktivite akışı olarak gösterir; önek uydurma.

## 6. Değişmez kurallar

- **Kayıt dışı iş yok.** Hub'a push'lanmamış kayıt, yapılmamış kayıttır.
- **Silme yok.** Oturum, artifact, `done/` görev ve knowledge kayıtları
  silinmez; geçersizleşen kayıt `~~üstü çizilir~~` ve nedeni yazılır.
- **Sözleşmeye sadakat.** `SYSTEM.md` şemasının dışında dosya/format icat
  etme. Değişiklik gerekiyorsa **önce kullanıcıya öner**; onaylanırsa sürümü
  artır ve `EVOLUTION.md`'ye karar olarak yaz.
- **Token asla dosyaya yazılmaz** (R-005). Kullanıcının token'ı yalnız
  telefonun güvenli deposunda durur; commit'e, log'a, artifact'e girmez.

## 7. İlk oturumda kullanıcıdan öğrenmen gerekenler

İskeleti kurduktan sonra projeyi tanı ve `EVOLUTION.md` Aşama 0 ile
`BACKLOG.md`'ye yaz — bir daha sorulmasın diye:

- Proje ne yapıyor, kime hitap ediyor?
- Bugün nerede duruyor (çalışan bir şey var mı, nerede)?
- İlk hedef ne, neyi başarınca "oldu" denecek?
- Bilinen kısıtlar neler (teknoloji, süre, bütçe, bağımlılık)?

Bunları öğrendikçe `waiting/`e ihtiyacın olursa çekinme: cevap bekliyorsan o
bir bekleyen görevdir.
