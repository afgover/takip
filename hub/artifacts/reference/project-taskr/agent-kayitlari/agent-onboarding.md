---
id: A-2026-08-01-025
session: none
type: info
title: "📋 Taskr Agent Onboarding Guide"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/AGENT_ONBOARDING.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# 📋 Taskr Agent Onboarding Guide

**MANDATORY WORKFLOW FOR ALL AGENTS**

Before beginning ANY work on the Taskr project, you must complete this onboarding workflow. This ensures all agents operate with complete context, preventing errors, inconsistencies, and critical issues in a production collaborative system.

⏱️ **Estimated Duration**: 20-30 minutes  
✅ **Status**: Must complete BEFORE project work  
📍 **Location**: `/Users/gover/Desktop/agents/projects/Taskr/`

---

## 🎯 Why This Workflow Matters

Taskr is a **production collaborative task management platform** with real user data (tasks, groups, shared tasks, real-time updates). Incomplete context leads to:

- **Data Integrity Issues**: Deleting tasks from shared groups, orphaning subtasks, breaking LTREE hierarchies
- **Real-Time Failures**: WebSocket sync breaking, offline queue corruption, missed updates
- **Permission Breaches**: Private tasks visible to wrong users, permission escalation in groups
- **Deployment Failures**: Breaking production on Coolify, downtime for active users
- **Collaboration Bugs**: Race conditions in simultaneous edits, lost updates in offline scenarios
- **Database Corruption**: LTREE path inconsistencies, invalid foreign keys, orphaned records

This workflow prevents all of these by establishing a two-layer documentation system: **Hub Rules** (apply to all projects) + **Project Rules** (Taskr-specific).

---

## 📚 Two-Layer Documentation System

```
AGENTS HUB (applies to ALL projects)
├── rules.md               → Development standards, commit practices
├── security.md            → Credential handling, production safety
├── CLAUDE.md              → Global working guidelines
└── projects/Taskr/        → Project-specific documentation
    ├── plan.md            → Vision, features, architecture
    ├── progress.md        → Current status, completed features
    ├── skills.md          → Technical patterns, real-time architecture
    ├── memory/            → Shared context, implementation details
    └── AGENT_ONBOARDING.md (this file)
```

**Hub documentation** = Rules that apply to every project  
**Project documentation** = Taskr-specific context, WebSocket patterns, LTREE hierarchies, deployment procedures

---

## 📋 Session Initialization Checklist

### Phase 1: Hub Repository Setup (5 minutes)

- [ ] Clone/pull the agents repository: `https://github.com/afgover/agents`
  ```bash
  git clone https://github.com/afgover/agents.git ~/Desktop/agents
  cd ~/Desktop/agents
  git pull origin main
  ```

- [ ] Verify you're in the correct directory:
  ```bash
  pwd  # Should show: /Users/gover/Desktop/agents
  ls -la projects/Taskr/
  ```

### Phase 2: Read Hub Documentation (8 minutes)

Read these files in order. They establish rules for ALL projects:

1. **[rules.md](https://github.com/afgover/agents/blob/main/rules.md)** (5 min)
   - Development standards
   - Git workflow
   - Commit message format
   - Pull request procedures
   - ⚠️ **CRITICAL**: GitHub push rule (always ask user before `git push origin main`)

2. **[README.md](https://github.com/afgover/agents/blob/main/README.md)** (3 min)
   - Project overview
   - Quick reference links
   - Contact information

### Phase 3: Read Taskr Project Documentation (12 minutes)

Read these files IN ORDER. They provide Taskr-specific context:

1. **[plan.md](https://github.com/afgover/agents/blob/main/projects/Taskr/plan.md)** (3 min)
   - **What**: Project vision (collaborative task management, real-time sync, social features)
   - **Why**: Bridge gap between simple to-do apps and complex project management
   - **How**: Architecture, Expo + NestJS, WebSocket real-time updates
   - **Read this first** to understand the big picture

2. **[progress.md](https://github.com/afgover/agents/blob/main/projects/Taskr/progress.md)** (4 min)
   - **What**: Current status, completed features, recent work
   - **Why**: Understand what exists and what's breaking
   - **Look at**: Completed features (CRUD, sharing, tags, groups), in-progress (WebSocket), known issues
   - **Key sections**: ✅ Completed (Phase 1 foundation), 🔄 In Progress (real-time sync, testing), 🚨 Known Issues

3. **[skills.md](https://github.com/afgover/agents/blob/main/projects/Taskr/skills.md)** (3 min)
   - **What**: Technical patterns, tools, libraries, real-time architecture
   - **Why**: Understand how to implement features consistently
   - **Look at**: Problem-solving patterns, WebSocket patterns, LTREE hierarchy operations
   - **Example**: How to implement task sharing, real-time broadcasts, offline sync queue

4. **[memory/MEMORY.md](https://github.com/afgover/agents/blob/main/projects/Taskr/memory/MEMORY.md)** (2 min)
   - **What**: Index of shared memories and architectural decisions
   - **Why**: Quick reference to decision history and context
   - **Read**: The index first, then click into specific memories if needed
   - **Key memories**:
     - `reference_realtime.md` — WebSocket/Socket.io implementation
     - `reference_database.md` — Database schema and LTREE hierarchy
     - `reference_deployment.md` — Coolify/Hetzner VPS deployment

### Phase 4: Verify Repository Connection (2 minutes)

- [ ] Clone/pull the main Taskr repository (if not already done):
  ```bash
  git clone https://github.com/afgover/taskr.git ~/Desktop/todo
  cd ~/Desktop/todo
  git pull origin main
  ```

- [ ] Verify project structure:
  ```bash
  ls -la
  # Should show: backend/, frontend/, docs/, package.json
  ```

- [ ] Check backend is running (or verify Coolify deployment):
  ```bash
  # Backend should be running on port 3006
  curl http://localhost:3006/api/docs
  # Should return Swagger documentation
  ```

### Phase 5: Complete Verification (3 minutes)

- [ ] **Quiz yourself**: Can you answer these without looking?
  - What is the GitHub push rule? (Answer: Always ask user before `git push origin main`)
  - What are the 5 phases of the Taskr roadmap? (Answer: Foundation, Collaboration, Mobile Polish, Social & Analytics, Scale & Reliability)
  - How does WebSocket real-time sync work? (Answer: Client sends update → server broadcasts to connected clients → optimistic UI update → server reconciliation)
  - What is LTREE and why is it used? (Answer: PostgreSQL hierarchical data type for organizing tags in parent-child relationships)
  - What are the main features completed? (Answer: Task CRUD, auth, tags, sharing, groups, Coolify deployment)

---

## 📖 Documentation Quick Reference

| Document | Read Time | Content | Why It Matters |
|----------|-----------|---------|---|
| **rules.md** | 5 min | Git workflow, GitHub push rule | Prevents pushing broken code to production |
| **plan.md** | 3 min | Vision, features, architecture | Understand the collaborative system design |
| **progress.md** | 4 min | Current status, completed features, issues | Know what's working, what's broken |
| **skills.md** | 3 min | Technical patterns, real-time architecture | Implement features consistently |
| **memory/MEMORY.md** | 2 min | Index of decisions and specs | Reference for implementation details |
| **memory/reference_realtime.md** | 5 min* | WebSocket/Socket.io patterns | Handle real-time updates correctly |
| **memory/reference_database.md** | 5 min* | Database schema, LTREE hierarchy | Manage collaborative data |
| **memory/reference_deployment.md** | 5 min* | Coolify/Hetzner deployment | Understand production setup |

*Only read detailed memories if you're working on those specific features.

---

## 🚨 Critical Rules (Non-Negotiable)

### GitHub Push Rule
```
⚠️  DO NOT: git push origin main
✅ DO THIS: Ask user for approval before pushing
```
**Why**: Auto-deploys to production on Coolify. You could break the app for active users.

### Data Integrity Rule
```
❌ NEVER delete user tasks or shares directly
❌ NEVER modify LTREE paths without updating descendants
❌ NEVER orphan subtasks or group members
✅ USE Prisma migrations for schema changes
✅ ALWAYS test cascade deletes locally first
```
**Why**: Collaborative data is permanent and affects multiple users. Wrong deletion = data loss.

### Real-Time Sync Rule
```
❌ NEVER assume WebSocket always connected
❌ NEVER skip offline queue implementation
❌ NEVER lose updates during sync failure
✅ ALWAYS implement reconnection logic
✅ ALWAYS queue updates during disconnection
✅ ALWAYS verify sync after reconnect
```
**Why**: Mobile users disconnect frequently. Missed updates = lost work.

### Permission & Privacy Rule
```
❌ NEVER return private tasks in shared API responses
❌ NEVER allow permission escalation in groups
❌ NEVER leak task data to non-owners
✅ ALWAYS verify user ownership before returning data
✅ ALWAYS check group membership for shared tasks
✅ ALWAYS validate access level (read vs edit)
```
**Why**: Users' task data is private. Leaked data = privacy breach.

### Collaborative Safety Rule
```
❌ NEVER assume single-user edit scenarios
❌ NEVER ignore race conditions in simultaneous updates
❌ NEVER overwrite another user's changes without merge
✅ ALWAYS implement conflict resolution (last-write-wins or CRDT)
✅ ALWAYS test with 2+ simultaneous editors
✅ ALWAYS broadcast updates to all interested clients
```
**Why**: Multiple users editing same task simultaneously = conflicts.

### LTREE Hierarchy Rule
```
❌ NEVER create paths that violate hierarchy (orphaned nodes)
❌ NEVER forget to update descendant paths on rename
❌ NEVER assume lquery syntax (use proper PostgreSQL functions)
✅ USE PostgreSQL path operations (@>, <@, @, ~)
✅ ALWAYS test with deeply nested tags (5+ levels)
✅ ALWAYS verify path integrity after operations
```
**Why**: Invalid LTREE paths break tag organization and queries.

### Deployment Rule
```
Before pushing to production:
1. Test feature in Expo app (golden path + edge cases)
2. Check for regressions (smoke test other features)
3. Verify WebSocket sync (test offline → online)
4. Verify permissions (user A can't see user B's private tasks)
5. Verify LTREE operations (tag creation/deletion)
6. Get user approval
7. Push to GitHub (triggers Coolify auto-deploy)
```
**Why**: Production Coolify deployment affects all active users.

### Credential Handling Rule
```
❌ NEVER hardcode API keys or secrets
❌ NEVER commit .env files
✅ USE environment variables (.env.local, not in repo)
✅ USE Coolify secrets management for production
```
**Why**: Prevents API key leaks and account compromise.

---

## 🔄 Complete This Before Doing ANYTHING Else

**Do not**:
- ❌ Open code files
- ❌ Run `npm install`
- ❌ Start the dev server
- ❌ Make any commits
- ❌ Ask about implementation details
- ❌ Assume WebSocket is working

**Do**:
- ✅ Read the documentation
- ✅ Understand the collaborative model
- ✅ Understand WebSocket real-time patterns
- ✅ Understand LTREE hierarchy operations
- ✅ Understand permission and privacy rules
- ✅ Verify you have the correct repo context
- ✅ Check recent commits match the progress documentation
- ✅ Verify the GitHub push rule
- ✅ Review the WebSocket integration status
- ✅ Then ask the user: "Documentation reviewed. What would you like me to work on?"

---

## 📝 What Each File Type Tells You

### `plan.md` — Read This First for Direction
```
Example answers:
- "What is Taskr?" → Collaborative task management, real-time sync, social features
- "What are we building next?" → Mobile polish, comments/likes, advanced analytics
- "Why?" → Reach mobile users, increase engagement, community building
- "What real-time patterns are critical?" → WebSocket sync, offline queue, conflict resolution
```

### `progress.md` — Read This for Current Status
```
Example answers:
- "What features exist?" → Task CRUD, auth, sharing, groups, LTREE tags
- "What's broken?" → Check "Known Issues" (WebSocket not fully tested, frontend config mismatch)
- "What's recent?" → 2026-05 Coolify deployment, code cleanup, testing roadmap
- "What should I work on next?" → Check "Next Steps" (WebSocket testing, QA, activity feed)
```

### `skills.md` — Read This for Implementation Patterns
```
Example answers:
- "How do I sync tasks in real-time?" → See "Real-Time WebSocket Pattern" section
- "How do I handle offline updates?" → See "Offline-First with AsyncStorage" pattern
- "How do I create hierarchical tags?" → See "Hierarchical Tag Operations" pattern
- "What libraries do we use?" → See "Tools & Libraries" section
```

### `memory/MEMORY.md` — Read This for Decision Context
```
Example answers:
- "How does real-time sync work?" → See reference_realtime.md
- "What's the database schema?" → See reference_database.md
- "How is deployment configured?" → See reference_deployment.md
- "What architectural decisions have been made?" → See memory index
```

---

## ✅ How You Know You're Ready

You're ready to start project work when you can answer ALL of these:

1. What is the GitHub push rule and why does it exist?
2. What are the 3-4 most important completed features?
3. How does WebSocket real-time sync work in Taskr?
4. What is LTREE and how are tags organized hierarchically?
5. What are the critical rules for collaborative data?
6. What is the current status of WebSocket integration?
7. What is the next priority for the project?

If you can't answer these, re-read the documentation.

---

## 🎬 After Onboarding: Your First Task

Once you've completed this checklist, message the user:

> "I've completed the Taskr onboarding:
> ✅ Read hub rules.md
> ✅ Read project plan.md, progress.md, skills.md
> ✅ Reviewed memory/MEMORY.md
> ✅ Verified repository structure
> ✅ Understand collaborative task management (tasks, sharing, groups)
> ✅ Understand real-time sync architecture (WebSocket, offline queue)
> ✅ Understand LTREE hierarchical tags
> ✅ Understand permission and privacy rules
> ✅ Verified GitHub push rule
> ✅ Verified Coolify deployment
> 
> Ready to work. What would you like me to focus on?"

Then wait for the user to provide your specific task.

---

## 🔗 Quick Links to All Documentation

### Hub Documentation
- GitHub Hub: https://github.com/afgover/agents
- rules.md: https://github.com/afgover/agents/blob/main/rules.md
- README: https://github.com/afgover/agents/blob/main/README.md

### Project Documentation
- Local Path: `/Users/gover/Desktop/agents/projects/Taskr/`
- plan.md: https://github.com/afgover/agents/blob/main/projects/Taskr/plan.md
- progress.md: https://github.com/afgover/agents/blob/main/projects/Taskr/progress.md
- skills.md: https://github.com/afgover/agents/blob/main/projects/Taskr/skills.md
- memory/: https://github.com/afgover/agents/tree/main/projects/Taskr/memory

### Main Repositories
- Taskr GitHub: https://github.com/afgover/taskr
- Backend API: http://localhost:3006/api/docs (Swagger)
- Production Deployment: Coolify on Hetzner VPS

---

## 💬 Questions During Onboarding?

If anything is unclear:
1. Check if the answer is in the referenced documentation
2. Look for similar examples in skills.md
3. Search memory/MEMORY.md for context
4. Ask the user — they can clarify or update the documentation

---

## 📅 For Returning Agents

Even if you've worked on Taskr before:

- [ ] **Every session**: Skim progress.md to see what changed since last time
- [ ] **Every quarter**: Re-read plan.md to ensure vision hasn't shifted
- [ ] **On uncertainty**: Check memory/MEMORY.md for architectural context
- [ ] **Before coding**: Verify GitHub push rule (always ask before main branch push)
- [ ] **Before real-time work**: Review WebSocket patterns (offline queue, conflict resolution)

Returning agents should spend 5-10 minutes refreshing context rather than assuming nothing changed.

---

## 🎓 This Workflow Applies to ALL Projects

This same two-layer documentation system (hub rules + project-specific docs) is used for **all** projects in the agents hub. Once you understand this workflow, you can onboard to any project by:

1. Reading hub rules
2. Reading the project's plan/progress/skills/memory
3. Starting work with complete context

---

**Version**: 1.0  
**Last Updated**: 2026-05-07  
**Status**: MANDATORY — All agents must complete this before project work  
**Owner**: Project Lead (afgover)

---

### ⬇️ START HERE IF YOU'RE NEW

If you're reading this for the first time:

1. Go to Phase 1 above ⬆️
2. Follow each phase in order
3. Don't skip any steps (data integrity depends on it)
4. After Phase 5, message the user that you're ready
5. Then and ONLY THEN begin project work

**Begin Phase 1 now.** ⬇️
