---
id: A-2026-08-01-003
session: none
type: design
title: "Project Taskr Application Dashboards"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.agents/PROJECT_TASKR_APPLICATION_DASHBOARDS.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Project Taskr Application Dashboards

**Date**: 2026-06-08
**Status**: Product and architecture proposal
**Scope**: Per-application dashboards and global read-only task dashboard

## Accepted Decisions

- Use the name `Application`.
- Personal todos are out of scope for Project Taskr. Users should use Taskr Basic for personal todos.
- The global dashboard can allow status changes where the user has permission.
- Todo tasks can be created without a due date.
- Every todo task must have owner/creator attribution. If an agent created it, show the agent name.
- `memory`, `plans`, `README`, and similar documentation records should be readable from dashboards, not edited inline in the dashboard MVP.
- Existing group behavior from the old project should become Project/Application behavior here: one project/application is one managed `Group`.
- Users added to the project/application can access its dashboard, read notes/docs, see tasks, mark work done/tested where permitted, and assign work according to role policy.
- Manager/admin/owner permissions remain broader than normal member permissions.
- Documentation detail views should support comments/review without inline editing.
- GitHub verification is out of MVP scope and should be added later.

## Goal

Project Taskr should show every application's operational work in a clean dashboard.

The dashboard is not a replacement for project documentation. `README`, `plan`, `progress`, `skills`, `memory`, and decision records remain project context. The dashboard is for actionable work:

- project tasks
- todo tasks
- assignments
- agent follow-ups
- test-pending work
- approvals
- blocked items
- deferred tasks
- Git-linked implementation tasks

There should also be a global task dashboard similar to the current Taskr feed, but users must not create tasks directly from the global dashboard. Tasks are created inside an application/project dashboard and then appear in the global view.

## Product Structure

```text
Project Taskr
  |
  |-- Applications
  |     |-- CoPilot Dashboard
  |     |-- Financer Dashboard
  |     |-- Taskr Dashboard
  |     |-- DataSources Dashboard
  |     |-- Custom App Dashboard
  |
  |-- Global Tasks Dashboard
        |-- Aggregates tasks from all application dashboards
        |-- Read-only creation model
        |-- Filtering, sorting, review, navigation allowed
        |-- Direct task creation disabled
```

## Key Rule

Tasks must have a source application/project.

The global dashboard is an aggregate view. It can show and update allowed status fields, but it should not own new task creation.

The old group concept is now the project/application access boundary for Project Taskr. A project/application is represented by one managed `Group`; adding a user to that group grants access to the application dashboard.

## Definitions

`Application`
: A first-class product/work area such as CoPilot, Financer, Taskr, DataSources, or any future app. In the current backend this can initially map to a managed `Group`, but the product language should use `Application` for this surface.

`Project`
: The access and collaboration boundary behind an application. In MVP, a project is a managed `Group`; the terms project and application may point to the same backend record depending on UI context.

`Application Dashboard`
: The command center for one application. It shows tasks, todos, assignments, sessions, approvals, memory summaries, plans, Git refs, and deployment/test states for that application.

`Global Tasks Dashboard`
: A Taskr-like feed of all tasks from all applications. It is for overview, filtering, review, and navigation. It does not have an "Add task" action.

## What Belongs In Each Application Dashboard

### 1. Header

- application name
- repo/branch
- latest commit SHA
- latest push/deploy date
- active agent session count
- open task count
- waiting test count
- blocked count

### 2. Work Overview

Compact counters:

- All open
- Today
- Overdue
- Blocked
- Waiting user
- Waiting test
- Approved
- Deferred
- Agent proposed
- Ready to commit/push

### 3. Task Board

Suggested columns:

```text
Inbox / Proposed
Ready
In Progress
Blocked
Waiting Test
Approved
Deferred
Done
```

Tasks shown here include:

- manually created project tasks
- todo tasks imported or created for this application
- tasks created from agent follow-ups
- tasks proposed by agent sessions
- Git-linked implementation tasks
- test/approval tasks

### 4. Task List

A dense list/table for scanning:

- title
- status
- source
- owner/assignee
- agent/session
- priority
- difficulty
- due date
- approval state
- test state
- linked commit
- last update

### 5. Session Activity

Shows active/recent `AgentSession` records:

- agent name/model
- started/ended time
- status
- token/cost total
- open follow-ups
- final summary
- linked changed files
- linked commits

### 6. Memory And Docs Summary

This is not the main place to edit documentation, but the dashboard should show concise context:

- active memory count
- current plan/progress summary
- recent decisions
- pending memory review
- link to full memory/plans/readme views

### 7. Test And Approval Queue

Shows:

- tasks waiting for user test
- required approver count
- who approved/rejected
- test notes
- changes requested
- deployments waiting approval

### 8. Git / Deployment Panel

Shows:

- branch
- latest local commit
- latest pushed commit
- changed files
- PR URL
- deployment status
- release notes

Git metadata should be submitted by agents initially and verified by GitHub webhooks later.

## Global Tasks Dashboard

### Purpose

Give the user one place to see all actionable tasks across every application.

### Creation Rule

No direct task creation from this dashboard.

Allowed actions:

- filter
- sort
- search
- open task detail
- navigate to source application dashboard
- update status where permitted
- approve/test where permitted
- bulk review selected tasks

Disallowed action:

- create standalone task without application/project source

### UI Layout

Top controls:

- search
- application filter
- status filter
- assignee/agent filter
- test state filter
- approval state filter
- due date filter
- priority/difficulty filter

Main views:

- List view: dense operational table
- Board view: status columns
- Calendar/deadline view later
- Approval queue view later

Each task row/card should show:

- application badge
- title
- source type: manual | todo | agent_follow_up | assignment | git | approval
- status
- assignee/agent
- due date
- priority/difficulty
- test state
- approval state
- commit SHA if available

Primary action:

- "Open in application"

No "Add Task" button should appear here.

## Data Model Options

### Option A: Reuse Managed Group As Application

Use existing `Group` with `mode = "managed"` as the application container.

Add fields later:

```text
Group
- projectKind: project | application
- repoUrl nullable
- defaultBranch nullable
- dashboardConfig json nullable
```

Pros:

- fastest
- reuses permissions, assignments, project memory, operations, artifacts
- minimal migration

Cons:

- `Group` becomes overloaded
- naming may get confusing for non-group app workspaces

Recommendation: use this for MVP. This is now the accepted MVP direction.

### Option B: Add Application Model

Create a first-class `Application` model.

```text
Application
- id
- name
- slug
- repoUrl
- defaultBranch
- ownerUserId
- groupId nullable
- status
- metadata
```

Pros:

- cleaner long-term domain model
- app-specific fields do not pollute `Group`
- easier to model repositories and deployments

Cons:

- more migration work
- permissions need new mapping or duplicated logic

Recommendation: introduce after MVP if `Group` starts feeling too broad.

## Task Source Model

Current `Task` can support much of this, but each task needs source metadata.

MVP approach:

- keep `Task`
- ensure project/app linkage through assignment `groupId`, tag `groupId`, or operation metadata
- add an explicit source model later

Recommended addition:

```text
ProjectTaskLink
- id
- groupId
- taskId
- sourceType: manual | todo | agent_follow_up | assignment | git | approval | imported
- sourceSessionId nullable
- sourceRunId nullable
- sourceOperationId nullable
- sourceCommitSha nullable
- createdByUserId nullable
- createdByAgentId nullable
- metadata json nullable
- createdAt
- updatedAt
```

Why:

- a task can be clearly tied to an application
- global dashboard can aggregate without guessing
- todo-imported tasks can keep provenance
- agent-generated tasks can be reviewed and traced

## Todo Task Handling

Todo tasks should not stay separate forever if they are actionable project work.

Recommended flow:

1. User creates/imports todo inside an application dashboard.
2. It becomes a normal `Task`.
3. `ProjectTaskLink.sourceType = "todo"`.
4. It appears in both:
   - that application's dashboard
   - global tasks dashboard
5. Global dashboard cannot create new todo tasks directly.

Personal todos are intentionally out of scope for Project Taskr. Users should use Taskr Basic for personal todos.

Todo tasks can be created without a due date, but they must always keep clear attribution:

- human-created todo: show creator/owner user
- agent-created todo: show agent name and linked session/run when available
- imported todo: show import source and importing user/agent

## Permissions

Application dashboard:

- project owner/admin/manager can create tasks
- members can create tasks only if allowed by project policy
- agents can propose tasks; direct creation requires explicit scope
- todo tasks require creator/owner attribution, including agent name for agent-created todos
- project members can read notes/docs and see project-linked tasks
- project members can mark allowed work as done/tested
- project members can assign work only within the role policy
- manager/admin/owner roles can manage members, review approvals, archive work, and override more states

Global dashboard:

- visible tasks depend on project membership
- creation disabled for everyone
- status update is allowed when the user has permission in the source application
- approve/test actions depend on each source application permission

## Recommended Navigation

```text
Main tabs
- Feed / Personal
- Applications
- Global Tasks
- Shared
- Settings
```

For the current app, this can start inside the existing Manager/Project tab:

```text
Project Tab
- Applications index
- Application dashboard
- Global tasks
- Approval queue
- Agent sessions
```

## Application Dashboard Sections

Suggested first screen order:

1. Operational counters
2. Task board/list toggle
3. Waiting test / approvals strip
4. Active agent sessions
5. Recent Git/deploy activity
6. Memory/plan/progress summary

Avoid making documentation the main dashboard body. Documentation should inform work, but tasks and decisions should be the operational surface. For MVP, memory, plans, README, progress, skills, and decision records are readable from the dashboard and open into detail views. Editing should stay in dedicated documentation/memory screens.

Documentation detail views should allow comments and review notes without inline editing the source content.

MVP implementation note:

- Documentation comments/reviews are stored in `ProjectDocumentReview`.
- `ProjectMemoryRecord` remains the readable source document for memory, plan, progress, skill, decision, and session note records.
- Application dashboard document cards open a read-only detail view.
- Detail review actions create `ProjectDocumentReview` rows and mirror a small audit entry into `ProjectOperationNode` with `doc_comment` or `doc_review`.

## Global Dashboard Sections

1. Filter bar
2. Global task list
3. Group by application/status
4. Test-pending lane
5. Recent commit-linked tasks
6. Deferred tasks

No create task control.

## Backend API Plan

### Application Dashboard

```text
GET /projects/:groupId/dashboard
```

Returns:

- counters
- task summaries
- assignments
- agent sessions
- approvals
- recent operations
- memory/doc summaries
- git refs

### Application Tasks

```text
GET /projects/:groupId/tasks
POST /projects/:groupId/tasks
PATCH /projects/:groupId/tasks/:taskId
```

Creation is allowed here, subject to project permission.

### Global Tasks

```text
GET /tasks/global
```

Returns all visible project-linked tasks.

No `POST /tasks/global`.

### Todo Import

```text
POST /projects/:groupId/todo-tasks
```

Creates a normal task with `sourceType = "todo"`.

## Frontend Implementation Plan

### Phase 1: Design And Aggregation

- Add dashboard design docs.
- Add backend dashboard aggregator service.
- Add global tasks read endpoint.
- Add project task source metadata.

### Phase 2: Application Dashboard MVP

- Add Applications index screen.
- Add ApplicationDashboardScreen.
- Show task list, assignment list, waiting test, recent sessions, memory summary.
- Add task creation only inside application dashboard.

### Phase 3: Global Tasks Dashboard MVP

- Add GlobalTasksDashboardScreen.
- Show all visible project-linked tasks.
- Add filters.
- Do not render create button.
- "Open in application" navigates to source dashboard/task detail.

### Phase 4: Todo Integration

- Add todo task creation/import inside application dashboard.
- Mark source as `todo`.
- Show todo source badge in app and global dashboards.
- Allow todo tasks without due dates.
- Require owner/creator display for every todo task.
- Show agent name when the todo was created by an agent.

### Phase 5: Approval And Session Integration

- Add waiting-test lane.
- Link agent sessions to created/deferred tasks.
- Show approval count and tester names.

### Phase 6: Git Integration

- Show commit refs on application dashboard.
- Show commit-linked tasks globally.
- Add GitHub webhook verification later. This is not part of the dashboard MVP.

## Open Questions

- Should `Application` remain a managed `Group` long-term, or become a new database model after MVP?
- Which statuses should be globally editable for members versus managers?
- Should documentation comments/reviews be stored as generic operation nodes or a dedicated document-review model?

## Recommendation

For MVP, keep the existing managed `Group` as the application container and add a `ProjectTaskLink`/source layer.

Build two screens:

1. Application Dashboard: full work center, task creation allowed.
2. Global Tasks Dashboard: aggregate view, no task creation.

This preserves the Taskr-style task experience while preventing orphan global tasks that do not belong to any application.
