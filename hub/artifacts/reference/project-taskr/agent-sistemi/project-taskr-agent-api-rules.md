---
id: A-2026-08-01-011
session: none
type: info
title: "Project Taskr Agent API Rules"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.agents/PROJECT_TASKR_AGENT_API_RULES.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Project Taskr Agent API Rules

> Authoritative operating procedure: `.codex/skills/project-taskr-agent-api/SKILL.md` and its `references/` files. Load that skill for every Project Taskr agent/API/session task. This file remains as a compatibility summary.

## Mandatory lifecycle

1. Authenticate with an agent API key and claim the user-provided session code.
2. Keep the connection alive with heartbeat calls while work is active.
3. Poll commands and acknowledge each leased command with its lease token.
4. Do not begin work until the prompt has a Project Taskr `taskId`.
5. Send plans, meaningful research results, tool outcomes, errors, and progress as task events.
6. Store generated documents, diffs, reports, and changed-file summaries as task artifacts.
7. Submit discovered bugs and follow-up work as suggestions. They become tasks only after user acceptance.
8. Request testing with explicit reviewers and one policy: `all`, `quorum`, or `named_final_approver`.
9. An agent may move work to `submitted`, `waiting_test`, `blocked`, or `changes_requested`; it must never mark a prompt task completed.
10. The prompt owner is the only actor that can give final acceptance and close the task.

## Data safety

- Redact credentials, tokens, private keys, passwords, and secrets before API submission.
- Send large or binary files as URI, checksum, size, MIME type, and summary rather than raw content.
- Use a stable idempotency key for every retried prompt or command-derived write.
- If the API is unavailable, spool events locally and replay them in order with the same idempotency keys.
- Never put secrets in event metadata, summaries, Git refs, or error messages.

## Required task records

- `agent_plan` before a substantial implementation.
- `research` for decisions based on repository or external investigation.
- `file_change` or an artifact containing changed files and diff statistics.
- `test_result` for each verification command and its result.
- `task_submitted` with the final summary, remaining risks, and test state.

The reference transport adapter is `backend/scripts/work-session-agent.js`. Production agents should implement the same HTTP lifecycle and may use WebSocket `command.available` only as a wake-up signal; HTTP polling remains the delivery authority.
