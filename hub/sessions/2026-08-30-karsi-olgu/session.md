---
id: S-2026-08-30-karsi-olgu
date: 2026-08-30
status: closed
reconstructed: false
author: afgover
topics: [token, karsi-olgu, oneri-riskleri]
artifacts:
  - artifacts/S-2026-08-30-uc-gorev/token-maliyeti.md
tasks_touched: []
---

# Oturum: token çalışmasının iki eki — öneri riskleri ve karşı-olgu

## Özet

Token çalışmasına iki ek yazıldı
([A-2026-08-30-001](../../artifacts/S-2026-08-30-uc-gorev/token-maliyeti.md)
§6–§7); **hiçbir öneri uygulanmadı** — kullanıcı "ben söyleyince" dedi.

**§6 — öneri riskleri:** en dokunanı Ö3 (arşivleme): temizlik değil şema
değişikliği — §15 bağlantıları ve uygulamanın bağlantı çözücüsü kırılır,
ayrıştırıcı+test+göç ister. Ö2'nin (BACKLOG grep) en ciddi riski gövde
körlüğü — B-098'in ön koşulları grep'te görünmezdi. Ö4'ün paradoksu açıkça
yazıldı: maliyeti azaltmaz, öngörülebilir yapar. Ö1 hata yüzeyini modelden
script'e taşır (audit'in ilk koşumundaki 120 sahte bulgu emsal).

**§7 — karşı-olgu deneyi:** aynı durum sorusu üç koşulda. Hub'lı 48.7k ve
eksiksiz cevap; gerçek hub'sız 42.0k ve **"cevap veremem"** — maliyet aynı,
değer farkı radikal. İlk hub'sız koşum geçersiz çıktı: ajan hub'ı git
geçmişinden okudu (silme yetmiyor, tarih de kayıttır). Envanter: 17 fix
olayı, 53 ders (21'i teste bağlı), 5 kurtarılmış karar, 80 `reconstructed`.
Başabaş: hub'ın 6 haftalık ~0.7M token bedeli, 2–7 hata tekrarını ya da ~35
durum sorusunu önlemekle ödeniyor; kayıtlar bu eşiğin üstünü belgeliyor.
Kesin kanıt ikiz proje ister — iddia o sınırla kuruldu.

## Kayıt

### [03:30] Kullanıcı
> 4 onerinde yerinde gorunuyor, uygulanan onerilerin uygulama gelistirmeye
> olasi negatif etkilerini de incele, rapora ekle, alternatif maliyeti
> hesaplayabilirmiyiz? eger hub sistemi olmasaydi, ne kadar hata olusurdu ve
> bunlari duzeltmeye ugrasirdik(token ve zaman maliyeti), daha sonra
> uygulamaya ben soyleyince baslarsin

### [03:31] Agent
İki ek: (1) dört önerinin negatif etkileri — özellikle uygulama (app) tarafına
dokunanlar; (2) karşı-olgu maliyeti. Karşı-olgunun ölçülebilir kısmı için
deney: aynı durum sorusu, hub'lı ve hub'sız takip kopyasında, gerçek token
sayımıyla. Hiçbir öneri uygulanmayacak — kullanıcı "ben söyleyince" dedi.

### [04:05] Agent
Deney tamam, ek bölümler yazıldı, oturum kapanıyor. Yöntem dürüstlüğü:
C1'in geçersizliği ve C1b'nin küçük talimat ihlali rapora aynen geçti.

