---
id: S-2026-08-02-secim-filtre-sozlesme
date: 2026-08-02
status: closed
topics: [sozlesme, bekleyenler, filtre, secim, isaretleme]
artifacts:
  - artifacts/reference/agent-kurulum-talimati.md
tasks_touched: []
---

# Oturum: Sözleşme sürüm kontrolü, çoklu repo bekleyenler, seçimden kayıt

## Özet
Üç istek geldi, üçü de sözleşmeye dokunduğu için tek sürüm artışında toplandı
(**1.5**).

**1. Sözleşme sürüm kontrolü (B-070, K-024, L-020).** Her hub `SYSTEM.md`'nin
bir kopyasını taşıyor ve ana kopya güncellenince diğerleri geriden geliyordu;
fark hiçbir yerde görünmüyordu. `financer_takip` canlı örnekti: sözleşmesi
1.3'te kalmışken `waiting/` klasörünü kullanıyordu. Ana kopya tanımlandı
(`afgover/takip`), agent'a her oturum açılışında karşılaştırma kuralı yazıldı
(§10) ve uygulama geride kalan repoyu Ayarlar → Repolar'da işaretliyor. Tek
yere bırakılmadı: agent atlarsa kullanıcı görüyor.

**2. Bekleyenler genişledi (B-067, B-068).** Liste artık **bütün repolardan**;
senkron tüm bağlı repoları kapsıyor. Her satırda repo, öncelik ve kategori
etiketi var ve üçüne göre filtreleme yapılabiliyor. Etiketler ancak yerel
kopya (B-057) sayesinde gösterilebiliyor — klasör listelemesiyle çizilseydi
dosya indirilmeden bilinemezlerdi.

**3. Seçimden kayıt (B-069, K-023).** Herhangi bir belgede metin seçilip
görev / yorum / düzeltme / tartışma kaydı oluşturulabiliyor; seçim sarı
işaretle ya da kırmızı altı çiziliyle gösteriliyor. **İşaret ayrıca
saklanmıyor, kayıttan türüyor** — böylece işaret ile kayıt ayrışamıyor.

`flutter analyze` temiz, **284 test** (23 yeni). Ana kopya sözleşme 1.5;
agent kurulum talimatı ve masaüstü kopyası güncellendi.

## Kayıt

### Kullanıcı
> buyuk ihtimal financer projesinde eski sozlesme var o nedenle gorevlerle
> ilgili kayitlar eksik kalmis,
> agenta kayit sistemine birseyler yazip okudugu zaman sozlesmenin versiyonunu
> check etme ve eski sozlesmeyi yenisi ile guncelleme icerecek bir talimat
> kuralim, master sozlesme bizim olusturdugumuz takip reposunda, ve ordan
> uygulamaya  sync olsun ve yeni repolarda guncellenecek bir kural dizesi
> olustur,
> Bekleyenler penceresini biraz gelistirelim, burda tum repolardaki isler
> goruntulencek sekilde duzenleme yap, oncelik, kategori ve repoya gore
> filtreleme ozeligi ekle, bekleyenler sayfasindaki gorevlerde de etiketler
> olsun(repo, oncelik ve kategori),
> herhangibir yerde, oturumlar,raporlar,bilgi tabani, gorevler vs. yazili olan
> her herde, text secince sari highlight, kirmizi altini cizme, ve secilen
> metin uzerinden yeni bir gorev olusturulcak bir gelistirme istiyorum, user
> bunu yorum olarak da yapabilsin, yada duzeltme, tartisma, yada baska bir
> istegi varsa o sekilde kayit olusturabilsin

### Agent
Kullanıcının teşhisi doğrulandı: `financer_takip`'in sözleşmesi gerçekten
1.3'te kalmıştı ve `waiting/` klasörünü tanımlamıyordu.

Üçüncü istekte tasarımı belirleyen bir çatal vardı ve sorulmadan
başlanmadı: işaretleme kalıcı mı, kalıcıysa nerede durur? Kullanıcı
**"hub'a yazılsın, işaret kayıttan türesin"** dedi — en sağlam seçenek.

**Sözleşme 1.5** üç isteği de karşıladı: görev şemasına `source`/`quote`/`mark`
bağlam alanları, kategori varsayılanlarına `yorum`/`duzeltme`/`tartisma`, ve
§10 olarak ana kopya + sürüm kontrolü kural dizisi.

Uygulama tarafında dikkat gerektiren üç nokta çıktı:

1. **Bekleyenler etiketleri.** Liste bugüne kadar klasör listelemesinden
   çiziliyordu (B-031: dosya indirme yok). Öncelik ve kategori frontmatter'da
   olduğu için o yolla gösterilemezlerdi. Yerel kopya (B-057) zaten bütün görev
   dosyalarını indirdiği için liste oradan çizilir hâle getirildi — ağ maliyeti
   artmadı, etiketler bedavaya geldi.
2. **Senkron tüm repoları kapsamalıydı.** Yalnız aktif repo inseydi liste ancak
   o repoya geçilince dolardı. Paylaşılan istemci her repo için kullanılabildi
   çünkü L-019 düzeltmesinden beri token isteğin yolundan seçiliyor — ayrı Dio
   açmak ETag önbelleğini kaybettirirdi.
3. **İşaretlerde iç içe geçme.** Alıntıları sırayla `replaceRange` ile sarmak
   yetmedi: kısa alıntı uzunun içine düşünce dıştaki işaret ikiye bölünüyordu.
   Konumlar özgün metin üzerinde toplanıp çakışanlar elenerek, sondan başa tek
   seferde uygulanır hâle getirildi. Testin yakaladığı gerçek bir hataydı
   (→ L-021).

Filtrede bilinçli bir karar: **etiketi bilinmeyen görev filtreye takılmıyor.**
"Önceliği high olanlar" denince, önceliği henüz okunamamış bir görevi gizlemek
onu kaybetmek olurdu.
