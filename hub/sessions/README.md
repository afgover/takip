# sessions/

Her çalışma oturumu için bir klasör: `sessions/<YYYY-MM-DD>-<slug>/session.md`.
Şema ve kurallar: `SYSTEM.md` §2. Örnek: `2026-07-30-altyapi-tasarimi/`.

Özet kurallar:
- Oturum açılır açılmaz dosya oluşturulur (`status: open`).
- Her mesaj alışverişi anında dosyaya işlenir; kullanıcı mesajları kısaltılmaz.
- Kapanışta özet yazılır, `status: closed` yapılır; kapalı dosya değiştirilmez.
