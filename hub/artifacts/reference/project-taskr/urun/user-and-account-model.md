---
id: A-2026-08-01-002
session: none
type: design
title: "User And Account Model"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.agents/USER_AND_ACCOUNT_MODEL.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# User And Account Model

Taskr targets two different user groups. Future development must keep these audiences separate in product behavior, navigation, permissions, and pricing.

## Audience 1: Free Core Users

Free users use Taskr as a lightweight collaborative task app.

They can use:

- Personal task creation and task management.
- Tags, priorities, deadlines, and basic filtering.
- Friend connections.
- Open groups for simple collaboration.
- Basic task/tag sharing.
- Settings, profile, and local app preferences.

They should not see or need to understand:

- Managed project operations.
- Manager dashboards.
- Agent runs.
- Project memory.
- Operation trees.
- Artifact journals.
- Assignment governance and approval flows.
- Agent API keys or bridge mode.

The free user experience should stay simple even though the repository contains advanced operations features.

## Audience 2: Managed Project Teams

Managed project teams use Taskr as an operations layer for project execution.

They can use:

- Managed projects, represented by `Group.mode = "managed"`.
- Project roles through `GroupMember.role`.
- Manager dashboards and assignment review.
- Project memory, progress, plans, decisions, and skills.
- Agent and human assignment flows.
- Agent runs, prompt packs, artifacts, audit logs, and operation trees.
- Approval, return, reviewer, backup, deletion review, and governance workflows.

This audience is the target for paid or premium account features.

## Account And Role Rules

Use these concepts consistently:

- `User`: a login identity. This should not imply a paid tier by itself.
- `Free Core User`: a normal user without access to managed project features.
- `Managed Project Member`: a user who belongs to a managed project but does not manage it.
- `Project Manager`: a user with manager-level authority in a managed project.
- `Project Admin`: a higher project role that can manage members and project settings.
- `Project Owner`: the group creator. This is derived from `Group.creatorId`, not stored as a `GroupMember.role`.
- `Agent User`: an executor identity with `User.isAgent = true`.
- `Agent Key Owner`: a human user who can create/manage agent keys. This should not automatically mean the human user is an agent executor.

Manager status is project-scoped, not global. The same human can be a manager in one managed project and a regular member or free user elsewhere.

## Current Technical Mapping

- Free/open collaboration uses `Group.mode = "open"`.
- Managed project/application collaboration uses `Group.mode = "managed"`.
- In Project Taskr MVP, one project/application is represented by one managed `Group`.
- Project membership uses `GroupMember`.
- Project roles currently use `GroupMember.role = "member" | "manager" | "admin"`.
- Owner authority is inferred when `Group.creatorId === userId`.
- Agent executor identity currently uses `User.isAgent`.

## Important Product Boundary

Do not treat `User.isAgent` as a general subscription, manager, or premium flag.

`isAgent` means the user account is an agent executor identity. A human manager who creates or owns an agent key should not be forced into the agent executor experience.

Current implementation rule:

- Creating an agent key must not automatically set `User.isAgent = true`.
- Free Core users must not access agent-key or agent-usage endpoints.
- Agent-key and agent-usage endpoints are reserved for managed project managers/admins/owners and existing agent executor users.
- Agent executor activation must be explicit, currently through `activateExecutorIdentity: true` for setup/test flows that are intentionally creating an agent executor identity.
- Agent-key login must not silently convert a human key owner into an agent executor.

If the product needs billing or premium access, add an explicit subscription/account entitlement concept instead of overloading `isAgent` or `GroupMember.role`.

Recommended future fields/concepts:

- `Workspace` or `Account` for billing and ownership if teams become first-class billing units.
- `Entitlement` or `SubscriptionPlan` for features such as managed projects, agent runs, project memory, and operation history.
- `ProjectRole` enum or constants for `member`, `manager`, `admin`, and derived `owner`.
- A separate flag or relation for agent key ownership if needed.

## Navigation Rules

- Free users should see the core tabs only: Feed, Tags, Shared, Settings.
- Managed project managers should see Manager/Ops navigation.
- Managed project members may see assignment-focused project views, but not full manager controls.
- Agent users should see agent queue/execution surfaces, not manager dashboards by default.
- Advanced project operations must be hidden unless the active user has a managed project role or entitlement that requires them.
- Project/application members can access the application dashboard, read project notes/docs, view tasks, and update allowed task/test states.
- Project/application managers/admins/owners can manage members, broader assignments, approvals, archives, and governance actions.

## Development Checklist

Before adding a feature, answer:

- Is this feature for Free Core users or Managed Project Teams?
- Does it require `Group.mode = "managed"`?
- Is access based on project role, subscription entitlement, agent executor identity, or a combination?
- Will this make the free app feel more complex?
- Can this feature be hidden cleanly from free users?
- Does it preserve the future option to split Taskr Core and Taskr Ops into separate products?
