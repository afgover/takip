---
id: A-2026-08-01-033
session: none
type: info
title: "Shared Task Priority Rules"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:SHARED_TASK_PRIORITY_RULES.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Shared Task Priority Rules

This document defines how `priority_number` behaves when a task is shared.

## Product Rule

Shared tasks use a **single common `priority_number`**.

- If a task already has a `priority_number` when it is shared, that value is carried over automatically because recipients see the same underlying task record.
- There is **no per-recipient priority override**.
- There is **no separate priority snapshot** stored on the share row.

## Current Model

Task sharing stores a reference to the task:

- `shared_items.task_id -> tasks.id`

Because the share points at the original task, the task's own fields remain the source of truth:

- `tasks.priority_number`
- `tasks.priority_mode`
- `tasks.deadline`
- `tasks.tags`

## What This Means In Practice

### Direct share

If User A shares a task with priority `72` to User B:

- User B sees priority `72`
- if User A updates it to `55`, User B sees `55`
- if User B is allowed to update the shared task and changes it to `80`, User A sees `80`

### Group share

If a task is shared into a group with priority `40`:

- all accepted viewers/members see priority `40`
- later updates change that same shared value for everyone

## Non-Goals

The current product rule explicitly does **not** support:

- recipient-specific priority
- different priorities per group member
- share-time copied priority that later diverges from the task

## Guardrail For Future Changes

If we ever add personalized shared task behavior, it should be modeled as a new field or layer, not by silently changing the meaning of `tasks.priority_number`.
