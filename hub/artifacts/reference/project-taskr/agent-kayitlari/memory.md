---
id: A-2026-08-01-024
session: none
type: info
title: "Taskr Project Shared Memory"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/memory/MEMORY.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Taskr Project Shared Memory

Index of shared memories for agents working on Taskr project.

**⚠️ NEW AGENTS**: Start with [AGENT_ONBOARDING.md](../AGENT_ONBOARDING.md) before reading anything else.

## Agent Onboarding (START HERE)

- [AGENT_ONBOARDING.md](../AGENT_ONBOARDING.md) — **MANDATORY for all agents**. Two-layer documentation workflow, session checklist, critical rules for collaborative systems.

## Critical References (Read First)

- [WebSocket Real-Time Architecture](reference_realtime.md) — Socket.io integration, event patterns, offline queue management
- [Database Schema & LTREE Hierarchy](reference_database.md) — 9 Prisma models, hierarchical tags, relationships
- [Coolify Deployment Pipeline](reference_deployment.md) — Auto-deployment on Hetzner VPS, container health, rollback procedures

## Feedback & Rules

- [Always ask before GitHub push](feedback_github_push.md) — Production system. Ask user before `git push origin main`.

## Project Context

- [WebSocket Integration Status](project_realtime.md) — IN PROGRESS (Q2 2026). Socket.io implementation, offline sync queue design.
- [QA & Testing Framework](project_testing.md) — IN PROGRESS (Q2 2026). Feature testing roadmap, API testing via Swagger.
- [Activity Feed Implementation](project_feed.md) — PLANNED (Q2 2026). Design complete, awaiting real-time integration.
- [Mobile Optimization Phase](project_mobile.md) — PLANNED (Q3 2026). AsyncStorage, push notifications, offline-first UX.

## Technical Reference

- [Tech Stack Overview](reference_tech_stack.md) — Expo ~54.0 + NestJS 11 + PostgreSQL, Socket.io real-time
- [Deployment Status](reference_deployment.md) — Coolify/Hetzner VPS, Docker health, production config
- [LTREE Tag System](reference_ltree_hierarchy.md) — Hierarchical tag implementation, query patterns, performance

---

**Last Updated**: 2026-05-07  
**Total Entries**: 6+ core memories  
**Status**: Complete and ready
