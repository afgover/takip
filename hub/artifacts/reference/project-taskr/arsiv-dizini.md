---
id: A-2026-08-01-000
session: none
type: info
title: "Project Taskr arşivi — dizin ve taşıma notu"
created: 2026-08-01T00:00:00Z
---

# Project Taskr Arşivi

`taskr` reposunun `project-taskr` branch'inde biriken proje belgeleri, proje
arşive kaldırılırken buraya taşındı (2026-08-01). Belgeler **olduğu gibi**
duruyor; her birinin başına yalnızca sözleşme frontmatter'ı ve kaynak yolunu
söyleyen bir arşiv notu eklendi.

## Neden burada

Project Taskr, bugünkü `takip` sisteminin öncülüydü: EVOLUTION Aşama 0, o
projenin mimari yönünü belirleme oturumudur ve "backend işletme yükü" tespiti
(L-001) oradan çıktı. Proje arşive kaldırıldığı için kendi `<proje>_takip`
hub'ı açılmadı; kayıtlar takip hub'ında **referans arşiv** olarak duruyor.

Bu belgeler **güncel değildir** — tarihsel kayıttır. Bugünkü sistemin geçerli
sözleşmesi `hub/SYSTEM.md`'dir.

## Burada olmayan

Project Taskr'ın yönettiği **projelerin kendi verisi** (CoPilot, Financer,
Sarraf, DataSources) bu repoda hiç yoktu; onlar uygulamanın veritabanında
(`Group`/`ProjectTaskLink`/`ProjectMemoryRecord` kayıtları) yaşıyordu. Repoda
bu adlar yalnızca örnek ve pano taslağı olarak geçiyor. O projeler takip
sistemine alınacaksa her biri için `<proje>_takip` reposu açılıp sıfırdan
başlanır (bkz. `artifacts/reference/proje-ekleme.md`).

## Dizin

### Ürün ve mimari kararları

Project Taskr'ın ne olduğu, Taskr Basic'ten nasıl ayrıldığı, hesap modeli ve uygulama panoları.

| Belge | Kaynak |
|---|---|
| [Architecture Flow](urun/architecture.md) | `.gemini/project_docs/architecture.md` |
| [Product Split Architecture Note](urun/hybrid-product-architecture.md) | `.agents/HYBRID_PRODUCT_ARCHITECTURE.md` |
| [🚀 App Store & Play Store Yayınlama Yol Haritası](urun/market-roadmap.md) | `.gemini/project_docs/MARKET_ROADMAP.md` |
| [Naval Bronze Mackerel (Taskr) - Coolify Deployment Report](urun/naval-bronze-mackerel-status.md) | `NAVAL_BRONZE_MACKEREL_STATUS.md` |
| [Project Taskr Application Dashboards](urun/project-taskr-application-dashboards.md) | `.agents/PROJECT_TASKR_APPLICATION_DASHBOARDS.md` |
| [Project Taskr Current Status](urun/project-taskr-current-status.md) | `.agents/PROJECT_TASKR_CURRENT_STATUS.md` |
| [Sitemap / UI Mapping](urun/sitemap.md) | `.gemini/project_docs/sitemap.md` |
| [User And Account Model](urun/user-and-account-model.md) | `.agents/USER_AND_ACCOUNT_MODEL.md` |

### Agent sistemi — bugünkü hub'ın atası

Project Taskr'ın veritabanı tabanlı agent oturum/kayıt sistemi. Bugünkü `SYSTEM.md` + `AGENT_PROTOCOL.md` sözleşmesi bu fikrin GitHub omurgasına taşınmış hâlidir (K-001); bu belgeler o dönüşümün başlangıç noktası.

| Belge | Kaynak |
|---|---|
| [Project Taskr Agent API Reference](agent-sistemi/api.md) | `.codex/skills/project-taskr-agent-api/references/api.md` |
| [Project Taskr Agent API Rules](agent-sistemi/project-taskr-agent-api-rules.md) | `.agents/PROJECT_TASKR_AGENT_API_RULES.md` |
| [Project Taskr — Agent Kayıt Disiplini, Task Detay Penceresi ve Bootstrap Yönerge Altyapısı (Plan)](agent-sistemi/project-taskr-agent-recording-and-bootstrap-plan.md) | `.agents/PROJECT_TASKR_AGENT_RECORDING_AND_BOOTSTRAP_PLAN.md` |
| [Project Taskr Agent Session System](agent-sistemi/project-taskr-agent-session-system.md) | `.agents/PROJECT_TASKR_AGENT_SESSION_SYSTEM.md` |
| [Project Taskr Agent API](agent-sistemi/skill.md) | `.codex/skills/project-taskr-agent-api/SKILL.md` |
| [Project Taskr Agent Workflow](agent-sistemi/workflow.md) | `.codex/skills/project-taskr-agent-api/references/workflow.md` |

### Altyapı ve süreç

Branch/dağıtım stratejisi, Coolify dağıtım durumu ve test rehberi, altyapı yapılacakları, göç analizi.

| Belge | Kaynak |
|---|---|
| [Branch And Deployment Strategy](altyapi/branch-and-deployment-strategy.md) | `.agents/BRANCH_AND_DEPLOYMENT_STRATEGY.md` |
| [Coolify Deployment Testing Guide](altyapi/coolify-testing-guide.md) | `COOLIFY_TESTING_GUIDE.md` |
| [Project Taskr Deployment Status](altyapi/deployment-status.md) | `DEPLOYMENT_STATUS.md` |
| [Supabase -> Coolify Migration Analysis](altyapi/migration-analysis.md) | `.gemini/project_docs/MIGRATION_ANALYSIS.md` |
| [server.md](altyapi/server.md) | `.agents/workflows/server.md` |
| [Todo Mobile App Infrastructure (Self-Hosted)](altyapi/todo-infrastructure.md) | `.gemini/project_docs/TODO_INFRASTRUCTURE.md` |

### Ajan çalışma kayıtları

O dönem agent'ların tuttuğu plan, ilerleme, hafıza ve kural dosyaları (`.gemini/`, `AGENTS.md`, `CLAUDE.md`).

| Belge | Kaynak |
|---|---|
| [📋 Taskr Agent Onboarding Guide](agent-kayitlari/agent-onboarding.md) | `.gemini/AGENT_ONBOARDING.md` |
| [Project Taskr Agent Rules](agent-kayitlari/agents.md) | `AGENTS.md` |
| [Project Taskr — Claude Code Rules](agent-kayitlari/claude.md) | `CLAUDE.md` |
| [Global Rules & Conventions](agent-kayitlari/global-rules.md) | `.gemini/global_rules.md` |
| [Taskr Project Shared Memory](agent-kayitlari/memory.md) | `.gemini/memory/MEMORY.md` |
| [Taskr — Collaborative Task Management Platform](agent-kayitlari/plan.md) | `.gemini/plan.md` |
| [Progress Log](agent-kayitlari/progress-log.md) | `.gemini/project_docs/PROGRESS_LOG.md` |
| [Taskr Project Progress & Status](agent-kayitlari/progress.md) | `.gemini/progress.md` |
| [Taskr Project](agent-kayitlari/readme.md) | `.gemini/README.md` |
| [Agents Hub - Security & Credential Management](agent-kayitlari/security.md) | `.gemini/security.md` |
| [Taskr & Agent Skills](agent-kayitlari/skills.md) | `.gemini/skills.md` |

### Taskr Basic ürün kuralları

**Farklı ürüne ait.** Etiket/öncelik semantiği `taskr` reposunun `main` branch'indeki Taskr Basic ürününü tanımlıyor. Taskr Basic ileride takip sistemine alınırsa bu belgeler `taskr_takip` hub'ına taşınmalı.

| Belge | Kaynak |
|---|---|
| [Portfolio Research Agent — Operating Contract (v1)](taskr-basic/portfolio-research.md) | `backend/scripts/prompts/portfolio-research.md` |
| [Shared Task Priority Rules](taskr-basic/shared-task-priority-rules.md) | `SHARED_TASK_PRIORITY_RULES.md` |
| [Tag Priority Resolution Rules](taskr-basic/tag-priority-rules.md) | `TAG_PRIORITY_RULES.md` |
| [100 Random Tag Priority Scenarios](taskr-basic/tag-priority-scenarios-100.md) | `TAG_PRIORITY_SCENARIOS_100.md` |
