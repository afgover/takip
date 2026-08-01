---
id: A-2026-08-01-019
session: none
type: analysis
title: "Supabase -> Coolify Migration Analysis"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/project_docs/MIGRATION_ANALYSIS.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Supabase -> Coolify Migration Analysis

## Overview
We have performed a comprehensive analysis of both the local codebase (`/Users/gover/Desktop/todo`) and the Hetzner server (`178.104.159.14`) to investigate the issue where Expo Go seemingly continues to pull data from Supabase.

The good news is that **the codebase has been completely decoupled from Supabase Cloud**. However, there are a few configuration caching and port mapping issues causing the confusion.

---

## 1. Local Codebase Analysis (`/Users/gover/Desktop/todo`)
- **No Supabase Code Left**: All `@supabase/supabase-js` dependencies and references have been successfully removed in previous commits. There is no hardcoded `supabase.co` URL anywhere in the project.
- **API Configuration**: The frontend API correctly points to the new NestJS backend using `src/config/api.ts`, which reads `EXPO_PUBLIC_API_URL`.
- **.env File**: Your local `.env` correctly points to `EXPO_PUBLIC_API_URL=http://178.104.159.14:3006`.
- **EAS Configuration Error (Fixed)**: We found that `eas.json` still contained the old `EXPO_PUBLIC_SUPABASE_URL` environment variables pointing to port `8000`. This would cause cloud builds to fail. We have updated this to use `EXPO_PUBLIC_API_URL` and port `3006`.

## 2. Server Analysis (Hetzner / Coolify)
- **Container Port**: The backend (`cmo6a2afk000uo1a53iciloqd`) is successfully running on Hetzner, and we confirmed via SSH it is mapped to port **`3006`** (not `8000` as stated in older docs).
- **Database**: The database is correctly linked to the local Hetzner Postgres container (`postgres-db`) with the `todo_db` schema via Coolify's environment variable `DATABASE_URL`. 
- **API Health**: Making a request to `http://178.104.159.14:3006/docs` successfully returns the Swagger UI. The API is live and healthy on the server.

---

## 3. Why it feels like it's still pulling from Supabase
If the codebase has no Supabase links, why is this happening?

1. **Expo Bundler Cache (Most Likely)**: Expo Go caches environment variables (`.env`) extremely aggressively. If you previously had `EXPO_PUBLIC_SUPABASE_URL` or port `8000` in your `.env` and updated it to `EXPO_PUBLIC_API_URL` with port `3006`, the bundler in your terminal is likely still using the old cached variables. 
2. **Identical Data**: Since the data was migrated seamlessly, the data on the Hetzner database is a 1-to-1 clone of Supabase, making it look like it's still fetching from the cloud.

---

## 4. Required Actions to Fix

1. **Clear Expo Cache**: Stop your current Expo Go server in your terminal and restart it with the clear cache flag:
   ```bash
   npx expo start -c
   ```
2. **Zombie Processes (Optional)**: If you still face issues, there might be a zombie node process holding onto the old port on your Mac. You can kill it using `lsof -ti:8081 | xargs kill -9`.
