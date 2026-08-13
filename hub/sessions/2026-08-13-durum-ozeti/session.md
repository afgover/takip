---
id: S-2026-08-13-durum-ozeti
date: 2026-08-13
status: open
reconstructed: false
author: afgover
topics: [durum-ozeti, acilis]
artifacts: []
tasks_touched: []
---

# Oturum: Durum özeti ile açılış

## Özet
(oturum açık)

## Kayıt

### Kullanıcı
> takip reposu için oturum aç. Başlangıç olarak son durumu özetle: git durumu
> (branch, bekleyen değişiklikler, son commitler) ve yarım kalan iş var mı.

### Agent — açılış kontrolleri ve durum özeti

**Git:** `main`, `origin/main` ile eşit, çalışma ağacı temiz, stash yok. Son
commit `d56798b` — bir önceki oturumun (S-2026-08-12-bildirim-yanlış-yönlendirme)
kapanışı. Ondan önceki iki commit aynı işin kendisi: `391ef3c` B-126 düzeltmesi
(outbox damgalı taslağın damgasını ezmesin) ve sözleşme 1.24.

**Açılış kontrolleri (AGENT_PROTOCOL madde 0–5):**

0. Hub dili `tr`; kullanıcı da Türkçe yazıyor — çakışma yok.
2. `tasks/inbox/` boş (yalnız README).
3. **Sözleşme kontrolü KOŞMADI.** `curl` ana kopyayı çekemedi (HTTP 404).
   Sebebi hata değil, durumun kendisi: `afgover/takip` hâlâ **private** (T-011
   `waiting/`te bekliyor), bu yüzden `raw.githubusercontent.com` 404 dönüyor.
   Bu hub zaten **ana kopyanın kendisi** olduğundan burada kontrol edilecek bir
   ayrışma yok; ama §10 zincirinin *diğer* hub'lar için hâlâ çalışmadığı bu
   404'le birebir görünüyor — B-097/T-011'in gerçek bedeli bu.
4. `SECURITY.md`'deki son `tarama` kaydı SEC-008, **2026-08-04** → 9 günlük,
   30 gün eşiğinin altında. Tarama koşulmadı, gerekmiyordu.
5. §13 geçici madde **G-001** (1.12 öncesi `waiting/` sorularına seçenek ekle):
   bu hub'da yapacak bir şey yok — `waiting/`teki iki görevin (T-010, T-011)
   ikisi de zaten `options` taşıyor, madde idempotent olduğu için atlanır.

**Yarım kalan iş:**
- `tasks/waiting/` iki görev, ikisi de kullanıcıda: **T-011** repoyu public yap
  (ön hazırlığı bitmiş, tek adım kaldı), **T-010** release imza anahtarı
  (bilinçli ertelenmiş; tetikleyicisi "APK bu bilgisayardan çıkacağı gün").
- `tasks/active/` boş, `inbox/` boş — devam eden kodlama işi yok.
- `BACKLOG.md`: 13 açık madde (biri şablon satırı B-001). Faz 5'te asıl duranlar
  B-052/B-053 (bir hafta gerçek kullanım + geri bildirim turu), B-097/B-098
  (public + store), B-103 (SEC-012 token kapsamı), B-101 (SEC-010 imza),
  B-110 (çoklu kullanıcı Katman 3+4). Faz 6 (B-060…B-064) bilinçli beklemede.
- `EVOLUTION.md`: Aşama 4 (Günlük Kullanım) aktif.

### Kullanıcı
> repo artık public

### Agent — T-011 kapandı, §10 zinciri ölçüldü

**Doğrulama önce, kayıt sonra** (T-011'in kendi koşulu): iki bağımsız ölçüm —
`api.github.com/repos/afgover/takip` → `"private": false`, ve §10'un kendi
komutu `curl -fsSL .../main/hub/SYSTEM.md` → 200, 38323 bayt, yerel kopyayla
**fark yok**. Aynı komut bu oturumun açılışında, dakikalar önce 404 dönüyordu;
açılış kaydına "kontrol koşmadı" diye yazılmıştı. Diğer hub'ların sözleşmeyi
ana kopyadan kontrol etmesi artık gerçekten çalışıyor.

Yazılanlar:
- **T-011** `waiting/` → `done/`; `result` dolduruldu, ölçüm notu eklendi.
- **B-097** işaretlendi. Maddenin özgün metni silinmedi, `[x]` kaydın altına
  "karar verilmeden önce yazılmıştı" etiketiyle taşındı.
- **SEC-013** (`karar`, `kapali`): görünürlük değişikliğinin veri sonuçları —
  hub içeriğinin tamamı görünür; 2026-08-06 öncesi 172 commit'te gerçek
  e-posta halka açık (geçmiş bilinçli olarak yeniden yazılmadı); üç açık
  güvenlik kaydı da yayımlandı (bilinçli, K-032); geri dönüşü yok sayılır.
  Ayrıca bundan sonra değişen şey: public repoda yanlışlıkla commit'lenen bir
  sır **geri alınamaz** — private'ta geçmiş temizlenebiliyordu.
- **R-008**: sözleşmede kırıcı değişiklik yapma özgürlüğü bitti. Yeni alanlar
  isteğe bağlı girer, zorunluluk §13 geçici maddesiyle geçilir, sürüm her
  değişiklikte artar.

**Düzeltilen bağ (SEC-010):** kayıt "B-097 kapanmadan bu kayıt kapanmalı"
diyordu, yani repoyu public yapmayı imza anahtarına bağlıyordu. Bağ yanlış
hedefteydi: tehlikeli olan görünürlük değil **APK'nın bu makineden çıkması**.
B-097 ikisini tek maddede topluyordu, gerçekleşen yalnız repo adımı; public
repo tek başına debug anahtarlı bir APK'yı kimsenin eline vermiyor, bugün risk
artmadı. Koşul yeniden yazıldı: SEC-010 kapanmadan **Releases'a APK konmaz**.
SEC-010 `acik` kalıyor, tetikleyicisi T-010'da (ertelenmiş).

### Kullanıcı
> devam etmeden önce 2 tane büyük çaplı ekleme yapmak istiyorum,
> ilki görev ağacı diye bir sayfa oluşturalım, agentın bir plan dahilinde
> oluşturduğu, (örnek sec 007, D021, yada herhangibir numaralandırma)ile
> oluşturduğu yada basit bir iş için önerdiği tüm adımlar bu sayfada kayıt
> altına alınsın, (session kayıtlarında herşey kaydediliyor fakat yapılan iş
> akışını takip etmek için bu yöntem daha ideal olur diye düşünüyorum)
> tamamlananlar tamamlandı olarak işaretlenir, yapılcak olanlar kalı, iptal
> edilenler nedeni ile iptal olarak işaretlenir. sistemin diğer akışını bu
> yaptığımız değiştirmesin, amaç yapılan işleri maddeler halinde izlemek,
> gerekirse müdahale etmek,
> 2. eklenti is yazılar arasında çalışacak bir hyperlink mekanizması kur,
> agent yada user texte tıklayınca istediği sayfanın istediği bölümüne geçiş
> yaptıran hyperlinkler oluşturabilsin, agenta gerekli görülen yerlerde bu
> mekanizmayı kullanacak şekilde teşvik edici bir not ekle yeni sözleşmeye

### Agent — dört karar soruldu, sözleşme 1.25 yazıldı

Uygulamaya bakıldı: `onTapLink` v1.5'ten beri `HubMarkdown`'dan yukarı
iletiliyor ama **hiçbir ekran uygulamıyor** — yani bugüne kadar uygulamada bir
bağlantıya dokunmak hiçbir şey yapmıyordu. İkinci madde bu yüzden kod işi.

Kullanıcıya dört soru soruldu ve cevapları: tek kök dosya (`PLAN.md`), kapsam
eşiği 3+ adım, uygulamada **ikisi de** (ağaç ekranı + tıklanabilir bağlantı),
çapa **ID tabanlı**.

**Bir düzeltme yapıldı:** çapa sorusunun seçenek metninde "GitHub'da çalışması
için başlıkların ID ile başlaması yeter" yazılmıştı; yanlış. GitHub çapayı
başlığın **tamamından** üretiyor, yani `#SEC-010` orada bölüme atlamıyor.
Kullanıcıya söylendi ve sınır sözleşmeye açıkça yazıldı — ölçmeden "çalışıyor"
dememe kuralının aynısı.

**Sözleşme 1.25 (§14 + §15), iki dil varyantında.** §14 görev ağacı: şema,
3+ adım eşiği, "diğer akışların yerine geçmez, onlara bağlantı verir" sınırı,
nedensiz iptal yasağı, **dosyanın opsiyonel olması**. §15 bağlantılar: ID
tabanlı çapa, GitHub sınırı, agent'ı teşvik eden "ne zaman bağlantı verilir"
kuralı (ilk geçiş bağlanır, tekrarları düz kalır). Protokole 7b/7c maddeleri
eklendi.

Bu, [R-008](knowledge/rules.md#R-008)'in ilk sınavıydı ve ikisi de **eklemeli**
çıktı: `PLAN.md` yoksa hub sözleşmeye aykırı değil, eksik bağlantı ihlal değil.
Eski hub'lar dokunulmadan geçerli.

**Uygulama:** `lib/hub/plan.dart` (ayrıştırıcı — girintiden ağaç, üstü çizili +
gerekçe = iptal, alan adları iki dilde), `lib/hub/hub_link.dart` (bağlantı
çözümleme + çapa satırı bulma), `lib/features/browse/plan_screen.dart` (açık
planlar üstte, kendiliğinden açık, durum filtresi), `hub_link_nav.dart` ve
`DocumentScreen`'e çapa desteği. Bağlantı dokunuşu beş ekrana bağlandı: belge,
yol haritası, güvenlik, bilgi tabanı, görev detayı.

Çapaya kaydırma için belge **çapa satırında ikiye bölünüp** aradaki işarete
kaydırılıyor. Alternatif, çizilmiş metinde bir satırın konumunu hesaplamaktı —
markdown'ın kendi sarma kurallarını uygulamadan tahmin etmek demekti. Bölme
yalnız satır başındaki yapılarda yapılıyor; girintili bir çapa bulunursa
kaydırma yapılmıyor, belge baştan açılıyor.

İlk plan olarak [P-001](../../PLAN.md) yazıldı: bu işin kendisi.

**Süit iki gerçek hata yakaladı, ikisi de düzeltildi:** (1) SEC-013'e
`Tür: karar` yazmıştım ama §12'nin sözlüğünde o değer yoktu — gerçek
`SECURITY.md`'yi okuyan test bunu gördü. Dördünden birine sıkıştırmak kaydı
yanlış etiketlerdi (repoyu public yapmak ne tarama, ne önlem, ne açık), o
yüzden **tür sözleşmeye eklendi** (§12, iki dil + uygulama + arayüz metni).
(2) Yeni tarayıcı kartı "Aktivite"yi test yüzeyinin dışına itmişti.

**Bu oturumdan gelmeyen bir kırık:** `task_lifecycle_test`'in iki testi 10
dakika zaman aşımına düşüyor. Ölçüldü — oturum öncesi commit (`d56798b`) ayrı
bir worktree'ye çıkarılıp aynı dosya orada koşuldu: **aynı iki test aynı
şekilde takılıyor.** Yani sözleşme 1.25 işiyle ilgisi yok. Kök neden kuvvetle
muhtemel `pumpAndSettle`'ın sonsuz animasyonla buluşması (gönder düğmesindeki
`CircularProgressIndicator`). [B-130](../../BACKLOG.md#B-130) olarak yazıldı,
düzeltilmedi — kullanıcının işi bu değildi.

### Kullanıcı
> buraya kadarki versiyonu apk uretip telefona kurarmisin

### Agent — cihaza kuruldu
`tool/install.sh` (release, `adb install -r`, kaldırma yok — L-014):
"Success", veri korundu. APK 56.1 MB, cihaz `R5CW71GRKPB`. `git diff lib/` boş,
yani kurulan yapı push'lanmış koddan — sözleşme 1.25'in uygulama tarafı
(görev ağacı ekranı + bağlantı gezinmesi) cihazda. İmza hatırlatması yine
çıktı: yapı hâlâ debug anahtarıyla imzalı (SEC-010).

### Kullanıcı
> devam et b-130 u bitir

### Agent — B-130 kapandı, kök neden ilk tahminden derinmiş

**İlk teşhis eksikti.** `pumpAndSettle` gerçekten asılıyor (sonsuz dönen
gösterge varken hiç oturmuyor) ama onu düzeltmek yetmedi; test yine 10 dakika
takıldı. Aşama aşama `debugPrint` koyarak takılmanın yeri bulundu:
`pollAndSettle` → `allPendingTasksProvider`.

**Kök neden:** provider'ın gövdesi ekran çizilirken testin **sahte zaman**
zonunda başlıyor. Gerçek async işe (yerel kopya + ağ) dayandığı için orada hiç
bitmiyor; sonuç "sonsuza kadar yükleniyor" olarak **önbelleğe yerleşiyor** ve
`.future` o ölü completer'a bağlanıyor. Belirti yanıltıcıydı: aynı
fonksiyonlar (`pendingFromStore`, `listPending`) `runAsync` içinden tek tek
çağrılınca sorunsuz bitiyordu — yalnız provider üzerinden çağrılınca değil.

**Düzeltme** (yalnız test tarafı, uygulama kodu değişmedi): `runAsync` içinde
provider'ı geçersiz kıl ve **durumu** bekle (`.future`yi değil);
`pumpAndSettle` yerine sınırlı `settle`. İki test 20 dakika zaman aşımı yerine
**2 saniyede** geçiyor. Ders [L-047](../../knowledge/lessons.md#L-047).

Teşhis üç yanlış hipotez ürettikten sonra ölçümle çözüldü; plan işin ortasında
[P-002](../../PLAN.md) olarak yazıldı ve bunun geriye dönük yazıldığı kaydın
kendisinde belirtildi.

Yolda çıkan ders [L-046](../../knowledge/lessons.md#L-046): `onTapLink` v1.5'te
açılmış, yorumunda "Faz 4'te bağlanacak" yazıyordu ve hiç bağlanmadı — testi
bile vardı (geri çağrının çağrıldığını doğruluyordu), ama kimsenin onu
geçirmediğini gösteren bir şey yoktu. Yarım bırakılan uzantı noktası kod
okuyana "destekleniyor" der, kullanıcıya hiçbir şey demez.
