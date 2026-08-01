---
id: A-2026-08-01-027
session: none
type: info
title: "Global Rules & Conventions"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/global_rules.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Global Rules & Conventions

## 1. AI BEHAVIOR & INTERACTION
- **Tone:** Concise, professional, and goal-oriented. No unnecessary pleasantries.
- **Objective Analysis:** Provide balanced, unbiased evaluation.
- **Context-First Approach:** Parse, read, and understand existing codebase before suggesting changes.
- **Workflow:** Use "Planning Mode" for non-trivial tasks. Present Impact Analysis before writing code.
- **Step-by-Step Execution:** For large tasks, create a TODO plan and wait for approval.
- **Safety:** Request confirmation for destructive commands (rm, drop, force push).
- **Comments:** Always add meaningful and explanatory comments.

## 2. BULLETPROOF SECURITY & DATA PROTECTION
- **Zero-Trust Auth:** Every backend endpoint MUST be protected by `@UseGuards(JwtAuthGuard)` unless marked `@Public()`.
- **Deep Authorization (IDOR Prevention):** Verify Resource Ownership at Business Logic level.
- **Input Validation:** Every request body, query, and param MUST be validated using Zod or class-validator.
- **XSS Prevention:** Sanitize all user-generated content.
- **Secret Management:** NEVER hardcode secrets. Use `.env` and `.gitignore`.
- **Rate Limiting:** Implement `nestjs/throttler` on sensitive routes.

## 3. ARCHITECTURE & CODE QUALITY
- **Type Safety (No `any` Policy):** Usage of `any` is strictly forbidden.
- **Separation of Concerns (SoC):** Controllers handle HTTP; Business Logic stays in Service layer.
- **SOLID Principles:** Write modular, extensible, and decoupled code.
- **Global Error Handling:** Use Global Exception Filters.

## 4. DATABASE & ORM
- **SQL Injection Prevention:** Use Prisma’s type-safe methods.
- **Pagination Required:** Always implement limits (`take`, `skip`).
- **N+1 Query Prevention:** Use Prisma's `include` and `select` effectively.

## 5. WORKFLOW, DEBUGGING & EFFICIENCY
- **Zombie Process Protocol:** If logic drifts, assume a "Zombie Process".
- **Immediate Action:** Run `lsof -ti:<port> | xargs kill -9` to clear stuck processes.

## 6. CONTINUOUS DOCUMENTATION & LOGGING
- **Dedicated Project Docs:** Maintain `.gemini/project_docs/` for contextual, structural, and progress documents.
- **Architecture Flow:** Maintain `architecture.md`.
- **Sitemap & UI Mapping:** Maintain `sitemap.md`.
- **Progress Tracking:** Maintain `PROGRESS_LOG.md`.

## 7. AUTOMATIC PROJECT WORKFLOWS
- **Server Reset:** Use `.gemini/workflows/server.md`.

---

# Agents Hub - Universal Rules (agents/rules.md)
- Follow session initialization, tracking, and end-of-session protocols.
- Use documentation-first communication.
- Document all errors and fixes in `errors&fixes.md`.
