---
id: A-2026-10-24-001
session: none
type: info
title: "Asistan katmanı — birden çok hub'ı tek başına yürütürken"
created: 2026-10-23T23:50:00Z
contract: "1.41"
---

# Asistan katmanı

## Özet

Birden çok projeyi tek başına yürüten biri için örnek bir yapı. Her proje
kendi hub'ını tutmaya devam eder; üstüne, hub'ları okuyup günü planlayan
bir asistan eklenir. Asistan hiçbir projenin sahibi olmaz, kullanıcının
cevabını uygulamanın kapısından taşır. Bağlayıcı kurallar `SYSTEM.md` §17;
bu belge yalnız anlatır.

## Hangi sorunu çözüyor

Takip yöntemi tek projeyi iyi kaydeder. Proje sayısı artınca darboğaz kayıt
olmaktan çıkar, kullanıcının dikkatine dönüşür:

- Her hub kendi bekleyen sorularını tutar; toplamı hiçbir yerde görünmez.
  Uygulama da bekleyenleri yalnız aktif repo için listeler.
- Sorular birikir ve yaşlanır. Ölçülen bir örnekte on iki hub'da 117 soru
  vardı; yarısından fazlası 30 günden eskiydi.
- Beklemeye alınan projeler sessizce unutulur; sözleşme güncellemeleri
  onlara oturum açılana kadar ulaşmaz.
- "Bugün ne yapmalıyım" sorusu her sabah elle, hub hub gezilerek
  cevaplanır.

## Yapı

Dört parça var; ilk ikisi zaten takip yönteminin parçası.

1. **Proje hub'ları.** Değişmez. Her projenin ajanı kendi hub'ına yazmaya
   devam eder.
2. **Takip uygulaması.** Telefonda okuma, seçenekli soruları tek dokunuşla
   cevaplama, görev ve not ekleme.
3. **Asistan reposu.** Üç şey taşır:
   - kayıt defteri: hangi hub'lar okunur, proje durumu (aktif, beklemede,
     arşiv), günlük zaman hedefi;
   - özet betiği: hub'ları tazeleyip tek bir brifing üretir;
   - asistanın kendi hub'ı, repo içinde `hub/` klasöründe.
4. **Etkileşim yüzü.** Asistanla konuşulan yer: thread'li ve zamanlanmış
   görev çalıştırabilen bir sohbet ortamı (örnekte Claude Projects). Sabah
   brifingi oradan rutinle gelir.

Karar: yeni bir mobil uygulama yazmak yerine var olan sohbet ortamı
kullanıldı. Eksik olan arayüz değildi; hub'ları okuyup önceliklendiren
mantıktı. Takip uygulaması okuma ve hızlı cevap için kalır.

## Günlük akış

1. **Sabah, rutin.** Özet betiği her hub'ı `git pull --ff-only` ile
   tazeler ve brifing üretir: gelen kutusu, masa başı işler, telefonda
   cevaplanacak sorular, proje panosu, beklemedeki projelere haftalık
   hatırlatma. Bu koşu oturum açmaz (§17).
2. **Gün içinde, telefon.** `options` taşıyan sorular takip uygulamasında
   tek dokunuşla cevaplanır. Brifing bu soruları ayrı listeler, böylece
   telefonda geçen kısa aralar da kullanılır.
3. **Masa başı.** Bilgisayar gerektiren işler. Brifing, öncelik ve yaşa
   göre ilk üçünü önerir; günlük süre hedefi kayıt defterindedir.
4. **Cevap asistana verilirse.** Kullanıcı sohbette "şu soruya B" derse
   asistan cevabı o projenin `tasks/inbox/` klasörüne, uygulamanın
   şemasıyla ve `via: asistan` alanıyla yazar. Projenin ajanı onu bir
   sonraki oturumda uygulamadan gelmiş gibi işler.

## Yazma sınırı ve gerekçesi

Asistan başka bir hub'da görev taşımaz, ID vermez, backlog işaretlemez,
oturum açmaz. Gerekçeler:

- **Sahiplik.** Bir projenin kaydı o projenin ajanınındır. İki yazar aynı
  dosyalarda çakışır ve sayaçlar (`T-`, `B-`) çift verilir.
- **Denetlenmiş kapı.** Uygulamanın yazma alanı (`tasks/inbox/`, `notes/`)
  zaten dar, çakışmasız ve her ajanın açılışta okuduğu yer. Asistan yeni
  bir kanal açmaz.
- **Kopya yok.** Projelerin soruları asistanın `waiting/` klasörüne
  kopyalanmaz; aynı soru iki yerde durursa iki ayrı cevap alır.

## Kurulum

1. Asistan için bir repo aç. Kişiselse **private** tut: özetler birden çok
   hub'ın içeriğini taşır.
2. Hub'ı repo içine kur (`hub/`), `agent-kurulum-talimati.md` ile. Projects
   ile çalışılacaksa `ORTAM.md` `projects` der.
3. Kayıt defterini yaz: her hub için yerel klonun yolu ve proje durumu.
4. Özet betiğini yaz: tazele, oku, sırala, yaz. Proje hub'larına yazmaz.
5. Sabah rutinini kur. Çıktı sohbete gelsin, repoya commit'lenmesin.
6. Takip uygulamasına asistan reposunu da ekle; token'ın onu kapsasın.

## Tuzaklar

- **Bayat klon.** Tazelenemeyen hub'dan okunan sayı yanlıştır ve hata
  vermez. Özet, tazelenemeyen hub'ı açıkça işaretlemeli.
- **Şema sapması.** Hub'lar zamanla şemadan kayar (ör. `priority: medium`,
  saatsiz `created`). Okuyucu hoşgörülü olmalı, sapmayı raporlamalı,
  düzeltmemeli.
- **Öncelik enflasyonu.** Her ajan `high` değerini kendine göre koyar;
  hub'lar arası sıralamada öncelik tek başına yetmez. Yaşa ve son tarihe
  (`due`) de bakılır.
- **Tekrar cevap.** Aynı soru hem uygulamadan hem asistandan
  cevaplanabilir. Asistan yazmadan önce inbox'a bakar; ajan çelişkide
  kullanıcıya sorar (§4).
- **Rutin gürültüsü.** Her sabah oturum açan bir rutin yılda yüzlerce boş
  kayıt üretir; yalnız okuyan koşu oturum açmaz.
- **CI tetiklemesi.** Hub kod reposundaysa her kayıt commit'i CI'ı
  tetikleyebilir; `hub/**` tetikleyiciden çıkarılır.
- **Gizlilik.** Brifing, okuduğu en kısıtlı hub kadar gizlidir.

## Sonuç

Asistan takip yöntemine yeni bir kayıt türü eklemez; var olan hub'ları
okur ve kullanıcının dikkatini yönetir. Yazdığı tek şey kullanıcının kendi
sözüdür, onu da uygulamanın kapısından yazar. Asistanı olmayan hub için
hiçbir şey değişmez.
