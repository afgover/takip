---
id: A-2026-08-01-013
session: none
type: info
title: "Project Taskr Agent API Reference"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.codex/skills/project-taskr-agent-api/references/api.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Project Taskr Agent API Reference

## Configuration

Defaults:

```text
Production API: https://project-taskr-api.gover.us
Local API:      http://127.0.0.1:3007
Project name:   Project Taskr
Keychain:       service=project-taskr-agent-key, account=$USER
```

Overrides:

- `TASKR_API_URL`
- `TASKR_PROJECT_ID` or `TASKR_PROJECT_NAME`
- `TASKR_AGENT_KEY` for secure non-macOS runtime injection
- `TASKR_KEYCHAIN_SERVICE` and `TASKR_KEYCHAIN_ACCOUNT`

Agent keys may be limited to projects when they are created or updated. Use `allProjects: true` for every managed project, including future projects, or `allProjects: false` with one or more `projectIds`. The API rejects project IDs the key owner cannot manage, and authenticated agent JWTs carry this project boundary to agent sessions, tasks, runs, and work-session connections.

Credential resolution is implemented by `backend/scripts/lib/agent-credentials.js`: environment injection first, macOS Keychain second. Never read the key into logs or command output.

## Session Commands

| Command | Required environment | Purpose |
|---|---|---|
| `session:ensure` | `TASKR_SESSION_TITLE` (when creating) | Resume the active session or create one (idempotent; never duplicates) |
| `session:start` | `TASKR_SESSION_TITLE` (when creating) | Same as ensure; pass `-- --new` to force a fresh session |
| `session:bootstrap` | none | Fetch the canonical operating directive; `-- --apply` writes it into the memory file |
| `session:tree` | none | Read the project task tree to choose a `parentTaskId` |
| `session:tags` | none | Read existing project tags/badges to attach |
| `session:prompt` | `TASKR_PROMPT_CONTENT` | Record a user prompt as a project task (placement + tags) |
| `session:message` | `TASKR_TASK_ID`, `TASKR_MESSAGE_CONTENT` | Log a user-visible `agent_message` turn for a task |
| `session:event` | `TASKR_EVENT_TYPE` | Append plan/progress/test/error/decision event |
| `session:submit` | `TASKR_TASK_ID` | Mark a prompt-task submitted for owner acceptance |
| `session:doc` / `session:memory` | `TASKR_DOC_TITLE`, content | Save a generated .md (plan/research/decision/skill/memory) |
| `session:git` | none for commit ref | Attach current Git commit and changed files |
| `session:follow-up` | `TASKR_FOLLOW_UP_TITLE` | Propose deferred work |
| `session:approval` | `TASKR_APPROVAL_TITLE` | Request test/review/acceptance |
| `session:status` | none | Read active session from API |
| `session:finish` | `TASKR_SESSION_SUMMARY` | Finish, verify read-back, clear local state |
| `session:upload` | optional title/summary | One-shot completed session for already-finished work |

`session:prompt` placement variables: `TASKR_PARENT_TASK_ID` (tree placement), `TASKR_TAG_IDS` / `TASKR_TAG_NAMES` (comma-separated existing project tags to attach), `TASKR_SUGGESTED_TAGS` (comma-separated names recorded as suggestions when no suitable tag exists — never auto-created).

Structured metadata variables accept JSON: `TASKR_METADATA`, `TASKR_PROMPT_METADATA`, `TASKR_EVENT_METADATA`, `TASKR_CHANGED_FILES`, `TASKR_DIFF_STATS`, `TASKR_FOLLOW_UP_METADATA`, `TASKR_APPROVAL_METADATA`, `TASKR_FINISH_METADATA`.

Project read endpoints for placement: `GET /projects/:groupId/task-tree` (nested by `parentTaskId`) and `GET /projects/:groupId/tags` (existing project tags). Directive bootstrap: `GET /agent/bootstrap`; `POST /auth/agent-key` also returns `directiveVersion`/`directiveChecksum`.

## Authentication

```http
POST /auth/agent-key
Content-Type: application/json

{"apiKey":"<secret from credential helper>"}
```

Use returned JWT as `Authorization: Bearer <token>`. JWTs are temporary; the durable credential remains in Keychain or secret injection.

Relevant scopes:

- session write: `agent:submit`
- session read: `task:read`
- connection: `agent:connect` or legacy claim/heartbeat/queue scopes
- task events/submission: `agent:event` or legacy `agent:submit`
- artifacts: `agent:artifact`
- suggestions: `agent:suggest`
- tests: `agent:test-request`

## Durable Agent Sessions

- `POST /agent/sessions`
- `GET /agent/sessions`
- `GET /agent/sessions/:id`
- `POST /agent/sessions/:id/events`
- `GET|POST /agent/sessions/:id/tasks`
- `GET|POST /agent/sessions/:id/approvals`
- `GET|POST /agent/sessions/:id/git-refs`
- `PATCH /agent/sessions/:id/finish`

Create sessions with `groupId`, `sessionType`, `title`, optional `runId`, `summary`, `instructions`, `metadata`, and explicit `contextItems`. Automatic context is enabled unless `autoContext: false` is sent.

Event payload fields:

```json
{
  "eventType": "test_result",
  "role": "agent",
  "summary": "Backend build passed",
  "content": "npm run build exited 0",
  "metadata": {"command":"npm run build","exitCode":0},
  "inputTokens": 0,
  "outputTokens": 0,
  "estimatedCostUsd": 0
}
```

Never store chain-of-thought. `content` is for concise user-visible facts, plans, outcomes, and redacted errors.

## Follow-Ups

`POST /agent/sessions/:id/tasks` accepts:

```json
{
  "title": "Add regression tests",
  "description": "Cover the new permission matrix.",
  "sourceType": "agent_follow_up",
  "metadata": {}
}
```

The initial status is `proposed`. A project user reviews it through `PATCH /projects/:groupId/session-tasks/:id`; only acceptance creates a linked project task.

## Approvals

`POST /agent/sessions/:id/approvals` accepts `approvalType`, `title`, `description`, optional `taskId`/`sessionTaskId`, `requiredApprovalCount`, and metadata. Initial status is `pending`. Review occurs through `PATCH /projects/:groupId/approvals/:id` and must preserve reviewer identity.

## Git References

`POST /agent/sessions/:id/git-refs` supports:

- `commit`: requires `commitSha`
- `push`: requires `commitSha` or `branch`
- `pull_request`: requires `pullRequestUrl`
- `deployment`: requires `deploymentUrl`

Include repository, branch, changed files, diff stats, and pushed/deployed timestamp when known. Never include credentials in repository URLs.

## Work-Session Connection API

Manager/prompt-owner endpoints:

- `POST /projects/:groupId/work-sessions`
- `POST /projects/:groupId/work-sessions/:id/invitations`
- `POST /projects/:groupId/work-sessions/:id/prompts` with stable `idempotencyKey`
- `GET /projects/:groupId/work-sessions/:id/tree|timeline`
- `POST /projects/:groupId/tasks/:taskId/accept|reopen|test-requests`

Agent endpoints:

- `POST /agent/connections/claim`
- `POST /agent/connections/:id/heartbeat`
- `GET /agent/connections/:id/commands`
- `POST /agent/commands/:id/ack`
- `POST /agent/tasks/:taskId/start|events|artifacts|suggestions|test-requests|submit`

Each acknowledgement must use the command lease token. Stable prompt idempotency keys prevent duplicate task creation.

## Project Records

Project users read sessions through:

- `/projects/:groupId/sessions`
- `/projects/:groupId/session-tasks`
- `/projects/:groupId/approvals`
- `/projects/:groupId/git-refs`

Project memory is under `/projects/:groupId/memory`. Record types: `memory`, `progress`, `plan`, `skill`, `decision`, `session_note`. Memory writes require manager-level project access. Use memory for durable reusable rules/decisions, not for transient command logs.

## Redaction

Before API transmission remove:

- agent keys and JWTs;
- passwords, OTPs, private keys, signing material;
- database credentials and connection strings;
- secrets embedded in URLs, headers, logs, diffs, or environment output;
- unnecessary personal or private data.

For large/binary artifacts submit URI, checksum, size, MIME type, and summary instead of raw bytes.
