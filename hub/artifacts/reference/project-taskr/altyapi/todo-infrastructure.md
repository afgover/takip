---
id: A-2026-08-01-018
session: none
type: plan
title: "Todo Mobile App Infrastructure (Self-Hosted)"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/project_docs/TODO_INFRASTRUCTURE.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Todo Mobile App Infrastructure (Self-Hosted)

## 1. Cloud Infrastructure (Hetzner)
- **VPS IP**: `178.104.159.14`
- **Region**: Falkenstein (nbg1)

## 2. Networking (Cloudflare)
- **Domain**: `todo.gover.us` (Planned)
- **Internal Port**: `3006`

## 3. Backend (NestJS)
- **Repository**: `/Users/gover/Desktop/todo/backend`
- **Database**: `postgres-db/todo_db` (To be created)
- **Technologies**: NestJS 11, Prisma 6, JWT, Bcrypt.

## 4. Mobile Frontend (Expo)
- **Repository**: `/Users/gover/Desktop/todo`
- **SDK**: Expo 52+
- **Auth**: Email/Password + JWT.

## 5. Migration Strategy
1.  **Phase 1**: Set up NestJS boilerplate with Auth.
2.  **Phase 2**: Translate Supabase RLS policies into NestJS Guards.
3.  **Phase 3**: Implement Real-time using Socket.io (to replace Supabase Realtime).
4.  **Phase 4**: Update Expo app to use `todo-api` instead of `supabase-sdk`.

---
*Initialized on 2026-04-19 by Antigravity AI.*
