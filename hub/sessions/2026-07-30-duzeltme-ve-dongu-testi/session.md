---
id: S-2026-07-30-duzeltme-ve-dongu-testi
date: 2026-07-30
status: closed
topics: [duzeltme, sozlesme-testi, hedef-karari]
artifacts:
  - artifacts/reference/flutter-app-design.md
tasks_touched: [T-001]
---

# Oturum: Repo düzeltmesi, sözleşme döngü testi ve hedef kararları

## Özet
*(Bu özet 2026-08-08'de, oturumun kendi kaydına dayanarak yazıldı — oturum
kapanışta kapatılmamış, dokuz gün `open` kalmıştır. Yeni bilgi eklenmedi;
aşağıdakilerin hepsi bu dosyadaki kayıttan çıkarılmıştır. Sebep ve önlem:
L-042.)*

Projenin **temel yapısı** bu oturumda oturdu. Dört karar, sonraki her şeyi
belirlediği için burada duruyor:

- **K-011 + K-012 — repo yapısı.** Hub önce ayrı bir veri reposundaydı
  (`taskr_takip`); oturum sonunda `takip/hub/` altına alındı. Yani `takip`
  kendi kendini barındırır: uygulama kodu ve kendi hafızası aynı yerde. Diğer
  projeler için `<proje>_takip` ayrı repo modeli geçerli kaldı. Sözleşme 1.2
  bunun için çıktı (hub kökü tanımı) ve R-002 yerini R-005'e bıraktı.
- **K-008 + K-009 — hedef.** Önce kişisel kullanım, ileride store; kişisel
  aşamanın platformu Android.
- **K-010 — kategoriler** 5 varsayılan + kullanıcı tanımlı serbest değer;
  liste mevcut görevlerden türetilir (sözleşme 1.1, §4).
- **B-016 — sözleşmenin kendisi sınandı.** Döngü testi taşıma işi üzerinden
  koşuldu: T-001 `inbox → active → done`, her adım §8 commit önekleriyle.
  Revizyon ihtiyacı çıkmadı, sözleşme 1.0 kaldı (B-017 ✅). Dersler L-003, L-004.

Faz 2 bu oturumda açıldı ve B-021 (Flutter iskeleti, takip@417da6b) yazıldı.
Ortamda SDK olmadığı için derleme doğrulaması B-020'ye bağlandı — iddia
edilmeyip ölçüme bırakılması, sonradan projenin genel kuralı olan yaklaşımın
ilk örneği.

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
