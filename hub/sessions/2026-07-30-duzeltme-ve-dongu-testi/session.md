---
id: S-2026-07-30-duzeltme-ve-dongu-testi
date: 2026-07-30
status: open
topics: [duzeltme, sozlesme-testi, hedef-karari]
artifacts:
  - artifacts/reference/flutter-app-design.md
tasks_touched: [T-001]
---

# Oturum: Repo düzeltmesi, sözleşme döngü testi ve hedef kararları

## Özet
(oturum kapanınca yazılacak)

## Kayıt

### Kullanıcı
> İlk özel repo `taskr_takip`. Zaten şu an taskr içerisindeyiz, buradan bir kayıt
> oluşturmayı başlatabilirsin. B-015'e daha sonra bakarız. B-016 için bu
> yaptıklarımızı kullanabilirsin. Öncelik hedef kişisel; ileride store
> (Android + iOS).

### Agent
Repo listesi kontrol edildi: hem `takip` hem `taskr_takip` mevcut; kullanıcı
`taskr_takip`i teyit etti.

### Kullanıcı
> taskr_takip

### Agent
Yapılanlar:
1. Hub geçmişi (4 commit) olduğu gibi `afgover/taskr_takip`e taşındı; `takip`
   kullanım dışı bırakıldı. → K-007, L-003
2. Bu oturum kaydı açıldı (status: open — konuşma sürdükçe güncellenecek).
3. B-016 sözleşme döngü testi bu taşıma işi üzerinden koşuldu: T-001 görevi
   `inbox`a eklendi → `active`e taşındı → notlarla `done`a taşındı; her adım
   sözleşmenin §8 commit önekleriyle işlendi. Revizyon ihtiyacı çıkmadı
   (B-017 ✅, sözleşme 1.0 kaldı). Dersler: L-003 (parametre teyidi),
   L-004 (Contents API yolu Faz 3'te ayrıca test edilecek).
4. Hedef kararı kayda geçti: önce kişisel kullanım, ileride Android + iOS store
   (K-008); `flutter-app-design.md` §8 güncellendi.
5. B-015 (uygulama token'ı) kullanıcı kararıyla ertelendi; Faz 2 öncesi yapılacak.

### Kullanıcı
> android

### Agent
Kişisel aşama platformu Android olarak kayda geçti (K-009); `flutter-app-design.md`
§8 ve B-020 güncellendi. Faz 2 öncesi açık kalan tek tasarım sorusu: görev
kategorileri sabit mi, kullanıcı tanımlı mı? Ayrıca uygulama kodunun hangi
repoda yaşayacağı (hub veri-reposu kod içermez) Faz 2 açılışında netleşecek.

### Kullanıcı
> Kategori önerilerin yerinde; user da ekleyebilsin. İlk başta verdiğim `takip`
> reposu, app'i içeren çatı repo olacak.

### Agent
İki karar işlendi: K-010 — kategoriler 5 varsayılan + kullanıcı tanımlı serbest
değer; app listeyi mevcut görevlerden türetir (Sözleşme 1.0 → 1.1, §4).
K-011 — Flutter uygulaması `afgover/takip` çatı reposunda yaşayacak; `takip`in
README'si buna göre yeniden yazıldı. Yapı: takip = uygulama, taskr_takip = veri
hub'ı, taskr = tarihçe. Faz 2'nin tüm tasarım öngereksinimleri tamamlandı;
kalan: B-015 (token, ertelendi) ve B-020 (kullanıcıda Flutter SDK).

### Kullanıcı
> devam

### Agent
Faz 2 açıldı (Aşama 1 ✅ → Aşama 2 aktif). B-021 tamamlandı: Flutter iskeleti
`takip` çatı reposuna yazıldı (takip@417da6b) — katmanlı mimari
(github → hub → features), Riverpod, tema, alt gezinmeli kabuk, onboarding +
Bekleyenler/Ekle/Tarayıcı/Ayarlar ekran taslakları; frontmatter parser ve slug
üretimi çalışır durumda, API katmanı TODO(B-023) işaretleriyle bekliyor.
Ortamda Flutter SDK olmadığından derleme doğrulaması B-020'ye bağlandı:
kullanıcı `flutter create . --platforms=android && flutter pub get &&
flutter analyze` koşacak (README'de belgeli).

### Kullanıcı
> Sadece takip deposunu, diğer repolardan farklı olarak, takip_takip diye ek
> repo oluşturmadan tüm dosya içeriğini takip reposu altında topla; diğer
> repolar için işleyiş öncekiyle aynı olacak.

### Agent
K-012 uygulandı: tüm hub içeriği `taskr_takip`ten `takip/hub/` klasörüne
taşındı; `taskr_takip` "taşındı" notuyla kullanım dışı bırakıldı. Sözleşme
1.2'ye çıktı (hub kökü tanımı), R-002 üstü çizilip R-005 eklendi (token artık
`takip`e scope'lu; app yine yalnızca `hub/tasks/inbox/`'a yazar). Uygulama
tarafında `constants.dart` yolları `hub/` önekine, onboarding varsayılan repo
değeri `afgover/takip`e güncellendi. Diğer projeler için `<proje>_takip`
ayrı repo modeli geçerli kalıyor.
