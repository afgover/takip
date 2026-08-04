---
id: S-2026-08-03-bos-secim-nota
date: 2026-08-03
status: closed
reconstructed: false
topics: [isaretleme, secim, not, inbox, akis]
artifacts: []
tasks_touched: []
---

# Oturum: Notsuz seçim göreve değil nota gider

## Özet
Uygulamanın en sık yaşanan gürültüsü kapatıldı: **boş (notsuz) seçim artık
göreve dönüşmüyor.** Kirlilik tek-dokunuşluk hızlı işaretlerden (Sarı/Kırmızı)
geliyordu — bunlar not sormadan `tasks/inbox`'a `yorum`/`duzeltme` görevi
yazıyor, "Yoğun", "temalı" gibi tek kelimeler Bekleyen görevler'i dolduruyordu.
(financer_takip hub'ında bu tür 8 boş seçim aynı gün elle ayıklanmıştı; kök
neden buradaymış.)

**Karar (kullanıcı seçti): notsuz seçim → `notes/`.** İşaret belgede kalır ama
iş kuyruğuna girmez; not yazılırsa "sen şunu yap" niyetidir → görev. Uygulamanın
zaten olan not/görev ayrımına (§11, B-088) oturuyor. Bu, **B-088'in** "sarı
işaret/kırmızı çizgi bilerek göreve gitmeye devam ediyor" kararını **tersine
çeviriyor** — o zaman işaretler "agent'a sinyal" sayılmıştı; kullanımda notsuz
işaret sinyal değil gürültü çıktı.

Tek karar noktası `AnnotatedDocument._create`: not boşsa `createNote`'a
yönlendiriyor (hem hızlı işaretleri hem "Görev oluştur" sayfasını kapsıyor).
`TaskDraft.note`/`createNote`'a `mark` parametresi eklendi ki notsuz sarı/kırmızı
işaret nota düşerken kendi rengini korusun (yeşile zorlanmasın). Sayfada not
boşken buton "İşaret olarak ekle" diyor (şeffaflık — "Görev oluştur"a basıp not
almak şaşırtmasın).

Eski kararı test eden iki test (`selection_flow_test`) yeni davranışa
güncellendi; notlu→görev testi eklendi. `flutter analyze` temiz, **350 test**
geçiyor. Commit `144b1af`. → B-099

## Kayıt

### Kullanıcı
> Boş seçim → görev akışını uygulamada kıs

### Agent
Akış üç yoldan kayıt üretiyordu: hızlı Sarı/Kırmızı (notsuz, tek dokunuş →
`tasks/inbox`), "Görev oluştur" sayfası (not "isteğe bağlı", boş bile geçer),
"Not ekle" (zaten `notes/`). Kirliliğin kaynağı ilk ikisi — özellikle quick
işaretler bilerek notsuzdu (kod yorumu "okurken akışı bölmemek" diyordu).

Boş durum için üç seçenek sunuldu: **(a)** nota yönlendir, **(b)** notu her
yerde zorunlu kıl (tek-dokunuş kalkar), **(c)** yalnız sayfada zorunlu (asıl
kaynağı çözmez). Kullanıcı **(a)**'yı seçti.

Uygulama: `_create`'te not boşsa `createNote`; `mark` parametresi rengi koruyor;
sayfa butonu dinamik. `selection_flow_test`'teki iki eski test yeni davranışa
güncellendi + notlu→görev testi eklendi. analyze temiz, 350 test.

### Kullanıcı
> takip hub'ına backlog + session kaydını da ekle

### Agent
B-099 backlog'a eklendi (tamamlandı, B-088'i tersine çevirdiği not düşüldü;
B-088'in artık yanlış olan "göreve gitmeye devam ediyor" cümlesine işaretçi
kondu). Bu oturum kaydı yazıldı. İki ayrı commit — `backlog:` ve
`session(S-...)` — ki aktivite akışı ikisini de doğru türde göstersin.
