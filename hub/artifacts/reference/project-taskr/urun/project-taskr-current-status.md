---
id: A-2026-08-01-004
session: none
type: report
title: "Project Taskr Current Status"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.agents/PROJECT_TASKR_CURRENT_STATUS.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Project Taskr Current Status

**Date**: 2026-06-10
**Branch**: `project-taskr`  
**Product Name**: Project Taskr  
**Status**: Coolify frontend and API are live. The Project Taskr-only navigation/feed integration is implemented locally and awaits commit, push, migration deploy, and frontend redeploy.

## Executive Summary

Project Taskr has been split conceptually from Taskr Basic.

The old managed `Group` model is now the MVP application/project container:

- one managed `Group` = one Application/Project
- users added to the group can access the Application dashboard
- managers/admins/owners keep broader controls
- personal todos remain outside Project Taskr and stay in Taskr Basic
- project/application tasks are linked through a source layer instead of existing as global standalone tasks

The agent workflow from the external `/Users/gover/Desktop/agents` hub has been moved into Project Taskr as a database/API workflow. Agents can now create sessions, store context snapshots, record events, propose follow-up tasks, request approvals/tests, attach Git metadata, and close sessions. The Application dashboard can show and act on these records.

## Completed Work

### Project Taskr Product Shell

- Main tabs are now `Tasks`, `Applications`, and `Settings`.
- The Tasks feed reads only `ProjectTaskLink` records from managed Applications the user can access.
- Personal Taskr todos, Tags, Shared inbox, templates, backup/restore, auto-tag scheduling, and personal priority controls are removed from the active Project Taskr navigation/settings.
- Applications are available to every managed group member, not only managers.
- Application dashboards are the initial Applications screen.
- Project Management is shown from the Application dashboard only for owner/admin/manager roles.
- Assignment task selection now reads project-linked tasks instead of a manager's personal task list.
- Tasks approved from project operation proposals are created directly as project tasks.
- Assignment creation guarantees a `ProjectTaskLink`; migration `20260610021500_backfill_assignment_project_task_links` backfills existing managed assignments.
- Login and registration branding now use Project Taskr.

### Product Split And Naming

- Branch/product boundary set to `project-taskr`.
- Package/backend naming moved to Project Taskr.
- Frontend API defaults point to `project-taskr-api.gover.us`.
- Product boundary verification script passes for branch `project-taskr`.
- Taskr Basic and Project Taskr are documented as separate products with separate Coolify backend/database requirements.

### Application/Project Model

- Existing managed `Group` is kept as the MVP application/project container.
- Application dashboard uses managed groups as selectable Applications.
- Global Tasks dashboard aggregates project-linked tasks but does not allow direct task creation.
- `ProjectTaskLink` adds a task source layer:
  - manual
  - todo
  - agent follow-up
  - assignment
  - git
  - approval
  - imported
- Todo tasks can be created without due dates.
- Owner/creator attribution is preserved, including agent creator attribution.

### Agent Session System

Implemented models and API support:

- `AgentSession`
- `AgentSessionEvent`
- `AgentSessionContextSnapshot`
- `AgentSessionTask`
- `AgentSessionApproval`
- `AgentSessionGitRef`

Implemented backend modules:

- `backend/src/agent-sessions`
- `backend/src/project-context`

Implemented agent session API:

- `POST /agent/sessions`
- `GET /agent/sessions`
- `GET /agent/sessions/:id`
- `POST /agent/sessions/:id/events`
- `PATCH /agent/sessions/:id/finish`
- `GET /agent/sessions/:id/tasks`
- `POST /agent/sessions/:id/tasks`
- `GET /agent/sessions/:id/approvals`
- `POST /agent/sessions/:id/approvals`
- `GET /agent/sessions/:id/git-refs`
- `POST /agent/sessions/:id/git-refs`

Implemented project/application API:

- `GET /projects/:groupId/sessions`
- `GET /projects/:groupId/session-tasks`
- `PATCH /projects/:groupId/session-tasks/:id`
- `GET /projects/:groupId/approvals`
- `PATCH /projects/:groupId/approvals/:id`
- `GET /projects/:groupId/git-refs`
- `GET /projects/:groupId/tasks`
- `POST /projects/:groupId/tasks`
- `PATCH /projects/:groupId/tasks/:taskId/status`

### Context Builder

`ProjectContextService` builds reusable project context from one managed group.

Current context includes:

- active memory/progress/plan/skill/decision records
- recent agent session summaries
- open project follow-ups/todos/approval tasks
- submitted/review-pending assignments as test-pending work
- optional current assignment/task context

When an agent session starts with `groupId` or `runId`, Project Taskr automatically stores the served context into `AgentSessionContextSnapshot`, unless `autoContext: false` is sent.

### Follow-Up Tasks

Agents can propose follow-up work under a session.

Project/application users can:

- accept a proposed follow-up, creating a normal `Task` plus `ProjectTaskLink`
- cancel a proposed follow-up

Session timeline events are written for:

- `follow_up_created`
- `follow_up_accepted`
- `follow_up_cancelled`

### Testing And Approval

Agents can request testing/review/approval through `AgentSessionApproval`.

Supported statuses:

- `pending`
- `tested`
- `approved`
- `rejected`
- `changes_requested`

Stored approval data includes:

- required approval count
- approved count
- reviewer user id
- reviewer nickname
- review note
- tested timestamp
- reviewed timestamp

If an approval is linked to a task and reaches final `approved`, that task is marked completed by the reviewing user.

### Git Metadata

Agents can attach unverified Git metadata to sessions.

Supported ref types:

- `commit`
- `push`
- `pull_request`
- `deployment`

`verifiedAt` remains `null` until GitHub webhook/verification is added later.

### UI

Application dashboard now includes:

- Application Todo creation
- Memory / Plans / Docs read-only cards
- Document detail view with comments/review notes, no inline editing
- Project task list with status actions
- Agent Sessions panel with token/cost summary
- Approval / Test Queue with actions
- Follow-up Backlog with accept/cancel actions
- Git / Deployment metadata panel

Global Tasks dashboard:

- lists tasks from all accessible Applications
- allows permitted status changes
- does not allow direct task creation

### Agents Hub Migration

Added import script:

```bash
npm --prefix backend run import:agents-hub -- --group-id <managedGroupId> --user-id <adminUserId>
```

Dry-run:

```bash
npm --prefix backend run import:agents-hub -- --group-id <managedGroupId> --dry-run
```

Default Taskr import dry-run result:

- 21 records

With nested folders:

- 39 records

Security handling:

- `security.md` is redacted before import
- token/private key-like values are redacted
- imported security records are marked with `metadata.redacted = true`

### Smoke Testing

Added Project Taskr session smoke test:

```bash
TASKR_API_URL=https://project-taskr-api.gover.us npm --prefix backend run smoke:project-taskr-session
```

It verifies:

- manager + agent user setup
- managed group/application setup
- agent session creation
- context snapshot creation
- session event append
- follow-up proposal
- follow-up acceptance into a normal project task
- approval request
- project approval
- Git ref creation
- project sessions/tasks/git refs visibility
- session finish

## New Migration Files

- `20260608143000_project_task_links`
- `20260608152000_project_document_reviews`
- `20260608154500_agent_sessions`
- `20260608161000_agent_session_context_and_git_refs`
- `20260608163500_agent_session_tasks`
- `20260608170000_agent_session_approvals`

These have been generated but not applied locally in this workspace because no local `DATABASE_URL` is currently configured.

## Validation Completed

The following checks passed after the latest changes:

```bash
npx --prefix backend prisma generate --schema backend/prisma/schema.prisma
npm --prefix backend run build
npx tsc --noEmit
npm run verify:product-boundary
git diff --check
```

Expo web server was reachable at:

```text
http://localhost:8082
```

Import script dry-run was also validated without DB writes.

## Not Yet Done

### Deployment / Runtime

- Frontend is live at `https://project-taskr.gover.us`.
- API health is live at `https://project-taskr-api.gover.us/health`.
- The local Project Taskr shell/feed changes dated 2026-06-10 have not been redeployed yet.
- Migration `20260610021500_backfill_assignment_project_task_links` has not been applied to production yet.
- Smoke tests have not run against a real Project Taskr backend yet.
- Agents hub docs have not been imported into a real Project Taskr managed group yet.

### Product Features Remaining

- GitHub webhook verification for commits/PRs/deployments.
- Dedicated session detail timeline screen.
- Dedicated approval/test queue screen.
- Dedicated follow-up backlog screen.
- Better task/detail navigation from Application dashboard cards.
- Bulk review actions.
- More granular multi-user approval policy beyond stored `requiredApprovalCount`.
- Rich context snapshot diff/replay UI.
- Real API client/SDK docs for external agents.
- Final production domain confirmation if `project-taskr-api.gover.us` changes.

### Technical Cleanup Remaining

- Apply migrations to a real DB and run smoke tests.
- Consider adding API tests for agent session endpoints.
- Consider splitting Application dashboard into smaller components as it grows.
- Consider moving old docs links in README from external agents hub to Project Taskr memory after import is complete.

## Coolify Redeploy Plan

1. Commit and push the current `project-taskr` changes.
2. Redeploy the backend application and verify the production start still runs:

```bash
prisma migrate deploy && node dist/main
```

3. Confirm the assignment backfill migration completed.
4. Redeploy the frontend from `Dockerfile.web`.
5. Run smoke tests:

```bash
TASKR_API_URL=https://project-taskr-api.gover.us npm --prefix backend run smoke:project-taskr-session
TASKR_API_URL=https://project-taskr-api.gover.us npm --prefix backend run smoke:manager-governance
TASKR_API_URL=https://project-taskr-api.gover.us npm --prefix backend run smoke:agent-flow
```

6. Import agents hub docs after identifying the production managed Application and admin user IDs:

```bash
npm --prefix backend run import:agents-hub -- --group-id <managedGroupId> --user-id <adminUserId> --dry-run
npm --prefix backend run import:agents-hub -- --group-id <managedGroupId> --user-id <adminUserId>
```

## Recommended Next Sequence

1. Review and commit the Project Taskr shell/feed integration.
2. Push `project-taskr` and redeploy backend plus frontend in Coolify.
3. Verify migration `20260610021500_backfill_assignment_project_task_links`.
4. Run `smoke:project-taskr-session` and governance/agent smoke tests.
5. Test with both a manager account and a normal project member account.
6. Import agents hub docs.
7. Open Application dashboard and verify:
   - memory cards render
   - session panel renders
   - follow-up backlog renders
   - approval queue renders
   - git refs render
8. Verify Tasks feed contains only project-linked tasks and has no direct task creation action.

## Decision Log

- Keep `Application` as the UI/product term.
- Keep managed `Group` as the MVP Application/Project container.
- Keep personal todos out of Project Taskr.
- Allow global dashboard status changes, but no global task creation.
- Allow project todo tasks without due date.
- Store owner/creator attribution, including agent creator attribution.
- Keep memory/plans/readme readable from dashboards.
- Support document comments/review without inline editing.
- Defer GitHub verification/webhooks until after the backend is live.
