---
id: S-2026-07-30-faz4-hub-tarayici
date: 2026-07-30
status: closed
topics: [gelistirme, flutter, tarayici]
artifacts: []
tasks_touched: []
---

# Oturum: Faz 4 — hub tarayıcı (B-040…B-046)

## Özet
Faz 4 tamamlandı: B-040…B-046. 164 test, `flutter analyze` temiz.

**Veri katmanındaki karar.** Kategori listeleri için klasör klasör gezmek
yerine tek bir özyinelemeli ağaç isteği (Git Trees API) kullanıldı. Alternatif,
`sessions/` içindeki her oturum ve `artifacts/` içindeki her klasör için ayrı
istek atmaktı — yani kayıt sayısıyla büyüyen istek sayısı. Ağaç isteği sabit
bir tanedir ve ETag'lendiği için değişiklik yokken limitten düşmez. Ağaç
kırpılırsa (çok büyük repo) sessizce eksik liste göstermek yerine hata veriliyor.

**B-040/041/042.** Kategori ekranı gezinmeye bağlandı; sözleşmedeki altı
kategoriye Aktivite ve Sözleşme kartları eklendi. Oturum ve artifact listeleri
ağaçtan çiziliyor, içerik ancak belge açılınca indiriliyor. Artifact'ın türü
ve gerçek başlığı frontmatter'da olduğu için liste çizildikten sonra tek tek
okunuyor; bu kayıt sayısı kadar istek demek, o yüzden üst sınır konuldu ve
gerekçe koda yazıldı. Okunamayan artifact listeden düşmüyor.

**B-043.** Bilgi tabanı kayıtları `## ID — başlık` bloklarından ayrıştırılıyor.
Önemli ayrıntı: R-004 gereği geçersizleşen kayıt silinmiyor, başlığı üstü
çiziliyor. Liste bunu göstermek zorunda — aksi hâlde geçersiz bir kural
geçerliymiş gibi okunurdu. Ayrıştırıcı gerçek `rules/skills/lessons`
dosyalarına karşı da test ediliyor.

**B-044.** Backlog ve evrim iki sekmede; görev kutuları ve üstü çizili
kararlar B-025'in eklenti setiyle GitHub'daki gibi çiziliyor.

**B-045.** Commit mesajları §8 kalıplarından insan diline çevriliyor
("task(T-001): active → done" → "T-001 tamamlandı"). K-012'den beri kod ve hub
aynı repoda olduğu için akışta uygulama commit'leri de var; ayrı tür sayılıp
varsayılanda gizleniyor, düğmeyle açılıyor. Kod commit'inde önek atılmıyor
(backlog referansı bilginin kendisi) ve tanınmayan kalıpta mesaj olduğu gibi
bırakılıyor — uydurmaktansa ham hâli dürüst.

**B-046.** ETag önbelleği artık cihazda saklanıyor: uygulama yeniden
açıldığında ETag'ler elde olduğu için içerik 304'le anında geliyor. Ayrıca ağ
yokken son bilinen içerik gösteriliyor ve bayat olduğu işaretleniyor. Sunucu
hatası (401/500) bu yola girmiyor — onu önbellekle gizlemek sorunu saklamak
olurdu.

İki küçük düzeltme testlerden çıktı: kod commit'lerinde `feat(B-023)` öneki
düşüyordu (backlog referansı kayboluyordu) ve dosya adındaki tarih yerel
olarak ayrıştırılmalı, çünkü gösterimde `toLocal()` uygulanıyor — UTC olarak
okunsa negatif saat diliminde bir gün geriye kayardı.

## Kayıt

### Kullanıcı
> faz 4e başla

### Agent
Faz 4 sırayla işleniyor. Veri katmanında bir karar: kategori listelerini
klasör klasör gezmek yerine tek bir özyinelemeli ağaç isteği (Git Trees API)
kullanılacak — oturumlar, artifact'lar ve bilgi tabanı tek istekte
çıkarılabiliyor, ETag'le birlikte pratikte bedava.
