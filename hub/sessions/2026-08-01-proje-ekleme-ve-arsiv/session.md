---
id: S-2026-08-01-proje-ekleme-ve-arsiv
date: 2026-08-01
status: closed
topics: [proje-ekleme, sozlesme, arsiv, project-taskr]
artifacts:
  - artifacts/reference/proje-ekleme.md
  - artifacts/reference/project-taskr/arsiv-dizini.md
tasks_touched: []
---

# Oturum: Proje ekleme prosedürü ve project-taskr arşivi

## Özet
Kullanıcı iki şey sordu: bir projeyi takip sistemine nasıl dahil edeceği ve
`project-taskr`'daki bilgilerin yeni sisteme taşınması. İkisi de yapıldı, ama
yol boyunca iki şey beklenenden farklı çıktı.

**Birincisi: sözleşme uygulamayla çelişiyordu.** Prosedürü yazarken görüldü ki
sözleşme 1.2 "diğer projeler için hub, `<proje>_takip` reposunun köküdür"
diyor, uygulama ise hub kökünü `hub/` diye **sabit** tutuyor
(`Hub.basePath`, bağlantı başına ayarlanamıyor). Yani sözleşmeye uyarak
kurulan ikinci bir repo, onboarding'de "hub/ klasörüne erişilemedi" diye
reddedilirdi — ikinci proje eklenmeye çalışıldığı ilk anda patlayacaktı.
Kullanıcı kararıyla sözleşme uygulamaya uyduruldu: **hub kökü her repoda
`hub/`** (sözleşme 1.3, K-020).

**İkincisi: aranan veri repoda yoktu.** Kullanıcı "proje bazında aktar"
dediğinde Project Taskr'ın yönettiği projeler (CoPilot, Financer, Sarraf,
DataSources) kastediliyor olabilirdi. Repo tarandı: bu adlar yalnızca pano
taslağında, bir portföy prompt'unda ve bir LTREE etiket örneğinde geçiyor —
hiçbirinin proje belgesi yok. Gerçek proje kayıtları uygulamanın
veritabanındaydı (`Group`, `ProjectTaskLink`, `ProjectMemoryRecord`,
`ProjectWorkSession` modelleri). Kullanıcıya soruldu; belgeleri kastettiğini
söyledi.

Sonuç: **35 belge** `artifacts/reference/project-taskr/` altına, beş konu
başlığında, kaynak yolları ve arşiv notlarıyla taşındı. Project Taskr arşive
kaldırıldığı için ayrı hub reposu açılmadı (K-021).

`flutter analyze` temiz, **247 test** geçiyor — sözleşme uyum testi
`hub/artifacts`'ı özyinelemeli taradığı için taşınan 35 belgenin frontmatter'ı
da doğrulanmış oldu.

## Kayıt

### Kullanıcı
> bir projeyi takip sistemine dahil etmek icin ne yapmam lazim, agenta ne
> demem lazim, onceden kurdugumuz project-taskr daki proje ilgili verileri de
> yeni takip sistemine tasimak istiyorum

### Agent
Repolar incelendi. `taskr` reposu **iki ürün** taşıyor: `main` = Taskr Basic,
`project-taskr` = Project Taskr (ayrı Coolify dağıtımı ve veritabanı olan
yönetilen proje/atama/agent operasyon ürünü). `taskr_takip` boş — yalnız
README, iskelet kurulmayı bekliyordu.

Uygulamada bir engel bulundu ve doğrulandı: `Hub.basePath = 'hub'` sabit,
`HubConfig`'de karşılığı yok. Sözleşme §1.2 ise diğer projeler için hub kökünü
repo kökü sayıyor. İkisi bir arada duramaz.

### Kullanıcı
> (soruya cevap) taskr_takip e kurmayacagiz, her proje icin ayri bir repo
> olusturuyorum, ornek financer projesi icin takip reposu financer_takip,
> (proje adi)_takip seklindeki repolar takip repolari olacaklar, senden
> istedigim project-taskr da onceden yuklenmis bilgileri proje bazinda
> aktarman · project-taskr i arsive kaldiracagiz

### Agent
"Proje bazında aktar" isteğinin iki okuması vardı — Project Taskr'ın yönettiği
projelerin verisi mi, yoksa repodaki belgeler mi. Varsayılmadan önce kanıt
arandı: `financer`, `copilot`, `sarraf`, `datasources` repoda tarandı; hepsi
yalnızca anıldıkları yerlerde (pano taslağı, portföy prompt'u, LTREE örneği)
geçiyor, hiçbirinin belgesi yok. Kullanıcıya soruldu.

### Kullanıcı
> (soruya cevap) Zaten belgeleri kastediyordum · hub kökü: `hub/` klasörü
> altında

### Agent
İki iş yapıldı:

**1. Sözleşme 1.3 (K-020).** Hub kökü her repoda `hub/`. Eski cümle üstü
çizilerek gerekçesiyle bırakıldı. Alternatif (uygulamaya bağlantı başına
`basePath` eklemek) değerlendirilip elendi: `Hub.*` sabitlerini kullanan her
katmanı örnek bazına çevirmek gerekirdi ve app'in "yalnız `hub/tasks/inbox`'a
yazar" garantisi derleme zamanı sabiti olmaktan çıkardı.

**2. Prosedür belgesi** (`artifacts/reference/proje-ekleme.md`): repo aç →
token kapsat → iskelet kur → uygulamaya ekle → agent'a tek cümle söyle.
Ayrıca sık karşılaşılan hatalar ve projeyi arşive kaldırma adımları.

**3. Arşiv taşıması** (K-021): 35 belge beş başlıkta —
`urun/`, `agent-sistemi/`, `altyapi/`, `agent-kayitlari/`, `taskr-basic/`.
Her belgenin başına sözleşme frontmatter'ı ve kaynak yolunu söyleyen bir
arşiv notu kondu; içerikler değiştirilmedi. Mükerrer `workflows/server.md`
elendi. `taskr-basic/` ayrı tutuldu çünkü o belgeler farklı bir ürüne ait;
Taskr Basic ileride takibe alınırsa `taskr_takip` hub'ına taşınacaklar.

Taşıma artifact sayısını 39'a çıkardı ve uygulamanın metadata sınırı 40'tı —
bir sonraki artifact başlıksız listelenecekti. Sınırın gerekçesi "kayıt sayısı
kadar ağ isteği"ydi; B-057'den beri bu okumalar yerel kopyadan geliyor, o
yüzden sınır 150'ye çıkarıldı (sıfırlanmadı: ilk senkron bitmeden liste
açılırsa okumalar yine ağa gider).
