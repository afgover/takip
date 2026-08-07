---
id: S-2026-08-06-ingilizce-secenegi
date: 2026-08-06
status: closed
reconstructed: false
author: afgover
topics: [i18n, dil, public]
artifacts: []
tasks_touched: []
---

# Oturum: İngilizce dil seçeneği — altyapı

## Özet
Kullanıcı public'ten önce İngilizce **seçeneği** istedi (Türkçe kalacak) — hem
uygulama hem yöntem belgeleri için. Altyapı kuruldu, kalan iş ölçülü bırakıldı.

**Ölçüm önce:** 337 Türkçe metin / 39 dosya. Katmanlara ayrıldığında tablo
netleşti: `lib/features` 219 (saf arayüz), `lib/hub`+`lib/core` 91 (karışık —
hata mesajları arayüz, commit mesajları değil), `task_draft.dart` 16 (**hub'a
yazılan içerik, çevrilmemeli**).

**Kararı ters çeviren bulgu:** K-032 "asıl varlık uygulama değil yöntem" diyor.
Public yapmanın amacı yöntemin yayılmasıysa, İngilizce arayüz tek başına
kimsenin işine yaramaz — İngilizce konuşan biri uygulamayı kurabilir ama
Türkçe sözleşmeyi okuyamadığı için yöntemi benimseyemez. Tersi çalışır.
Kullanıcı ikisini de istedi; belgeler B-116 olarak ayrıldı ve **B-097'nin ön
koşulu** yapıldı.

**Tuzak:** uygulama hub'a `## İstek`, `## Notlar` yazıyor ve `noteTextFrom()`
bunları regex ile arıyor. Arayüz dili bunları da çevirseydi aynı hub'da iki
şema oluşur ve mevcut bütün kayıtlar okunamaz hâle gelirdi. Sözleşme 1.18 bunu
kural olarak yazdı: **arayüz dili ≠ kayıt dili.**

**Yapılan (B-114):** `flutter_localizations` + ARB (tr/en), `l10n.yaml`,
Ayarlar'da Sistem/Türkçe/English seçici (varsayılan sistem dili, diske
yazılıyor). Delege listesi tek kaynaktan hem uygulamaya hem testlere veriliyor
— ayrı tanımlansaydı test ortamı uygulamadan farklı davranırdı; nitekim ilk
koşumda dört test tam bu yüzden kırıldı ve testler ayrı bir `MaterialApp`
kurduğu her yerde aynı hata tekrarlandı.

**Kalan iş tahmin değil ölçü (B-115):** `l10n_coverage_test.dart` üç şeyi şart
koşuyor — taşınmış dosyada Türkçe metin kalmaması, bekleyen 23 dosyalık
listenin gerçekle uyuşması, ve iki ARB'nin aynı anahtarları taşıması. Sonuncusu
önemli: eksik anahtar **sessizdir**, `gen_l10n` onu şablondan doldurur ve
İngilizce seçen kullanıcı o satırda Türkçe görür, hiçbir şey hata vermez.
Listeyi elle yazarken bir dosyayı fazladan koymuştum; test bunu da yakaladı.

433 test, analyze temiz.

## Kayıt

### Kullanıcı
> public yapmadan once ingilizce dil secenegi de ekleyip oyle yapalim

### Agent
Kapsam ölçüldü ve K-032'ye dayanan ters argüman sunuldu (yöntem belgeleri
arayüzden önce gelir). Ayrıca sözleşmeyle sabitlenmiş gövde başlıklarının
tuzağı gösterildi.

### Kullanıcı
> komple ingilizce olmasin, ingilizce secenegi de secilebilsin, yontem
> belgeleri ve uygulama ui i ingilizce olsun

### Agent
Altyapı kuruldu ve dil seçici eklendi (B-114). Kalan iki parça ölçülü olarak
ayrıldı: 23 ekranın metinleri (B-115) ve yöntem belgeleri (B-116, B-097'nin ön
koşulu). Sözleşme 1.18: arayüz dili ile kayıt dili ayrı.

### Agent — ID çakışması (kendi testim yakaladı)
Yeni maddelere B-111/112/113 verdim; **B-111 zaten kullanılmıştı**. Bu,
B-109'un çözdüğü eşzamanlılık sorunu değil: numarayı dosyadan değil
**hafızadan** verdim. `hub_id_uniqueness_test` bunu ilk koşumda yakaladı —
tam da bu iş için yazılmıştı ve ilk gerçek müşterisi kendi yazarı oldu.
Maddeler B-114/115/116'ya çekildi, atıflar güncellendi. Protokole tek cümle
eklendi: numara **dosyadaki en büyükten** türetilir.
