---
id: A-2026-10-14-001
session: S-2026-10-14-coklu-kullanici-sync
type: analysis
title: "Çoklu kullanıcı, senkron ve mesajlaşma"
created: 2026-10-14T07:54:00Z
---

# Çoklu kullanıcı, senkron ve mesajlaşma

## Özet

Senkron sağlam ama yalnız uygulama açıkken çalışıyor; bildirim yok. Ayrı
bir mesajlaşma sistemi önerilmez: kararı iki yere böler, ajan okuyamaz.
Önerilen sıra: hub içinde "kime" ve yorum, Android paylaş menüsü, gecikme
ölçülüp acıtırsa push (B-060). Görev ekranı "bana göre" görünümlere
bölünmeli. Önerinin ağırlığı "Fatih Gover kim" sorusuna bağlı (§3).

## Kapsam ve yöntem

- Uygulama kodu dosya ve satır düzeyinde haritalandı; kritik iddialar
  ayrıca elle doğrulandı.
- Hub'daki önceki kararlar okundu: K-003, K-017, K-036, B-060, B-061,
  B-108..110 ve çoklu kullanıcı analizi A-2026-08-06-001.
- 14 reponun 2026-08-15'ten beri commit yazarları sayıldı.
- Dış dünyaya dair üç iddia birinci kaynağından doğrulandı (GitHub ve
  Slack belgeleri).
- [DOGRULANMALI] Kişi sayısı, kullanım sıklığı ve hangi hubın yoğun
  olduğu ölçülemedi; bunlar §6'daki sorularda.

## 1. Bugünkü senkron

- Uygulama açıkken her bağlı hubın son commit'ini 45 saniyede bir soruyor
  (ayarlardan 30 sn ile 5 dk arası). ETag kullanıldığı için değişiklik
  yoksa cevap 304 geliyor ve GitHub'ın istek kotasından düşmüyor.
- Değişiklik görülünce yalnız değişen dosyalar iniyor; yerel kopya
  çevrimdışı okunabiliyor.
- Uygulama arka planda ya da kapalıyken **hiçbir şey olmuyor**. Bildirim
  yok; projede bildirim eklentisi de yok.
- Yazma: her kayıt bir commit. Uygulama yalnız **yeni dosya** açıyor
  (inbox, notes); aynı ada denk gelirse `-2`, `-3` diye ayırıyor. Bu
  yüzden iki kişinin yazması pratikte çakışmıyor.
- Çevrimdışı yazılanlar kuyrukta bekliyor, bağlantı gelince gidiyor.
- Ajan tarafı oturum açılışında ve 30 dakikada bir inbox'a bakıyor;
  görevin ilk dokunuşa kadar bekleme ortancası 0,1 saat (denetim §8).

**Sonuç:** yazma modeli çok kullanıcıya hazır. Eksik olan **haber
almak**: bir kişi için gecikme "uygulamayı açana kadar".

## 2. Çoklu kullanıcı bugün

- Kimlik var: her bağlantı kendi GitHub kullanıcı adını biliyor, görev ve
  notlara yazar (`author`) işleniyor (sözleşme 1.15).
- `for` ("kimi bekliyor") okunuyor ama listede kullanılmıyor: bekleyen
  her görev herkese aynı "Seni bekliyor" etiketiyle görünüyor.
- `assignee` ("kim üstlendi") sözleşmede tanımlı, uygulamada hiç yok.
  B-110 bunu bilinçli olarak "ikinci kişi gelince"ye bırakmıştı.
- "Cevapladım" bilgisi cihazda tutuluyor; iki kişi aynı soruyu birbirinden
  habersiz cevaplayabilir.
- Görev listesi yalnız aktif hubı gösteriyor. Birleşik liste denenmiş ve
  "hangi projedeyim" karışınca bilinçli olarak geri alınmış.

**Kullanım ölçümü:** 14 repoda commit'lerin neredeyse tamamı tek GitHub
hesabından (`afgover`). Tek istisna "Fatih Gover": portfoyinfo'da 12,
takip'te 3 commit, hiçbiri bir GitHub hesabına bağlı değil.

## 3. Mesajlaşma gerekli mi

### Aslında dört ayrı ihtiyaç

| İhtiyaç | Örnek | Bugün |
|---|---|---|
| Haber almak | "sana görev geldi" | Yok |
| Yönlendirmek | "bunu Fatih yapsın" | Yarım: for var |
| Görev üzerine konuşmak | "şu kısmı netleştir" | Yok |
| Anlık sohbet | hızlı soru, ses | Kapsam dışı |

"Mesajlaşma" dendiğinde çoğu zaman ilk üçü kastediliyor. İlk üçü hub'ın
içinde çözülebilir; dördüncüsü için en iyi araç zaten cebinizde olan
sohbet uygulamasıdır.

### Seçenekler

| Seçenek | Kazanç | Bedel |
|---|---|---|
| Slack | Anlık, olgun | Ücretsizde 90 gün görünür |
| Telegram, WhatsApp | Herkeste var | Karar hub dışında kalır |
| GitHub Issues | Bahsetme bildirimi | İkinci görev sistemi |
| Hub içi yorum ve atama | Tek kaynak, ajan okur | Anlık değil |
| Push servisi (B-060) | Saniyede haber | Küçük servis işletmek |
| Kendi sohbetimiz | Yok | GitHub sohbet için değil |

- **Dış sohbet uygulamaları.** Asıl bedel teknik değil: karar iki yerde
  yaşamaya başlar. Hub'ın varlık sebebi bilgiyi tek yerde toplamak; "kişi
  başına ayrı hub" seçeneği de aynı gerekçeyle reddedilmişti
  (A-2026-08-06-001). Sohbette alınan karar ajanın göremediği bir karardır.
  Slack'in ücretsiz planında mesajlar 90 gün sonra görünmez oluyor, bir
  yıldan eskiler siliniyor.
- **GitHub Issues.** GitHub Mobile yalnız bahsetme, atama, inceleme isteği
  ve dağıtım onayında bildirim gönderiyor; düz commit'ler bildirim
  üretmiyor. Bildirimi bedavaya almak için görevleri issue'ya taşımak
  gerekir, bu da dosya tabanlı görev modelinin yanına ikinci bir sistem
  kurmak demek.
- **Kendi sohbetimiz.** Her mesajın bir commit olması GitHub'ı sohbet
  sunucusu gibi kullanmak olur; GitHub'ın kendisi sorgulamak yerine
  webhook öneriyor ve sohbet trafiği commit geçmişini boğar.
- **Push servisi.** K-017'nin tespiti hâlâ geçerli: geriye kalan tek gerçek
  boşluk bildirim gecikmesi. Tasarım hazır (B-060): webhook, veri taşımayan
  ve token tutmayan bir aracı fonksiyon, telefona push; veri yine uygulamanın
  kendi token'ıyla GitHub'dan çekilir. Bedeli küçük de olsa bir servis
  işletmek (K-001).

### Öneri

1. **Hub içinde yönlendirme ve konuşma** (servis yok): görevi birine
   atamak, "bana gelenler" görünümü ve görev başına yorum akışı. Yorum,
   mevcut dosyayı değiştirmeden **yeni küçük bir dosya** olarak yazılır;
   böylece uygulamanın çakışmasız yazma özelliği korunur.
2. **Android paylaş menüsü:** herhangi bir sohbet uygulamasındaki bir
   mesajı tek dokunuşla takip'e görev ya da not olarak göndermek. Sohbet
   istenen uygulamada sürer, karar ve iş hub'a girer. Servis gerektirmez.
3. **Push (B-060), ölçüme bağlı:** kişiden kişiye görevlerde ilk dokunuşa
   kadar geçen süre ölçülür; acıtıyorsa kurulur.
4. **Slack önerilmez:** küçük bir ekip için ek bir uygulama, ücretsiz
   planda geçmiş kısıtlı.

[KARAR] Öneri iki senaryoya göre ağırlık değiştiriyor:

- **Fatih Gover sensen** (başka makine ya da ortam): gerçek ikinci kişi
  yok, büyük çoklu kullanıcı yatırımı erken (B-110'un gerekçesi geçerli).
  O ortamın git kimliği `afgover` hesabına bağlanmalı, yoksa commit'ler
  hiçbir hesaba bağlı görünmeye devam eder.
- **Fatih ayrı bir kişiyse:** commit'leri hiçbir GitHub hesabına bağlı
  değil. Bu, K-017'nin kararı yeniden açma ölçütlerinden birini
  ("GitHub hesabı olmayan kullanıcı") tetikler. [RISK] Senin token'ınla
  yazıyorsa kimlik ve izin ayrımı yok. Öneri: kendi ücretsiz GitHub hesabı,
  repoya ortak çalışan izni ve uygulamada kendi token'ı.

## 4. Çoklu kullanıcılı görev ekranı

### Bugünkü ekranın sorunları (ölçüldü)

- Tek liste; yalnız kategori ve öncelik süzgeci. Kişiye göre süzme ya da
  gruplama, arama yok.
- "Seni bekliyor" herkese aynı görünüyor.
- Satırda eylem yok; detay ekranında taşıma, düzenleme, atama yok.
- Yazar listede görünmüyor.
- [BLOKER] Hata: soru cevaplandıktan ya da çevrimdışı kuyruk boşaldıktan
  sonra yanlış liste yenileniyor; ekran bir sonraki sorgulamaya kadar,
  45 saniyeye kadar eski kalıyor. "Hantal" hissinin bir kaynağı bu.

### Önerilen tasarım

**Üstte dört görünüm:**

- **Bana:** bana atanan, beni bekleyen, bana yorum gelen.
- **Açtıklarım:** yazarı ben olan.
- **Ekip:** herkes, kişiye göre gruplu.
- **Ajanlar:** ajanların açtığı ve ajanların sorduğu.

**Satır:** başlık; yazar ve sorumlu için küçük avatarlar (GitHub kullanıcı
adından); bekleme süresi; bekleyen soruda seçenek sayısı; okunmamış
işareti.

**Kaydırma eylemleri:** sağa "Üstlen" (sorumlu ben, aktife geçer), sola
"Bitir" ya da "Cevapla"; uzun basınca "Ata", "Yorum", "Öncelik".

**Detay:** üstte durum, yazar, sorumlu; ortada gövde; altta zaman sıralı
yorum akışı ve yazma kutusu. Bekleyen sorunun seçenekleri olduğu gibi
kalır, ama cevaplandı bilgisi cihazda değil hubda tutulur.

**Ekran genelinde:** başlık ve gövdede arama (`tool/ara.sh`'taki harf
katlama uygulamaya taşınabilir) ve kaydedilebilen görünümler.

### Veri tarafının ön koşulları

- Atama ve yorum için uygulamanın yazma alanının genişlemesi gerekiyor.
  R-001 bugün uygulamaya yalnız inbox'ı (sonradan notlar eklendi) veriyor.
  En güvenli yol: atama ve yorum **yeni dosya** olarak yazılır, mevcut
  dosyaya dokunulmaz. [KARAR]
- `for` alanının listede gerçekten kullanılması.
- "Cevaplandı" bilgisinin hubda tutulması.
- Yorum dosyasının biçimi sözleşmeye girer (1.37).

## 5. Aşamalar

| Aşama | İçerik | Ön koşul |
|---|---|---|
| 0 | Liste hatası, for ve yazar | Yok |
| 1 | Bana/Ekip görünümü, paylaş | Yok |
| 2 | Yorum ve atama dosyaları | Sözleşme 1.37 |
| 3 | Push servisi (B-060) | Gecikme ölçümü |
| 4 | GitHub App (B-061) | 3+ kişi |

Aşama 0 ve 1 sözleşmeye dokunmadan, yalnız uygulamada yapılabilir ve
senaryodan bağımsız olarak faydalıdır.

## 6. Senin kararın gerekenler

1. [KARAR] Fatih Gover kim: sen mi, ayrı bir kişi mi? Ayrı kişiyse kendi
   GitHub hesabı var mı?
2. [KARAR] Kaç kişi, hangi hubda yoğun çalışacak (commit'lere göre
   portfoyinfo)? Ne sıklıkla birbirinize iş göndereceksiniz?
3. [KARAR] Şu an sohbet için bir uygulama kullanıyor musunuz? Paylaş
   menüsünün önceliği buna bağlı.
4. [KARAR] Uygulama atama ve yorum için yeni dosya yazabilsin mi (R-001
   genişlemesi)?
5. [KARAR] Aşama 0'a hemen başlanabilir mi? Liste hatası tek başına
   küçük bir düzeltme.
