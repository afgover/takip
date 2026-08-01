---
id: A-2026-08-01-006
session: none
type: design
title: "Architecture Flow"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/project_docs/architecture.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Architecture Flow

## Overview
Taskr is a React Native application built with Expo, using Supabase for the backend.

## Tech Stack
- **Frontend**: React Native, Expo (SDK 55), TypeScript.
- **State Management**: Zustand.
- **Navigation**: React Navigation (Bottom Tabs, Native Stack).
- **Backend**: Supabase.
- **UI Components**: 
  - `@gorhom/bottom-sheet`
  - `@shopify/flash-list`
  - `react-native-reanimated`

## Directory Structure
- `src/components`: Reusable UI components.
- `src/screens`: Application screens.
- `src/services`: API and external service logic (Supabase).
- `src/store`: Zustand state stores.
- `src/navigation`: Navigation configuration and definitions.
- `src/hooks`: Custom React hooks.
- `src/types`: TypeScript interfaces and types.
- `supabase`: Local Supabase configuration and migrations.

## Data Flow & Mechanics
- **Hierarchical Tags**: Uses Postgres `LTREE` with Materialized Path logic for tag trees.
- **Priority Logic**: Dynamic priority adjustment based on deadlines (implemented in `priorityService`).
- **Sharing Architecture**:
  - `shared_items` table acts as the unified sharing registry for both tasks and tags.
  - Automated sharing propagates tag-level shares to any new tasks created with those tags.
  - Supabase Realtime handles live notifications.
- **Feed Performance**: Uses `@shopify/flash-list` (v2) for smooth scrolling.
