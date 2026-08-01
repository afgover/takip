---
id: A-2026-08-01-001
session: none
type: design
title: "Product Split Architecture Note"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.agents/HYBRID_PRODUCT_ARCHITECTURE.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Product Split Architecture Note

Taskr is now split into two products:

- `main` branch: Taskr Basic, the public market app.
- `project-taskr` branch: Project Taskr, the managed project, assignment, agent, and operations app.

This is a product and deployment decision. Future agents must keep GitHub branches, app identifiers, backend deployments, database connections, and Coolify services separate.

## Product Direction

- Taskr Basic remains the simple collaborative task management experience: personal tasks, tags, shared tasks, open groups, collaboration, and real-time updates.
- Project Taskr is a separate operations product for managed project teams.
- The user/account model is defined in [USER_AND_ACCOUNT_MODEL.md](USER_AND_ACCOUNT_MODEL.md). Keep Free Core users separate from Managed Project Teams in navigation, permissions, and product copy.
- Public Basic users must not see agent runs, project memory, manager governance, operation queues, agent API keys, or managed group controls.
- Manager users may reuse core primitives such as users, tasks, tags, groups, auth, and sharing, but the Manager app must use its own backend deployment and database.

## Development Rules

- Do not merge manager/project/agent functionality into `main`.
- Do not point Project Taskr builds at the Taskr Basic backend.
- Do not point Taskr Basic builds at the Project Taskr backend.
- Keep manager, project operations, agent runs, project memory, governance, audit, and artifact features in the `project-taskr` branch.
- Keep Taskr Basic copy, navigation, and settings free of Manager/AI language.
- Use separate app identifiers for each product so store builds cannot overwrite one another.
- Use separate Coolify backend services and separate databases.
- Prefer explicit manager endpoints and DTOs over hidden coupling through unrelated controllers.
- When adding tests or smoke scripts, keep Basic behavior and Manager behavior separately runnable.

## Implementation Checklist For Future Agents

Before adding or modifying manager/project/agent functionality, check:

- Am I on the `project-taskr` branch?
- Is this using the Manager backend URL and Manager database?
- Is the app identifier still distinct from Taskr Basic?
- Are permissions and managed group scope explicit?
- Does any change need to be manually mirrored to `main` as a Basic-safe core fix?

## Current Decision

Taskr Basic continues on `main`. Project Taskr continues on `project-taskr`. They may share repository history, but they must not share production backend deployments or databases.
