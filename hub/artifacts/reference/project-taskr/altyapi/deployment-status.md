---
id: A-2026-08-01-016
session: none
type: report
title: "Project Taskr Deployment Status"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:DEPLOYMENT_STATUS.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Project Taskr Deployment Status

**Project**: Project Taskr
**Branch**: `project-taskr`
**Date**: 2026-06-10
**Status**: Frontend and API live; local Project Taskr shell/feed integration requires redeploy

---

## Product Split

Taskr Basic and Project Taskr must not share the same production backend.

- Taskr Basic continues on `main`.
- Project Taskr continues on `project-taskr`.
- Project Taskr needs a separate Coolify backend service.
- Project Taskr needs a separate PostgreSQL database.

See `.agents/BRANCH_AND_DEPLOYMENT_STRATEGY.md` before pushing or deploying.
See `.agents/PROJECT_TASKR_CURRENT_STATUS.md` for the full local implementation handoff and remaining plan.

---

## Project Taskr Frontend Configuration

API endpoint resolution:

1. `EXPO_PUBLIC_API_URL`
2. `app.json` `extra.apiUrl`
3. Project Taskr placeholder domain

Current Project Taskr defaults:

```bash
EXPO_PUBLIC_TASKR_PRODUCT=project-taskr
EXPO_PUBLIC_API_URL=https://project-taskr-api.gover.us
EXPO_PUBLIC_LOCAL_API_URL=http://127.0.0.1:3007
```

The app talks to the Project Taskr NestJS API through `src/config/api.ts` using Axios and Socket.io.

---

## Project Taskr Backend Configuration

Local default:

```bash
PORT=3007
TASKR_API_URL=http://127.0.0.1:3007
```

Coolify production:

```bash
NODE_ENV=production
PORT=3007
DATABASE_URL=postgresql://project-taskr-db-url
JWT_SECRET=project-taskr-specific-secret
CORS_ORIGINS=https://project-taskr.gover.us
RATE_LIMIT_TTL_MS=60000
RATE_LIMIT_MAX=120
ENABLE_SWAGGER=false
```

The backend fails readiness when PostgreSQL is unavailable, applies global HTTP rate limiting, restricts HTTP/WebSocket browser origins, and keeps Swagger disabled in production unless explicitly enabled.

Use a separate Coolify application that tracks the `project-taskr` branch.

Live services:

- Frontend: `https://project-taskr.gover.us`
- API: `https://project-taskr-api.gover.us`

The next backend deployment must apply migration `20260610021500_backfill_assignment_project_task_links`.

---

## Architecture Overview

```text
Project Taskr App
  |
  | HTTP (Axios) + JWT
  | WebSocket (Socket.io)
  v
Project Taskr NestJS Backend on Coolify
  |
  | Prisma
  v
Project Taskr PostgreSQL Database
```

---

## Smoke Tests

After creating the Project Taskr Coolify service:

```bash
TASKR_API_URL=https://project-taskr-api.gover.us npm --prefix backend run smoke:manager-governance
TASKR_API_URL=https://project-taskr-api.gover.us npm --prefix backend run smoke:agent-flow
TASKR_API_URL=https://project-taskr-api.gover.us npm --prefix backend run smoke:project-taskr-session
```

After creating the Project Taskr managed application/group, import the existing agents hub docs:

```bash
npm --prefix backend run import:agents-hub -- --group-id <managedGroupId> --user-id <adminUserId> --dry-run
npm --prefix backend run import:agents-hub -- --group-id <managedGroupId> --user-id <adminUserId>
```

Use `--include-nested` if Gemini/project-doc nested files should be imported too.

---

## Next Steps

1. Commit and push the current `project-taskr` changes.
2. Redeploy backend and confirm `prisma migrate deploy` succeeds.
3. Confirm assignment tasks were backfilled into `project_task_links`.
4. Redeploy the frontend from `Dockerfile.web`.
5. Test Tasks and Applications with manager and member accounts.
6. Run Project Taskr smoke tests against the live backend.
7. Import agents hub docs into Project Taskr memory.
