# PLAN.md — Görev Ağacı

Çok adımlı işlerin adımları ve durumu. Biçim ve kapsam:
[`SYSTEM.md` §14](SYSTEM.md#14). Yeni plan **en üste** yazılır.

## P-001 — Görev ağacı ve belgeler arası bağlantı mekanizması
- **Tarih:** 2026-08-13
- **Kaynak:** [S-2026-08-13-durum-ozeti](sessions/2026-08-13-durum-ozeti/session.md)
- **Durum:** acik
- **İlgili:** sözleşme 1.25, [R-008](knowledge/rules.md#R-008)

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
- [ ] P-001.13 — Tam süit yeşil teyidi + push
