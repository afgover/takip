---
id: S-2026-08-21-gorunmez-kuyruk
date: 2026-08-21
status: closed
reconstructed: false
author: afgover
topics: [kuyruk, coklu-hub, sessiz-kayip, baglanti]
artifacts: []
tasks_touched: []
---

# Oturum: B-140 — bağlantısı kaldırılmış repoya ait kuyruk taslağı görünmüyor

## Özet

**Ölçüm, backlog'a yazdığım teşhisi düzeltti.** B-140'ı açarken "taslak
görünmez oluyor" demiştim; ölçünce durum daha ince çıktı ve bence daha kötü.

Sahte iki bağlantı ve üç taslakla koşulan ölçüm şunu gösterdi: bağlantı
silinince taslak kuyrukta **kalıyor** (2 → 2) ve bekleyenler listesinde hiç
görünmüyor — buraya kadar tahmin doğruydu. Ama Ayarlar → Veri satırı
`outboxProvider`'ın **tamamını** okuyor, yani öksüz taslak **sayılıyor**.
Kullanıcı "2 görev kuyrukta" görüyor, birini bulabiliyor, diğerinin nerede
olduğunu hiçbir yerden okuyamıyor.

**Asıl kusur görünmezlik değil, tutulamayan bir sözdü.** O satırın alt yazısı
"Bağlantı gelince gönderilecek" diyor; öksüz taslak için bu yanlış — bir daha
hiç gönderilmeyecek. "Şimdi göndermeyi dene" düğmesi de onun için sessizce
hiçbir şey yapmıyor (`flush` hedefi bulamayınca kuyrukta bırakıyor). Silme
diyaloğu sayıyı söylüyor ama ne yapılacağını sormuyor.

**Karar (kullanıcı): Ayarlar'da ayrı gösterilsin, söz düzeltilsin.** Silme
kullanıcı kararı kaldı — `flush`'ın "kendiliğinden atma" kararı bilinçliydi
ve korundu; ama sakladığını gösteremeyen bir koruma da sessiz kayıptır.

Kuyruk artık **tek geçişte** ikiye ayrılıyor (`QueueSplit`). İki ayrı süzgeç
yazılsaydı zamanla ayrışabilir, aynı taslak hem "gönderilecek" hem
"gönderilemez" sayılabilirdi; tek geçiş, iki yarının toplamının her zaman
kuyruğun tamamına eşit olmasını garanti ediyor ve test bunu ölçüyor.

**Ölçüm:** `flutter analyze` temiz, **622 test** (612 + 10).

## Kayıt

### Kullanıcı
> b140

### Agent — ölçüm (tahmin değil)

Ölçüm sahte iki bağlantı ve üç taslakla koşuldu:

```
SİLMEDEN ÖNCE   outbox: 2  ·  bekleyenler: (A işi)
SİLDİKTEN SONRA outbox: 2  ·  bekleyenler: (A işi)
                (A işi@a/bir, B işi@b/iki)   kalan bağlantı: (a/bir)
```

Ölçüm bittikten sonra geçici test dosyası **silindi**; kalıcı karşılıkları
`active_repo_scope_test.dart`'taki regresyon testleri.

### Agent — düzeltme

- `QueueSplit` — kuyruğun iki yarısı tek geçişte, tek sınıfta.
- Ayarlar → Veri: gidebilecekler ve gönderilemeyenler **ayrı satır**. Öksüz
  satırı hangi repoyu beklediğini yazıyor, çünkü çıkış yolu repoyu geri
  eklemek: eklenince taslak kendiliğinden gidiyor (test bunu da ölçüyor).
- `Outbox.discardForRepos` — silme **repo bazında**, çünkü kullanıcının
  ekranda gördüğü şey "şu repoya ait N görev". Taslak kimliğiyle silmek,
  listeyi gördüğü an ile düğmeye bastığı an arasında kuyruk değişirse yanlış
  kaydı silebilirdi.
- Silme onaya bağlı: hiç gönderilmemiş, kullanıcının yazdığı bir iş siliniyor
  ve geri getirilemiyor.

**Damgasız taslak öksüz sayılmıyor.** T-003 öncesi kayıtlar damgasızdır ve
hedefleri "aktif repo" diye yorumlanıyor; öksüz saymak, gidebilecek bir işi
"gönderilemez" göstermek olurdu.

**Ölçüm:** `flutter analyze` temiz, **622 test**.
