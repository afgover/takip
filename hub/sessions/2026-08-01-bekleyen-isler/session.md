---
id: S-2026-08-01-bekleyen-isler
date: 2026-08-01
status: closed
topics: [gorev-mekanizmasi, sozlesme, waiting]
artifacts: []
tasks_touched: [T-004]
---

# Oturum: Bekleyen işler mekanizması — eksik yön

## Özet
Kullanıcı sordu: agent'ın kullanıcıdan beklediği işler "Bekleyenler"de
görünüyor mu? Ölçüldü: **görünmüyordu**, ve bu bir eksiklik değil, tasarımın
tek yönlü olmasıydı.

Sistem `inbox → active → done` olarak kurulmuştu ve üçünün de anlamı "agent
ele alacak"tı. Görev şemasında sorumlu alanı yoktu. Agent'ın kullanıcıdan
beklediği işler yalnız `BACKLOG.md`'de `(user)` etiketiyle yaşıyordu — 50
maddenin 2'si — ve uygulamada hiçbir yerde görünmüyordu.

**Canlı kanıt aynı gün yaşanmıştı:** B-015 (token üret) ve B-020 (SDK kur)
30 Temmuz'dan 1 Ağustos'a kadar bekledi ve yalnızca agent sohbette
hatırlattığı için ilerledi. Kullanıcının telefonunda hiçbir iz yoktu.

Sözleşme 1.4 ile `tasks/waiting/` eklendi (K-022): agent'ın kullanıcıdan
somut bir şey beklediği durum. Uygulama bu klasörü de okuyor, bekleyenler
listenin **başında** duruyor ve görev detayındaki **"Yaptım"** düğmesi
kapatma yolunu sohbetten çıkarıyor.

`flutter analyze` temiz, **258 test** (11 yeni). Mekanizmanın ilk gerçek
görevi T-004 olarak `waiting/`e kondu.

## Kayıt

### Kullanıcı
> yapilcak isler mekanizmasini ele alalim, ozellikle agentin userdan bekledigi
> isler bekleyenlerde gorunuyorlar mi?

### Agent
Tahmin yerine ölçüldü:

| | |
|---|---|
| "Bekleyenler" | `tasks/inbox/` + `tasks/active/` |
| İkisinin anlamı | "agent ele alacak" |
| Şemadaki alanlar | `id, title, created_by, created, updated, priority, category, tags, session, result` — **sorumlu yok** |
| Durumlar | inbox / active / done — "kullanıcıyı bekliyor" yok |
| Agent→user işler | Yalnız `BACKLOG.md`, `(user)`; 50 maddenin 2'si |

`created_by` alanı var ama o "kim oluşturdu"yu söylüyor, "kim yapacak"ı değil.

Üç yol kullanıcıya sunuldu: yeni klasör, frontmatter alanı, yalnız backlog'u
yüzeye çıkarmak. Kullanıcı **yeni klasör** ve **uygulamadan "Yaptım"
düğmesi**ni seçti.

### Agent — uygulama
**Sözleşme 1.4 (K-022).** `tasks/waiting/` eklendi. Elenen alternatifler
gerekçeleriyle kayda geçti: frontmatter alanı "durum = klasör" ilkesini
(K-004) bozar ve listeleri dosya indirmeden çizilemez hâle getirirdi; yalnız
backlog'u yüzeye çıkarmak ise yol haritası ölçeğindeki işlerle günlük işleri
karıştırırdı. Ölçek ayrımı sözleşmeye yazıldı: kısa vadeli somut işler
`waiting/`, yol haritası işleri backlog.

**R-001 gevşetilmedi.** Kullanıcı işi bitirince app dosyayı taşımıyor,
`inbox/`a bildirim görevi yazıyor; taşımayı agent yapıyor. Böylece "app yalnız
inbox'a yazar" garantisi derleme zamanı sabiti olarak kalıyor. Test bunu
ayrıca doğruluyor: PUT yalnız inbox'a gidiyor, DELETE hiç yok, `waiting/`
dosyasına dokunulmuyor.

**Sıralama.** Kullanıcıyı bekleyenler listenin başında. Tarihe göre
sıralansaydı agent'ın beklediği eski bir iş listenin dibinde kalabilirdi —
görünmemesi zaten çözülen sorundu.

**Protokol.** `AGENT_PROTOCOL.md`'ye 9. madde eklendi: kullanıcıdan bir şey
bekleniyorsa görev açılıp `waiting/`e konur, beklenen şey `## Notlar`a
yapılabilir biçimde yazılır. "Sohbette söylemek yeterli değildir" gerekçesiyle
birlikte.

Mekanizma kendi ilk görevi üzerinde sınandı: **T-004** (bağlantı yedeğini al)
`waiting/`e kondu — kullanıcıya daha önce sohbette söylenmiş ama teyit
edilmemiş somut bir iş.

Yol boyunca bir commit hatası oldu: `B-060` zaten Faz 6'da başka bir maddeydi,
commit mesajı yanlış referans veriyordu; push'lanmadan `B-065` olarak
düzeltildi. Düzeltirken `reset --soft HEAD~2` iki commit'i birleştirdi ve
görev dosyası kod commit'ine karıştı — ayrıştırılıp yeniden commit'lendi.
