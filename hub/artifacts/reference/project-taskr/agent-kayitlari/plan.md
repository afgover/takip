---
id: A-2026-08-01-021
session: none
type: plan
title: "Taskr — Collaborative Task Management Platform"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/plan.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Taskr — Collaborative Task Management Platform

**Version**: 1.0.0  
**Status**: Production (Live)  
**Last Updated**: 2026-05-07

---

## 📋 Vision

Taskr is a **real-time collaborative task management platform** designed for teams and individuals to organize, share, and collaborate on tasks with full-featured subtasks, hierarchical tags, and social engagement.

Bridge the gap between simple to-do apps and complex project management tools by providing:
- **Individual task management** (personal productivity)
- **Team collaboration** (shared tasks, groups, real-time sync)
- **Social features** (follow friends, share portfolios, see what others are doing)
- **Mobile-first experience** (Expo React Native)

---

## 🎯 Core Features

### Task Management
- **Tasks & Subtasks**: Hierarchical task structure with dependent subtasks
- **Task States**: Draft, active, completed, archived (full lifecycle)
- **Descriptions & Metadata**: Rich text, due dates, priority, labels
- **Collaborative Editing**: Real-time updates across users via WebSocket
- **Activity Feed**: Track changes, comments, and updates

### Tag System
- **Hierarchical Tags**: Parent-child relationships using PostgreSQL LTREE
- **Tag Organization**: Organize tasks by category, project, area of life
- **Custom Colors**: Visual differentiation of tag groups
- **Smart Filtering**: Filter tasks by single or multiple tags
- **Tag Management**: Create, edit, delete tags with propagation to subtasks

### Sharing & Collaboration
- **Share with Users**: Invite specific users to view/edit tasks
- **Task Groups**: Organize related tasks into shared groups
- **Permission Levels**: Read-only, edit, admin permissions
- **Friend System**: Add friends, see their public tasks
- **Group Ownership**: Users manage groups they create

### Social Features
- **User Profiles**: Public, friends-only, or private visibility
- **Follow System**: Follow friends and see their activity
- **Activity Feed**: Shared tasks, group updates, user posts
- **Public Tasks**: Share task completion achievements
- **Comments** (Planned): Discuss tasks with collaborators
- **Notifications** (Planned): Real-time alerts for shares, updates

### Real-Time Updates
- **WebSocket Integration**: Live task sync via Socket.io
- **Optimistic Updates**: Immediate UI feedback, server-reconciliation
- **Offline Support**: AsyncStorage caching for mobile resilience
- **Conflict Resolution**: Last-write-wins or manual merge strategies

---

## 🏗️ Architecture

### Frontend (Expo + React Native)
```
- Expo ~54.0.0 (managed React Native)
- React 19.1.0 for UI components
- @react-navigation for navigation flows
- @gorhom/bottom-sheet for modals and overlays
- expo-notifications for push alerts (planned)
- AsyncStorage for offline caching
```

### Backend (NestJS + PostgreSQL)
```
- NestJS 11 with modular architecture
- Prisma ORM with 9 core models
- PostgreSQL with LTREE for hierarchical tags
- Socket.io for real-time synchronization
- JWT authentication with role-based access
```

### Data Model
**Core Tables**:
- User — Account, profile, settings
- Task — Core task entity with metadata
- Subtask — Child tasks, dependencies
- Tag — Hierarchical labels (LTREE path)
- TaskTag — Many-to-many relationship
- TaskShare — Sharing permissions
- Group — Shared task collections
- GroupMember — Group membership with roles
- Follow — Social connections

**Critical Uniqueness**:
- `User(email)` — Unique accounts
- `Task(id, userId)` — User-scoped tasks
- `Follow(userId, followerId)` — One follow per pair
- `TaskShare(taskId, sharedWithId)` — One share per recipient

### Deployment
- **Infrastructure**: Coolify auto-deployment on Hetzner VPS
- **Backend Port**: 3006 (NestJS)
- **Database**: PostgreSQL (managed via Prisma)
- **Container**: Docker with health checks
- **Auto-restart**: Coolify handles process management

---

## 📊 Financial Model & Success Metrics

### Core Metrics
- **User Growth**: Active weekly users (AWU), daily active users (DAU)
- **Engagement**: Tasks created/completed per user, sharing ratio
- **Retention**: Week-over-week retention, churn rate
- **Social**: Average friends per user, follow-back rate

### Product Success Indicators
- **Task Completion Rate**: % of created tasks marked complete
- **Collaboration Adoption**: % of tasks shared with other users
- **Group Usage**: Average members per group, group activity levels
- **Real-Time Reliability**: WebSocket sync success rate, reconnect efficiency

### Future Monetization (Post-MVP)
- **Free Tier**: Up to 50 tasks, 5 groups, basic sharing
- **Pro Tier** ($5/month): Unlimited tasks, 20 groups, advanced analytics
- **Team Plan** ($15/month/member): Group management, audit logs, priorities

---

## 🛣️ Roadmap

### Phase 1: Foundation (Q1 2026) ✅ COMPLETED
- Core task CRUD (create, read, update, delete)
- Authentication & user accounts
- Basic tagging system
- Sharing with users
- Deployment on Coolify

### Phase 2: Collaboration (Q2 2026) 🔄 IN PROGRESS
- Real-time WebSocket sync via Socket.io
- Task groups with membership
- Groups and friends system
- Activity feed (tasks, group updates)
- Testing infrastructure + QA

### Phase 3: Mobile Polish (Q2-Q3 2026) 📅 PLANNED
- Offline-first AsyncStorage caching
- Push notifications (expo-notifications)
- Bottom-sheet modals for actions
- Performance optimization
- Mobile-specific UX improvements

### Phase 4: Social & Analytics (Q3 2026) 📅 PLANNED
- Comments & discussions on tasks
- Public task sharing & achievement badges
- Analytics dashboard (completion trends, tag usage)
- Advanced search & filtering
- Social discovery

### Phase 5: Scale & Reliability (Q4 2026) 📅 PLANNED
- Database optimization (indexes, query analysis)
- Load testing for concurrent users
- Advanced conflict resolution
- Integration with external calendars
- Backup & disaster recovery

---

## 🏆 Key Differentiators

### vs. Todoist
- **Collaboration-first**: Built for teams, not just individuals
- **Real-time sync**: Changes visible instantly
- **Hierarchical tags**: Better organization than flat labels
- **Social features**: See what friends are accomplishing
- **Mobile-native**: True native app, not web wrapper

### vs. Asana / Monday.com
- **Lightweight**: No complex project management overhead
- **Faster**: Native mobile app vs. web-based
- **Personal use**: Works great for individual tasks
- **Simple pricing**: Not enterprise-focused

### vs. Apple Reminders
- **Collaboration**: Share tasks with others
- **Hierarchical organization**: LTREE tag structure
- **Social engagement**: Follow friends, see achievements
- **Cross-platform**: iOS/Android parity with Expo
- **Team features**: Groups, permissions, shared workspaces

---

## 💡 Implementation Priorities

### Critical Path (Ship Now)
1. ✅ Core task CRUD
2. ✅ Authentication & JWT
3. ✅ Basic sharing (users)
4. ✅ Tag system with LTREE
5. 🔄 Real-time sync (Socket.io)
6. 🔄 Groups and group sharing
7. 📅 Testing framework and QA

### High Value (Next Quarter)
8. 📅 Offline sync (AsyncStorage)
9. 📅 Activity feed UI
10. 📅 Push notifications
11. 📅 Comment threads

### Nice-to-Have (Future)
12. 📅 Analytics dashboard
13. 📅 Advanced search
14. 📅 Integration with Google Calendar
15. 📅 Teams/workspaces

---

## 📚 Technical Documentation

Full documentation structure in agents hub:

- **plan.md** (this file) — Vision, features, roadmap, financial model
- **progress.md** — Current status, deployment details, known issues
- **skills.md** — Technical patterns, real-time architecture, Expo patterns
- **memory/MEMORY.md** — Index of architectural decisions and specs
- **AGENT_ONBOARDING.md** — Mandatory 5-phase workflow for all agents

Production repository: `/Users/gover/Desktop/todo/` (GitHub: https://github.com/afgover/taskr)

---

## 🔗 Key Links

- **GitHub**: https://github.com/afgover/taskr
- **Deployment**: Coolify on Hetzner VPS (port 3006)
- **Backend API**: Swagger docs at `http://localhost:3006/api/docs`
- **Agents Hub**: https://github.com/afgover/agents/tree/main/projects/Taskr

---

## 👥 Team & Ownership

- **Creator/Lead**: afgover
- **Development Status**: Active (Phase 2/5)
- **Production Ready**: Yes (running on Coolify)

---

## ⚠️ Critical Rules

### GitHub Push
```
DO NOT: git push origin main without user approval
DO THIS: Ask user for approval before pushing
Reason: Auto-deploys to production
```

### Data Integrity
```
❌ NEVER delete user tasks or shares directly
❌ NEVER modify tag paths without updating descendants
✅ ALWAYS use Prisma migrations for schema changes
✅ ALWAYS test WebSocket sync in development
```

### Real-Time Reliability
```
❌ NEVER assume WebSocket always connected
✅ ALWAYS implement reconnection logic
✅ ALWAYS queue updates during disconnection
✅ ALWAYS verify sync after reconnect
```

### Collaborative Safety
```
❌ NEVER allow permission escalation in groups
❌ NEVER leak private tasks in shared queries
✅ ALWAYS verify user ownership before returning data
✅ ALWAYS check group membership for shared tasks
```

---

**Last Updated**: 2026-05-07  
**Status**: Production (Active Development)  
**Next Review**: 2026-05-14
