---
id: A-2026-08-01-007
session: none
type: design
title: "Sitemap / UI Mapping"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/project_docs/sitemap.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Sitemap / UI Mapping

## Overview
This document maps the UI components to their respective files and logic.

## Main Tabs
- **Home**: `src/screens/HomeScreen.tsx`
  - Purpose: Overview of tasks.
- **Tasks**: `src/screens/TasksScreen.tsx`
  - Purpose: Detailed task list.
- **Calendar**: `src/screens/CalendarScreen.tsx`
  - Purpose: Date-based task view.
- **Settings**: `src/screens/SettingsScreen.tsx`
  - Purpose: App configuration.

## Features
- **Add Task**: `src/components/AddTaskModal.tsx`
  - Triggered by FAB on Home/Tasks screens.
- **Task Details**: `src/screens/TaskDetailsScreen.tsx`
  - Opens when a task item is clicked.
- **Bottom Sheet**: Uses `@gorhom/bottom-sheet` for task creation/editing.

## Navigation Flow
- `src/navigation/AppNavigator.tsx`: Root navigator.
- `src/navigation/TabNavigator.tsx`: Bottom tab definition.
- `src/navigation/MainNavigator.tsx`: Stack navigator for screens.

## Services
- `src/services/supabase.ts`: Supabase client initialization.
- `src/services/taskService.ts`: Task CRUD operations.
