# PLAN.md — Görev Ağacı

Çok adımlı işlerin adımları ve durumu. Biçim ve kapsam:
[`SYSTEM.md` §14](SYSTEM.md#14). Yeni plan **en üste** yazılır.

## P-003 — B-103: token kapsam kontrolü (SEC-012)
- **Tarih:** 2026-08-15
- **Kaynak:** [S-2026-08-15-gorev-kapsami](sessions/2026-08-15-gorev-kapsami/session.md)
- **Durum:** acik
- **İlgili:** [B-103](BACKLOG.md#B-103), [SEC-012](SECURITY.md#SEC-012),
  [SEC-006](SECURITY.md#SEC-006), [T-006](tasks/done/2026-08-04-token-kapsam-olcumu.md)

> **Karar (2026-08-15, kullanıcı):** kontrol token'ın *nasıl üretildiğini*
> tahmin etmeye çalışmaz — "All repositories" modu ölçülemez ve hesabın toplam
> repo sayısı bu token'la zaten okunamaz. Bunun yerine **fazla erişim** ölçülür:
> **N** = token'ın gördüğü repo sayısı, **K** = bu token'la bağlı hub sayısı.
> `N > K` → uyarı. Eşik keyfi bir sabit değil, uygulamanın kendi ihtiyacı.
> Zamanlama: bağlantı kurulurken + Ayarlar'da elle tetiklenen düğme.

- [ ] P-003.1 — Repo sayısını ölçen katman: `GET /user/repos?per_page=1`,
      `Link` başlığındaki `rel="last"` sayfa numarası = toplam. **En iyi çaba**
      ([readLogin](../lib/hub/hub_access.dart) çizgisi): hata/başlıksız yanıt →
      `null` = "bilinmiyor", asla 0 sayılmaz
- [ ] P-003.2 — Karar mantığı `token_scope.dart`'a: N ve K'dan uyarı üret.
      **Tek yönlü** ([L-009](knowledge/lessons.md#L-009)): yalnız `N > K`
      konuşur; N bilinmiyorsa, N ≤ K ise ve K bilinmiyorsa **susar** — "bu token
      dar" cümlesi hiçbir yolda kurulmaz
- [ ] P-003.3 — Bağlantı kurulurken koş: `checkHubAccess`'e ekle, mevcut
      klasik-token uyarısıyla tek uyarıda birleşsin. K = aynı token'la bağlı
      hub sayısı + kurulmakta olan bağlantı
- [ ] P-003.4 — Ayarlar'a "token kapsamını ölç" düğmesi; sonucu (uyarı ya da
      "fazla erişim görünmüyor") ekranda göster
- [ ] P-003.5 — Arayüz metinleri: `app_tr.arb`, `app_en.arb`
- [ ] P-003.6 — Testler: sayfalama başlığının ayrıştırılması, tek yönlü yorumun
      her dalı, bağlantı akışı, Ayarlar düğmesi
- [ ] P-003.7 — Kayıtlar: [SEC-012](SECURITY.md#SEC-012) güncellenir (kontrol
      artık var; kalan sınır yazılır), B-103 işaretlenir, oturum kaydı; tam süit
      + push

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
