---
id: S-2026-07-30-versiyon-stratejisi
date: 2026-07-30
status: closed
topics: [mimari, strateji, karar]
artifacts: []
tasks_touched: []
---

# Oturum: Light/Pro versiyon tartışması

## Özet
Kullanıcı iki ayrı versiyon fikrini gündeme getirdi: mevcut backend'siz "light"
ve ekip çalışması için backend'li, webhook'lu, doğrudan içerik aktarımı olan
"pro". Tartışma sonunda fikir **ertelendi**: gerçek kullanım testinden sonra,
gerekirse yeniden ele alınacak (K-017).

Agent'ın karşı görüşünün özeti — kararın gerekçesi olarak kayda geçiyor:

1. **Zamanlama.** Light versiyonu 191 testten geçiyor ama henüz hiçbir gerçek
   cihazda çalışmadı (B-015, B-020, B-034, B-052 açık). "Light yetmiyor"
   tespitini yapabilecek tek veri kaynağı bir haftalık gerçek kullanım; o veri
   yokken ikinci versiyon planlamak, eksikleri tahmin ederek iş üretmek olur.
2. **L-001 riski.** İlk taskr backend işletme yükü yüzünden bırakılmıştı;
   mevcut mimari o dersin doğrudan sonucu. Ürün kullanılmaya başlamadan
   backend'i geri çağırmak aynı hatayı tekrarlamak olur.
3. **Takım çalışması backend gerektirmiyor.** GitHub zaten çok kullanıcılı:
   kim ne yaptı (commit yazarı), kim neye erişir (collaborator izinleri),
   eşzamanlı yazma çakışmaması (K-004 dosya-başına-görev) hazır. Hub reposuna
   bugün birkaç kişi collaborator yapılsa sistem çalışır. Geriye kalan gerçek
   boşluk **bildirim gecikmesi**.
4. **Backend'in gerçekten satın alacağı iki şey:** push bildirimi (B-060, zaten
   veri modeline dokunmayan stateless relay olarak tasarlı) ve dosya/medya eki
   (Contents API 1 MB sınırı + git'e binary koymanın kalıcı maliyeti).
5. **Öneri:** iki kod tabanı yerine "tek ürün + opsiyonel bileşen". İki versiyon
   iki veri modeli, iki auth, iki dağıtım ve aralarında bir uyumluluk yüzeyi
   demek; tek kişilik ekip için ağır ve zamanla ikisi birbirinden uzaklaşır.
   Ürün aslında sözleşmedir (SYSTEM.md), app onun istemcisi — ikinci bir
   istemci yazmak bugün de backend'siz mümkün.

Pro'yu haklı çıkaracak kanıtlar da kayda geçti (K-017): GitHub hesabı olmayan
kullanıcılar, düzenli medya eki, saniyeler mertebesinde bildirim ihtiyacı,
repo dışı entegrasyon.

## Kayıt

### Kullanıcı
> oluşturduğumuz app backende gerek olmadan tamamen yüklü cihazdan kendisi
> githuba bağlanıp ordan aldığı veriler ile çalışmak üzere yapılandırıldı,
> mutabıkmıyız?

### Agent
Doğrulandı — kod tabanında tek ağ adresi var: `https://api.github.com`. Kendi
backend'imiz yok, token cihazın güvenli deposunda, tüm veri hub'dan geliyor;
cihazda tutulanlar yalnızca yerel yardımcılar (outbox, ETag önbelleği,
ayarlar). Bu özelliği ileride bozabilecek iki nokta belirtildi: B-060 (push
için relay) ve B-061 (store aşamasında OAuth).

### Kullanıcı
> 2 versiyon hazırlasak nasıl olur, ilki şu an yaptığımız light versiyonu,
> backendle işi yok, user doğrudan github ile alakadar, 2. versiyon pro, ekip
> çalışması için daha ideal, backend ile webhook, doğrudan içerik aktarımı
> gibi daha gelişmiş özellikler barındırır, fikrin nedir?

### Agent
Yön makul ama sıra yanlış görüşü savunuldu; yukarıdaki beş maddelik gerekçe
sunuldu ve "iki versiyon" yerine "tek ürün + opsiyonel bileşen" önerildi.

### Kullanıcı
> tamam bu önerimi şimdilik bir kenara bırakalım, gerçek uygulama testine
> başladıktan sonra gerekirse gündeme getiririz

### Agent
Karar K-017 olarak `EVOLUTION.md`'ye, yeniden değerlendirme maddesi B-064
olarak backlog'a işlendi.
