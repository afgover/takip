---
id: A-2026-08-01-020
session: none
type: info
title: "server.md"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.agents/workflows/server.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

---
description: Reset the development environment and restart the Expo server
---

// turbo-all
1. Clear zombie processes on port 8081 (Metro) and 19000 (Expo Legacy if any)
```bash
lsof -ti:8081,19000,19001,19002 | xargs kill -9 || true
```

2. Clear Expo and Metro caches
```bash
npx expo start --clear
```

3. Restart the server in the background
```bash
npm run start
```
