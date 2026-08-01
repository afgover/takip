---
id: A-2026-08-01-015
session: none
type: info
title: "Branch And Deployment Strategy"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.agents/BRANCH_AND_DEPLOYMENT_STRATEGY.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Branch And Deployment Strategy

Taskr is maintained as two separate products from the same repository history.

## Branch Ownership

- `main`: Taskr Basic.
- `project-taskr`: Project Taskr.

Do not develop managed groups, assignments, agent runs, project memory, agent API keys, project operations, or manager dashboards on `main`.

Core bug fixes may be copied between branches when needed, but Project Taskr-specific behavior must stay on `project-taskr`.

## App Identity

Taskr Basic and Project Taskr must use separate mobile app identities.

- Taskr Basic app name: `Taskr`.
- Taskr Basic branch: `main`.
- Project Taskr app name: `Project Taskr`.
- Project Taskr branch: `project-taskr`.
- Project Taskr iOS bundle id: `com.afgover.projecttaskr`.
- Project Taskr Android package: `com.afgover.projecttaskr`.

If a future store release changes these identifiers, update this file before building.

## Backend Deployment

Do not use a single production backend for both products.

Create separate Coolify services:

- `taskr-basic-api`: tracks `main`.
- `project-taskr-api`: tracks `project-taskr`.

Each service needs its own database connection:

- `taskr-basic-db` for Basic.
- `project-taskr-db` for Project Taskr.

The two services can expose the same internal container port if Coolify routes by domain, but their public URLs and `DATABASE_URL` values must be different.

Recommended public URLs:

- Basic API: existing Basic API URL.
- Project Taskr API: `https://project-taskr-api.gover.us` or the final Project Taskr API domain.

## Project Taskr Branch Defaults

The `project-taskr` branch defaults are intentionally different from Basic:

- Local Project Taskr backend: `http://127.0.0.1:3007`.
- Project Taskr EAS API URL: `https://project-taskr-api.gover.us`.
- Project Taskr product env: `EXPO_PUBLIC_TASKR_PRODUCT=project-taskr`.

Override these with environment variables when needed:

```bash
EXPO_PUBLIC_API_URL=https://your-project-taskr-api.example.com
EXPO_PUBLIC_LOCAL_API_URL=http://127.0.0.1:3007
TASKR_API_URL=http://127.0.0.1:3007
PORT=3007
DATABASE_URL=postgresql://...
```

## Pre-Push Checklist

Before pushing `main`:

- Confirm branch: `git branch --show-current` returns `main`.
- Confirm no manager screens, agent services, or project-ops changes are included.
- Confirm app identity is Taskr Basic.
- Confirm API URL points to the Basic backend.

Before pushing `project-taskr`:

- Confirm branch: `git branch --show-current` returns `project-taskr`.
- Confirm app identity is Project Taskr.
- Confirm EAS env points to the Project Taskr backend.
- Confirm Coolify service tracks `project-taskr`.
- Confirm `DATABASE_URL` belongs to the Project Taskr database.

## Coolify Setup For Project Taskr

1. Create a new Coolify application from `https://github.com/afgover/taskr.git`.
2. Set branch to `project-taskr`.
3. Use the backend Dockerfile path for the backend service.
4. Create or attach a separate PostgreSQL database for Project Taskr.
5. Set environment variables:

```bash
NODE_ENV=production
PORT=3007
DATABASE_URL=postgresql://...
JWT_SECRET=...
```

6. Assign the Project Taskr API domain.
7. Update `app.json`, `eas.json`, and EAS secrets if the domain differs from the placeholder.
8. Run Project Taskr smoke tests against the new API:

```bash
TASKR_API_URL=https://your-project-taskr-api.example.com npm --prefix backend run smoke:manager-governance
TASKR_API_URL=https://your-project-taskr-api.example.com npm --prefix backend run smoke:agent-flow
```
