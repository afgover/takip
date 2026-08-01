---
id: A-2026-08-01-026
session: none
type: info
title: "Taskr Project"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/README.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Taskr Project

A collaborative real-time task management platform with sharing, groups, and social features.

**Status**: Production (Live)  
**Version**: 1.0.0  
**Last Updated**: 2026-05-07

---

## 🚨 AGENTS: START HERE

**NEW OR RETURNING AGENTS**: Before doing ANY project work, read **[AGENT_ONBOARDING.md](AGENT_ONBOARDING.md)** (20-30 min).

This establishes the mandatory documentation workflow all agents must follow. Real-time sync accuracy and data integrity depend on it.

→ **[Go to AGENT_ONBOARDING.md](AGENT_ONBOARDING.md)**

---

## Project Structure

```
Taskr/
├── plan.md                    # Vision, objectives, features, roadmap
├── progress.md                # Current status and completed features
├── skills.md                  # Technical patterns, real-time architecture
├── memory/                    # Shared context and implementation specs
│   ├── MEMORY.md              # Memory index
│   ├── reference_realtime.md  # WebSocket patterns and offline sync
│   ├── reference_database.md  # Database schema, LTREE hierarchies
│   └── reference_deployment.md # Coolify deployment procedures
├── AGENT_ONBOARDING.md        # Mandatory onboarding workflow
└── README.md                  # This file
```

---

## Quick Reference

### Current Objective
Implement **Real-Time Collaboration** (WebSocket sync + offline queue)  
→ Timeline: Q2 2026 (ongoing)  
→ See [plan.md](plan.md) for full roadmap

### Core Features
- ✅ Task management (CRUD, subtasks, metadata)
- ✅ Authentication (JWT, user accounts)
- ✅ Hierarchical tags (PostgreSQL LTREE)
- ✅ Task sharing (with permission levels)
- ✅ Groups (shared task collections)
- ✅ Friend system (follow other users)
- ✅ Coolify deployment (auto-deploy on Hetzner VPS)
- 🔄 Real-time WebSocket sync (in progress)
- 📅 Offline sync queue (planned)

### Recent Work
- **2026-05-07**: Full documentation created for agents hub, testing roadmap outlined
- **2026-05-03**: Code cleanup completed, production-ready codebase
- **2026-04-27**: Phase 1 features deployed via Coolify

### Critical Rule
⚠️ **Always ask before `git push origin main`** — Production system  
→ See [memory/feedback_github_push.md](memory/feedback_github_push.md)

---

## Documentation

| Document | Purpose |
|----------|---------|
| **[plan.md](plan.md)** | Vision, objectives, features, roadmap, financial model |
| **[progress.md](progress.md)** | What's done, what's in progress, known issues |
| **[skills.md](skills.md)** | Technical patterns, real-time architecture, tools |
| **[memory/MEMORY.md](memory/MEMORY.md)** | Index of shared memories and specs |

---

## Technology Stack

- **Frontend**: Expo ~54.0 + React Native 0.81 + Zustand
- **Backend**: NestJS 11 + Prisma + PostgreSQL
- **Real-Time**: Socket.io WebSocket + offline AsyncStorage
- **Deployment**: Coolify auto-deploy on Hetzner VPS (port 3006)

---

## Key Skills & Patterns

### Real-Time Collaboration
- **WebSocket Sync**: Client sends update → server broadcasts → other clients receive
- **Offline Queue**: Store updates in AsyncStorage during disconnection
- **Conflict Resolution**: Last-write-wins or manual merge for simultaneous edits
- **Optimistic Updates**: Show changes immediately, reconcile with server

### Hierarchical Organization
- **LTREE Tags**: PostgreSQL native hierarchical tag structure
- **Tag Relationships**: Parent-child tag organization for task categorization
- **Nested Queries**: Efficient queries for tag hierarchies and descendants

### Collaborative Features
- **Task Sharing**: Share individual tasks with permission levels
- **Groups**: Shared task collections with member management
- **Permissions**: Read-only, edit, admin access levels
- **Privacy**: Private tasks hidden from non-owners

### Deployment
- **Coolify Pipeline**: Auto-deployment on git push
- **Docker Containers**: Health checks, auto-restart
- **PostgreSQL Database**: Persistent data storage
- **WebSocket Port**: 3006 for real-time connections

---

## Development Workflow

```bash
# Local development
npm run dev                    # http://localhost:3000 (frontend)
npm run start:dev             # http://localhost:3006 (backend)

# Database
npx prisma studio            # Visual DB explorer
npx prisma migrate dev --name [description]

# Build & verify
npm run build                 # Production build
npm run lint                  # Type check
```

### Before Pushing to GitHub
1. Test feature in Expo app (golden path + edge cases)
2. Verify no regressions
3. Test WebSocket sync (verify offline → online works)
4. Verify permissions (private tasks stay private)
5. Verify LTREE operations (tag creation/deletion)
6. **Ask user for approval**: "Should I push to GitHub?"
7. Wait for confirmation
8. `git push origin main`

---

## Contact & Links

- **GitHub**: https://github.com/afgover/taskr
- **Deployment**: Coolify on Hetzner VPS (port 3006)
- **API Docs**: http://localhost:3006/api/docs (Swagger)
- **Tech Stack**: NestJS + Expo React Native + PostgreSQL

---

## Memory Index

Quick access to shared memories:

- **Always ask before GitHub push** → [feedback_github_push.md](memory/feedback_github_push.md)
- **Real-Time WebSocket Patterns** → [reference_realtime.md](memory/reference_realtime.md)
- **Database Schema & LTREE** → [reference_database.md](memory/reference_database.md)
- **Coolify Deployment** → [reference_deployment.md](memory/reference_deployment.md)

See [memory/MEMORY.md](memory/MEMORY.md) for full index.

---

**Last Updated**: 2026-05-07  
**Status**: Active Development (Phase 2/5)  
**Next Review**: 2026-05-14
