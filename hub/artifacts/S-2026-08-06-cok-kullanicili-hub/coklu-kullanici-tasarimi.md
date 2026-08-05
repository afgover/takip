---
id: A-2026-08-06-001
session: S-2026-08-06-cok-kullanicili-hub
type: design
title: "Aynı hub'ı birden çok kişi kullandığında karmaşayı önleme"
created: 2026-08-06T02:00:00Z
---

# Aynı hub'ı birden çok kişi kullandığında

Senaryo: aynı projede 2–5 kişi. Herkes görev açıyor, kendi agent'ını koşuyor,
aynı `BACKLOG.md` ve `knowledge/`e yazıyor.

---

## 1. Neyin kırıldığı (ölçüldü, tahmin değil)

### 1.1 Kimlik şemada hiç yok

`created_by` alanı yalnız `user` | `agent` değerini alıyor — bu bir **rol**,
kimlik değil. "Bu görevi kim açtı", "bu kararı kim verdi" sorularının cevabı
hiçbir kayıtta yok. Uygulama GitHub `login`'ini bile bilmiyor: `/user` hiç
çağrılmıyor.

En keskin hâli `waiting/`: sözleşmedeki anlamı "agent **kullanıcıyı** bekliyor".
İki kişi varken bu cümlenin öznesi yok. Kullanıcı A'nın cevaplaması gereken bir
soruyu B görür, ya da ikisi de görmezden gelir çünkü "herhalde diğeri
bakacak".

> Not: git zaten kimliği taşıyor (commit yazarı). Eksik olan, **kaydın
> kendisinin** kimliği taşıması — bir dosyayı okurken `git blame` yapmadan kimin
> yazdığı bilinmiyor ve uygulama zaten git geçmişini satır düzeyinde okumuyor.

### 1.2 Bütün ID'ler tekil sayaç, çakışmaları sessiz

`T-`, `B-`, `L-`, `SK-`, `R-`, `SEC-`, `K-`, `A-` — hepsi "son numarayı bul, bir
artır" ile veriliyor. İki agent aynı anda çalışırsa ikisi de aynı numarayı
seçer. Dosyalar **farklı** olduğu için git bunu çakışma saymaz, push reddedilmez,
test kırılmaz. İki farklı kayıt aynı ID'yi taşır ve buna atıf yapan her satır
belirsizleşir.

Bu, sistemin en sinsi kırılması: her şey çalışmaya devam eder.

### 1.3 Altı dosyaya herkes ekleme yapıyor

`BACKLOG.md` (507 satır), `EVOLUTION.md` (538), `lessons.md` (595),
`SECURITY.md`, `rules.md`, `skills.md`. Bunlar 1.2'nin aksine **gürültülü**
kırılır — git çakışması verir. Yani tehlike değil, sürtünme.

Ama `BACKLOG.md`'de sürtünme daha yüksek: maddeler faz başlıklarının **ortasına**
giriyor, dosya sonuna değil.

### 1.4 `notes/` tanımı gereği tek kişilik

Sözleşme §11: "kullanıcının **kendisi** için aldığı notlar". Ortak bir klasörde
herkesin notu birbirine karışır ve "agent notlara dokunmaz" kuralı, notun
sahibinin kim olduğu bilinmediğinde anlamını yitirir.

---

## 2. Tasarım ilkesi

Bu projenin tekrar eden dersi: **sessiz bozulma, gürültülü bozulmadan kötüdür**
(L-035, L-039, K-035). Çoklu kullanıcıda da ölçü bu olmalı — çakışmayı
imkânsız kılmaya çalışmak yerine, önce **görünür** kılmak.

İkinci ilke: mevcut kayıtlar bozulmasın. Hub'da yüzlerce çapraz atıf var
(`L-035`, `B-102`, `SEC-009`…). ID biçimini değiştiren bir çözüm, bugüne kadarki
bütün referansları ikinci sınıf hâle getirir.

---

## 3. Öneri: dört katman

### Katman 1 — Kimlik (asıl çözüm, en ucuz)

Şemaya iki alan:

```yaml
author: afgover        # kaydı kim oluşturdu (GitHub login)
for: mehmet            # yalnız waiting/: kimden bekleniyor
```

- **Uygulama** `login`'i onboarding'de bir kez `/user`'dan okuyup bağlantıyla
  saklar; her yazdığı göreve/nota koyar.
- **Agent** kendi oturum kaydına ve açtığı görevlere aynı alanı yazar.
- **Bekleyenler ekranı** `for:` alanına göre süzer — "seni bekleyen" gerçekten
  seni bekleyen olur.
- Eksik `author` bir hata değildir: eski kayıtların hepsinde yok ve olmayacak.

Karmaşanın büyük kısmı bu tek katmanla gider, çünkü karmaşanın çoğu "bu kimin
işi" belirsizliğidir.

> **Kimliğin sınırı:** aynı token'ı iki kişi paylaşırsa kimlikler tek kişiye
> çöker. Bu, herkesin kendi token'ını üretmesi için ayrı bir gerekçe (R-005).

### Katman 2 — Çakışmayı sessiz olmaktan çıkar

1. **Tekrarlı ID testi.** Hub dosyalarını tarayıp aynı ID'nin iki kez
   tanımlandığı durumda kırılan bir test. `hub_files_test.dart` zaten gerçek hub
   dosyalarını okuyor; aynı yere eklenir. Çakışma böylece **bir sonraki test
   koşumunda** yakalanır ve düzeltmesi tek satır (birini yeniden numarala).
2. **Protokole pencere daraltma.** ID atamadan hemen önce `git pull --rebase`,
   attıktan hemen sonra push. Çakışma penceresi saniyelere iner.

Bu ikisi çakışmayı imkânsız kılmaz — **görünür** kılar. İlkeye uygun ve maliyeti
neredeyse sıfır.

### Katman 3 — Kim neyi ele alıyor

İki kişinin aynı görevi aynı anda yapması, ID çakışmasından daha pahalı bir
karmaşa. Klasör-durum modeli bunu zaten yarı yarıya çözüyor (`active/` = "ele
alındı"), eksik olan **kimin** aldığı:

```yaml
assignee: afgover      # active/'e taşıyan kendini yazar
```

Kural: `inbox/`ta duran bir işi almak = `active/`e taşımak **ve** `assignee`
yazmak. Zaten atomik bir hareket (dosya taşıma) olduğu için ikinci bir kilit
mekanizmasına gerek yok; git, aynı dosyayı iki kişinin taşımasını çakışma
olarak verir.

### Katman 4 — Paylaşılan dosyalar

Kod değil, **yazım kuralı**:

- Yeni kayıtlar dosyanın **sonuna** eklenir (knowledge ve SECURITY zaten öyle).
- `BACKLOG.md` istisna: maddeler faz içine giriyor. Kural — yeni madde ilgili
  fazın **sonuna** eklenir, araya sokulmaz.
- Var olan bir kaydı **yeniden düzenlemek** (biçim değiştirme, sıralama) tek
  başına bir commit olur ve aynı oturumda başka değişiklikle karıştırılmaz.

Bunlar çakışmayı bitirmez ama otomatik birleşebilir hâle getirir.

---

## 4. Reddedilen alternatifler

| Alternatif | Neden değil |
|---|---|
| **ID'lere kullanıcı öneki** (`T-afgover-011`) | Çakışmayı yapısal olarak bitirir ama bugüne kadarki bütün ID'ler ve yüzlerce çapraz atıf ikinci sınıfa düşer; iki biçim kalıcı olarak yan yana yaşar |
| **Zaman/rastgele ID** (`T-20260806-3f2a`) | Aynı sorun, üstüne okunabilirlik ve sıra kaybı. `B-102`'nin `B-101`'den sonra geldiğini görmek gerçek bir değer |
| **Kişi başına numara bloğu** (A: 100-199) | Katı ve israflı; blok dolunca ne olacağı belirsiz |
| **Branch + PR per oturum** | Git'in gerçek cevabı ve 5+ kişide doğru olabilir. Ama uygulama Contents API ile **sabit bir branch'e** yazıyor; branch desteği eklemek uygulamada ciddi iş. 2-5 kişide maliyeti faydasından büyük — açık kalsın, ölçek büyürse yeniden değerlendirilir |
| **Kişi başına ayrı hub** | Karmaşayı çözer ama hub'ın varlık sebebini yok eder: ortak karar, ortak ders, ortak yol haritası. Zaten dağılmış bilgiyi toplamak için var |

---

## 5. Uygulama sırası

1. **Katman 1** (kimlik) — sözleşme + uygulama + `/user` çağrısı. Tek başına
   dağıtılabilir ve en çok faydayı verir.
2. **Katman 2** (tekrarlı ID testi + protokol maddesi) — küçük, kodda birkaç
   satır.
3. **Katman 3** (`assignee`) — sözleşme maddesi; uygulamada yalnız gösterim.
4. **Katman 4** — yalnız `AGENT_PROTOCOL.md`'ye yazım kuralı.

1–3 sözleşme değişikliği, yani sürüm artışı gerektirir.

---

## 6. Açık sorular

- **`notes/` ne olacak?** İki seçenek: (a) `notes/<login>/` alt klasörü — app'in
  yazma kapısı (`HubFolder`) kullanıcı boyutunu öğrenmeli; (b) düz kalsın,
  ayrım `author:` alanıyla yapılsın ve uygulama süzsün. (b) daha az yapısal
  değişiklik ama "agent notlara dokunmaz" kuralını zayıflatır — agent artık
  hangi notun kime ait olduğunu **alan okuyarak** bilir, klasörden değil.
- **Eski kayıtlar geriye dönük etiketlenecek mi?** Öneri: hayır. `author`
  alanının yokluğu "tek kullanıcı dönemi" demektir ve bu bilgi zaten doğru.
