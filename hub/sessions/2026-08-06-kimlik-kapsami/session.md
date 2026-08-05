---
id: S-2026-08-06-kimlik-kapsami
date: 2026-08-06
status: closed
reconstructed: false
author: afgover
topics: [coklu-kullanici, kimlik, notlar]
artifacts: []
tasks_touched: []
---

# Oturum: Kimliğin kapsamı — görünürlük, kişisel notlar, agent kayıtları

## Özet
Kullanıcının üç sorusu üç gerçek boşluğu açığa çıkardı; üçü de "tanımlanmış ama
işlemiyor" kategorisinde.

**Veri tarafı çalışıyordu.** `hub/notes/afgover/2026-08-05-github.md` hem doğru
klasörde hem `author: afgover` taşıyor — kimlik katmanı uçtan uca işliyor.
Şikâyet ("notlarda afgover görünmüyor") **görüntülemeyi** işaret ediyordu.

**(a) `author` hiçbir ekranda gösterilmiyordu.** Artık görev detayında rozet,
işaret kartında satır var. Notlarda bilerek **gösterilmiyor**: not kişisel,
orada yazan hep "ben" olurdu.

**(b) Notlar kişisel değildi.** `annotationsIn` bütün `notes/**` dosyalarını
tarıyordu; takımda herkes herkesin notunu belgede işaretli görürdü — 1.9'da
(K-029) notu ayırmanın sebebine aykırı. Kullanıcının önerisi alındı: notlar
kişisel kalır, paylaşmak isteyen görev açar (`gorev`/`duzeltme`/`tartisma`).
Süzme iki durumda yapılmıyor — kimlik bilinmiyorsa ve 1.15 öncesi düz
notlarda; ikisinde de gizlemek var olan veriyi yok ederdi. Önek sızıntısı da
teste bağlandı (`afgover2` klasörü `afgover`a görünmemeli).

**(c) 41 oturum kaydının hiçbirinde `author` yoktu.** 1.15'te kuralı yazıp
kendi prosedürüme koymamışım: kodla zorlanan kısmı (app kayıtları) uyguladım,
yalnız belgede duran kısmı unuttum. Protokol maddesi 1'e eklendi ve bu oturum
ilk kez `author` ile açıldı. → L-041

`knowledge/` ve `SECURITY.md` bilinçli olarak **ayrı kimlik alanı taşımıyor**:
`Kaynak:` zaten oturuma işaret ediyor ve oturum artık kimliği taşıyor, yani
zincir çözülüyor. Aynı bilgiyi iki yerde tutmak ayrışmaya davetiye olurdu.

Sözleşme 1.16, 430 test, analyze temiz.

## Kayıt

### Kullanıcı
> notlarda afgover gorunmuyor, aslinda notlar kisisel kalabilir, paylasmak
> isteyen gorev olustur ile tasklere bir sey ekleyebilir, yada tartisma
> mantikli olabilir, burdan eklenen gorevler icin rumuz gorunuyormu, onu
> kontrol edelim,
> ikinci husus session kayitlari vs. rumuz kaydi ile olusturuluyormu, yada
> eklenen bir guvenlik guncellemesi yada bir kural rumuz iceriyor mu?

### Agent
Önce ölçüldü. Veri tarafı **çalışıyor**: `hub/notes/afgover/2026-08-05-github.md`
hem doğru klasörde hem `author: afgover` taşıyor — yani `/user` ya da elle
giriş işini görmüş. Üç gerçek boşluk çıktı:

1. **`author` hiçbir ekranda gösterilmiyor** (`grep` ile doğrulandı). Veri
   yazılıyor ama kullanıcı göremiyor — L-039/L-040'ın aynı kalıbı, üçüncü kez.
2. **Notlar kişisel değil.** `annotationsIn` bütün `notes/**` dosyalarını
   tarıyor; takımda herkes herkesin notunu belgede işaretli görürdü. Kullanıcı
   doğru olanı söyledi: notlar kişisel kalsın, paylaşmak isteyen görev açsın.
3. **41 oturum kaydının hiçbirinde `author` yok.** Sözleşme 1.15 "author görev,
   not ve **oturum**a yazılır" diyor; kuralı yazdım ve o günden beri açtığım
   her oturumda kendim atladım. Güvenlik ve knowledge kayıtlarında da kimlik
   yok.

### Agent — uygulama
`isMyNote` sahiplik süzgeci (iki tarama yolunda da), `Annotation.author`,
görev detayında kimlik rozeti, işaret kartında kimlik satırı. Sözleşme §11'e
"not kişiseldir, paylaşım yolu görevdir" kuralı; §2 oturum şemasına `author`;
protokol adım 1'e oturum kimliği ve knowledge/SECURITY'nin neden ayrı alan
taşımadığı.

`personal_notes_test.dart` yedi durumu sabitliyor — özellikle iki tanesi:
kimlik bilinmiyorken hiçbir şeyin gizlenmemesi ve `afgover2`nin `afgover`a
sızmaması (önek değil, tam eşleşme).
→ B-111, L-041
