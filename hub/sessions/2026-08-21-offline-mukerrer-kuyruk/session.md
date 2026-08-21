---
id: S-2026-08-21-offline-mukerrer-kuyruk
date: 2026-08-21
status: closed
reconstructed: false
author: afgover
topics: [offline, kuyruk, bekleyen-gorevler, mukerrer]
artifacts: []
tasks_touched: [T-018]
---

# Oturum: Bekleyen görev offline tamamlanınca mükerrer kuyruğa giriyor

## Özet

Telefondan düşen tek bir bildirimle açıldı ve bildirimin **tarif ettiğinden
geniş** bir kusur çıktı.

**Kök neden çevrimdışılık değildi.** "Bu bekleme bildirildi" bilgisi detay
ekranının widget durumunda (`_reported`) yaşıyordu ve ekran kapanınca ölüyordu.
Görev `waiting/`ten ancak agent işleyince çıktığı için (app dosyayı taşıyamaz,
R-001) liste onu göstermeye devam ediyor; ekrana dönen kullanıcı ikinci bir
bildirim üretebiliyordu. Çevrimiçinde de aynıydı — çevrimdışı yalnız
**görünür** kılıyordu: iki taslak kuyrukta yan yana duruyor, `flush` ikisini de
yazıyor (ikincisi `-2.md`). Çevrimiçinde iki dosya agent'ın inbox'ında
birikiyor ve kimse saymıyor. Kapsam kullanıcının gördüğü koşulla
sınırlansaydı düzeltme "geçti" görünüp aynı hata başka kılıkta duracaktı
([L-051](../../knowledge/lessons.md#L-051)).

**Çözüm tek kayıt.** Bilgi cihazda kalıcı bir kayda taşındı
(`lib/hub/reported_waiting.dart`); doğrudan giden bildirim de kuyruğa düşen de
onu yazıyor. Kuyruktaki taslağa ayrıca "hangi beklemeyi cevaplıyorum" alanı
**konmadı** — aynı olgu iki yerde tutulmasın diye. Kayıt görev `waiting/`ten
çıkınca düşüyor ve bu, senkronun silinmiş belge temizliğiyle **aynı yerde**
duruyor: ikisi de tek bir ölçüme dayanıyor ("bu dosya hub'da artık yok").

**Görünürlük korundu (kullanıcı kararı).** Bildirilmiş satır listeden
gizlenmiyor; rozeti "Bildirildi" oluyor ve düğmeleri kapalı geliyor. Gizlemek,
agent işlemezse sessiz kayıp demekti — K-022'nin çözdüğü sorunun aynısı.

**Yan iş:** süitin "en fazla bir oturum açık" ölçümü, 15 Ağustos oturumunun
`open` bırakıldığını yakaladı; özeti yazılıp kapatıldı.

**Ölçüm:** `flutter analyze` temiz, **604 test** (586 + 18).

## Kayıt

### Kullanıcı
> son durum

### Agent — durum ölçüldü

`flutter analyze` temiz, **586 test** geçti, sözleşme 1.26 ana kopyayla farksız.
Uzakta bekleyen 1 commit vardı: telefondan düşen yeni inbox görevi (`high`).
Son `tarama` (SEC-008) 17 günlük, 30 gün eşiği dolmadı. §13/G-001 idempotent —
iki `waiting/` görevinde de `options` zaten var, dokunulmadı.

### Kullanıcı
> pull et, o offline hatasını yapalım

### Agent — ölçüm: kusur çevrimdışına ait değil

Bildirim ele alındı, [T-018](../../tasks/done/2026-08-21-bekleyen-gorevlerin-offline-da-tamamlanmasi.md)
numarası verildi. Kök neden `_WaitingBannerState._reported` alanı çıktı: ekran
ömrü kadar yaşayan bir bayrak, kalıcı bir olguyu tutuyordu. İki gönderim yolu
(doğrudan / kuyruk) da aynı bayrağa bakıyordu, dolayısıyla ikisi de aynı
şekilde kırıktı.

Kullanıcıya iki soru soruldu, ikisi de önerilen seçenekle cevaplandı:
bildirilmiş satır **listede kalsın** (gizlenmesin), kapsam **iki yolu birden**
alsın. Plan [P-010](../../PLAN.md) uygulamadan önce yazıldı (sekiz adım).

### Agent — düzeltme ve ölçüm

`lib/hub/reported_waiting.dart`: repo + görev yolu → zaman. Anahtarın repoyu
içermesi bilinçli — yol hub-göreli, tek başına görevi tanımlamıyor ve bir hub
diğerinin düğmesini kilitlerdi ([L-045](../../knowledge/lessons.md#L-045)).

Üç ayrı cevap tutuluyor (evet / hayır / bilinmiyor): kayıt yüklenirken düğme
**kapalı** — "bilmiyorum" hâlinde açık bırakmak, önlenmek istenen mükerrer
bildirimi davet ederdi. Kayıt **okunamazsa** (hata) düğme açılıyor: bozuk bir
yerel kayıt yüzünden kullanıcının işini bildirememesi daha ağır bir kusur.

Regresyon testleri hatanın kendisini kuruyor: aynı ekranda ikinci dokunuş değil,
**ekranın yeniden açılması**. Çevrimdışı ölçümü diskteki kuyruk kaydından
okunuyor — mükerrer kayıt orada oluşuyordu.

**Ölçüm:** `flutter analyze` temiz, **604 test** (586 + 18).
