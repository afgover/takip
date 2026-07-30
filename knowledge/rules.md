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

## R-002 — Uygulama token'ı yalnızca hub'a scope'lanır
- **Tarih:** 2026-07-30
- **Kaynak:** Aşama 0, K-002
- **Açıklama:** Fine-grained token "Only select repositories → hub" ile üretilir;
  izinler `Contents: Read & write` + `Metadata: Read` ile sınırlıdır. Token asla
  kod repolarına erişemez.

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
