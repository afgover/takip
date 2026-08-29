---
id: T-019
title: "Public repodaki kişisel tanımlayıcılar: kayıtlarda ne yapılsın?"
created_by: agent
created: "2026-08-29T12:25:00Z"
updated: "2026-08-29T12:25:00Z"
priority: normal
category: tartisma
tags: [guvenlik, kisisel-veri, public]
session: S-2026-08-29-public-tarama
result: none
options: ["Olduğu gibi kalsın — düşük risk, kayıt yeter", "Çalışma ağacından temizle — kayıtlar düzenlenir, geçmişte kalır", "Geçmişten de silinsin — force-push, SHA'lar değişir"]
multi: false
---

# Public repodaki kişisel tanımlayıcılar: kayıtlarda ne yapılsın?

## İstek

2026-08-29 taraması (SEC-017) çalışma ağacında üç kişisel tanımlayıcı sınıfı
buldu; hiçbiri sır değil, hepsi kimlik izi:

1. **Cihaz serisi** `R5CW71GRKPB` — üç oturum kaydında
   (2026-08-01-b020, 2026-08-13-durum-ozeti, 2026-08-29-telefon-guncelleme).
   `tool/install.sh`'taki örnek yer tutucuyla değiştirildi.
2. **E-posta** — `hub/artifacts/reference/project-taskr/` arşiv
   belgelerinde içerik olarak (2 yer). Commit yazarlığındaki e-posta zaten
   bilinçli karar (SEC-013, 2026-08-13). Testteki gerçek adres örnek adrese
   çevrildi.
3. **macOS kullanıcı adı** — `/Users/gover` yolları, aynı arşiv
   belgelerinde (~5 dosya).

## Notlar

Risk değerlendirmesi: üçü de doğrudan zarar üretmez (seri numarası uzaktan
kullanılamaz, e-posta GitHub profilinde zaten açık, kullanıcı adı yol
bilgisi). Karar yine de kullanıcının — çünkü "silme yok" kuralının tek meşru
istisnası kişisel veridir ve o istisnayı agent kendi başına kullanmaz.
Kapalı oturum kaydını düzenlemek de aynı iznin konusu (§2: kapanan dosya
değiştirilmez). Seçenek 3'ün bedeli: repo public, SHA'lar değişir,
klonlayanlar kopar.
