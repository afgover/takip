---
id: A-2026-08-01-030
session: none
type: info
title: "Project Taskr Agent Rules"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:AGENTS.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Project Taskr Agent Rules

For every Project Taskr coding, API, deployment, task, agent, session, or project-management request, load and follow `.codex/skills/project-taskr-agent-api/SKILL.md`.

Mandatory rules:

- Work only on the branch/product boundary documented by the skill. Never mix Taskr Basic and Project Taskr changes.
- Never place an agent key, JWT, password, session code, or other secret in Git, logs, events, metadata, prompts, or chat output.
- Use the Project Taskr API as the durable record for agent work. Record the session lifecycle, meaningful progress, tests, Git metadata, follow-ups, approvals, and final status.
- Do not mark user-owned prompt work accepted or completed. Agents submit work; the prompt owner or assigned reviewer performs final acceptance.
- Before ending a completed coding task, verify the implementation, commit/push when requested or implied by the workflow, attach the final commit to the session, finish the API session, and verify that the session can be read back.

Detailed API contracts and lifecycle rules live in the skill references. Those files are the authoritative agent operating procedure for this repository.

<!-- BEGIN PROJECT TASKR DIRECTIVE (managed by session:bootstrap) -->
<!-- version: 2026-06-19.1 sha256:3e94e904bc69672de6c376fad71602f959976d1639b6b7bb12fa4150a31b24d2 -->

# Project Taskr Agent Operating Directive

You are connected to Project Taskr through its agent API. Use the API as the durable system of
record for your work. Do not rely on chat history or local markdown alone.

## Session
- Ensure exactly one active session before substantial work: `npm --prefix backend run session:ensure`.
  It resumes the active session or creates one; it never opens a duplicate. Use `--new` only for a
  deliberately separate session.
- Record a concise, user-visible `agent_plan` before implementation. Never log hidden reasoning.

## Every prompt becomes a task
- Every user prompt that changes the repository, the API, project state, or any external system must
  be recorded as a prompt-task (`session:prompt`) before the first mutation — even a prompt small
  enough to finish immediately. The only exception is a purely read-only question.
- Use a stable idempotency key so a retried prompt reuses its task instead of duplicating it.
- Place each prompt-task in the correct spot of the project task tree (`parentTaskId`) and attach the
  relevant existing project tags/badges. Read the task tree and available tags first; do not invent
  new tags — leave `suggestedTags` for the human to create.
- Log each user-visible answer turn as an `agent_message` linked to its task (`session:message`).

## Record the whole session
- `research`/`decision`/`progress` events for findings, material choices, and milestones.
- `file_change` plus a Git ref (`session:git`) with commit SHA, branch, and changed files for code changes.
- `test_result` for every verification command and outcome, including tests that could not run.
- Documents: save every generated .md (plan/research/decision/skill/memory) with `session:doc`.
- Finish with an accurate status (`session:finish`) and verify by reading the session back.

## Roles and acceptance
- Agents submit, block, request changes/testing, or propose follow-ups. Only the prompt owner or an
  assigned reviewer performs final acceptance. Never mark user-owned work completed.

## Data safety
- Never print, commit, log, upload, or embed the agent key, JWT, password, session code, or any secret
  — not in events, metadata, artifacts, Git refs, errors, or chat output. Redact before sending.
- Keep Project Taskr work on the `project-taskr` branch; never mix Taskr Basic (`main`) changes.
<!-- END PROJECT TASKR DIRECTIVE -->
