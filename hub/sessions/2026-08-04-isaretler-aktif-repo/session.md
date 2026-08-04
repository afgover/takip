---
id: S-2026-08-04-isaretler-aktif-repo
date: 2026-08-04
status: closed
reconstructed: false
topics: [isaretler, coklu-repo, sozlesme-1.13]
artifacts: []
tasks_touched: []
---

# Oturum: İşaretler listesi aktif repoya bağlandı

## Özet
Uygulama cihaza kuruldu ve **kullanımın ilk saatinde** 1.12'nin bir kararı geri
alındı: işaretler listesi bütün repoları birleştiriyordu, **aktif repoya**
bağlandı (sözleşme 1.13, B-106).

Gerekçe K-034'te: bir listenin kapsamı, listedeki kaydın ne işe yaradığına göre
seçilir — "birleştirebiliyoruz" gerekçe değil. İşaret bir belgedeki **yeri**
hatırlatır, belge de bir projeye aittir; hepsi tek listede olunca ekran bağlam
yığınına dönüyor. Bekleyenler bilinçli olarak birleşik kaldı, çünkü oradaki
soru başka: "hangi projede olursa olsun **bende** bekleyen ne var" (B-067).

Ekrana hangi reponun listesi olduğu yazıldı — yazmasa kullanıcı eksik bir
listeyi tam sanardı, ki bu boş liste görmekten kötüdür. `AnnotationEntry`
kalktı (repo etiketi artık satır başına değişmiyor), `allAnnotationsFrom` →
`annotationsIn`. Hedef belge hâlâ kaydın **kendi** `repoSlug`'ından okunuyor:
bugün ikisi aynı ama "listedeki her şey aktif repodandır" varsayımını koda
gömmek L-031'e açık kapı bırakırdı.

399 test, analyze temiz. Yeni APK cihaza kuruldu (yerinde güncelleme, veri
korundu).

Döngünün kendisi kayda değer: özellik sabah yazıldı, akşam cihazda denendi,
aynı gün düzeltildi ve düzeltme sözleşmeye işlendi — Aşama 4'ün hedefi (B-052)
tam olarak bu.

## Kayıt

### Kullanıcı
> telefona kur

### Agent
Release derlenip cihaza (SM F731B) yerinde kuruldu — `tool/install.sh`,
`adb install -r`. `firstInstallTime` 2026-08-01'de kaldı, yani paket
kaldırılmadı ve token'lar korundu (L-014/L-016 yolundan geçildi).

### Kullanıcı
> isaretler tum repolar olmasin, hangi repo secili ise o reponun isaretleri
> goruntulensin

### Agent
Kullanımdan gelen ilk geri bildirim, özelliğin kendisinden bir gün bile
sonra değil — aynı gün. Doğrusu da bu: liste "her yerdeki her işaret" olunca
hangi projede olduğun kayboluyor ve ekran bir bağlam yığınına dönüşüyor.
Uygulamanın geri kalanı zaten **aktif repo** kavramıyla çalışıyor (üstteki
repo şeridi, Bekleyenler dışındaki her liste); işaretler bunun dışında
kalmıştı.

**Yapılanlar:** `repoAnnotationsProvider` yalnız aktif bağlantıyı tarıyor;
başlıkta repo adı; `AnnotationEntry` kaldırıldı (liste tek repoya ait olduğu
için repo etiketi satır başına değişmiyor, kartta yerine işaretin adı var);
`annotationsIn` tek bağlantı alıyor, yani başka repo sızması **yapısal olarak**
mümkün değil — test bunu sabitliyor.

Sözleşme 1.13 §11'e düzeltme notu düşüldü (1.12'nin cümlesi silinmedi, neyin
neden değiştiği yazıldı). Kurulum talimatı, README ve `Hub.contractVersion` da
1.13'e çekildi. → B-106, K-034
