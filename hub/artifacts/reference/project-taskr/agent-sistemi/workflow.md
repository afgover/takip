---
id: A-2026-08-01-014
session: none
type: info
title: "Project Taskr Agent Workflow"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.codex/skills/project-taskr-agent-api/references/workflow.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Project Taskr Agent Workflow

## 1. Preflight

1. Read `AGENTS.md`, this skill, `.agents/BRANCH_AND_DEPLOYMENT_STRATEGY.md`, and relevant project status docs.
2. Inspect `git status`, current branch, remotes, and recent commits. Preserve unrelated user changes.
3. Confirm the target product:
   - Project Taskr: branch `project-taskr`, API `https://project-taskr-api.gover.us`, local API `http://127.0.0.1:3007`.
   - Taskr Basic: branch `main`; do not introduce Project Taskr manager/agent/project-ops behavior.
4. Confirm the credential is available without displaying it. Use the shared credential helper.
5. Identify the managed project by `TASKR_PROJECT_ID` or `TASKR_PROJECT_NAME` (default `Project Taskr`).

## 2. Start The Session

Start before substantial investigation or mutation. Prefer the idempotent command so a re-run mid-task resumes the active session instead of orphaning it:

```bash
TASKR_SESSION_TITLE='Concise task title' \
TASKR_SESSION_SUMMARY='Requested outcome and initial scope.' \
npm --prefix backend run session:ensure
```

`session:ensure` resumes the active local session if one exists, otherwise creates a new one. `session:start` behaves the same; pass `--new` (`npm --prefix backend run session:start -- --new`) only when a deliberately separate session is required. Never assume `start` opens a fresh session — it now resumes by default.

The API automatically snapshots active project memory, recent sessions, open follow-ups, approvals, and relevant project context. The command stores only the active session ID/project ID in `.taskr-agent-session.json`, mode `0600`, ignored by Git.

Immediately record the implementation plan:

```bash
TASKR_EVENT_TYPE=agent_plan \
TASKR_EVENT_SUMMARY='Implementation plan' \
TASKR_EVENT_CONTENT='Inspect current behavior; implement scoped changes; verify; commit/push; close session.' \
npm --prefix backend run session:event
```

Plans must be concise and user-visible. Never send hidden reasoning.

## 2b. Every Prompt Becomes A Task (mandatory)

Every user prompt that touches the repository, the API, project state, or any external system must be recorded as a prompt-task before the first mutation — even a request small enough to finish immediately. The only exception is a purely read-only question that changes no state.

```bash
TASKR_PROMPT_CONTENT='Full prompt text as received from the user.' \
TASKR_PROMPT_TITLE='Short task title' \
TASKR_IDEMPOTENCY_KEY='stable-key-for-this-prompt' \
npm --prefix backend run session:prompt
```

Use a stable `TASKR_IDEMPOTENCY_KEY` so a retried prompt reuses the same task instead of duplicating it. The command prints the created `taskId`.

Record every user-visible answer turn for that task as the conversation transcript:

```bash
TASKR_TASK_ID='<taskId from session:prompt>' \
TASKR_MESSAGE_SUMMARY='One-line gist of the answer' \
TASKR_MESSAGE_CONTENT='The user-visible response delivered this turn.' \
npm --prefix backend run session:message
```

`session:message` logs an `agent_message` event linked to the task. Log it for each meaningful answer turn, not hidden reasoning. When the task work is complete, submit it with `session:submit` (`TASKR_TASK_ID`, `TASKR_SUBMIT_SUMMARY`); never mark it accepted — only the prompt owner accepts.

## 3. Execute And Report

Work autonomously through diagnosis, implementation, verification, and delivery.

Record events when they improve auditability:

- `research`: repository/API findings that changed the approach.
- `decision`: a material architecture, security, data-model, or compatibility choice.
- `progress`: a completed milestone.
- `file_change`: changed-file summary before final Git attachment when useful.
- `test_result`: command, outcome, and relevant failure details.
- `blocked`: concrete blocker, attempted recovery, and required external action.
- `error`: operational/API error after redaction.

Do not flood the API with every shell command. Store meaningful milestones and outcomes.

## 4. Work-Session Commands

When the user supplies a session invitation code, use `npm --prefix backend run agent:work-session` or implement the same protocol:

1. `POST /auth/agent-key`.
2. `POST /agent/connections/claim` with the session code.
3. Heartbeat with `POST /agent/connections/:id/heartbeat`.
4. Poll `GET /agent/connections/:id/commands`.
5. For each prompt command, call `POST /agent/tasks/:taskId/start` before work.
6. Send plans/progress/errors with `POST /agent/tasks/:taskId/events`.
7. Send reports/diffs/changed-file summaries with `/artifacts`.
8. Submit discovered future work through `/suggestions`.
9. Request tests through `/test-requests`.
10. Submit through `/submit`, then acknowledge the command using its lease token.

Never start a command without `taskId`. Never treat WebSocket delivery as authoritative. Never accept the task on behalf of the prompt owner.

## 5. Follow-Ups And Approvals

Known unfinished work must become a proposed follow-up:

```bash
TASKR_FOLLOW_UP_TITLE='Add API regression tests' \
TASKR_FOLLOW_UP_DESCRIPTION='Cover friendship authorization and project role boundaries.' \
TASKR_FOLLOW_UP_TYPE=agent_follow_up \
npm --prefix backend run session:follow-up
```

Use `bug` as the type for a discovered defect. Proposal does not create an accepted project task until a user reviews it.

Request human validation when risk or workflow requires it:

```bash
TASKR_APPROVAL_TYPE=test \
TASKR_APPROVAL_TITLE='Verify project member permissions' \
TASKR_APPROVAL_DESCRIPTION='Owner/admin/manager/member behavior requires user validation.' \
TASKR_REQUIRED_APPROVALS=1 \
npm --prefix backend run session:approval
```

Do not claim approval before the API contains reviewer identity and outcome.

## 6. Verification And GitHub

Before delivery:

1. Run focused tests, type checks, builds, schema validation, and product-boundary checks proportional to risk.
2. Record each important result as `test_result`, including tests that could not run and why.
3. Check `git diff --check` and inspect `git status`.
4. Commit only intended files. Do not revert unrelated user changes.
5. Push the correct branch when requested or required by the workflow.
6. Confirm the remote branch advanced.
7. Attach the final commit after the push:

```bash
npm --prefix backend run session:git
```

Use `TASKR_GIT_REF_TYPE=pull_request` or `deployment` plus the appropriate URL for those refs. Submitted refs are unverified until GitHub webhook verification exists; do not describe them as server-verified.

## 7. Session Finish

The final summary must state:

- requested outcome and implementation result;
- important files/components changed;
- tests and their outcomes;
- commit/branch/push state;
- remaining risks, blocked items, follow-ups, and approval state.

Finish only after all required records exist:

```bash
TASKR_SESSION_STATUS=completed \
TASKR_SESSION_SUMMARY='Implemented ..., verified ..., pushed commit ...; remaining risk ... .' \
npm --prefix backend run session:finish
```

Allowed truthful terminal statuses include `completed`, `failed`, and `cancelled`. Do not use `completed` when required work remains unfinished. The finish command reads the session back and only then deletes local active-session state.

## 8. Recovery

- API unavailable: keep work local, do not expose credentials, retry events in original order, and use stable task/prompt idempotency keys where supported.
- Stale local state: call `session:status`. Remove the state file only after confirming the remote session is terminal or unrecoverable.
- Push failure: record `blocked` or `error`; do not attach a nonexistent push/commit ref.
- Interrupted work: record current state and follow-ups, then finish as `failed`/`cancelled` when possible.
- Secret exposure: stop transmission, revoke/rotate the key, scrub generated records where supported, and report the exposure without repeating the secret.

## 9. Roles And Acceptance

- Owner: project creator; derived owner authority and creator membership stored as admin.
- Admin: can manage members and roles; only owner can grant/edit admin role where enforced.
- Manager: can coordinate project operations but cannot administer membership.
- Member: participates within allowed project/task operations.
- Agent: executor identity; agent status is not a billing or global manager entitlement.

Normal users must be accepted friends before an admin adds them to a project. Agent executor accounts may be added without friendship. Project authority is always scoped to one managed project.
