---
id: S-2026-08-12-bildirim-yanlis-yonlendirme
date: 2026-08-12
status: open
reconstructed: false
author: afgover
topics: [coklu-hub, outbox, bildirim, analiz]
artifacts: []
tasks_touched: []
---

# Oturum: Yanlış hub'a düşen bildirimler — kök neden analizi

## Özet
(oturum kapanışında yazılacak)

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
