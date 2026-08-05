---
id: S-2026-08-06-cok-kullanicili-hub
date: 2026-08-06
status: closed
reconstructed: false
topics: [coklu-kullanici, sozlesme, tasarim]
artifacts:
  - artifacts/S-2026-08-06-cok-kullanicili-hub/coklu-kullanici-tasarimi.md
tasks_touched: []
---

# Oturum: Aynı hub'ı birden çok kişi kullandığında

## Özet
Takım senaryosu için **Katman 1+2** uygulandı (sözleşme 1.15); Katman 3+4
bilinçli olarak ikinci kişi gelene kadar ertelendi.

**Ölçüm önce yapıldı.** Dört kırılma bulundu: kimlik şemada hiç yok
(`created_by` bir rol), bütün ID'ler tekil sayaç ve çakışmaları **sessiz**,
altı dosyaya herkes ekleme yapıyor, `notes/` tek kişilik. Bunlardan yalnız
ikincisi sessiz — diğerleri git çakışması olarak zaten gürültülü.

**Karar (K-036): kimlik eşzamanlılıktan önce gelir.** Karmaşanın büyük kısmı
"iki kişi aynı anda yazdı" değil, "bu kimin işi" belirsizliğinden geliyor ve o
en ucuz katman. `author`, `for`, `assignee` alanları eklendi; üçü de isteğe
bağlı ve yokluk "bilinmiyor" demek. `for`suz bir `waiting/` görevi **herkesi**
bekler — aksi hâlde tek kullanıcılı dönemin bütün görevleri kimsenin görmediği
bir kuyruğa düşerdi.

**Notlar klasörle ayrıldı** (`notes/<login>/`), alanla değil: "agent notlara
dokunmaz" garantisi böylece yapısal kalıyor. R-001 korundu — app hâlâ yol
değil **ad** veriyor ve ad, yol parçasına dönüşmeden harf/rakam/tireye
indirgeniyor (`../../` denemesi teste bağlandı).

**Çakışma imkânsız kılınmadı, görünür kılındı.** ID biçimini değiştirmek
yüzlerce mevcut atfı ikinci sınıfa düşürürdü; onun yerine hub'ı okuyan bir test
tekrarlı ID tanımını yakalıyor ve protokol ID atamadan önce rebase istiyor.
Test, tarayıcının **kendisinin** bozulmasını da kontrol ediyor (L-035): desen
bozulursa sessizce "temiz" demeye başlardı.

Uygulama `login`'i onboarding'de `/user`'dan **en iyi çabayla** okuyor.
Fine-grained token'la bu uç noktanın davranışı bu proje için ölçülmediği için
başarısı varsayılmadı: okunamazsa bağlantı yine kurulur ve kayıtlar `author`sız
gider (L-009'un kuralı, B-092'nin çizgisi).

418 test, analyze temiz. Yeni sözleşme kuralı ilk kez kendi üzerimizde
uygulandı: B-108/B-109/B-110 numaraları rebase sonrası atanıp hemen push'landı.

## Kayıt

### Kullanıcı
> takip reposunu birden fazla kullanici kullandiginda karmasa yaratmamak bir
> yontem uretelim

### Agent
Önce neyin gerçekten kırıldığı ölçüldü (tahminle tasarlamamak için). Dört
somut kırılma bulundu: kimlik şemada hiç yok (`created_by` bir *rol*, kimlik
değil; uygulama GitHub `login`'ini bilmiyor), bütün ID'ler tekil sayaç ve
çakışmaları **sessiz**, altı dosyaya herkes ekleme yapıyor, `notes/` tanımı
gereği tek kişilik.

Senaryo soruldu; kullanıcı **takım** (aynı hub, 2-5 kişi) dedi. Tasarım
artifact'e yazıldı.

### Agent — uygulama
Katman 1: `HubConfig.login` (+`/user` en iyi çaba), `HubTask.author`/`waitingFor`,
`TaskDraft`'ın beş üreticisine `author`, `notes/<login>/` yolu ve `sanitizeLogin`,
kimliğin **yazılacak reponun** bağlantısından seçilmesi
(`loginForRepoProvider` — L-019'un aynı gerekçesi), bekleyen şeridinde
"kimi bekliyor" metni.

Katman 2: `hub_id_uniqueness_test.dart` (245 tanım) ve protokole ID kuralı.
İlk koşumda `BACKLOG.md`'nin başındaki biçim örneği yanlış pozitif verdi —
kod bloklarını ayıklamak gerekti; ayıklamasaydım test olmayan bir çakışma
bildirip güvenilirliğini kaybederdi.

Sözleşme 1.15'e çekildi (uygulama sabiti, README, kurulum talimatı dahil).
→ B-108, B-109, B-110, K-036
