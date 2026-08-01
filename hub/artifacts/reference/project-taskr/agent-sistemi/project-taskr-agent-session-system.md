---
id: A-2026-08-01-009
session: none
type: design
title: "Project Taskr Agent Session System"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.agents/PROJECT_TASKR_AGENT_SESSION_SYSTEM.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Project Taskr Agent Session System

> Current agent execution rules and API lifecycle: `.codex/skills/project-taskr-agent-api/SKILL.md`. This document retains architecture/history; the skill is authoritative for runtime behavior.

**Date**: 2026-06-08
**Status**: Architecture proposal
**Decision**: Continue on `project-taskr`; do not use a separate `manager` branch.

For the latest implementation handoff, completed work, remaining backlog, and Coolify setup order, see `.agents/PROJECT_TASKR_CURRENT_STATUS.md`.

## Goal

Move the current external `agents` repository workflow into Project Taskr itself.

Today, agents use a file-based hub:

- read global rules, security notes, project plan, progress, skills, and memory before work
- work in the project repo
- update progress/memory/plan/todo files at session end
- commit/push the documentation hub

Project Taskr should become the system of record for this workflow through its own API and database:

- create an agent session before work starts
- attach every user prompt, agent response, plan, suggestion, decision, tool/action result, token usage, and cost estimate to that session
- preserve deferred work as first-class tasks or follow-up records
- track testing, user approvals, required approver count, GitHub commit/push metadata, and agent identity
- feed future agents with project memory, rules, recent session summaries, open decisions, and pending work before they start

## What Already Exists

The `project-taskr` branch already has useful foundations:

- `ApiKey`: agent API keys, scopes, budgets, rate limits
- `AgentRun`: run queue, prompt pack, result summary, token usage, estimated cost, agent identity
- `AgentAuditLog`: actor/event timeline
- `AgentQuestion`: question/answer flow
- `TaskAssignment` and `TaskAssignmentParticipant`: assignment lifecycle
- `ProjectMemoryRecord`: memory/progress/plan/skill/decision/session-note records
- `ProjectOperationNode`: operation tree/journal
- `ProjectArtifact`: stored outputs, artifacts, changed-file metadata
- `ProjectOpsService`: memory, operations, artifact APIs
- `AgentRunsService`: prompt pack, structured result import, memory write-back, usage/cost fields

This means the correct path is not a full rewrite. The missing piece is a higher-level `AgentSession` layer that connects multiple prompts, responses, tool events, plans, tasks, tests, approvals, and Git metadata into one durable work session.

## Implemented MVP Slice

The first Project Taskr-native session layer is now implemented:

- `AgentSession`: one durable agent work session, optionally linked to a managed `Group` application and/or `AgentRun`.
- `AgentSessionEvent`: append-only event records for prompts, responses, plans, tool results, summaries, token usage, and session lifecycle events.
- `AgentSessionContextSnapshot`: exact context items served or submitted when a session starts.
- `AgentSessionGitRef`: Git/PR/deployment metadata placeholder for later verification.
- `backend/src/agent-sessions`: reusable session service/module used by agent endpoints and project endpoints.
- Agent API endpoints:
  - `POST /agent/sessions`
  - `GET /agent/sessions`
  - `GET /agent/sessions/:id`
  - `POST /agent/sessions/:id/events`
  - `PATCH /agent/sessions/:id/finish`
- Project API endpoint:
  - `GET /projects/:groupId/sessions`
- Session write endpoints use the existing `agent:submit` scope so current agent keys do not need a new scope.
- Session read endpoints use the existing `task:read` scope.
- If a session is tied to an application, the agent must be a member of that managed `Group`.
- Token and estimated-cost values can be submitted per event and are rolled into session totals.
- `AgentRunsService` appends `agent_run_submitted` / `agent_run_failed` events when `sessionId` is provided by the agent.

Still pending:

- Manager/application dashboard visibility for session timelines.
- Dedicated approval and session-task tables.
- Automated GitHub verification/webhook integration.

## Implemented Phase 2 Slice

Reusable project context building is now implemented:

- `backend/src/project-context/ProjectContextService` builds the project context from one managed `Group`.
- Context currently includes:
  - active `ProjectMemoryRecord` items
  - recent `AgentSession` summaries
  - open project follow-ups/todos/approval tasks from `ProjectTaskLink`
  - submitted/review-pending assignments as test-pending work
  - optional current assignment/task context
- `AgentSessionsService.createSession` automatically stores built context as `AgentSessionContextSnapshot` rows when the session has a `groupId` or `runId`.
- Agents can disable automatic context snapshots with `autoContext: false`, or submit explicit `contextSnapshots` / `contextItems`.
- `AgentRunsService` now uses the same `ProjectContextService` for prompt packs, so run context and session context are generated from one source.

## Implemented Phase 3 Slice

Agent follow-up task capture is now implemented:

- `AgentSessionTask` stores proposed follow-up work under a session.
- Agent API endpoints:
  - `GET /agent/sessions/:id/tasks`
  - `POST /agent/sessions/:id/tasks`
- Project API endpoints:
  - `GET /projects/:groupId/session-tasks`
  - `PATCH /projects/:groupId/session-tasks/:id`
- Proposed session tasks can be accepted or cancelled from the project/application side.
- Accepted session tasks create a normal `Task` plus a `ProjectTaskLink` with `sourceSessionId` and source type `agent_follow_up`.
- Follow-up lifecycle events are mirrored into `AgentSessionEvent` as `follow_up_created`, `follow_up_accepted`, or `follow_up_cancelled`.

## Implemented Phase 4 Slice

Session-level testing and approval is now implemented:

- `AgentSessionApproval` stores test/review/accept/reject/deploy approval requests.
- Agent API endpoints:
  - `GET /agent/sessions/:id/approvals`
  - `POST /agent/sessions/:id/approvals`
- Project API endpoints:
  - `GET /projects/:groupId/approvals`
  - `PATCH /projects/:groupId/approvals/:id`
- Supported approval statuses:
  - `pending`
  - `tested`
  - `approved`
  - `rejected`
  - `changes_requested`
- Required approval count is stored per approval request.
- User identity, nickname, tested timestamp, reviewed timestamp, and review note are stored.
- Approval decisions are mirrored into `AgentSessionEvent` as `approval_requested` and `approval_recorded`.
- If an approval is linked to a task and reaches final `approved`, that task is marked completed by the reviewing user.

## Implemented Phase 5 Slice

Git/PR/deployment metadata capture is now implemented without GitHub verification:

- `AgentSessionGitRef` is used for `commit`, `push`, `pull_request`, and `deployment` refs.
- Agent API endpoints:
  - `GET /agent/sessions/:id/git-refs`
  - `POST /agent/sessions/:id/git-refs`
- Project API endpoint:
  - `GET /projects/:groupId/git-refs`
- Required fields are validated by ref type:
  - `commit`: `commitSha`
  - `push`: `commitSha` or `branch`
  - `pull_request`: `pullRequestUrl`
  - `deployment`: `deploymentUrl`
- Git refs are mirrored into `AgentSessionEvent` as `git_commit`, `git_push`, `git_pull_request`, or `git_deployment`.
- `verifiedAt` remains null until the later GitHub webhook/verification phase.

## Implemented Phase 6 Slice

Application dashboard now surfaces the session workflow:

- Recent agent sessions with status, agent, event count, summary, and token/cost totals.
- Approval/test queue with actions:
  - `tested`
  - `approved`
  - `changes_requested`
  - `rejected`
- Follow-up backlog with actions:
  - accept proposed follow-up into a normal project task
  - cancel proposed follow-up
- Git/deployment metadata panel showing commit/PR/deployment refs and verification state.
- Summary counters now include waiting test and proposed follow-up counts.

## Implemented Phase 7 Slice

Agents hub migration tooling is now implemented:

- `backend/scripts/import-agents-hub-memory.js` imports markdown from `/Users/gover/Desktop/agents` into `ProjectMemoryRecord`.
- Backend npm script:
  - `npm --prefix backend run import:agents-hub -- --group-id <managedGroupId> --user-id <userId>`
- Dry run:
  - `npm --prefix backend run import:agents-hub -- --group-id <managedGroupId> --dry-run`
- Default import source:
  - hub `README.md`
  - hub `MEMORY.md`
  - hub `rules.md`
  - redacted hub `security.md`
  - project `README.md`
  - project `AGENT_ONBOARDING.md`
  - project `plan.md`
  - project `progress.md`
  - project `skills.md`
  - project `memory/*.md`
  - project `plans/*.md`
- The default project folder is `Taskr`; use `--project <Name>` for another agents hub project folder.
- Use `--include-nested` to also include nested folders such as `gemini/project_docs`.
- The import is idempotent by `metadata.sourcePath`; reruns update existing imported records instead of duplicating them.
- Security files are redacted before import and marked with `metadata.redacted = true`.

## Proposed Product Model

### Core Concepts

`Project`
: Existing managed `Group` with `mode = "managed"`. This remains the project container for now.

`AgentSession`
: A complete work session started by an agent or user. It is the top-level record for one collaboration episode.

`AgentSessionEvent`
: Ordered append-only event stream under a session. Stores prompts, responses, plans, tool calls, errors, decisions, approvals, token reports, and status changes.

`AgentSessionTask`
: Follow-up work extracted from the session. Can link to a normal `Task`, `TaskAssignment`, or remain as a session backlog item until approved.

`AgentSessionApproval`
: Human validation record. Supports one or many required approvers.

`AgentSessionGitRef`
: GitHub/repo metadata: branch, commit SHA, pushed-at, PR URL, changed files, diff stats, deployment refs.

`AgentSessionContextSnapshot`
: The exact rules/memory/progress/plan/skills context served to the agent before work starts.

## Proposed Database Additions

### AgentSession

```text
AgentSession
- id
- groupId
- assignmentId nullable
- taskId nullable
- runId nullable
- title
- status: opened | active | waiting_user | waiting_test | approved | closed | cancelled
- startedByUserId nullable
- agentUserId nullable
- agentName nullable
- agentProvider nullable
- agentModel nullable
- clientName nullable
- sessionExternalId nullable
- summary nullable
- finalSummary nullable
- totalInputTokens int nullable
- totalOutputTokens int nullable
- totalReasoningTokens int nullable
- totalToolTokens int nullable
- estimatedCostUsd float nullable
- startedAt
- endedAt nullable
- createdAt
- updatedAt
```

### AgentSessionEvent

```text
AgentSessionEvent
- id
- sessionId
- eventIndex int
- eventType:
  session_started | context_served | user_prompt | agent_response |
  agent_plan | tool_call | tool_result | file_change | decision |
  suggestion | follow_up_created | test_status_changed |
  approval_requested | approval_recorded | git_commit | git_push |
  session_summary | session_closed | error
- actorType: user | agent | system | tool
- actorUserId nullable
- agentUserId nullable
- title nullable
- content text nullable
- metadata json nullable
- inputTokens int nullable
- outputTokens int nullable
- reasoningTokens int nullable
- estimatedCostUsd float nullable
- createdAt
```

Important: this table should be append-only for audit integrity. Corrections should be new events, not destructive edits.

### AgentSessionTask

```text
AgentSessionTask
- id
- sessionId
- groupId
- taskId nullable
- assignmentId nullable
- title
- description text nullable
- sourceEventId nullable
- status: proposed | accepted | in_progress | done | deferred | cancelled
- priorityNumber nullable
- difficultyNumber nullable
- dueDate nullable
- createdByAgentUserId nullable
- acceptedByUserId nullable
- createdAt
- updatedAt
```

### AgentSessionApproval

```text
AgentSessionApproval
- id
- sessionId
- targetType: session | task | artifact | git_ref | deployment | change_set
- targetId nullable
- approvalType: test | review | accept | reject | deploy
- status: pending | approved | rejected | changes_requested
- requiredApprovalCount int default 1
- approvedByUserId nullable
- approvedByNickname nullable
- note nullable
- testedAt nullable
- createdAt
- updatedAt
```

For multi-user approvals, use one row per required approval or add an `ApprovalPolicy` table later. MVP can store `requiredApprovalCount` plus counted approved rows.

### AgentSessionGitRef

```text
AgentSessionGitRef
- id
- sessionId
- repo
- branch
- commitSha nullable
- parentCommitSha nullable
- commitMessage nullable
- pushedAt nullable
- pullRequestUrl nullable
- deploymentUrl nullable
- changedFiles json
- diffStat json
- createdAt
```

### AgentSessionContextSnapshot

```text
AgentSessionContextSnapshot
- id
- sessionId
- sourceType: rule | security | memory | progress | plan | skill | decision | recent_session | open_task
- sourceId nullable
- title
- content text
- metadata json nullable
- createdAt
```

This preserves exactly what the agent saw at session start, even if memory changes later.

## API Flow

### 1. Agent Connects Before Work

```text
POST /projects/:groupId/agent-sessions
Authorization: Bearer agent/user token
Body:
  agentName
  agentProvider
  agentModel
  clientName
  assignmentId?
  taskId?
  intent?
```

Backend should:

- validate project access and agent key scopes
- create `AgentSession`
- create `session_started` event
- assemble context from active `ProjectMemoryRecord`, recent sessions, open follow-ups, rules, current project state
- store context as `AgentSessionContextSnapshot`
- return a structured prompt pack

### 2. User Prompts and Agent Responses Are Logged

```text
POST /agent-sessions/:sessionId/events
```

Events should be written for:

- user prompt
- agent response
- plan/checklist
- tool calls and tool outputs
- file edits and changed file summaries
- decisions
- errors
- token/cost increments

### 3. Deferred Work Is Converted To Tasks

```text
POST /agent-sessions/:sessionId/follow-ups
```

The agent can propose follow-ups. A project manager can approve them into real `Task` / `TaskAssignment` records.

Default rule:

- proposed by agent = `proposed`
- accepted by user/manager = create or link real task
- unfinished at session close = `deferred` or `accepted`, depending on approval

### 4. Testing and Approval

```text
POST /agent-sessions/:sessionId/approvals
PATCH /agent-sessions/:sessionId/approvals/:approvalId
```

Supported states:

- `pending`: test/review required
- `approved`: tested and approved by user
- `rejected`: tested and rejected
- `changes_requested`: tested but needs revision

Every approval must store user identity and timestamp. Multi-user test policies can require N approvals before final session status becomes `approved`.

### 5. GitHub / Git Metadata

```text
POST /agent-sessions/:sessionId/git-refs
```

Store:

- repo
- branch
- commit SHA
- commit message
- changed files
- diff stats
- PR URL
- push/deploy date

For MVP, this can be manual/agent-submitted metadata. Later it can be verified by GitHub webhook.

### 6. Session Close

```text
POST /agent-sessions/:sessionId/close
```

Backend should:

- require final summary
- require open follow-up classification
- compute token/cost totals from events
- mark untested work as `waiting_test`
- create/update `ProjectMemoryRecord` summaries if approved or pending-review
- create a `ProjectOperationNode` session journal
- attach artifacts and Git refs

## Session Start Prompt Pack

The agent should receive:

- project identity and branch rules
- security/push rules
- active memory records
- active plan/progress/skills/decisions
- recent session summaries
- open follow-ups and test-pending items
- relevant assignment/task details
- required output schema

The output schema should request:

- summary
- changed files
- tests run
- token usage, if known
- open questions
- deferred tasks
- proposed memory updates
- proposed decisions
- Git metadata, if available
- approval/test requirements

## UI Requirements

### Project Dashboard

- active sessions
- waiting user input
- waiting test
- approved/rejected sessions
- token/cost totals
- latest commit refs
- open follow-up tasks

### Session Detail

- event timeline
- prompt/response viewer
- plans and checklists
- changed files
- artifacts
- Git commits
- token/cost breakdown
- follow-up tasks
- approvals and required approver count
- final summary

### Approval Queue

- filter by project, session, task, artifact, deployment
- approve/reject/request changes
- record tester username and note
- show missing approver count

## Pros

- Project Taskr becomes the source of truth instead of scattered markdown files.
- Future agents get structured context through API, not stale local files.
- User prompts and agent outputs become searchable, auditable project history.
- Token/cost tracking becomes possible per project, agent, model, user, and session.
- Deferred work stops disappearing into chat history.
- Testing and approval become explicit workflow states.
- GitHub commits and deployment history can be tied to real sessions and project tasks.
- This creates a strong foundation for multi-agent teams and paid managed-project features.

## Cons / Tradeoffs

- Capturing every prompt and response can create large tables quickly.
- Full transcript storage may include sensitive user data, secrets, or credentials unless redaction exists.
- Agents cannot always know exact token counts unless the client/tool reports them.
- Logging every tool call may be noisy; UI must summarize well.
- Multi-user approval logic can become complex if introduced too early.
- Git metadata submitted by agents is not trustworthy until verified by GitHub webhooks.
- Too much mandatory workflow can slow small tasks unless the UI supports lightweight sessions.
- Storing agent reasoning or hidden chain-of-thought should be avoided; store user-visible plans/summaries and tool-visible outputs only.

## Security and Privacy Rules

- Never store raw secrets from prompts, `.env`, API keys, or tokens.
- Add server-side redaction for common secret patterns before storing event content.
- Store auth/API key references, not raw API keys.
- Make event visibility project-scoped.
- Keep agent write permissions scoped by project, assignment, and action.
- Add retention policy for full transcripts.
- Allow long-term memory to store summaries/decisions, not every raw event forever.
- Treat Git metadata from an agent as unverified until webhook-confirmed.

## Recommended Storage Policy

MVP:

- keep full event transcript for recent sessions
- store summarized session memory permanently
- mark sensitive events with `metadata.sensitive = true`
- do not expose raw sensitive events in broad dashboards

Later:

- automatic redaction
- archive old raw events to object storage
- keep compact summaries in PostgreSQL
- configurable retention per project

## What To Add

- first-class session model
- event stream under session
- explicit context snapshot
- follow-up task extraction
- test/approval queue
- Git ref metadata
- session close workflow
- session summary to project memory
- context builder that replaces `agents` repo file reading
- dashboards for sessions, approvals, follow-ups, and costs

## What To Avoid Initially

- deleting the existing `AgentRun` / `ProjectMemoryRecord` architecture
- storing hidden reasoning traces
- automatic GitHub push from Project Taskr
- automatic deployment approval without human sign-off
- full multi-tenant workspace billing before the session workflow works
- over-complicated approval chains in MVP

## Relationship To Existing Models

`AgentSession` should sit above `AgentRun`.

```text
Project / Group
  -> AgentSession
      -> AgentSessionEvent[]
      -> AgentRun[] (optional execution runs)
      -> ProjectOperationNode[] (journal)
      -> ProjectArtifact[]
      -> AgentSessionTask[]
      -> AgentSessionApproval[]
      -> AgentSessionGitRef[]
```

`AgentRun` remains useful for a specific execution attempt. `AgentSession` is the wider conversation/work container.

## Phased Implementation Plan

### Phase 0: Align Product Language

- Keep branch `project-taskr`.
- Keep Project Taskr as product name.
- Update any remaining deployment docs when final API domain is chosen.

### Phase 1: Session Data Foundation

- Add Prisma models:
  - `AgentSession`
  - `AgentSessionEvent`
  - `AgentSessionContextSnapshot`
  - `AgentSessionGitRef`
- Add NestJS module:
  - `backend/src/agent-sessions`
- Add endpoints:
  - create session
  - get session
  - list project sessions
  - append event
  - close session
- Add event append helper used by AgentRuns/ProjectOps.
- Add indexes for project, status, agent, createdAt.

Exit criteria:

- an agent can open a session through API
- context snapshot is stored
- prompts/responses/tool summaries can be appended
- token/cost totals roll up to the session

### Phase 2: Context Builder

- Convert current prompt pack logic into a reusable project context builder.
- Include:
  - active memory/progress/plan/skill/decision records
  - recent session summaries
  - open follow-ups
  - test-pending work
  - current assignment/task context
- Store every served context item in `AgentSessionContextSnapshot`.

Exit criteria:

- every new session can reproduce exactly what context was served to the agent.

### Phase 3: Follow-Up Tasks

- Add `AgentSessionTask`.
- Add propose/accept/cancel endpoints.
- Allow accepted follow-ups to create/link normal `Task` and optionally `TaskAssignment`.
- At session close, require every follow-up to be classified.

Exit criteria:

- deferred work appears in Project Taskr as project-visible backlog, not only in chat.

### Phase 4: Testing and Approval

- Add `AgentSessionApproval`.
- Add approval queue endpoints and UI.
- Support:
  - test pending
  - approved by user
  - rejected
  - changes requested
  - required approval count
- Store approver user id, nickname, timestamp, and note.

Exit criteria:

- user-tested work can be marked tested/approved
- untested work remains visibly test-pending
- session cannot silently look complete when required tests are missing

### Phase 5: GitHub Metadata

- Add Git ref endpoints.
- Store commit SHA, branch, changed files, diff stat, push date, PR URL.
- Add optional GitHub webhook later for verification.

Exit criteria:

- sessions can be traced to commits and pushes.

### Phase 6: UI

- Add Project Sessions dashboard.
- Add Session Detail timeline.
- Add approval/test queue.
- Add follow-up backlog.
- Add token/cost summary by project and agent.

Exit criteria:

- user can inspect what happened, what changed, what is pending, who approved, and what commit shipped it.

### Phase 7: Agents Repo Migration

- Import current agents hub docs into `ProjectMemoryRecord`:
  - rules
  - security summary
  - plan
  - progress
  - skills
  - memory records
- Keep markdown as fallback during transition.
- Mark Project Taskr as source of truth once context builder is stable.

Exit criteria:

- future agents can start from Project Taskr API without reading `/Users/gover/Desktop/agents`.

## Open Decisions

- Should every user prompt be stored verbatim, or should users choose full transcript vs summary-only?
- What is the final Project Taskr API domain?
- Should approval be project-wide or per artifact/task/session?
- Should GitHub verification be required before showing a commit as trusted?
- Should session events be immutable forever, or archive/redact after a retention window?
- Should Project Taskr support external agents only through API keys, or also through a local bridge app?

## Recommendation

Build this as an extension of the existing Project Memory and AgentRun foundation.

Do not redesign the whole project model yet. Use managed `Group` as the project container, add `AgentSession` as the missing top-level session/audit object, and let the workflow mature before introducing a separate `Workspace`/billing model.

The ideal MVP is:

1. session create
2. context snapshot
3. event append
4. final summary
5. follow-up extraction
6. test approval status
7. Git metadata

After that works reliably, Project Taskr can replace the external `agents` repository workflow.
