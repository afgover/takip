---
id: S-2026-08-21-hub-ayrimi
date: 2026-08-21
status: closed
reconstructed: false
author: afgover
topics: [coklu-hub, gorev, kimlik, kurulum]
artifacts: []
tasks_touched: []
---

# Oturum: Görevlerde "hangi hub" ayrımı — iki taraflı doğrulama

## Özet

Kurulum öncesi istenen doğrulama yapıldı: görevlerde "hangi hub" ayrımı **iki
taraf için de** — agent'ın okuduğu dosya ve kullanıcının gördüğü ekran —
yüzey yüzey ölçüldü. **İki boşluk** çıktı ve ikisi de aynı ilkenin eksik
uygulanmasıydı; ikisi de giderildi ([B-139](../../BACKLOG.md#B-139)).

**(a) Agent tarafı.** Bildirim, seçim kaydı ve not gövdelerinde
`- **Repo:**` satırı vardı (sözleşme 1.24) ama **normal görevde yoktu** —
`TaskDraft.create` bu parametreyi hiç almıyordu. Oysa 1.24'ün gerekçesi
görevin **türüne** bağlı değil: yol hub-göreli, ID hub başına, ikisi de hub'ı
tanımlamıyor. Yanlış hub'a düşen bir görev, [L-045](../../knowledge/lessons.md#L-045)'teki
bildirimlerle tam olarak aynı sebepten teşhis edilemezdi. Bugünkü
[T-018](../../tasks/done/2026-08-21-bekleyen-gorevlerin-offline-da-tamamlanmasi.md)
tam da böyle bir görev — dosyasında hangi hub'a ait olduğu yazmıyor.

**(b) Kullanıcı tarafı.** `RepoSwitcher` kabukta duruyor, yani dört sekmenin
hepsinde aktif repo görünüyor. Ama görev **detay ekranı** `push` ile açılıyor
ve kendi `Scaffold`'unu getirdiği için şeridi örtüyor; meta rozetlerinde de
repo yoktu. Bu, "Yaptım" ve "Cevabı gönder" düğmelerinin bulunduğu ekran —
yani **yazmanın hedefi görünmüyordu**. L-045'in kullanıcı tarafındaki
karşılığı. Rozet kondu; `doneTasksProvider` damga basmadığı için
tamamlananlarda çalışmayacaktı, o da düzeltildi.

**Bitişik bir bulgu kapsama katılmadı, kayda geçti**
([B-140](../../BACKLOG.md#B-140)): bağlantısı kaldırılmış bir repoya ait kuyruk
taslağı **görünmez** oluyor — `flush` onu bilinçli saklıyor ama
`queuedForActiveRepoProvider` yalnız kendi reposu aktifken gösteriyor ve o
repo bir daha aktif olamıyor. Sakladığını gösteremeyen bir koruma, sessiz
kayıptır. Ayrı kusur, ayrı karar.

**Kurulum yapıldı.** Telefondaki uygulama 13 Ağustos'tan kalmıştı; aradaki
dört işlevsel değişiklik (B-131/B-132, B-103, B-133, B-135) cihazda yoktu —
yani kullanıcının bugün bildirdiği hatanın düzeltmesi de repoda durup
telefonda çalışmıyordu. `tool/install.sh --no-build` ile **yerinde**
güncellendi.

**Ölçüm:** `flutter analyze` temiz, **612 test** (604 + 8); kurulum sonrası
`firstInstallTime` **değişmedi** (2026-08-01), yani kaldırma olmadı ve veri
korundu; uygulama açıldı, süreç ayakta, çökme izi yok.

## Kayıt

### Kullanıcı
> kurmadan once gorevlerde hem ajanin hem de userin gorecegi hangi hubi
> ilgilendirdigi ayriminin net olarak yapildigini dogrula eksik varsa gider,
> sonra teefona kur

### Agent — doğrulama: yüzey yüzey

| Yüzey | Durum |
|---|---|
| Bildirim gövdeleri (`waitingDone`, `waitingAnswer`) | ✓ `Repo` satırı var (1.24) |
| Seçim kaydı (`fromSelection`), not (`note`) | ✓ `Repo` satırı var |
| **Normal görev** (`create`) | ✗ **yoktu** → giderildi |
| Kabuk: repo şeridi (4 sekme) | ✓ |
| Ekle ekranı: hedef repo seçici | ✓ (B-132) |
| Bekleyenler listesi | ✓ aktif repoya bağlı (B-131), şerit üstte |
| **Görev detayı** | ✗ **şerit örtülü, rozet yok** → giderildi |
| Tamamlananlar | ✗ damga yoktu → giderildi |
| Kuyruk satırları | ✓ aktif repoya süzülüyor · ⚠ bitişik bulgu: [B-140](../../BACKLOG.md#B-140) |

### Agent — düzeltme

Gövdedeki `Repo` satırı ile kuyruk damgası **aynı kaynaktan** basılıyor
(`create`'in tek `repoSlug` parametresi). Ayrı yerlerden bassalardı zamanla
ayrışır, gövde bir hub'ı kuyruk başkasını gösterebilirdi — düzeltilen kusurun
kendisini yeniden üretirdi.

Satır kullanıcının metnine **yapıştırılmadı**, boş satırla ayrıldı: `## İstek`
kullanıcının yazdığı şeydir, makine okunur olgu onun içine karışmamalı
(T-014'ün ayrımı).

Rozet, damga yoksa **hiç çizilmiyor**. Boş bir rozet "reposuz" diye bir şey
uydururdu — kimlik alanının (sözleşme 1.15) izlediği çizginin aynısı.

**Ölçüm:** `flutter analyze` temiz, **612 test**.

### Kullanıcı
> telefona kur

### Agent — kuruldu ve doğrulandı

İlk denemede `adb devices` boş döndü (cihaz düşmüştü); derleme yine de
yapıldı, böylece kurulum tek adım kaldı. Cihaz geri gelince
`tool/install.sh --no-build`.

Kurulumun **veriyi koruduğu iddiaya değil ölçüme** dayanıyor:
`firstInstallTime` 2026-08-01'de kaldı (kaldırma olsaydı sıfırlanırdı),
`lastUpdateTime` 2026-08-21 21:00 oldu. Uygulama açıldı, süreç ayakta,
logcat'te çökme izi yok.

**Not:** `versionCode` hâlâ 1 — 1 Ağustos'tan beri artmamış. "Hangi build
kurulu" sorusunun cevabı yalnız kurulum zaman damgasında duruyor; bugünkü
ölçümü onunla yapabildim ama kırılgan bir dayanak. Aşama 5'e uygun küçük bir
madde olabilir, kullanıcıya söylendi.
