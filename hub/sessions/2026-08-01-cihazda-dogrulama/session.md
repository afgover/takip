---
id: S-2026-08-01-cihazda-dogrulama
date: 2026-08-01
status: closed
topics: [cihazda-dogrulama, ui, coklu-repo]
artifacts: []
tasks_touched: []
---

# Oturum: Cihazda doğrulama ve güvenli alan düzeltmesi

## Özet
Kullanıcı token'ı girip bağlandı; çoklu repo arayüzü **ilk kez gerçek cihazda**
görüldü ve hemen bir hata çıktı: repo şeridi durum çubuğunun altına giriyor,
repo adı saatin ve pil ikonunun üzerine biniyordu. 237 test geçtiği hâlde
görülmemişti — widget testleri sistem alanı olmayan bir ekranda koşuyor.

Düzeltildi (`SafeArea(bottom: false)`), testi yazıldı ve testin gerçekten
koruduğu düzeltme geri alınarak sınandı (`0.0 >= 48.0` diye kırılıyor). Yeni
sürüm `tool/install.sh` ile kuruldu, cihazda gözle doğrulandı: şerit okunur,
repo listesi doğru çiziliyor (aktif repo işaretli, "Repo ekle", "Repoları
yönet"). → takip@5a4b78e, L-017

## Kayıt

### Kullanıcı
> telefon acik

### Agent
Ekran görüntüsü alındı: uygulama onboarding'de, token girilmemiş. Token'ın
kullanıcı tarafından girilmesi gerektiği söylendi (agent kimlik bilgisi
girmiyor).

### Kullanıcı
> baglandi

### Agent
Bağlantı doğrulandı, ama aynı ekran görüntüsünde **gerçek bir hata** görüldü:
repo şeridi durum çubuğunun altına giriyordu. Kabuğun gövdesi `AppBar`sız
başladığı için üst sistem alanı bırakılmamıştı; şerit T-003'e kadar en üstte
kalıcı bir bileşen olmadığından sorun daha önce ortaya çıkmamıştı
(`HubStatusBanner` hata yokken görünmüyor).

`SafeArea(bottom: false)` eklendi — alt taraf hariç, orayı
`bottomNavigationBar` zaten hallediyor. Test `MediaQueryData(padding:)` ile
yazıldı ve **düzeltme geçici olarak geri alınıp testin kırıldığı görüldü**;
geçen test ile yakalayan test aynı şey değil. 237 test, analyze temiz.

Yeni sürüm kuruldu ve cihazda gözle doğrulandı. → L-017
