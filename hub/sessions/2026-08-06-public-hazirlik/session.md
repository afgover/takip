---
id: S-2026-08-06-public-hazirlik
date: 2026-08-06
status: closed
reconstructed: false
author: afgover
topics: [public, sozlesme, dagitim]
artifacts: []
tasks_touched: [T-011]
---

# Oturum: Public'e hazırlık ve §10 zincirinin somutlaştırılması

## Özet
Kullanıcı repoyu public yapmaya ve diğer hub'ların sözleşmeyi ana kopyadan
otomatik kontrol etmesine karar verdi. Ayarı agent değiştiremez (hesap ayarı,
erişim yok) → **T-011** `waiting/`e kondu; hazırlık ve sözleşme tarafı yapıldı.

**Ölçülen ve B-097'de olmayan iki şey:**

1. **§10 zinciri bugün 404 veriyor.** `raw.githubusercontent.com` üzerinden ana
   kopyaya erişim, repo private olduğu için hiç çalışmamış. Yani sözleşmenin
   1.5'ten beri tarif ettiği "her agent oturum açılışında ana kopyayla
   karşılaştırır" adımı, diğer repolarda **hiçbir zaman koşamamış**. Public
   yapmanın en somut kazancı bu; kullanıcının isteği de zaten buydu.
2. **172 commit `afgover@gmail.com` taşıyor.** B-097'nin analizinde yoktu.
   Public olduğu an bu adres herkese görünür ve toplanır. Düzeltmenin ucuz anı
   yalnızca public'ten önce.
   **Karar (kullanıcı):** `git config user.email` noreply adresine çevrildi,
   geçmiş yeniden yazılmadı. Gerekçe: `filter-repo` bütün SHA'ları değiştirirdi
   ve hub kayıtları SHA'lara atıf yapıyor (`takip@ec267a3`, `144b1af`) —
   temizlik, kendi kayıt bütünlüğümüzü bozardı.

**Sözleşme 1.17.** §10'un kontrolü tek komuta indirildi (`curl` + `diff`), hem
sürüm farkını hem de en tehlikeli durumu — sürüm aynı, içerik farklı (ayrışma,
L-022) — tek adımda kapsıyor. Yanına bir kural yazıldı: **istek başarısız
olursa kontrol koşmamıştır**; "güncelim" diye yorumlanamaz ve kayda "kontrol
edildi" yazılamaz. Bu, L-035'in aynı kuralı: koşmayan bir kontrol, geçmiş bir
kontrol değildir — ve tam da bugün 404 döndüğü için yazılması gerekiyordu.

430 test, analyze temiz.

## Kayıt

### Kullanıcı
> takip reposunu public yapalim, sozlesmeyi diger repolar otomatik publikteki
> sozlesmeden check etsinler

### Agent
Önce neyin görünür olacağı ölçüldü: 42 oturum, 43 artifact, 282 commit, üç
açık güvenlik kaydı — ve B-097'de olmayan e-posta bulgusu. Kullanıcıya
soruldu; "bundan sonrası noreply" seçildi.

§10 zincirinin bugünkü durumu da ölçüldü: **404**. Sözleşme 1.17 ile kontrol
somut bir komuta indirildi ve başarısız isteğin nasıl yorumlanacağı yazıldı.
Public yapma adımı T-011 olarak kullanıcıya bırakıldı; ayar değiştikten sonra
agent `curl`'ün 200 döndüğünü **ölçüp** B-097'yi kapatacak.
