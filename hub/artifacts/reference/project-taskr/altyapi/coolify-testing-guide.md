---
id: A-2026-08-01-017
session: none
type: info
title: "Coolify Deployment Testing Guide"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:COOLIFY_TESTING_GUIDE.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Coolify Deployment Testing Guide

This guide verifies that Taskr is working against the self-hosted NestJS backend deployed with Coolify on Hetzner.

**Project Taskr API Base URL**: `https://project-taskr-api.gover.us`
**Local Project Taskr API**: `http://127.0.0.1:3007`
**Swagger UI**: `https://project-taskr-api.gover.us/docs`

## Pre-Testing Setup

### 1. Environment Configuration

Frontend:

```bash
EXPO_PUBLIC_TASKR_PRODUCT=project-taskr
EXPO_PUBLIC_API_URL=https://project-taskr-api.gover.us
# Replace with the final Manager API domain when assigned.
```

Backend:

```bash
PORT=3007
NODE_ENV=production
DATABASE_URL=postgresql://...
JWT_SECRET=...
CORS_ORIGINS=https://project-taskr.gover.us
RATE_LIMIT_TTL_MS=60000
RATE_LIMIT_MAX=120
ENABLE_SWAGGER=false
```

Production Swagger is disabled by default. Temporarily set `ENABLE_SWAGGER=true` only when API documentation is required, then disable it again.

### 2. Service Verification Checklist

- [ ] SSH into Hetzner VPS: `ssh root@178.104.159.14`
- [ ] Verify API liveness: `curl http://localhost:3007/health/live`
- [ ] Verify API and database readiness: `curl http://localhost:3007/health`
- [ ] Confirm production Swagger is unavailable unless explicitly enabled: `curl -I http://localhost:3007/docs`
- [ ] Verify PostgreSQL is running and reachable by the backend.
- [ ] Verify Expo app builds with the same `EXPO_PUBLIC_API_URL`.

### 3. Network & Port Verification

```bash
netstat -tlnp | grep -E "3007|5432"
```

Expected:

- `3007` - Manager NestJS backend locally
- `5432` - PostgreSQL, if exposed locally on the VPS/network

---

## Core Feature Testing

Mark each item as working or note the actual result.

### Authentication

- [ ] Register a new user.
- [ ] Login with the new credentials.
- [ ] Close and reopen the app; token persistence should keep the user logged in.

### Task Management

- [ ] Create a task with title, description, priority, and deadline.
- [ ] Edit the task title/priority/deadline.
- [ ] Add subtasks from the task detail screen.
- [ ] Toggle active/completed status.
- [ ] Delete a task.
- [ ] Delete completed tasks from the completed filter.

### Tag System

- [ ] Create a parent tag.
- [ ] Create a child tag.
- [ ] Assign a tag to a task.
- [ ] Filter by parent tag and confirm descendants are included.
- [ ] Edit tag name/color/icon/priority range.
- [ ] Delete a tag.

### Social & Sharing

- [ ] Search another user by nickname.
- [ ] Send a friend request.
- [ ] Accept the friend request from another account.
- [ ] Create a group.
- [ ] Share a task with a friend.
- [ ] Share a task with a group.
- [ ] Accept or decline a shared task from the recipient account.

### Realtime

- [ ] Open the same account or shared workflow on two devices/sessions.
- [ ] Share a task from one session.
- [ ] Confirm the other session receives the inbox/update signal through Socket.io.

### Statistics

- [ ] Open Statistics screen.
- [ ] Confirm performance score is displayed.
- [ ] Confirm completion rate by tag is displayed.
- [ ] Confirm peak hour analysis is displayed.

---

## Backend API Verification

Test directly through Swagger UI at `https://project-taskr-api.gover.us/docs`.

Authentication:

- [ ] `POST /auth/register`
- [ ] `POST /auth/login`
- [ ] Use the JWT token in `Authorization: Bearer <token>`.

Tasks:

- [ ] `POST /tasks`
- [ ] `GET /tasks`
- [ ] `GET /tasks/{id}`
- [ ] `PUT /tasks/{id}`
- [ ] `DELETE /tasks/{id}`

Tags:

- [ ] `POST /tags`
- [ ] `GET /tags`
- [ ] `PUT /tags/{id}`
- [ ] `DELETE /tags/{id}`

Social:

- [ ] `POST /social/friend-request`
- [ ] `POST /social/accept-request`
- [ ] `GET /social/friends`
- [ ] `POST /social/groups`

Shares:

- [ ] `POST /shares`
- [ ] `GET /shares`
- [ ] Accept/decline share endpoints as exposed in Swagger.

Project Taskr session workflow:

- [ ] `POST /agent/sessions`
- [ ] `POST /agent/sessions/{id}/events`
- [ ] `POST /agent/sessions/{id}/tasks`
- [ ] `PATCH /projects/{groupId}/session-tasks/{id}`
- [ ] `POST /agent/sessions/{id}/approvals`
- [ ] `PATCH /projects/{groupId}/approvals/{id}`
- [ ] `POST /agent/sessions/{id}/git-refs`
- [ ] `GET /projects/{groupId}/sessions`
- [ ] `GET /projects/{groupId}/git-refs`

Smoke command:

```bash
TASKR_API_URL=https://project-taskr-api.gover.us npm --prefix backend run smoke:project-taskr-session
```

Error handling:

- [ ] Invalid JWT returns `401`.
- [ ] Missing required fields return `400`.
- [ ] Non-existent resource returns `404`.
- [ ] Unauthorized access is blocked.

---

## Quality Check

- [ ] App has no unhandled promise rejections during main workflows.
- [ ] Large task lists scroll smoothly.
- [ ] API responses are reasonably fast.
- [ ] Socket.io connection is established after login.
- [ ] All API requests use the Manager backend domain or `http://127.0.0.1:3007` locally.
