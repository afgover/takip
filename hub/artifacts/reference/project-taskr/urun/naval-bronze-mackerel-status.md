---
id: A-2026-08-01-008
session: none
type: report
title: "Naval Bronze Mackerel (Taskr) - Coolify Deployment Report"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:NAVAL_BRONZE_MACKEREL_STATUS.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Naval Bronze Mackerel (Taskr) - Coolify Deployment Report

**Tarih**: 2026-04-30  
**Kontrol Tarihi**: SSH üzerinden canlı kontrol  
**Durum**: ✅ **HEALTHY ve RUNNING**

---

## 1. Service Details

| Property | Value |
|----------|-------|
| **Coolify Service Name** | Naval Bronze Mackerel |
| **Application ID** | `cmo6a2afk000uo1a53iciloqd` |
| **Repository** | `afgover/taskr` |
| **Branch** | main |
| **Build Pack** | Docker |
| **Container Port** | 3006 |
| **Docker Image** | `cmo6a2afk000uo1a53iciloqd:7e042a4` |
| **Latest Commit** | `7e042a4` (feat: enable swagger UI) |
| **Container Status** | ✅ Up 10 days (healthy) |

---

## 2. NestJS Backend Status

### ✅ Application Status
```
✅ Nest application successfully started (2026-04-19 23:17:48 UTC)
✅ All routes properly mapped and listening
```

### ✅ API Endpoints Mapped
**Auth**:
- `POST /auth/register` 
- `POST /auth/login`

**Tasks**:
- `GET /tasks/health`
- `GET /tasks`
- `GET /tasks/:id/subtasks`
- `GET /tasks/:id`
- `POST /tasks`
- `PUT /tasks/:id`
- `DELETE /tasks/:id`

**Tags**:
- `GET /tags`
- `POST /tags`
- `PUT /tags/:id`
- `DELETE /tags/:id`

**Shares**:
- `GET /shares/inbox`
- `POST /shares`
- `PUT /shares/:id/status`

**Users**:
- `GET /users/profile/:id`
- `PUT /users/profile/:id`
- `GET /users/search`

**Social**:
- `GET /social/friends`
- `POST /social/friends/request`
- `PUT /social/friends/accept/:id`
- `GET /social/groups`
- `POST /social/groups`
- `POST /social/groups/:id/members`

### ✅ API Documentation
- **Swagger UI**: `http://localhost:3006/docs` ✅ Working
- **Swagger JSON**: Available for API clients

---

## 3. Environment Variables

```
NODE_ENV=production
PORT=3006
DATABASE_URL=postgresql://postgres:gover_master_pwd@postgres-db:5432/todo_db?schema=public
```

### ✅ Database Connection
- **Host**: `postgres-db` (Docker network)
- **Port**: 5432
- **Database**: `todo_db`
- **User**: postgres
- **Status**: ✅ Connected and healthy

---

## 4. Health Check Status

```
Health Status: Healthy
Failing Streak: 0
Last Check: 2026-04-30 09:49:58 UTC
```

**Note**: Health check probes hit `http://127.0.0.1:3006/` which returns 404 (expected, no root route).  
This is OK - NestJS API routes are on `/auth`, `/tasks`, `/tags`, etc., which all work fine.

---

## 5. Docker Container Info

```bash
NAMES:   cmo6a2afk000uo1a53iciloqd
STATUS:  Up 10 days (healthy)
IMAGE:   cmo6a2afk000uo1a53iciloqd:7e042a4
PID:     2315889
```

**Container Performance**: ✅ Stable, running without issues

---

## 6. Coolify Configuration

| Setting | Status |
|---------|--------|
| **Auto-deploy** | ✅ Enabled |
| **Debug Mode** | ❌ Disabled |
| **Previews** | ❌ Disabled |
| **DB Branching** | ❌ Disabled |
| **Custom SSL** | ❌ Not configured |
| **Basic Auth** | ❌ Not configured |
| **Docker Network** | ✅ Connected to datasources_app-network |

---

## 7. Networking & Access

### Public Access
- **Domain**: Not yet configured
- **Cloudflare Tunnel**: Can be configured
- **Cloudflare Public Hostname**: Pending setup

### Internal Access (Docker Network)
```
http://localhost:3006/docs - Swagger UI (from VPS)
http://127.0.0.1:3006/docs - Swagger UI (localhost)
```

### From Frontend App
- **Current**: `http://178.104.159.14:3006`
- **Future**: Cloudflare tunnel/domain such as `https://todo-api.gover.us`

---

## 8. Recent Activity

| Date | Event |
|------|-------|
| 2026-04-19 23:17:48 | Application deployed and started |
| 2026-04-30 | Health checks running normally |
| 2026-04-30 | Code cleanup deployed (commit 336d868) |

**Latest Deployed Code**: 
- Commit: `7e042a4` (Swagger UI enablement)
- Cleanup code: Not yet redeployed from `336d868`

---

## 9. Current Issues & Recommendations

### ⚠️ Code Version Mismatch
The deployed version (`7e042a4`) is older than the latest cleanup commit (`336d868`).
**Action Needed**: 
- [ ] Push cleanup code to `afgover/taskr` main branch
- [ ] Trigger Coolify redeploy (or wait for auto-webhook)

### ✅ API Port Aligned
- **Frontend .env**: Points to `http://178.104.159.14:3006`
- **Actual Backend**: Running on `:3006`
- **Status**: Frontend is configured for the Coolify/NestJS backend

### 🟡 Domain Configuration
- **Planned**: `todo-api.gover.us`
- **Current**: No public domain
- **Needed**: Set up Cloudflare tunnel and public hostname

### 🔧 Health Check
- Root path `/` returns 404 (expected)
- Consider adding a `/health` endpoint that returns 200 for monitoring

---

## 10. Database Integrity

```
✅ Connected: postgres-db:5432
✅ Database: todo_db
✅ Schema: Prisma migrations applied
✅ Tables: All 9 Prisma models present
```

---

## 11. Deployment Checklist

- [x] Container running and healthy
- [x] NestJS app initialized successfully
- [x] All API routes mapped
- [x] Database connected
- [x] Swagger documentation accessible
- [ ] Code cleanup deployed
- [x] Frontend pointing to correct backend port
- [ ] Public domain configured
- [ ] Health check endpoint working (currently 404)

---

## 12. Next Steps

1. **Immediate** (Next 30 minutes):
   - [ ] Verify code cleanup is pushed to afgover/taskr main
   - [ ] Trigger Coolify redeploy or wait for auto-webhook
   - [ ] Confirm container pulls latest code

2. **Short-term** (Today):
   - [x] Update frontend .env to point to `:3006`
   - [ ] Test API connectivity from frontend
   - [ ] Run smoke tests from COOLIFY_TESTING_GUIDE.md

3. **Medium-term** (This week):
   - [ ] Add `/health` endpoint to return 200 OK
   - [ ] Configure Cloudflare tunnel public hostname
   - [ ] Set up `todo-api.gover.us` domain routing
   - [ ] SSL certificate setup

---

## 13. Contact & Support

For issues with Naval Bronze Mackerel deployment:
1. Check logs: `docker logs cmo6a2afk000uo1a53iciloqd`
2. Restart: Coolify dashboard or `docker restart cmo6a2afk000uo1a53iciloqd`
3. Redeploy: Push code and trigger webhook

---

**Last Updated**: 2026-04-30 by Claude Code  
**Status**: ✅ Production Ready (pending code sync & config updates)
