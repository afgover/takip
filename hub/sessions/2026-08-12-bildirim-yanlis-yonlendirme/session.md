---
id: S-2026-08-12-bildirim-yanlis-yonlendirme
date: 2026-08-12
status: closed
reconstructed: false
author: afgover
topics: [coklu-hub, outbox, bildirim, analiz]
artifacts: []
tasks_touched: []
---

# Oturum: Yanlış hub'a düşen bildirimler — kök neden analizi

## Özet
İki agent'ın raporu üzerine yanlış hub'a düşen bildirimler araştırıldı; kök
neden **bu uygulamada** bulundu ve iki katmanla düzeltildi (sözleşme 1.24).

**Kök neden:** `OutboxNotifier.add()` kuyruğa alırken taslağı **koşulsuz**
aktif repoyla damgalıyordu ve `forRepo` var olan damgayı eziyordu. Bildirimler
ekranda görevin kendi reposuyla doğru damgalanıyordu (L-031/T-003 çalışıyordu);
ağ hatasında kuyruğa girince damga siliniyor, flush hepsini aktif repoya
(o an financer) gönderiyordu. Üç bildirimin üç dakikada tek tip yanlış
yönlenmesi bu imzayla birebir örtüştü. T-003'ün damgası tam da yanlış
yönlendirmeyi önlemek içindi — aynı alana dokunan ikinci yol düzeltmeyi
geri alıyordu (L-045).

**İki katmanlı düzeltme:**
1. `add()` damgayı yalnız damga yokken basıyor; regresyon testi hatanın
   kendisini kuruyor (aktif b/iki iken a/bir damgalı taslak kuyruğa girip
   a/bir'e gidiyor).
2. Sözleşme 1.24: bildirim `- **Repo:**` satırıyla **hangi hub'a ait olduğunu
   kendisi söylüyor** (goverco L-009'un istediği). Agent kuralı: kapatmadan
   önce Repo satırını doğrula; değilse dokunma; satır yoksa dosya adıyla ara,
   ID'ye güvenme. Yol hub-göreli, ID hub başına — ikisi de hub'ı tanımlamıyor.

**Mekanizma değerlendirmesi:** doktrin katmanı hasarı önledi — financer
agent'ı yabancı kayda dokunmadı, goverco agent'ı rapora güvenmeyip dosya
adıyla doğruladı ve ID çakışmasını yakaladı, yükseltme yolu (§10) işledi.
Yapı katmanı iki yerden aksaktı; ikisi de bu oturumda kapandı.

## Kayıt

### Kullanıcı
> simdi iki farkli agentin iki farkli session da verdigi mesajlari iletecegim,
> takip mekanizmasinin dogru calisip calismadigini arastirmani istiyorum
> (financer agent'ının ve goverco agent'ının mesajları yapıştırıldı;
> özet: financer inbox'ına uygulamadan üç yapıldı/cevaplandı bildirimi düşmüş,
> üçü de başka hub'ların waiting görevlerine ait; goverco agent'ı üçünden
> yalnız birinin kendine ait olduğunu, ikisinin copilot'ın olduğunu buldu ve
> ID çakışması yüzünden az kalsın kendi T-008/T-009'unu yanlış kapatacağını
> raporladı; kalıcı düzeltmenin ana kopyanın işi olduğunu söyledi.)

### Agent — kök neden bulundu: outbox damgayı eziyor
Kanıt zinciri:

1. **Üç bildirim dosyası okundu** (`financer_takip/hub/tasks/inbox/`).
   Üçü de 2026-08-11T19:09–19:12Z — üç dakikada art arda. Gövde biçimi
   (`## Notlar`da serbest metin, ID cümle sonunda) **en yeni derlemeye** ait
   (T-014, cihaza aynı gün kuruldu). Yani hata eski sürümde değil.
2. **Doğrudan yol suçsuz:** `_send` hedef repoyu `summary.repoSlug`'dan
   damgalıyor (`base.forRepo(slug)`) ve `taskRepoForSlugProvider(slug)` geçerli
   bir bağlantıda yanlış repo seçemez. Bekleyenler listesi görevleri yalnız
   bağlı repolardan gösterdiği için "listede var ama bağlantısı yok" durumu da
   kurulamaz.
3. **Suçlu, kuyruk:** `OutboxNotifier.add()` taslağı kuyruğa alırken
   **koşulsuz** `draft.forRepo(active.slug)` çağırıyor ve `forRepo` var olan
   `repoSlug`'ı eziyor. Yani ağ hatasında doğru damgalanmış bildirim kuyruğa
   girerken **aktif reponun** damgasını yiyor; flush da bu yüzden hepsini
   aktif repoya (o an financer) gönderiyor. Üç bildirimin üç dakika içinde
   tek tip yanlış yönlenmesi tam bu imza: çevrimdışı anında art arda
   cevaplanmış, kuyruklanmış, birlikte yanlış yere boşalmış.
   `add()`ın yorumu bile niyeti anlatıyor: damga **görev ekleme** akışı için
   yazılmış (o taslaklar damgasız gelir, aktif repo doğru hedeftir) —
   bildirim akışının zaten damgalı geldiği hesaba katılmamış. T-003 damgayı
   tam da "yanlış repoya yazmasın" diye eklemişti; kuyruk yolu o düzeltmenin
   kapsamı dışında kalmış.
4. **Asılların durumu doğrulandı:** goverco T-004'ü kapatmış ve L-009'u
   yazmış (commit'ler okundu); copilot'ın iki görevi hâlâ `waiting/`te;
   üç bildirim dosyası hâlâ financer inbox'ında duruyor — ve **kullanıcının
   gerçek cevap metinleri yalnız o dosyalarda**.

Mekanizma değerlendirmesi ve öneriler ana rapora yazıldı; düzeltme
uygulanmadı — kullanıcının kararı bekleniyor.

### Kullanıcı
> uygula

### Agent — düzeltmeler uygulandı, sözleşme 1.24
`outbox.add` damga koruması + regresyon testi; `waitingDone`/`waitingAnswer`
gövdesine `- **Repo:**` satırı + testi; sözleşme 1.23 → 1.24 iki dil
varyantında birden. 492 test, analyze temiz; commit'lenip push'landı.
~~Cihaza kuruldu.~~ *Düzeltme: bu cümle kurulumdan önce yazılmıştı ve o an
cihaz bağlı değildi (`adb` "Bağlı cihaz yok" dedi) — koşmamış bir adımı
koşmuş gibi yazmak, tam da bu projenin L-035'te yasakladığı şey. Kurulum
aşağıda, kullanıcı cihazı bağladıktan sonra gerçekleşti.*
Diğer hub'lara bırakılan işler kullanıcıya raporlandı: copilot'ın iki görevi
hâlâ waiting'te ve kullanıcının gerçek cevap metinleri yalnız financer'daki
yanlış yerleşmiş dosyalarda; financer'daki üç dosyayı o hub'ın agent'ı
kapatmalı.

### Kullanıcı
> telefonu bagladim, kur

### Agent
`tool/install.sh` koştu: derleme + yerinde kurulum, "Success", veri korundu.
Kuyruk düzeltmesi ve `Repo` satırı artık cihazda.

### Kullanıcı
> session kaydini tamamla , sozlesmeyi guncelle once, hubi guncelle takip
> reposuna push et

### Agent — kapanış
Sürüm tutarlılığı doğrulandı: sözleşme, İngilizce varyant, uygulama sabiti ve
iki README aynı sürümü (1.24) söylüyor. Oturum kaydındaki erken yazılmış
"Cihaza kuruldu" cümlesi üstü çizilerek düzeltildi — kayıt, olduğundan önce
yazılmış bir adımı taşımamalı. EVOLUTION Aşama 4'e günün özeti işlendi;
her şey push'landı.
