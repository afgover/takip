---
id: S-2026-07-30-faz3-todo-dongusu
date: 2026-07-30
status: closed
topics: [gelistirme, flutter, mvp]
artifacts: []
tasks_touched: [T-002]
---

# Oturum: Faz 3 — todo döngüsü (B-030…B-034)

## Özet
Faz 3'ün agent tarafı bitti: B-030, B-031, B-032, B-033 tamamlandı; B-034'ün
sözleşme ayağı tamamlandı, cihaz ayağı kullanıcıya bağlı kaldı. 128 test,
`flutter analyze` temiz.

**B-031 — bekleyenler.** Liste iki klasör isteğiyle çiziliyor, dosya
indirilmiyor (SYSTEM.md §4: durum klasör, ad tarih+slug). İçerik ancak detaya
girilince çekiliyor. `pendingTasksProvider` yoklamanın `headSha`'sını izlediği
için hub'da bir şey değişince liste kendiliğinden tazeleniyor — B-024 ilk kez
gerçek bir işe bağlandı.

**B-030 — görev ekleme.** `TaskDraft` yazma yolunun tek kaynağı: dosya adı,
içerik ve commit mesajı orada üretiliyor, JSON'a çevrilebiliyor (outbox aynı
taslağı gönderiyor) ve yeniden adlandırılabiliyor (çakışma). `id: pending` —
ID atamak agent'ın işi. Kategoriler K-010'a göre; bütün görev dosyalarını
indirmemek için "gördükçe biriktir" + serbest giriş yaklaşımı seçildi,
gerekçesi kodda yazılı.

**B-032 — outbox.** Kuyruğa yalnız ağ hatası düşüyor; yetki/biçim hatası
beklemekle düzelmeyeceği için kullanıcıya hemen söyleniyor. Bağlantının
geldiğini anlamak için ayrı bir dinleyici eklenmedi: yoklamanın başarılı
kontrolü zaten "çevrimiçiyiz" demek.

**B-033 — çakışma.** Buradaki asıl mesele, çakışmanın iki farklı şey
anlamına gelebilmesi. Outbox yeniden denerken yazma başarılı olup yanıt
kaybolmuş olabilir — o zaman dosya aynı içerikle durur ve kopya açmak yanlış
olur. Ya da aynı gün aynı başlıkla gerçekten başka bir görevdir — o zaman da
üstüne yazmak yanlış olur. Ayrımı yapmanın tek yolu dosyayı okumak; sözleşmenin
"yeniden oku, yeniden dene"si tam olarak bu.

**B-034 — döngü.** İki ayak var. (1) Sözleşme ayağı: GitHub Contents API'sini
taklit eden bir hub üzerinde, gerçek ekranlarla tam döngü — görev eklendi,
agent inbox → active → done taşıdı, app durumu ve sonucu gördü; ayrıca ağ
kesintisi senaryosu. (2) Gerçek hub ayağı: T-002 dosyası app'in `TaskDraft`
üreticisinden çıktığı hâliyle gerçek hub'a kondu ve döngüden geçirildi; biçim
bozulmadı, `hub_files_test` artık onu da okuyor. **Kalan:** gerçek GitHub
üzerinden cihazda koşum — B-015 (token) ve B-020 (SDK) tamamlanmadan
yapılamaz, madde bu yüzden açık bırakıldı.

Test tarafında bir tuzak çıktı: `testWidgets` sahte saatte koştuğu için
HTTP çağrısını doğrudan `await` etmek testi sessizce askıda bırakıyor. Aynı
kod düz `test()` içinde çalıştığından sorun yanlış yerde aranıyor. Çözüm
`tester.runAsync` — L-008.

## Kayıt

### Kullanıcı
> faz3 b031-b034 arasını sırayla yapabilirsin

### Agent
Bağımlılık belirtildi: B-032 (outbox) ve B-034 (uçtan uca test) B-030'un yazma
yoluna dayanıyor, dolayısıyla B-030 atlanamaz. Sıra B-031 → B-030 → B-032 →
B-033 → B-034 olarak işletiliyor.
