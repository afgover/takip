# PLAN.md — Görev Ağacı

Çok adımlı işlerin adımları ve durumu. Biçim ve kapsam:
[`SYSTEM.md` §14](SYSTEM.md#14). Yeni plan **en üste** yazılır; geriye dönük
plan (`Türetilmiş: true`) kapalı doğduğu için kapalıların arasına tarih
sırasıyla girer.

## P-011 — B-139: görevde "hangi hub" ayrımı iki tarafta da görünsün
- **Tarih:** 2026-08-21
- **Kaynak:** [S-2026-08-21-hub-ayrimi](sessions/2026-08-21-hub-ayrimi/session.md)
- **Durum:** tamamlandi
- **İlgili:** [B-139](BACKLOG.md#B-139), [L-045](knowledge/lessons.md#L-045), [§4](SYSTEM.md#4)

> Doğrulama iki boşluk buldu ve ikisi de **aynı ilkenin** eksik uygulanması:
> sözleşme 1.24 "bildirim hedef hub'ını kendisi söyler" diyor, ama (a) normal
> görev bunu söylemiyor, (b) kullanıcı görev **detayındayken** hangi hub'da
> olduğunu göremiyor — üstelik yazma düğmeleri tam orada.

- [x] P-011.1 — Doğrulama: iki tarafın bütün yüzeyleri tek tek ölçülsün · ✅ 2026-08-21 · iki boşluk + bir bitişik bulgu ([B-140](BACKLOG.md#B-140))
- [x] P-011.2 — Agent tarafı: normal görev de `Repo` satırını taşısın · ✅ 2026-08-21
- [x] P-011.3 — Kullanıcı tarafı: detay ekranına repo rozeti · ✅ 2026-08-21
- [x] P-011.4 — Tamamlananlar da repo damgası taşısın (rozet orada da çalışsın) · ✅ 2026-08-21
- [x] P-011.5 — Testler · ✅ 2026-08-21 · 8 yeni test (612)
- [x] P-011.6 — Kayıtlar, tam süit + push · ✅ 2026-08-21 · 612 test
- [x] P-011.7 — APK derle ve telefona kur · ✅ 2026-08-21 21:00 · yerinde güncelleme, veri korundu

## P-010 — B-135: bildirilmiş bekleme yeniden bildirilebiliyor
- **Tarih:** 2026-08-21
- **Kaynak:** [S-2026-08-21-offline-mukerrer-kuyruk](sessions/2026-08-21-offline-mukerrer-kuyruk/session.md)
- **Durum:** tamamlandi
- **İlgili:** [B-135](BACKLOG.md#B-135), [T-018](tasks/active/2026-08-21-bekleyen-gorevlerin-offline-da-tamamlanmasi.md)

> **Karar (2026-08-21, kullanıcı).** Bildirilmiş görev listede **kalır**,
> "bildirildi" işaretiyle. App dosyayı `waiting/`ten taşıyamıyor (R-001);
> gizlemek, agent işlemezse sessiz kayıp demek olurdu — K-022'nin çözdüğü
> sorunun aynısı. Kapsam çevrimdışıyla sınırlı değil: kusur tek (bilgi kalıcı
> değil), kayıt katmanı iki.

- [x] P-010.1 — Cihazda "bildirildi" kaydı: repo + görev yolu → zaman · ✅ 2026-08-21 · `lib/hub/reported_waiting.dart`
- [x] P-010.2 — İki gönderim yolu da kaydı yazsın: gönderildi ve kuyruğa alındı · ✅ 2026-08-21
- [x] P-010.3 — Detay ekranı düğme durumunu kayıttan okusun, widget'tan değil · ✅ 2026-08-21 · `_reported` alanı kalktı
- [x] P-010.4 — Bekleyenler listesinde "bildirildi" rozeti · ✅ 2026-08-21 · durum rozetinin yerine geçiyor
- [x] P-010.5 — Kayıt, görev `waiting/`ten çıkınca temizlensin · ✅ 2026-08-21 · senkronun silinmiş belge temizliğiyle aynı yerde
- [x] P-010.6 — Arayüz metinleri (`app_tr.arb`, `app_en.arb`) · ✅ 2026-08-21
- [x] P-010.7 — Testler: mükerrer gönderimi kuran regresyon + temizleme · ✅ 2026-08-21 · 18 yeni test
- [x] P-010.8 — Kayıtlar, tam süit + push · ✅ 2026-08-21 · 604 test, `flutter analyze` temiz

## P-009 — B-133: sarkan adım satırı tamamlanma tarihini yutuyor
- **Tarih:** 2026-08-15
- **Kaynak:** [S-2026-08-15-gorev-agaci-tesviki](sessions/2026-08-15-gorev-agaci-tesviki/session.md)
- **Durum:** tamamlandi
- **İlgili:** [B-133](BACKLOG.md#B-133), [§14](SYSTEM.md#14)

- [x] P-009.1 — Ayrıştırıcı: devam satırı `·` ayracını yeniden arasın · ✅ 2026-08-15
- [x] P-009.2 — Testler: ayracın satır sonunda ve devam satırında olduğu haller · ✅ 2026-08-15 · 5 yeni test
- [x] P-009.3 — Gerçek `PLAN.md` üzerinde ölçüm: kaç adımda tarih geri geldi · ✅ 2026-08-15 · 19 adım (ilk sayım 9 demişti, gözleydi)
- [x] P-009.4 — Kayıtlar ve push · ✅ 2026-08-15 · 586 test

## P-004 — Sözleşme 1.26: geriye dönük plan ve ağacın doldurulması
- **Tarih:** 2026-08-15
- **Kaynak:** [S-2026-08-15-gorev-agaci-tesviki](sessions/2026-08-15-gorev-agaci-tesviki/session.md)
- **Durum:** tamamlandi
- **İlgili:** [B-134](BACKLOG.md#B-134), [§14](SYSTEM.md#14), [R-008](knowledge/rules.md#R-008)

> **Karar (2026-08-15, kullanıcı).** Ağaçların boş kalmasının sebebi agent'ların
> ihmali değil, kuralın yapısal boşluğu: §14 adımları "uygulanmadan önce" ister
> ve iş geç fark edildiğinde **hiçbir yol bırakmaz** — uydur (yasak) ya da atla.
> Bu repoda bugün tam olarak bu yaşandı. Çözüm, **uydurma** ile **türetme**yi
> ayırmak: geriye dönük plan serbest, ama `Türetilmiş: true` ile işaretli ve
> `Kaynak:` adımların nereden türetildiğini gösteriyor. Hub'da bu kalıp zaten
> var (oturumlarda v1.6).
>
> Adım satırları bilerek **kısa** yazıldı: gerekçe buraya değil, bağlantı
> verilen kayda gider ([B-133](BACKLOG.md#B-133) ölçümü).

- [x] P-004.1 — `SYSTEM.md` §14: geriye dönük plan kuralı + sürüm 1.26 · ✅ 2026-08-15
- [x] P-004.2 — `SYSTEM.en.md` aynı değişiklik · ✅ 2026-08-15
- [x] P-004.3 — `AGENT_PROTOCOL.md` ve `.en`: madde 7b'ye geç fark edilen iş yolu · ✅ 2026-08-15
- [x] P-004.4 — Uygulama: `Plan.reconstructed` + kartta etiket · ✅ 2026-08-15
- [x] P-004.5 — Arayüz metinleri (`app_tr.arb`, `app_en.arb`) · ✅ 2026-08-15
- [x] P-004.6 — Sürüm tutarlılığı: `constants.dart`, iki README · ✅ 2026-08-15
- [x] P-004.7 — `takip`'in geçmişi: çok adımlı işler oturum kayıtlarından türetilir · ✅ 2026-08-15 · dört plan: P-005…P-008
- [x] P-004.8 — Testler: ayrıştırıcı, ekran etiketi, sürüm tutarlılığı · ✅ 2026-08-15 · 581 test
- [x] P-004.9 — `EVOLUTION.md` 1.26 kaydı, oturum kaydı, tam süit + push · ✅ 2026-08-15

## P-005 — Görev kapsamı: liste ve hedef aktif repoya bağlandı
- **Tarih:** 2026-08-15
- **Kaynak:** [S-2026-08-15-gorev-kapsami](sessions/2026-08-15-gorev-kapsami/session.md)
- **Durum:** tamamlandi
- **Türetilmiş:** true
- **İlgili:** [B-131](BACKLOG.md#B-131), [B-132](BACKLOG.md#B-132), [L-048](knowledge/lessons.md#L-048)

> Planı **iş bittikten sonra** yazıldı (sözleşme 1.26). Bu, kuralı doğuran
> vakanın kendisi: çok adımlı olduğu anlaşıldığında adımlar bitmişti ve o
> oturumda ağaç atlanmıştı. Adımlar oturum kaydından türetildi.

- [x] P-005.1 — Mekanizma ölçüldü: görev nereye gidiyor, agent ne görüyor · ✅ 2026-08-15
- [x] P-005.2 — Yanlış yönlenme araştırıldı: inbox geçmişi + bütün yazma yolları · ✅ 2026-08-15
- [x] P-005.3 — Bekleyenler aktif repoya daraltıldı · ✅ 2026-08-15 · [B-131](BACKLOG.md#B-131)
- [x] P-005.4 — Ekle ekranına hedef repo seçici kondu · ✅ 2026-08-15 · [B-132](BACKLOG.md#B-132)
- [x] P-005.5 — Testler ve tam süit · ✅ 2026-08-15 · 540 test
- [x] P-005.6 — Ders ve backlog kayıtları · ✅ 2026-08-15 · [L-048](knowledge/lessons.md#L-048)

## P-006 — Çoklu hub'da bildirimin yanlış repoya düşmesi
- **Tarih:** 2026-08-12
- **Kaynak:** [S-2026-08-12-bildirim-yanlis-yonlendirme](sessions/2026-08-12-bildirim-yanlis-yonlendirme/session.md)
- **Durum:** tamamlandi
- **Türetilmiş:** true
- **İlgili:** [B-126](BACKLOG.md#B-126), [B-127](BACKLOG.md#B-127), [L-045](knowledge/lessons.md#L-045)

- [x] P-006.1 — İki agent'ın raporu incelendi, kök neden bu uygulamada arandı · ✅ 2026-08-12
- [x] P-006.2 — Kök neden bulundu: `add()` taslağı koşulsuz aktif repoyla damgalıyordu · ✅ 2026-08-12
- [x] P-006.3 — Kuyruk damgayı korur hâle getirildi + regresyon testi · ✅ 2026-08-12 · [B-126](BACKLOG.md#B-126)
- [x] P-006.4 — Sözleşme 1.24: bildirim hedef hub'ını kendisi söyler · ✅ 2026-08-12 · [B-127](BACKLOG.md#B-127)
- [x] P-006.5 — Mekanizma değerlendirmesi: doktrin katmanı hasarı önlemişti · ✅ 2026-08-12

## P-007 — i18n: 337 metnin taşınması ve sözleşmenin İngilizcesi
- **Tarih:** 2026-08-08
- **Kaynak:** [S-2026-08-08-i18n-tamamlama](sessions/2026-08-08-i18n-tamamlama/session.md)
- **Durum:** tamamlandi
- **Türetilmiş:** true
- **İlgili:** [B-115](BACKLOG.md#B-115), [B-116](BACKLOG.md#B-116), [L-043](knowledge/lessons.md#L-043)

- [x] P-007.1 — Kalan 6 ekranın metinleri ARB'ye taşındı · ✅ 2026-08-08
- [x] P-007.2 — Arayüz dili ile kayıt dili ayrıldı: biri okuyanı, biri hedef repoyu izliyor · ✅ 2026-08-08
- [x] P-007.3 — Ayrımın ortaya çıkardığı kusur giderildi: bildirim gövdeleri hub diline bakmıyordu · ✅ 2026-08-08
- [x] P-007.4 — Sözleşme 1.21: dil varyantı, düz adla saklama kuralı · ✅ 2026-08-08 · [B-116](BACKLOG.md#B-116)
- [x] P-007.5 — Çevrilmeyecek sınır yazıldı: kategori ve tür değerleri veridir · ✅ 2026-08-08
- [x] P-007.6 — İki yeni ölçüm: kayıt dili testi + ölü ARB anahtarı kontrolü · ✅ 2026-08-08 · [L-043](knowledge/lessons.md#L-043)
- [x] P-007.7 — Tam süit · ✅ 2026-08-08 · 460 test

## P-008 — Güvenlik katmanı: ilk tarama ve kapsam denetimi
- **Tarih:** 2026-08-04
- **Kaynak:** [S-2026-08-04-guvenlik-taramasi](sessions/2026-08-04-guvenlik-taramasi/session.md)
- **Durum:** tamamlandi
- **Türetilmiş:** true
- **İlgili:** [SEC-008](SECURITY.md#SEC-008), [SEC-012](SECURITY.md#SEC-012), [L-035](knowledge/lessons.md#L-035)

- [x] P-008.1 — 68 paket OSV'ye soruldu · ✅ 2026-08-04
- [x] P-008.2 — Boş sonuç kontrol grubuyla doğrulandı · ✅ 2026-08-04 · [L-035](knowledge/lessons.md#L-035)
- [x] P-008.3 — Sır taraması: çalışma ağacı ve git geçmişinin tamamı · ✅ 2026-08-04
- [x] P-008.4 — Android yapılandırması incelendi; iki bulgu çıktı · ✅ 2026-08-04 · SEC-009, SEC-010
- [x] P-008.5 — Token kapsam denetimi eklendi, fazladan istek yapmadan · ✅ 2026-08-04
- [x] P-008.6 — Kapanamayan kısım ayrı kayıt oldu, ölçümü kullanıcıya soruldu · ✅ 2026-08-04 · [SEC-012](SECURITY.md#SEC-012), T-006

## P-003 — B-103: token kapsam kontrolü (SEC-012)
- **Tarih:** 2026-08-15
- **Kaynak:** [S-2026-08-15-gorev-kapsami](sessions/2026-08-15-gorev-kapsami/session.md)
- **Durum:** tamamlandi
- **İlgili:** [B-103](BACKLOG.md#B-103), [SEC-012](SECURITY.md#SEC-012),
  [SEC-006](SECURITY.md#SEC-006), [T-006](tasks/done/2026-08-04-token-kapsam-olcumu.md)

> **Karar (2026-08-15, kullanıcı):** kontrol token'ın *nasıl üretildiğini*
> tahmin etmeye çalışmaz — "All repositories" modu ölçülemez ve hesabın toplam
> repo sayısı bu token'la zaten okunamaz. Bunun yerine **fazla erişim** ölçülür:
> **N** = token'ın gördüğü repo sayısı, **K** = bu token'la bağlı hub sayısı.
> `N > K` → uyarı. Eşik keyfi bir sabit değil, uygulamanın kendi ihtiyacı.
> Zamanlama: bağlantı kurulurken + Ayarlar'da elle tetiklenen düğme.

- [x] P-003.1 — Repo sayısını ölçen katman: `GET /user/repos?per_page=1`,
      `Link` başlığındaki `rel="last"` sayfa numarası = toplam. **En iyi çaba**
      ([readLogin](../lib/hub/hub_access.dart) çizgisi): hata/başlıksız yanıt →
      `null` = "bilinmiyor", asla 0 sayılmaz · ✅ 2026-08-15 ·
      `lib/github/repo_scope_api.dart`; süzgeç parametresi bilerek verilmedi —
      ölçülen istek sadeydi, `per_page` kapsamı değil sayfalanışı değiştirir
- [x] P-003.2 — Karar mantığı `token_scope.dart`'a: N ve K'dan uyarı üret.
      **Tek yönlü** ([L-009](knowledge/lessons.md#L-009)): yalnız `N > K`
      konuşur; N bilinmiyorsa, N ≤ K ise ve K bilinmiyorsa **susar** — "bu token
      dar" cümlesi hiçbir yolda kurulmaz · ✅ 2026-08-15 · `tokenScopeExcess`;
      susduğu üç dal (N null, N ≤ K, K < 1) dosyada tek tek gerekçeli
- [x] P-003.3 — Bağlantı kurulurken koş: `checkHubAccess`'e ekle, mevcut
      klasik-token uyarısıyla tek uyarıda birleşsin. K = aynı token'la bağlı
      hub sayısı + kurulmakta olan bağlantı · ✅ 2026-08-15 · K hesabı
      `reposNeededForToken`'da ve `hubAccessVerifierProvider`da çağrılıyor —
      iki çağrı yerinin (onboarding, bağlantı ekranı) aynı kuralı iki kez
      yazıp zamanla ayrışmaması için. Klasik token uyarısı varsa ölçüm hiç
      koşmuyor: klasik token zaten hesabın tamamını kapsıyor
- [x] P-003.4 — Ayarlar'a "token kapsamını ölç" düğmesi; sonucu (uyarı ya da
      "fazla erişim görünmüyor") ekranda göster · ✅ 2026-08-15 · üç sonuç
      **ayrı**: ölçülemedi / fazla erişim yok / uyarı. Klasik token'da istek
      harcanmıyor, uyarı önekten okunuyor
- [x] P-003.5 — Arayüz metinleri: `app_tr.arb`, `app_en.arb` · ✅ 2026-08-15;
      uyarı gövdeleri `hub/token_scope.dart`'ta kalıyor — B-092'nin çizgisi,
      çeviri kapsamı `lib/features` altını ölçüyor
- [x] P-003.6 — Testler: sayfalama başlığının ayrıştırılması, tek yönlü yorumun
      her dalı, bağlantı akışı, Ayarlar düğmesi · ✅ 2026-08-15 · **34 yeni
      test**. Süit yazılırken bir hata da yakalandı: aynı türden iki yer
      tutucunun sırası ters verilmişti ve hiçbir katman görmüyordu
      ([L-050](knowledge/lessons.md#L-050))
- [x] P-003.7 — Kayıtlar: [SEC-012](SECURITY.md#SEC-012) güncellenir (kontrol
      artık var; kalan sınır yazılır), B-103 işaretlenir, oturum kaydı; tam süit
      + push · ✅ 2026-08-15; SEC-012 `kapali` — başlığındaki iddia ("ölçülemiyor")
      artık geçerli değil, kalan sınır kayda ayrıca yazıldı. **575 test geçti**,
      `flutter analyze` temiz

## P-002 — B-130: entegrasyon testlerinin zaman aşımı
- **Tarih:** 2026-08-13
- **Kaynak:** [S-2026-08-13-durum-ozeti](sessions/2026-08-13-durum-ozeti/session.md)
- **Durum:** tamamlandi
- **İlgili:** [B-130](BACKLOG.md#B-130), [L-047](knowledge/lessons.md#L-047)

> Bu plan işin **ortasında** yazıldı: teşhis birkaç adım sürünce çok adımlı bir
> işe dönüştüğü anlaşıldı (sözleşme §14 planı önce ister). Adımlar geriye dönük
> uydurulmadı, gerçekte koşulan sırayla yazıldı.

- [x] P-002.1 — Kırığın bu oturumdan gelmediğini ölç: oturum öncesi commit ayrı
      worktree'de koşuldu, aynı iki test aynı şekilde düştü · ✅ 2026-08-13
- [x] P-002.2 — `pumpAndSettle` teşhisi: sonsuz dönen gösterge varken hiç
      oturmuyor; yerine sınırlı `settle` · ✅ 2026-08-13
- [x] P-002.3 — Asıl takılmayı daralt: aşama işaretleriyle `pollAndSettle`
      içindeki `allPendingTasksProvider` bulundu · ✅ 2026-08-13
- [x] P-002.4 — Kök neden: provider gövdesi ekran çizilirken **sahte zaman
      zonunda** başlıyor ve gerçek async işe dayandığı için hiç bitmiyor;
      `.future` de o ölü completer'a bağlı kalıyor · ✅ 2026-08-13
- [x] P-002.5 — Düzeltme: `runAsync` içinde geçersiz kıl + durumu bekle ·
      ✅ 2026-08-13; iki test 20 dakika zaman aşımı yerine 2 saniyede geçiyor
- [x] P-002.6 — Teşhis kalıntılarını temizle (geçici test, izleme satırları,
      uygulama kodundaki geçici çıktılar) · ✅ 2026-08-13
- [x] P-002.7 — Ders kaydı, backlog işareti, tam süit ve push · ✅ 2026-08-13;
      **533 test, hepsi geçti** (26 saniye — eskiden 20+ dakika sürüp 2 kırıkla
      bitiyordu)

## P-001 — Görev ağacı ve belgeler arası bağlantı mekanizması
- **Tarih:** 2026-08-13
- **Kaynak:** [S-2026-08-13-durum-ozeti](sessions/2026-08-13-durum-ozeti/session.md)
- **Durum:** tamamlandi
- **İlgili:** sözleşme 1.25, [R-008](knowledge/rules.md#R-008),
  [B-128](BACKLOG.md#B-128), [B-129](BACKLOG.md#B-129)

- [x] P-001.1 — Sözleşme §14: `PLAN.md` şeması, kapsam eşiği (3+ adım), diğer
      akışlarla sınır · ✅ 2026-08-13
- [x] P-001.2 — Sözleşme §15: ID tabanlı çapa, GitHub sınırının açıkça yazılması,
      agent'ı teşvik eden "ne zaman bağlantı verilir" kuralı · ✅ 2026-08-13
- [x] P-001.3 — İngilizce varyant (`SYSTEM.en.md` §14–§15 + sürüm) · ✅ 2026-08-13
- [x] P-001.4 — `AGENT_PROTOCOL.md` ve `.en` — madde 7b/7c · ✅ 2026-08-13
- [x] P-001.5 — `PLAN.md` oluşturuldu; ilk kaydı bu planın kendisi · ✅ 2026-08-13
- [x] P-001.6 — Uygulama: ayrıştırıcı (`lib/hub/plan.dart`) — plan blokları,
      girintiden ağaç, üstü çizili + neden = iptal · ✅ 2026-08-13
- [x] P-001.7 — Uygulama: görev ağacı ekranı + tarayıcıya kart; dosya yoksa boş
      durum (sözleşme §14/6) · ✅ 2026-08-13
- [x] P-001.8 — Uygulama: hub içi bağlantıya dokunma → hedef belge + ID çapasına
      kaydırma · ✅ 2026-08-13; belge çapada ikiye bölünüp aradaki işarete
      kaydırılıyor
- [x] P-001.9 — Arayüz metinleri (`app_tr.arb`, `app_en.arb`) · ✅ 2026-08-13
- [x] P-001.10 — Testler: ayrıştırıcı, ekran, bağlantı çözümleme · ✅ 2026-08-13;
      39 yeni test
- [x] P-001.11 — Sürüm tutarlılığı: `constants.dart`, iki README; `EVOLUTION.md`
      ve oturum kaydı · ✅ 2026-08-13
- [x] P-001.12 — Süitin yakaladığı iki hata düzeltildi: SEC-013'ün türü
      sözleşmede yoktu (§12'ye `karar` eklendi), yeni kart tarayıcı testinin
      yüzeyini taşırmıştı · ✅ 2026-08-13
- [x] P-001.13 — Tam süit teyidi + push · ✅ 2026-08-13; 531 geçti, 2 kırık ve
      ikisi de [B-130](BACKLOG.md#B-130) (oturum öncesi commit'te de düşüyor,
      ölçüldü). Ana kopya 1.25'i sunuyor: `curl` + `diff` farksız
