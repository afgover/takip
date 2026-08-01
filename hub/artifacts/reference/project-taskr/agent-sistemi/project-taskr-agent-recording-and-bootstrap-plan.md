---
id: A-2026-08-01-010
session: none
type: plan
title: "Project Taskr — Agent Kayıt Disiplini, Task Detay Penceresi ve Bootstrap Yönerge Altyapısı (Plan)"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.agents/PROJECT_TASKR_AGENT_RECORDING_AND_BOOTSTRAP_PLAN.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Project Taskr — Agent Kayıt Disiplini, Task Detay Penceresi ve Bootstrap Yönerge Altyapısı (Plan)

**Tarih:** 2026-06-19
**Branch:** `project-taskr`
**Kapsam:** Agent API üzerinden bağlanan agent'ın (1) bağlanır bağlanmaz kanonik yönerge setini alıp kendi hafızasına yazması, (2) her prompt'u — anlık biten en küçük iş bile — bir task olarak kaydetmesi, (3) session başından sonuna kadar tüm iş/yazışma/md dosyası/kod değişikliği/commit'i zaman damgalı kayıt altına alması, (4) bunların tıklanabilir bir detay penceresinde görüntülenmesi.

> Bu doküman bir uygulama planıdır; kod henüz değiştirilmedi. Onay sonrası fazlar halinde uygulanır.

---

## 1. Amaç ve Tasarım İlkesi

İki katman var ve karıştırılmamalı:

- **Operasyon yönergesi (global):** "Bir Project Taskr agent'ı nasıl çalışır." Tek kaynak API'de, agent bağlanınca alır, kullanıcı onayıyla kendi hafızasına yazar. Proje verisi değildir.
- **Proje kaydı (proje bazlı):** Session, task, event, doküman, git ref — `groupId`'ye bağlı durable kayıt. Bunlar zaten var.

İlke: **API kanonik kaynaktır, agent kayıt eder, insan onaylar/kapatır.** Agent hiçbir zaman kullanıcı sahipli işi "tamamlandı" işaretlemez.

---

## 2. Mevcut Durum (kod üzerinde doğrulanmış)

Beklenenden olgun. Aşağıdakiler **zaten çalışıyor**:

### 2.1 Her prompt = task
`backend/src/agent-sessions/agent-sessions.service.ts:534` `createSessionPrompt`:
- `idempotencyKey` zorunlu (duplikat task üretmez).
- Tek transaction'da: `Task` (title = ilk satır, description = tam prompt) + `AgentSessionEvent(eventType=user_prompt, role=user)` + `ProjectTaskLink(sourceType=prompt, kind=prompt, workflowStatus=queued)`.
- Zorluk/öncelik otomatik hesaplanıyor (`calculateTaskDifficulty`).
- `task.created` WebSocket event'i yayılıyor.

→ "En küçük prompt bile task olsun" **altyapısı hazır.** Eksik olan, agent'ın bunu *her seferinde otomatik* yapmasını garanti eden disiplin (skill + CLI).

### 2.2 Agent yanıtları ve session log'u
- `appendEvent` / `addSessionEvent` (`agent-sessions.service.ts:449,471`) → `AgentSessionEvent` (eventType, role, content, summary, inputTokens, outputTokens, estimatedCostUsd, `createdAt`).
- `submitSessionPromptTask:632` → task'ı `submitted`/`waiting_test` yapar, `task_submitted` event'i ekler, zorluğu yeniden hesaplar.

### 2.3 MD dosyaları / kurallar / planlar
`attachSessionDocument:701` → `ProjectMemoryRecord` (recordType ∈ `plan, research, decision, skill, memory, progress, session_note` — bkz `SESSION_DOCUMENT_TYPES:31`) + `document_saved` event. `metadata.repoPath` ve `metadata.commitSha` taşınıyor. Repo'daki `.md` yazımı agent tarafında, kaydı API'de.

### 2.4 Commit / tarih-saat / değişen dosyalar
`createGitRef:926` → `AgentSessionGitRef`: `refType (commit/push/pull_request/deployment)`, `commitSha`, `branch`, `changedFiles (Json)`, `diffStats (Json)`, `pushedAt`, `createdAt`, `verifiedAt`. CLI (`backend/scripts/agent-session.js`) `git show --name-only` ile değişen dosyaları otomatik dolduruyor.

### 2.5 Detay görüntüleme
`src/screens/manager/AgentSessionDetailScreen.tsx` zaten tek session için **satır içi** olarak gösteriyor:
- Header (status, sahip, başlangıç→bitiş zamanı), istatistik (prompt/event/token/maliyet).
- "Promptlar & Yanıtlar": her prompt-task + altında agent yanıt event'leri.
- Dokümanlar & Hafıza (repoPath @ commitSha + içerik).
- Sonraya bırakılan işler, Git kayıtları, genel session log.

### 2.6 Bağlantı noktası
`backend/src/auth/auth.controller.ts:19` `POST /auth/agent-key` → `loginWithAgentKey` → `{ access_token, ... }`. Şu an yönerge servis etmiyor.

### 2.7 Yönerge içeriği
`.codex/skills/project-taskr-agent-api/SKILL.md` + `references/workflow.md` + `references/api.md` olgun. `AGENTS.md` skill'e yönlendiriyor.

---

## 3. Boşluk Analizi (gerçekten eksik olanlar)

| # | Boşluk | Etki | Nerede |
|---|---|---|---|
| G1 | **Bootstrap yönerge servisi yok.** Yönerge yalnız repo dosyası; API'den versiyonlu servis edilmiyor; agent kendi hafızasına onayla yazmıyor. | Her client/repo'da kopya bayatlar; Claude Code kökte `CLAUDE.md` olmadığı için kuralı hiç yüklemez. | `auth.controller.ts`, yeni endpoint |
| G2 | **Per-task detay penceresi yok.** Her şey session seviyesinde satır içi. Bir task'a tıklayıp *yalnız o task'ın* tam dökümünü (prompt + tüm yanıtlar + ilgili md + commit + tarih/saat + diff özeti) gösteren pencere yok. | Kullanıcı isteği: "tıklayınca bir pencerede detay". | Yeni `TaskActivityDetail` modal/screen |
| G3 | **Kayıt disiplini garanti değil.** Backend destekliyor ama agent'ın her prompt'u task açması, her turu transcript'e yazması, her md'yi kaydetmesi skill/CLI ile zorlanmıyor. Event taksonomisinde net `agent_message`/`file_change` sözleşmesi yok. | Eksik/dağınık kayıt. | skill + `agent-session.js` + event taxonomy |
| G4 | **`session:start` resume yapmıyor.** `agent-session.js:62` her çağrıda yeni session açıp state'i ezer → öksüz/duplikat session. | "Düzenli devam" kırılır. | `agent-session.js` |
| G5 | **Kök `CLAUDE.md` yok.** Codex `AGENTS.md`, Gemini `.gemini/` okuyor; Claude Code okumuyor. | Claude'da kural otomatik yüklenmez. | yeni `CLAUDE.md` |

---

## 4. Detaylı Tasarım

### 4.1 (G1+G5) Bootstrap Yönerge Altyapısı

**Backend — kanonik yönergeyi versiyonlu servis et.**

- Yeni sabit modül: `backend/src/agent-directives/agent-directives.constants.ts`
  - `AGENT_DIRECTIVE_VERSION = 'YYYY-MM-DD.N'` (ör. `2026-06-19.1`).
  - `AGENT_DIRECTIVE_BODY` — `SKILL.md`'nin özü (operasyon yönergesi). Tek kaynak burada tutulur; repo dosyaları buradan üretilir/senkronlanır (bkz. 4.6).
  - `directiveChecksum()` → `sha256(body)`.
- Yeni endpoint: `GET /agent/bootstrap` (`agents.controller.ts`, scope `task:read`):
  ```json
  {
    "version": "2026-06-19.1",
    "checksum": "sha256:…",
    "format": "markdown",
    "directives": "<AGENT_DIRECTIVE_BODY>",
    "memoryHints": {
      "claude": "CLAUDE.md veya ~/.claude memory",
      "codex": "AGENTS.md",
      "gemini": ".gemini/memory"
    }
  }
  ```
- `POST /auth/agent-key` yanıtına ek alanlar: `directiveVersion`, `directiveChecksum` (gövde değil, sadece sürüm — agent değişti mi anlasın, gerekirse `/agent/bootstrap` çeksin).

**Agent tarafı — al → onay iste → hafızaya yaz → sürümü sakla.**

- Yeni CLI: `backend/scripts/agent-session.js bootstrap` (`session:bootstrap`):
  1. `/auth/agent-key` → `directiveVersion` oku.
  2. Lokal `.taskr-agent-directive.json` (gitignore) ile karşılaştır.
  3. Sürüm aynıysa: sessiz çık (`up-to-date`).
  4. Farklı/ilk ise: `/agent/bootstrap` çek, **stdout'a öneri bas** ("Şu yönergeyi hafızana yazayım mı? [client hedefi]") ve `--apply` verilmeden **yazmaz** (kullanıcı onayı şartı).
  5. `--apply` ile: client hedef dosyasına yazar (varsayılan `CLAUDE.md`/`AGENTS.md` — `--target` ile seçilebilir), `.taskr-agent-directive.json`'a `{version, checksum, target, appliedAt}` yazar.
- Kök `CLAUDE.md` eklenir (ince, `AGENTS.md` ile aynı yönlendirme). Böylece üç client da kuralı otomatik yükler; bootstrap CLI bunu API sürümüyle taze tutar.

**Onay modeli:** CLI asla `--apply` olmadan hafızaya yazmaz; "user onayıyla" şartı buradan karşılanır.

### 4.2 (G3) Zorunlu Kayıt Modeli — "her prompt task, baştan sona kayıt"

**Event taksonomisini netleştir** (kod değil, sözleşme + doğrulama):

| eventType | role | Ne zaman | İçerik |
|---|---|---|---|
| `user_prompt` | user | Her prompt (createSessionPrompt otomatik üretir) | Tam prompt metni |
| `agent_plan` | agent | Önemli işten önce | Plan özeti |
| `agent_message` | agent | Her agent yanıt turu | Kullanıcıya görünen yanıt (chain-of-thought değil) |
| `research` | agent | Repo/dış araştırma kararı | Bulgu |
| `file_change` | agent | Kod değişikliği | Değişen dosya özeti + diff istatistiği (metadata) |
| `test_result` | agent | Her doğrulama komutu | Komut + sonuç |
| `task_submitted` | agent | Task teslimi | Final özet + risk + test durumu |

- `agent_message`'ı taksonomiye ekle (yeni event tipi adı; şema değişmez, `eventType` serbest string). `AgentSessionDetailScreen` ve yeni detay penceresi bunu "yazışma" olarak gösterir.
- **Disiplin kuralı (skill + workflow.md):**
  - Repo/API/proje state'ine dokunan **her prompt** → ilk mutasyondan önce `session:prompt` ile task aç (anlık biten iş dahil; istisna yalnız hiçbir state değiştirmeyen salt-okunur soru).
  - Her agent yanıt turu → `session:event eventType=agent_message`.
  - Üretilen her `.md` → `session:doc`/`session:memory` (recordType uygun: `plan/skill/decision/...`).
  - Her commit/push → `session:git` (commitSha + changedFiles + diffStats + pushedAt).
  - Session sonu → `session:finish` + read-back doğrulama.

**CLI eklemeleri (`agent-session.js`):**
- `session:message` kısayolu (`event eventType=agent_message` sarmalayıcı).
- `session:turn` (opsiyonel makro): bir turda hem `agent_message` hem ilgili `file_change`'i tek komutla yazar (pratiklik için).
- `file_change` event'i için `TASKR_CHANGED_FILES`/`TASKR_DIFF_STATS` zaten var (api.md:38) — `git diff --stat` çıktısını otomatik dolduran bir yardımcı eklenir.

### 4.3 (G4) `session:start` → resume-or-create

`agent-session.js` `start`:
1. `.taskr-agent-session.json` oku.
2. State'te `sessionId` varsa `GET /agent/sessions/:id` ile durumu kontrol et; `active` ise **onu kullan** (resume), yeni açma.
3. Yoksa/aktif değilse yeni session aç ve state'i yaz.
4. `--new` bayrağı zorla yeni session açar.

Alternatif/ek: `session:ensure` (idempotent başlat). Skill "önce `session:ensure`" der. Böylece görev ortasında tekrar çağrılınca duplikat/öksüz session olmaz → "düzenli devam".

### 4.4 (G2) Task Detay Penceresi — `TaskActivityDetailScreen`

**Amaç:** Session detayında veya global task listesinde bir task'a tıklayınca, *yalnız o task'a ait* her şeyi tek pencerede toplayan modal/screen.

**Veri kaynağı:** Çoğu zaten mevcut, tek task'a göre filtrelenecek:
- Prompt: `ProjectTaskLink(kind=prompt)` + bağlı `Task` (title/description/status/priority/difficulty).
- Yazışma/işler: o task'a ait `AgentSessionEvent`'ler — `metadata.taskId === taskId` ile filtre (kod halihazırda `eventsByTask` üretiyor, `AgentSessionDetailScreen:174`). Tipe göre gruplanır: planlar, agent_message'lar (yazışma), file_change'ler, test_result'lar, task_submitted.
- MD dosyaları: o task'la ilişkili `ProjectMemoryRecord`'lar (session + `metadata.taskId`/`sourceCommitSha` eşleşmesi).
- Kod değişikliği + commit + tarih/saat: ilgili `AgentSessionGitRef`'ler — `commitSha`, `branch`, `changedFiles`, `diffStats`, `pushedAt`/`createdAt` (yerel saat formatlı).

**UI bölümleri (tek scroll pencere / modal):**
1. **Başlık & durum:** task başlığı, workflow durumu (pill), sahip, oluşturma zamanı, zorluk/öncelik.
2. **Prompt:** tam metin (seçilebilir).
3. **Zaman çizelgesi (yazışma):** kronolojik event akışı — her kart: rol, eventType etiketi, **tarih-saat (yerel)**, özet + içerik. agent_message'lar belirgin.
4. **Üretilen dokümanlar:** md başlığı + recordType + repoPath@commit + içerik (genişletilebilir).
5. **Kod & commit:** değişen dosya listesi + diff istatistiği + commit SHA (kısa) + tam SHA kopyalanabilir + commit zamanı + PR/deploy linki (varsa).
6. **Aksiyonlar (sahip ise):** Kabul & kapat / Test-inceleme iste / Değişiklik iste (mevcut `AgentSessionDetailScreen` mantığı yeniden kullanılır).

**Erişim/navigasyon:**
- `AgentSessionDetailScreen`'deki prompt kartı `TouchableOpacity` olur → `navigation.navigate('TaskActivityDetail', { sessionId, taskId })`.
- Global Tasks feed'indeki proje task'ı da aynı detaya gider (proje task'ları için).
- Yeni route `ManagerStack`/`FeedStack`'e eklenir (`src/navigation/`), tip `src/types/navigation.ts`'e eklenir.

**Backend desteği:** Çoğu veri session detay endpoint'inden geliyor. İsteğe bağlı kolaylaştırıcı: `GET /projects/:groupId/tasks/:taskId/activity` — tek task'ın event+doc+gitRef birleşik görünümü (performans ve mobil için tercih edilir; yoksa frontend mevcut session verisini filtreler). **Karar:** Önce frontend-filtre ile MVP, gerekirse agregasyon endpoint'i (bkz. Açık Kararlar).

### 4.5 Veri modeli değişiklikleri

Şema büyük ölçüde yeterli. Minimal:
- **Zorunlu yeni model yok.** `agent_message` yeni bir `eventType` string'i, migration gerekmez.
- (Opsiyonel) `AgentSessionEvent.metadata.taskId` zaten kullanılıyor; per-task sorgu performansı için ileride `taskId` kolonu + index düşünülebilir — MVP'de gerekmez.
- (Opsiyonel) Agregasyon endpoint'i eklenirse şema değişmez.

### 4.7 (YENİ) Agent task'ı ağaç görünümüne kendi yerleştirsin + ilgili tag/badge eklesin

**Model (doğrulandı):**
- Ağaç = `Task.parentTaskId` self-relation (`TaskSubtasks`) + `subtaskCount`/`subtaskCompleted`. Proje task ağacı bunun üzerinden kuruluyor (`work-sessions.service.ts getTree`, `task.subtasks`).
- Badge/tag = proje-scope `Tag` (`Tag.groupId`), hiyerarşik (LTREE `path`), `color`+`icon` taşır → görsel badge. Task↔Tag çok-çok (`Task.tags`).
- Parent yerleştirme deseni zaten kısmen var: `reviewProjectSessionTask` (`agent-sessions.service.ts:1151`) `sourceMetadata.parentTaskId` ile alt task bağlıyor. `createSessionPrompt` ise şu an **düz** task açıyor (parent/tag yok) — burası genişletilecek.

**Akış: agent önce okur, sonra yerleştirir.**
1. **Okuma (yeni/mevcut uçlar):** Agent task açmadan önce mevcut ağacı ve uygun tag'leri görür:
   - `GET /projects/:groupId/task-tree` — *yeni*: proje task'larını `parentTaskId`'ye göre iç içe (id, title, status, tag'ler, derinlik) döndürür. Agent nereye yerleştireceğini buradan seçer.
   - `GET /projects/:groupId/tags` — *yeni veya `GET /tags?groupId=` genişletmesi*: proje-scope tag listesi (id, name, path, color, icon, priorityMode/min/max). Agent ilgili tag'leri buradan seçer.
   - Bu iki blok ayrıca session başlangıç context'ine (`ProjectContextService`) eklenir; agent ilk prompttan itibaren ağaç+tag farkındalığıyla başlar.
2. **Yerleştirme (createSessionPrompt genişletmesi):** Payload'a opsiyonel alanlar eklenir:
   - `parentTaskId` — agent'ın seçtiği üst task (ağaçtaki yer). Doğrulama: aynı `groupId`'ye bağlı bir task olmalı (`ProjectTaskLink` üzerinden), döngü/kendine-parent engellenir.
   - `tagIds` (ve/veya `tagNames`) — eklenecek tag'ler. Doğrulama: yalnız aynı projeye (`groupId`) ait mevcut tag'ler bağlanır.
   - Transaction içinde: `task.create({ parentTaskId, tags: { connect } })`; parent varsa `parent.subtaskCount` artırılır (mevcut sayaç mantığıyla tutarlı, transaction'lı).
3. **Karar mantığı agent'ta:** Doğru yer ve ilgili tag seçimi LLM yargısıyla agent tarafında yapılır; backend yalnız **doğrular** (heuristik otomatik yerleştirme yapmaz). Skill bu seçimi zorunlu adım yapar: "Prompt-task açarken ağacı oku, en uygun parent'ı ve ilgili mevcut tag'leri payload'a koy."
4. **Tag oluşturma politikası:** Varsayılan olarak agent **yeni tag üretmez**, yalnız mevcut proje tag'lerinden ilgili olanları ekler (tag enflasyonunu önler). Gerçekten uygun tag yoksa: bir `suggestedTags` alanıyla **öneri** bırakır, tag oluşturmayı insan onayına bırakır (bkz. Açık Kararlar #6).

**CLI:** `agent-session.js prompt` → `TASKR_PARENT_TASK_ID`, `TASKR_TAG_IDS`/`TASKR_TAG_NAMES`, `TASKR_SUGGESTED_TAGS` env'leri; `session:tree` ve `session:tags` (okuma kısayolları).

**UI:** Task detay penceresi (4.4) ve `AgentSessionDetailScreen` task'ın parent zincirini (breadcrumb) ve tag badge'lerini (renk+ikon) gösterir. Global Tasks ağaç görünümü agent-yerleştirilen task'ı doğru dalda render eder (mevcut `parentTaskId` ağacı yeterli).

### 4.6 Tek kaynak senkronu (yönerge bayatlamasın)

- `AGENT_DIRECTIVE_BODY` kanonik kaynak. `SKILL.md`, `AGENTS.md`, `CLAUDE.md` bundan türetilir.
- Küçük script: `backend/scripts/sync-agent-directive.js` → sabitten repo dosyalarını üretir + sürüm/checksum tutarlılığını doğrular (CI/pre-commit'e bağlanabilir). Böylece "API'deki yönerge" ile "repo'daki dosyalar" ayrışmaz.

---

## 5. Dosya Bazlı Değişiklik Listesi

**Backend**
- `backend/src/agent-directives/agent-directives.constants.ts` — *yeni*: sürüm + gövde + checksum.
- `backend/src/agents/agents.controller.ts` — *değişiklik*: `GET /agent/bootstrap`.
- `backend/src/agents/agents.service.ts` — *değişiklik*: bootstrap getter.
- `backend/src/auth/auth.service.ts` — *değişiklik*: agent-key yanıtına `directiveVersion`/`directiveChecksum`.
- `backend/src/agent-sessions/agent-sessions.service.ts` — *değişiklik*: `agent_message` taksonomisi; `createSessionPrompt` genişletmesi (`parentTaskId` + `tagIds`/`tagNames` + `subtaskCount` bakımı + doğrulama); (ops.) `GET /projects/:groupId/tasks/:taskId/activity` agregasyonu.
- `backend/src/project-ops/project-ops.controller.ts` (veya ilgili proje controller) — *değişiklik*: `GET /projects/:groupId/task-tree`, `GET /projects/:groupId/tags`.
- `backend/src/project-context/project-context.service.ts` — *değişiklik*: context'e proje task ağacı + uygun tag listesi ekle (agent ilk prompttan ağaç/tag farkındalıklı başlasın).
- `backend/scripts/agent-session.js` — *değişiklik*: `start` resume-or-create + `--new`; yeni `bootstrap`, `message`, (ops.) `turn`, `ensure`.
- `backend/scripts/sync-agent-directive.js` — *yeni*.
- `backend/package.json` — *değişiklik*: `session:bootstrap`, `session:message`, `session:ensure` script'leri.

**Frontend**
- `src/screens/manager/TaskActivityDetailScreen.tsx` — *yeni*: per-task detay penceresi.
- `src/screens/manager/AgentSessionDetailScreen.tsx` — *değişiklik*: prompt kartı tıklanabilir → detaya git; `agent_message` görünümü; parent breadcrumb + tag badge'leri.
- `src/services/projectOpsService.ts` (veya ilgili) — *değişiklik*: `getProjectTaskTree` + `getProjectTags` fetch (agent ve UI ağaç/tag verisi).
- `src/screens/feed/FeedScreen.tsx` / `TaskDetailScreen.tsx` — *değişiklik*: proje task'ından detaya geçiş.
- `src/navigation/ManagerStack.tsx`, `FeedStack.tsx` — *değişiklik*: yeni route.
- `src/types/navigation.ts` — *değişiklik*: route param tipi (`{ sessionId; taskId }`).
- `src/services/agentRunService.ts` (veya ilgili servis) — *değişiklik*: per-task activity fetch (agregasyon endpoint'i eklenirse).

**Kural/skill/dok**
- `CLAUDE.md` (kök) — *yeni*.
- `.codex/skills/project-taskr-agent-api/SKILL.md` + `references/workflow.md` + `references/api.md` — *değişiklik*: zorunlu kayıt sözleşmesi, `agent_message`/`file_change`, `session:ensure`/`bootstrap`.
- `.gitignore` — *değişiklik*: `.taskr-agent-directive.json`.

---

## 6. Fazlama (önerilen sıra)

- **Faz 0 — Disiplin & resume (düşük risk, yüksek getiri): ✅ TAMAMLANDI (2026-06-19).** `session:start` resume-or-create + `--new` + `session:ensure`; `session:message`/`agent_message`; skill+workflow.md'ye "her prompt = task + her tur agent_message" zorunlu sözleşmesi. Doğrulama: `node --check`, package.json geçerli, `verify:product-boundary` geçti.
- **Faz 1 — Bootstrap altyapısı: ✅ TAMAMLANDI (2026-06-19).** `agent-directives.constants.ts` (sürüm+gövde+checksum) + `GET /agent/bootstrap` + agent-key yanıtına `directiveVersion`/`directiveChecksum`; `session:bootstrap` CLI (`--apply` onayı, yönetilen blok, `.taskr-agent-directive.json`); kök `CLAUDE.md`; `sync-agent-directive.js` (`directive:sync` + `--check`). Doğrulama: backend build temiz, checksum runtime↔sync tutarlı, boundary geçti.
- **Faz 2 — Task detay penceresi: ✅ TAMAMLANDI (2026-06-19).** `TaskActivityDetailScreen` (prompt + yazışma transcript + md dokümanlar + kod/commit + tarih-saat + parent breadcrumb + tag badge + alt task'lar + sahip aksiyonları); `ManagerStack` route + `TaskActivityDetail` tip; `AgentSessionDetailScreen` prompt kartı tıklanabilir ("Detayı aç →"). Doğrulama: `tsc --noEmit` temiz.
- **Faz 2.5 — Ağaç yerleşimi + tag/badge: ✅ BACKEND+CLI TAMAMLANDI (2026-06-19).** `GET /projects/:groupId/task-tree` + `/tags` okuma uçları; `createSessionPrompt` `parentTaskId`+`tagIds`/`tagNames`+`suggestedTags` genişletmesi + doğrulama + `subtaskCount` artırımı; CLI `session:tree`/`session:tags` + prompt env'leri (`TASKR_PARENT_TASK_ID`/`TASKR_TAG_IDS`/`TASKR_TAG_NAMES`/`TASKR_SUGGESTED_TAGS`); skill+api.md güncellendi. Doğrulama: backend build temiz, boundary geçti. *Kalan: context'e ağaç/tag ekleme (ProjectContextService) ve UI breadcrumb/badge — Faz 2 ile birlikte.*
- **Faz 3 — Cila: ✅ TEMEL KISIM TAMAMLANDI (2026-06-19).** `ProjectContextService` artık session başlangıç context'ine `projectTaskTree` (parent farkındalığı) + `availableTags` ekliyor → agent ilk prompttan ağaç/tag farkındalıklı başlar. Doğrulama: backend build temiz, boundary geçti.
  - *Opsiyonel/ertelendi:* `/projects/:groupId/tasks/:taskId/activity` agregasyon endpoint'i (şu an frontend-filtre yeterli), commit SHA kopyalama düğmesi, `directive:sync --check`'in CI/pre-commit'e bağlanması.

Her faz sonunda: `npx tsc --noEmit`, `npm --prefix backend run build`, `npm run verify:product-boundary`. ✅ Hepsi geçti. Migration gerekmedi (şema değişmedi).

---

## 7. Kararlar (kullanıcı onayıyla sabitlendi — 2026-06-19)

1. **Hafıza hedefi varsayılanı:** ✅ Client'a göre `CLAUDE.md`/`AGENTS.md` (repo kökü); kullanıcı `--target` ile ezebilir.
2. **Onay UX'i:** ✅ `--apply` bayrağı (headless-güvenli); bayraksız sadece öneri basar, yazmaz.
3. **Detay verisi:** ✅ Önce frontend-filtre (MVP); performans sorununda Faz 3 agregasyon endpoint'i.
4. **`agent_message` zorunluluğu:** ✅ Kullanıcıya görünen her yanıt turu kaydedilir; salt-içsel adımlar hariç.
5. **Yönerge tek-kaynağı:** ✅ Backend sabiti master; `SKILL.md`/`AGENTS.md`/`CLAUDE.md` sync script ile türetilir.
6. **Tag oluşturma politikası (yeni gereksinim):** ✅ Agent yalnız **mevcut** proje tag'lerinden ilgili olanları ekler; yeni tag üretmez, uygun tag yoksa `suggestedTags` ile öneri bırakır (oluşturma insan onayında). Ağaç yerleşimi agent yargısıyla, backend doğrular.

---

## 8. Riskler

- **Kayıt yükü/maliyet:** Her tur event yazmak token/istek artırır. Mitigasyon: `agent_message` yalnız kullanıcıya görünen yanıt; içsel adımlar `metadata` ile özetlenir.
- **Client farklılığı:** Hafıza yazımı client'a bağlı (CLAUDE.md vs AGENTS.md vs .gemini). Endpoint tek, yazıcı helper client başına ince uyarlama ister.
- **Yönerge ikiye düşme:** Backend sabiti ile repo dosyası ayrışabilir → `sync-agent-directive.js` + CI doğrulaması şart.
- **Detay penceresi N+1:** Çok event'li task'ta frontend-filtre yavaşlayabilir → Faz 3 agregasyon endpoint'i.
