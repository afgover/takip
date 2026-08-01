---
id: A-2026-08-01-029
session: none
type: info
title: "Taskr & Agent Skills"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/skills.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Taskr & Agent Skills

## Agent Core Skills

### Design Aesthetics
- **Rich Aesthetics**: Vibrant colors, dark modes, glassmorphism, dynamic animations.
- **Visual Excellence**: Premium feel, modern typography, smooth gradients.
- **Dynamic Design**: Responsive, hover effects, interactive elements.

### Web Application Development
- **Core**: HTML, Javascript, Vanilla CSS.
- **Frameworks**: React Native (Expo), NestJS.
- **Optimization**: SEO best practices (for web), performance.

---

## Taskr Project Skills

### Expo + React Native Frontend
- **Managed Workflow**: Expo ~54.0.0.
- **Navigation**: Stack, tab, drawer navigation.
- **Bottom Sheet**: Modals and overlays via `@gorhom/bottom-sheet`.
- **State Management**: Zustand stores.
- **Persistence**: AsyncStorage for offline-first support.

### NestJS Backend
- **Modular Architecture**: Feature-based modules (tasks, auth, tags, social).
- **Real-Time**: WebSocket Gateways via Socket.io.
- **Security**: JWT auth, guards, user ownership verification.

### Database / Prisma (PostgreSQL)
- **Hierarchical Tags**: PostgreSQL LTREE support for nested tags.
- **Sharing System**: Task and group permissions (read/edit/admin).
- **Optimized Queries**: Selective loading for relations.

### Real-Time Sync Pattern
- **Optimistic UI Updates**: Immediate feedback on client.
- **Socket.io Broadcasting**: Real-time event propagation.
- **Offline Queue**: Sync updates upon reconnection.

### Tools
- `npm run start` (Expo), `npm run dev` (Backend).
- `npx prisma studio`, `npx prisma migrate dev`.
