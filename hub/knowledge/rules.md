# Kurallar (rules)

Projede uyulacak kalıcı kurallar. Kayıtlar silinmez; geçersizleşen kural üstü
çizilir ve nedeni yazılır. Biçim: `SYSTEM.md` §5.

---

## R-001 — App'in yazma alanı tek: tasks/inbox/
- **Tarih:** 2026-07-30
- **Kaynak:** Aşama 0 tasarım oturumu
- **Açıklama:** Kullanıcı uygulaması hub'da yalnızca `tasks/inbox/`'a dosya yazar.
  Taşıma, düzenleme ve diğer tüm klasörlere yazma agent'ın işidir. Bu, izin
  modelini basit ve öngörülebilir tutar.

## ~~R-002 — Uygulama token'ı yalnızca hub'a scope'lanır~~
- **Tarih:** 2026-07-30 (geçersiz: 2026-07-30, K-012 — bkz. R-005)
- **Kaynak:** Aşama 0, K-002
- **Açıklama:** ~~Token asla kod repolarına erişemez.~~ `takip` özel durumunda
  hub, uygulama reposunun içinde yaşadığı için token bu repoya scope'lanır;
  ayrıntı R-005'te. Diğer projeler için ilke geçerliliğini korur.

## R-003 — Hub'a push'lanmamış kayıt, yapılmamış kayıttır
- **Tarih:** 2026-07-30
- **Kaynak:** AGENT_PROTOCOL.md
- **Açıklama:** Agent'ın ürettiği hiçbir çıktı, hub'a commit'lenip push'lanmadan
  tamamlanmış sayılmaz.

## R-004 — Silme yok, üstü çizme var
- **Tarih:** 2026-07-30
- **Kaynak:** SYSTEM.md
- **Açıklama:** Oturum, artifact, done-görev ve knowledge kayıtları silinmez.
  Geçersizleşen kayıt üstü çizilerek işaretlenir ve gerekçesi eklenir.

## R-005 — Token `takip`e scope'lanır; app'in yazma alanı hub/tasks/inbox/
- **Tarih:** 2026-07-30
- **Kaynak:** K-012
- **Açıklama:** `takip` kendi hub'ını barındırdığı için uygulama token'ı
  "Only select repositories → takip" ile üretilir (`Contents: R&W`,
  `Metadata: R`). Kod ve veri aynı repoda olduğundan token teknik olarak koda
  da yazabilir — bilinçli tercih (K-012); app davranış olarak yalnızca
  `hub/tasks/inbox/`'a yazar (R-001, yol öneki `hub/`). Diğer projelerde ayrı
  `<proje>_takip` repo modeli ve eski scope kuralı geçerlidir.
