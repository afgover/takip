# SYSTEM.md — Taskr Hub Format Contract

*English · canonical copy: [`SYSTEM.md`](SYSTEM.md) (Turkish)*

This document defines **where every file in a hub repository lives, how it is
named, and what schema it follows**. Neither the agent nor the user application
steps outside it. Contract changes are recorded in `EVOLUTION.md` and the
version number at the top of this file is incremented.

**Contract version:** 1.28
**Master copy:** `afgover/takip` → `hub/SYSTEM.md` (Turkish) ·
`hub/SYSTEM.en.md` (English)
(see §10 — every hub updates its own copy from there)
**Time format:** ISO 8601, UTC, everywhere (`2026-07-30T14:05:00Z`)
**Hub language:** en
**Language rule:** field names (frontmatter keys) are always English; everything
else is in the **hub language**
**File names:** lower case, no non-ASCII letters, hyphens instead of spaces
(`task-name`)

> **Which copy wins (v1.21).** The Turkish `SYSTEM.md` is the **canonical**
> copy; this file is derived from it. If the two ever disagree, the Turkish one
> is correct and this one has a translation bug. That is not a claim that
> Turkish is better — it is that a system with two authorities drifts, and
> nobody notices while it does (L-022 is exactly that failure, lived).
>
> Report a disagreement rather than acting on it.

> **A hub has one language (v1.19).** The language is chosen when the hub is set
> up and written in the `**Hub language:**` field. Three things follow it:
>
> 1. **The contract and the protocol** — the agent takes its reference from
>    here, so `SYSTEM.md` and `AGENT_PROTOCOL.md` are in the hub language.
> 2. **The app's interface** — drawn in the active hub's language.
> 3. **Records created from then on** — including body headings (table below).
>
> The language can be changed later, but doing so **is not retroactive**: older
> records stay in the language they were written in. That is an accepted state,
> not a bug — choosing a language belongs to setup time.
>
> **Body headings by language:**
>
> | Field | tr | en |
> |---|---|---|
> | Request | `## İstek` | `## Request` |
> | Notes | `## Notlar` | `## Notes` |
> | Where | `## Nerede` | `## Where` |
> | Quote | `## Alıntı` | `## Quote` |
>
> In-body field names follow the same rule: `Seçim`/`Choice`,
> `Açıklama`/`Explanation`, `Dosya`/`File`, `Bölüm`/`Section`,
> `Tür`/`Type`, `Durum`/`Status`.
>
> **The parser accepts all of them.** It is not restricted to the language the
> hub declares: there are records written before the language field existed,
> hand-edited files, and hubs whose language was changed. Accepting a set costs
> nothing; accepting narrowly costs an unreadable record.
>
> If `**Hub language:**` is absent, **`tr`** is assumed — that is the actual
> state of every hub that predates the field.

> **The hub root (v1.3, K-020):** Every path in this contract is relative to the
> hub root, and the hub root is **always** the **`hub/`** folder inside the
> repository — no exceptions.
>
> - Each project gets its own tracking repository: **`<project>_takip`**
>   (e.g. `financer_takip`), with hub content installed under its `hub/` folder.
> - The `takip` project hosts its own hub in its own repository (K-012); the
>   structure is the same, `takip/hub/`.
>
> ~~v1.2: for other projects the hub is the root of the `<project>_takip`
> repository.~~ Invalid: the app holds the hub root fixed at `hub/` and it is
> not configurable per connection; a root-level repository would be rejected
> during onboarding. The contract was fitted to the app so that one rule holds
> for every repository (K-020).

---

## 1. Root files

| File | Purpose | Who writes it |
|---|---|---|
| `SYSTEM.md` | This contract | agent (with the user's approval) |
| `AGENT_PROTOCOL.md` | The agent's recording procedure | agent (with the user's approval) |
| `BACKLOG.md` | The work list — single source of truth | agent |
| `EVOLUTION.md` | The project's evolution, stage by stage | agent |
| `SECURITY.md` | Security log — scans, measures, holes (§12) | agent |
| `PLAN.md` | Task tree — steps and state of multi-step jobs (§14) | agent |

## 2. `sessions/` — session records

**One folder** per working session:

```
sessions/<YYYY-MM-DD>-<slug>/
  session.md          # the full record of the session
```

`session.md` schema:

```markdown
---
id: S-2026-07-30-infrastructure-design
date: 2026-07-30
status: open            # open | closed
reconstructed: false    # (v1.6) optional; true = written after the fact,
                        # following a context compaction
author: afgover         # (v1.15) who ran the session
topics: [architecture, github-api]
artifacts:              # paths of files produced in this session
  - artifacts/S-2026-07-30-infrastructure-design/report.md
tasks_touched: [T-001, T-002]   # task IDs handled in this session
---

# Session: <title>

## Summary
(Written by the agent as the session closes: what was discussed, what was
decided, what was produced — 5-10 lines.)

## Record

### [14:05] User
> (the user's message — not shortened, meaning intact)

### [14:07] Agent
(the substance of the agent's reply: decisions made, findings, work done. Long
code or report output goes to `artifacts/`, not here, and is linked from here.)
```

Rules:
- The file is created **the moment the session opens** (`status: open`).
- Every user message and every agent reply is appended **as it is given**, not
  saved up for the end of the session.
- On closing, `status: closed` is set and `## Summary` is filled in.
- A session file is not modified after it closes (if a correction is needed, a
  new session links to it).
- **(v1.6) Reconstructed session.** If a session could not be recorded live
  because of context compaction, it may be written after the fact — but then
  `reconstructed: true` goes into the frontmatter. This is **not** an exception
  to "no work without a record"; it marks honestly how the record was produced:
  a record written after the fact cannot claim the timestamp accuracy of a live
  one. Timestamps may be omitted or approximate.
  *(The rule was born in `financer_takip` and taken into the master from
  there — K-025.)*
- **(v1.23) Checkpoints (the 30-minute rhythm).** The records accumulating in
  an open session are updated and pushed at most **30 minutes** apart — the
  session stays `open`, and `## Summary` is still written at close. This puts a
  **time bound** on "a record not pushed is a record never made": if the chat
  dies unexpectedly (context compaction, a closed window), at most 30 minutes
  are lost. The `reconstructed: true` exception (v1.6) was born from exactly
  that gap; checkpoints narrow it and reduce the need for after-the-fact
  records.
  On the same rhythm `tasks/inbox/` is checked too: the user may file tasks
  from the phone while the session runs, and should not have to say so in
  chat — that is what the app exists for. Extra trigger: when the user writes
  their first message **after a gap longer than 30 minutes**, or when the
  session did not start from zero (continuing after compaction), the opening
  inbox check is repeated.
- **(v1.20) Only one session may be open at a time**, and it must be the most
  recent one. If an older session is still `open` when you open a new one, close
  it first: derive its summary from its own record and **say in the `## Summary`
  that it was derived** (add no new information).
  The rule was added after a session stayed open for nine days (L-042). A
  session with no summary does not exist for whoever is looking — the next agent
  scans the sessions, reads the summaries, and concludes "there is nothing
  here". That session carried the project's founding decisions.

- **(v1.27) The audit is the scan's sibling.** §12's `scan` record looks at
  the **code**; the check that looks at the hub itself is separate and is
  defined in `AGENT_PROTOCOL.en.md` item 4b: repeated IDs, an `id: pending`
  that escaped `inbox`, a session closed with an empty summary, a task closed
  with an empty `result`, a session left open, a record dated ahead of its own
  commit. None of them reads prose — the party writing the record is the party
  being audited. The **clock** is also verified using the network request item
  3 already makes (v1.27, L-052): the whole hub hangs on dates, and a wrong
  clock cannot be seen from inside the hub.

- **(v1.28) Opening is one command; the definition stays in the items.**
  The opening measurements run in a single call via `tool/acilis.sh`, and
  `BACKLOG.md` is read selectively at opening (open items by pattern, the
  body before acting). The reason was measured (A-2026-08-30-001): the cost
  of opening comes from the number of turns. The script implements the
  items, it does not define them; a check that could not run is done by
  hand and never written up as run.

## 3. `artifacts/` — produced files

Every report, plan, analysis or info file produced during a session is stored
here:

```
artifacts/<session-id>/<file-name>.md
```

Every artifact file starts with frontmatter:

```markdown
---
id: A-2026-07-30-001
session: S-2026-07-30-infrastructure-design
type: report            # report | plan | info | analysis | design
title: "GitHub permission model research"
created: 2026-07-30T14:20:00Z
---
```

Permanent reference documents that do not belong to a session (architectural
decisions, for instance) go under `artifacts/reference/`, with `session: none`
in the frontmatter.

## 4. `tasks/` — tasks

**Status is the folder.** A task file moves between folders over its lifetime:

```
tasks/inbox/     # new: added by the user (app) or the agent, not yet picked up
tasks/active/    # the agent picked it up and is working on it
tasks/waiting/   # the agent is waiting on the user — the ball is theirs (v1.4)
tasks/done/      # finished (archive — never deleted)
```

> **Why `waiting/` exists (v1.4, K-022):** Up to contract 1.3 the system only
> modelled the **user → agent** direction; both `inbox` and `active` meant "the
> agent will handle it". Work the agent expected from the user (generate a
> token, connect a device, make a decision, approve something) lived only in
> `BACKLOG.md` behind a `(user)` label and appeared nowhere in the app — the
> user only found out if it came up in chat. `waiting/` gives that direction a
> folder too, preserving the "status is the folder" principle.
>
> A distinction of scale: `waiting/` is for **concrete, short-term** work
> ("generate a token"). Roadmap-scale user work (`(user)` entries, e.g. "a week
> of real use") stays in `BACKLOG.md`.

File name: `<YYYY-MM-DD>-<slug>.md` (e.g. `2026-07-30-shopping-list.md`).

Task schema:

```markdown
---
id: T-001                    # unique, increasing; assigned by the agent. The app
                             # writes id: pending and the agent assigns the real
                             # ID when it first handles the task.
title: "Prepare the shopping list"
created_by: user             # user | agent
created: 2026-07-30T14:05:00Z
updated: 2026-07-30T16:00:00Z
priority: normal             # low | normal | high | urgent
category: gorev              # defaults: gorev, arastirma, gelistirme, hata,
                             # fikir, yorum, duzeltme, tartisma (last three
                             # v1.5) — a free value is valid too (user-defined).
                             # The app derives the picker list from the defaults
                             # plus categories seen in existing tasks. (v1.1)
tags: []
session: none                # ID of the session that handled it (agent fills in)
result: none                 # when finished: a one-line summary or artifact link
author: afgover              # (v1.15) the GitHub account that created the record
for: mehmet                  # (v1.15) waiting/ only: who it is waited on
assignee: afgover            # (v1.15) who moved it to active/

# --- Context fields (v1.5) — present only in records produced by selecting
# text in a document; never written for ordinary tasks. The three are meaningful
# together.
source: hub/sessions/2026-08-01-x/session.md   # the document the record is tied to
quote: "the full marked text"                  # a verbatim quote from it
mark: highlight              # highlight (yellow) | underline (red) |
                             # comment (green, v1.8) | bookmark (blue, v1.12)
                             # — how it is drawn in the document
---

# <title>

## Request
(The user's or agent's definition of the work.)

## Notes
(The agent's working notes — status updates are appended as dated lines.)
```

Rules:
- **The app writes only to `tasks/inbox/`**; it touches no other folder. This
  did not change in v1.4 either: when the user finishes a waiting item, the app
  does not move that file — it writes a **notification task into inbox** (see
  below).
- **(v1.7) The app may delete a record it wrote that is still in `inbox/`.**
  Only there: if the agent has moved the record to `active/`, the app cannot
  touch it — that work has been picked up, and destroying it silently would
  throw away the agent's work. This does not soften R-001, it keeps its boundary
  identical: the only folder the app touches is still `inbox/`. Rationale: the
  user must be able to undo a mark they made by accident; opening a task for the
  agent to do that would turn a one-tap mistake into work for two parties
  (K-026).
- Only the agent moves files between folders
  (`inbox → active → waiting → active → done`; the order is not limited to
  these, but every transition is the agent's).
- A move is delete-old-path plus write-new-path (two Contents API calls); commit
  message: `task(T-001): active → done`.
- Files in `done/` are never deleted; once a year they may be gathered under
  `done/archive-<year>/`.

### Identity (v1.15)

In a single-user hub the answer to "who" was obvious and had no place in the
schema. When several people use the same hub, that gap becomes the main source
of confusion: `created_by` is a **role** (`user`/`agent`), not an identity.

| Field | Where | Meaning |
|---|---|---|
| `author` | task, note, session | The GitHub account that created the record |
| `for` | `waiting/` only | **Whom** the work is waited on |
| `assignee` | `active/` | Who took the work on |

Rules:

- **All three are optional and their absence is not an error.** They are missing
  from every record written during the single-user period and are not
  backfilled. Absence means "unknown".
- A `waiting/` task with no `for` waits on **everyone**. Otherwise old tasks
  would fall into a queue nobody watches.
- `assignee` is written **at the same time** as the `inbox/` → `active/` move.
  The move is already atomic, so no separate lock is needed: two people moving
  the same file is a conflict in git.
- The app reads `author` from the token's owner (`/user` → `login`) and uses the
  identity of **whichever connection it is writing to**. If it cannot be read,
  the field is simply omitted — a working connection is never rejected over an
  identity.
- If two people share one token, the identities collapse into one person. That
  is a separate reason for everyone to generate their own token (R-005).

### IDs and concurrency (v1.15)

All IDs (`T-`, `B-`, `L-`, `SK-`, `R-`, `SEC-`, `K-`, `A-`) are single counters.
If two agents work at the same time they both pick the same number, and because
the files differ **git does not treat it as a conflict**: nothing errors, and
two records carry the same ID.

The contract does not make the collision impossible — changing the ID format
(user prefixes, random IDs) would demote hundreds of existing references.
Instead it makes the collision **visible**:

- The agent runs `git pull --rebase` right before assigning an ID, and pushes
  right after (`AGENT_PROTOCOL.md`).
- A test that reads the hub catches duplicate ID definitions; the fix is to
  renumber one of them.

### Using `waiting/`

**The agent moves a task to `waiting/` only while it awaits something concrete
from the user**, and writes what it is waiting for in one line under
`## Notes`. If what is expected is vague, the task stays in `active/` — "maybe
the user will do something" is not `waiting/`.

#### Waiting with options (v1.12)

Not every waiting item is "do it and tell me"; often what the agent is waiting
for is a **decision** ("which one should we do?"). Up to contract 1.11 the
user's only answer was a "Done" button, with no way to respond to a question —
the user had to go back to chat, or the answer was never recorded at all.

The agent offers options by adding two fields to the `waiting/` task:

```yaml
options: ["I will generate a fine-grained token", "Stay on classic", "Later"]
multi: false                 # true → more than one option can be marked
```

Rules:

- `options` is written **by the agent**; the app does not modify the field.
- With no `options`, behaviour is as in 1.11: a single "Done" button. Old tasks
  keep working unchanged.
- With `options`, "Done" is **not shown**: the agent asked a question, and the
  answer to it is a choice, not "done".
- The user can **always** write an optional explanation next to the choice
  ("No, because…"). The option list makes the answer machine-readable; the free
  text is there to say what the list does not cover. Neither replaces the other.
- Once answered, the question **closes**: the app does not send a second answer
  for the same task. If the conversation needs to continue, the agent opens a
  new `waiting/` task — one task equals one question.

When the user finishes the work (or answers the question), the app writes a
notification task into `tasks/inbox/` with this schema:

```markdown
---
id: pending
title: "<original title> — done"
created_by: user
category: gorev
tags: [waiting-done]
...
---

## Request
The work awaited in `tasks/waiting/<file>.md` (T-00X) is done.

- **Repo:** `afgover/<project>_takip`
```

When an option question is answered, the same schema goes with
`tags: [waiting-answer]` and "— answered" in the title; the body carries the
choice and, if given, the explanation:

```markdown
## Request
The question in `tasks/waiting/<file>.md` (T-00X) has been answered.

- **Repo:** `afgover/<project>_takip`
- **Choice:** I will generate a fine-grained token
- **Explanation:** I will do it this week.
```

> **A notification names its own hub (v1.24).** The `Repo` line is the hub the
> notification belongs to. The path is hub-relative and task IDs are per-hub —
> neither identifies the hub; a notification that lands in the wrong hub can
> only be diagnosed by this line. This actually happened: the app's queue
> dropped three notifications into `financer_takip`, and because the IDs
> (`T-008`, `T-009`) collided with tasks there, the wrong tasks were nearly
> closed (goverco L-009).
> **Agent rule:** before closing a notification, verify the `Repo` line names
> your hub. If it does not, **do not touch it** — tell the user. If the line
> is missing (a pre-v1.24 notification), search for the file name in your own
> `waiting/` folder; do not trust the ID.

When the agent sees this notification it moves the original task from
`waiting/` to `done/` (or back to `active/` if the work continues) and closes
the notification task into `done/`. The reason the notification is a separate
task is R-001: the app's write area is a single folder, and that guarantee is a
compile-time constant.

### Records produced by selecting text in a document (v1.5, K-023)

In the app the user can select text in any document (session, report, knowledge
base, task, roadmap) and **create a record**. What is created is still an
ordinary task — written to `tasks/inbox/` per R-001 — but it carries three extra
fields:

| Field | Meaning |
|---|---|
| `source` | The hub path of the document the record is tied to |
| `quote` | A **verbatim** quote from it; the mark is located by this |
| `mark` | `highlight` (yellow), `underline` (red), `comment` (green) or `bookmark` (blue, v1.12) |

`category` says **what the record is**: `gorev` (work to do), `yorum` (comment),
`duzeltme` (something believed wrong), `tartisma` (an open question), or a free
value.

**The mark derives from the record; it is not stored separately.** When the app
draws a document it finds the records whose `source` is that document and marks
the `quote` text in it. So the mark and the record can never drift apart: delete
the record and the mark goes, view the record on another device and the mark is
there.

Rules:
- If `quote` cannot be found in the document, no mark is drawn; **the record is
  still valid** and appears in lists. The document may have changed — that is
  expected.
- A document may carry several records; each marks its own `quote`.
- The agent treats these as ordinary tasks: assigns an ID, moves them to
  `active`, writes a `result`. For `duzeltme` records, if the correction is
  made, the `source` document itself is updated too.

**A note is not a task (v1.9).** If the user picks "Add note" from the same
menu, the record does **not** go under `tasks/` — it is written to `notes/`
(§11). The distinction is the user's intent: a task says "you do this", a note
says "let me remember this". Putting both in the same folder pushed every line
the user wrote to themselves into the agent's work queue.

**A bookmark is never a task (v1.12).** A record carrying `mark: bookmark` goes
to `notes/` even when a note was written. For the other marks the distinction is
whether a note exists (no note → `notes/`, note → `tasks/inbox/`, see §11 and
B-099); for a bookmark the intent is in the name: "let me find this again". A
note attached to a bookmark is not work handed to the agent, it is a marker the
user left for themselves.

## 5. `knowledge/` — the knowledge base

Three living files; every record is added individually with an ID and a date,
and never deleted (a record that stops being true is `~~struck through~~` with
the reason written next to it):

- `knowledge/rules.md` — **Rules** (`R-001`, `R-002`…): permanent rules to
  follow in this project. E.g. "R-001: the app writes only to tasks/inbox/."
- `knowledge/skills.md` — **Skills** (`SK-001`…): reusable capabilities or
  procedures the agent acquired in this project. E.g. "SK-001: SHA-checked file
  update via the Contents API."
- `knowledge/lessons.md` — **Lessons learned** (`L-001`…): mistakes made and
  what came out of them. E.g. "L-001: one big JSON file collides on concurrent
  writes; use one record per file."

Record format (identical in all three files):

```markdown
## R-001 — The app has a single write area: tasks/inbox/
- **Date:** 2026-07-30
- **Source:** S-2026-07-30-infrastructure-design
- **Description:** ...
```

## 6. `BACKLOG.md` — the work list

- A checkbox list with IDs (`B-001`…), split into phases.
- **Finished work is never deleted**: its box is checked, the date and any
  artifact or commit link is added, and it stays in the list. Outstanding work
  stays in the list too.
- New work is always added to the relevant phase in ID order; when a phase ends,
  a ✅ and the closing date go on the phase heading.
- The detailed format is defined at the top of `BACKLOG.md`.

## 7. `EVOLUTION.md` — the project's evolution

- The project advances in **stages** (Stage 0, 1, 2…); each stage is a section
  in this file: goal, decisions made, outcome, date range.
- The active stage's section is **continuously updated**; when the stage closes,
  a ✅ goes at the top of the section and the next stage opens.
- Changes to the contract (this file) are recorded here as decisions too.

## 8. Commit message rules

Every commit in the hub says what it is in one line:

```
session(S-...): session opened / record updated / session closed
task(T-001): added to inbox / active → done / note added
artifact(A-...): <title> added
backlog: B-014 finished
evolution: Stage 1 closed
knowledge: L-003 added
note: added / deleted (app)             # (v1.11) notes/ — the user's note
security: SEC-005 added / SEC-002 closed  # (v1.11) SECURITY.md
plan(P-001): plan opened / step completed / plan closed  # (v1.25) PLAN.md
system: contract updated to 1.1
```

The app shows commit history as an **activity feed** based on these prefixes. A
prefix not in this list counts as a "code commit" and appears as such in the
feed; that is why the prefix for a new record type is written **here too**. This
was missed when `notes/` (1.9) and `SECURITY.md` (1.10) were added: the user's
own note showed up in the feed as "code" (fixed in v1.11).

## 9. Categories (the app's view)

The app's browse screen derives these categories from the folders:

| Category | Source |
|---|---|
| Pending tasks | `tasks/inbox/` + `tasks/active/` + `tasks/waiting/` |
| Done | `tasks/done/` |
| Sessions | `sessions/` |
| Reports & Plans | `artifacts/` (sub-filtered by frontmatter `type`) |
| Knowledge base | `knowledge/` |
| Roadmap | `BACKLOG.md`, `EVOLUTION.md` |

## 10. Contract version and updating (v1.5, K-024)

The **master copy** of this file is `hub/SYSTEM.md` in the `afgover/takip`
repository. The copies in other projects' hubs derive from it and **may fall
behind**.

A copy that has fallen behind is a silent trap: the agent reads the contract in
its own hub, does not know about a folder that is not in it (say
`tasks/waiting/`), and never exhibits the behaviour the latest contract expects.
This actually happened — `financer_takip` was stuck on 1.3 while using the
`waiting/` folder, i.e. using a folder its own contract did not define (L-020).

### Language variants (v1.21)

The master exists in two files, and **a hub fetches the one matching its own
language**:

| Hub language | Master to fetch |
|---|---|
| `tr` | `hub/SYSTEM.md`, `hub/AGENT_PROTOCOL.md` |
| `en` | `hub/SYSTEM.en.md`, `hub/AGENT_PROTOCOL.en.md` |

Whichever variant it fetches, the hub stores it under its **own** `hub/SYSTEM.md`
and `hub/AGENT_PROTOCOL.md`. The file name in a hub does not carry a language
suffix — only the master repository holds the variants side by side. This keeps
every path in this contract identical in every language, and keeps the app
(which reads `hub/SYSTEM.md`) from needing to know the language before it can
find the file.

The Turkish file is **canonical**: if the two variants disagree, the Turkish one
is correct and the English one has a translation bug. Report it rather than
acting on it, and fix it in the master. Two binding copies drift silently — this
project has lived exactly that (L-022).

### The rule sequence

At **every session opening** every agent does the following:

1. Read the **contract version** from the first lines of its own hub's
   `hub/SYSTEM.md`, and the `**Hub language:**` field.
2. Compare against the master. One command covers both version and content
   (v1.17); pick the file for your hub's language (v1.21):

   ```bash
   # Hub language: en
   curl -fsSL https://raw.githubusercontent.com/afgover/takip/main/hub/SYSTEM.en.md \
     -o /tmp/SYSTEM.master.md && diff /tmp/SYSTEM.master.md hub/SYSTEM.md
   ```

   - Empty `diff`: your copy is **byte-identical** to the master, nothing to do.
   - Non-empty `diff`: act per items 4/5/6 below (are the versions different, or
     is the version the same with different content — the latter is divergence).
   - **If `curl` fails, the check DID NOT RUN.** Do not read that as "I am up to
     date" and do not write "contract checked" in your record. Without network,
     or if the address changed, the same holds. A check that did not run is not
     a check that passed (the same rule as L-035).

   The agent of `afgover/takip` itself skips this step: that repository *is* the
   master.
3. **If the versions match**, do nothing.
4. **If your copy is behind:**
   - Take the master as-is and overwrite `hub/SYSTEM.md`.
   - Refresh `hub/AGENT_PROTOCOL.md` the same way (it comes from the master too,
     in the same language variant).
   - Create any folders the new version introduces (e.g. `tasks/waiting/`).
   - Commit: `system: contract <old> → <new>`
   - Add a one-line note to `EVOLUTION.md`: which version moved to which.
   - Tell the user **what changed**, in one sentence.
5. **If your copy is ahead** (newer than the master): do not overwrite. It means
   a local change was made without updating the master; tell the user and
   suggest moving the change into the master.
6. **If the versions are equal but the content differs (divergence):** this is
   the most dangerous case, and a check that only looks at version numbers
   **cannot see it**. It means two hubs took the same number for different
   changes. Do not overwrite; show the user the difference, move the local
   addition into the master, increment the master's version, and then update.
   This actually happened: `financer_takip` used 1.4 for "the `reconstructed`
   field" while the master used 1.4 for "`tasks/waiting/`" (L-022). **This is
   why comparing versions is not enough; content is compared before updating.**

Change the contract **only in the master**. If a project turns up a new need,
propose it to the user first; if approved, increment the version in
`afgover/takip` — other hubs pick it up on their next session by themselves.

> **A change to `AGENT_PROTOCOL.md` also increments the version (v1.14).** The
> propagation mechanism only looks at this file's version number (step 2); if
> the protocol is changed on its own, other hubs **never** receive it and no
> check notices. So the version is incremented for every new rule written into
> the protocol — even when the change is not a single line in `SYSTEM.md`.

> **On the app side:** the app reads each connection's contract version and
> flags the ones behind the master under **Settings → Repositories**. So a hub
> that has fallen behind is visible to the user even when the agent misses it.

## 11. `notes/` — the user's own notes (v1.9)

Notes the user takes **for themselves**. They are not tasks: they do not appear
in the work queue, they get no ID, and they have no `active`/`done` status.

```
notes/
  <login>/                        # (v1.15) the owner's GitHub account
    2026-08-03-vulkan-backend.md
  2026-08-03-old-note.md          # pre-v1.15: flat, still valid
```

File name in the same format as tasks: `<YYYY-MM-DD>-<slug>.md`.

**Ownership is read from the folder (v1.15).** So that notes from several people
do not get mixed, each user has their own subfolder. Making the distinction
structural — a **folder** rather than a field — is deliberate: it keeps "the
agent does not touch notes" structural, with no need to open a file and read a
field to know whose it is.
`tasks/inbox/` was deliberately not split: it is the shared work queue, and
splitting it would hide work.

**A note is personal; the way to share is a task (v1.16).** When the app draws a
document it marks **only your own** notes; somebody else's note appears neither
in the document nor in the marks list. Whoever wants to share opens a task —
`gorev`, `duzeltme` or `tartisma`. The distinction is intent and is already
defined in §4: a note is "let me remember this", a task is "you do this", a
discussion is "let us talk about this".
The rationale continues 1.9's (K-029): everyone seeing everyone's notes stops a
note from being "a thing written to oneself" — a user taking a note for
themselves does not want to be saying something to others.

Filtering is **not** applied in two cases, both deliberately:
- If the identity is unknown: filtering would hide everything.
- If the note is directly under `notes/` (pre-v1.15): the owner is unknown, and
  hiding it would silently destroy existing notes.

On the app side R-001's guarantee holds: the app still gives no path, picks the
folder from a closed set, and passes the user name as a **name**; the name is
reduced to letters, digits and hyphens before it ever becomes a path segment.

```markdown
---
title: Impeller Vulkan backend
created_by: user
created: 2026-08-03T09:10:00Z
updated: 2026-08-03T09:10:00Z
source: hub/sessions/2026-08-03-from-scratch/session.md
quote: Using the Impeller rendering backend
mark: comment
---

Let me look at this later.
```

The `source`/`quote`/`mark` fields mean the same as in §4's selection records
and do the same job: when the app draws the document it finds the note too and
marks the quote in `mark`'s colour. So a note also carries its own mark and no
mark is stored separately. A note not taken from a document selection may lack
these three fields.

**Bookmarks (v1.12) live here.** A record carrying `mark: bookmark` is always
written to `notes/` — even with a note (§4). The app gathers all marks (tasks
and notes) **from the active repository** into one list, from which you go to
the document the record is tied to; that is exactly a bookmark's job.

> **v1.13 correction.** In 1.12 this list combined *all* connections. Within the
> first hour of use it turned out to backfire: a mark reminds you of a **place**
> in a document, and a document belongs to a project — with everything in one
> list the screen becomes a pile of contexts. The list now belongs to the active
> repository and which one it is written on the screen; to look at another
> project you switch repositories.
> The `tasks/` lists are a deliberate exception: there the question is "what is
> waiting on **me**, in whichever project", so they stay combined.

**Agent rules:**
- Notes belong to the user. The agent does **not** treat them as work: no ID, no
  moving, no `result`, no "done".
- The agent **may read** notes and use them as context ("the user noted this
  here"). If a note needs to become work, the user says so; the agent does not
  open a task on its own.
- The agent does not delete or edit a note. The user deletes it from the app.
- If a note really does contain work, the agent **asks** (opening a question in
  `tasks/waiting/` if needed) rather than deciding by itself.

**App rules:** R-001's write area became two in v1.9 — `tasks/inbox/` and
`notes/`. Both are structurally closed: the app gives a file name, not a path,
and cannot choose the folder.

## 12. `SECURITY.md` — the security log (v1.10)

**Everything done and everything still to do** about the project's security is
kept in one living file as records with IDs. The point: the answer to "what did
we do about this" should not scatter across session records but be readable from
one place.

Record format as in `knowledge/` (§5), with two extra fields:

```markdown
## SEC-001 — The token lives only in the device's secure storage
- **Date:** 2026-08-03
- **Type:** measure
- **Status:** closed
- **Source:** S-2026-08-01-token-persistence
- **Description:** The token is kept in `flutter_secure_storage`; it is never
  written to a file, a commit or a log under any circumstances.
```

| Field | Values | Meaning |
|---|---|---|
| `Type` | `scan` | An audit or scan performed, and its findings |
| | `measure` | A protection, hardening or rule adopted |
| | `hole` | A known vulnerability or risky behaviour |
| | `todo` | Security work that needs doing |
| | `decision` | (v1.25) A security decision whose consequences are accepted |
| `Status` | `open` | Not closed yet — pushed to the top of the screen |
| | `closed` | Finished or fixed |

Values are written in plain ASCII (the same rationale as the file-name rule);
the screen shows readable equivalents.

**Agent rules:**
- **Every** piece of security work gets a record here: a dependency scan, a
  permission change, anything touching tokens or identity, a data-storage
  decision, a hole found. Writing it only in the session record is not enough —
  the security history must be readable from one place.
- **(v1.14) The date of a `scan` record is a trigger.** At every session opening
  the agent looks at the last `scan` record; if it is older than 30 days it runs
  the scan again (`AGENT_PROTOCOL.md`, item 4). A scan reflects the advisory
  database of the day it ran, so it is not a one-off approval. Keeping the
  trigger **in the record itself** rather than in a separate calendar is
  deliberate: it stays visible when forgotten, and no second system is needed to
  keep the reminder alive.
- When a `hole` record is fixed it is **not deleted**: `Status` becomes `closed`
  and how it was fixed is written underneath. A record that stops being true is
  `~~struck through~~` with the reason, as in R-004.
- `todo` records also go into `BACKLOG.md`; here they sit in security context,
  there in work order. If the two disagree, `BACKLOG.md` is the source of truth.
- **No secrets are written.** Tokens, passwords, keys, private URLs — none of
  them go into this file (or any other hub file). A record describes **what is
  protected**, not the protected thing itself.
- The user sees this log in the app under **Browse → Security**.

## 13. Transitional rules (v1.22)

This section holds rules that apply only to **hubs set up before a given
version** and that are **removed** once their work is done. The reason they sit
in their own section is concrete: in a hub created from scratch they do nothing,
and had they lived in the body of the contract, somebody reading the method for
the first time would take them for permanent rules. Putting a temporary rule
among the permanent ones makes the contract unreadable over time.

Every entry states three things: **who it concerns**, **when it goes away**, and
**why it is temporary**. No entry is added to this section without them — a
temporary rule with no removal condition is a permanent rule.

### G-001 — Add options to old `waiting/` questions

- **Who it concerns:** hubs with `waiting/` tasks opened **before contract
  1.12**. Nothing to do in a newly created hub.
- **When it goes away:** once applied in the hubs it concerns; it ends for
  everyone when the master copy deletes the entry.
- **Why it is temporary:** 1.12 introduced waiting-with-options but **was not
  retroactive**. Questions opened before that date still sit behind a single
  "Done" button, even though their answer is a **decision**, not "done".

At session opening the agent looks at the tasks in `tasks/waiting/` and adds
options (`options`, and `multi` if needed) to those whose body awaits a
**decision** but which carry no `options` field. It tells the user what it
changed.

The distinction is sharp and is not applied in reverse:

| What is awaited | What to do |
|---|---|
| A **decision** ("which one should we do?") | add `options` |
| A **piece of work** ("generate a token") | leave it alone — the answer really is "done" |

The rule is **idempotent**: a task that already carries `options` is skipped.
That is why no "did this run in this hub" record is kept — the state is carried
by the task itself, and a separate flag could drift from the files.

> **Adding options is an improvement, not an obligation.** Since v1.22 the user
> can write **free text** in an option-less waiting task too (T-014), so the
> problem of an answer having nowhere to go is already solved. This entry exists
> to make the answer *machine-readable*. A task you are unsure about is left as
> it is: an invented option list forces the user into a frame the agent never
> thought through, and records a wrong answer in a form that looks right.

## 14. `PLAN.md` — the task tree (v1.25, retroactive plans v1.26)

A session record holds **what was discussed**, `BACKLOG.md` **what is to be
done**, `tasks/` **the user-facing state of a job**. The fourth was a question
none of them answered: *which step is a multi-step job on right now?* The answer
was buried in the prose of the session record; reading it meant reading the
whole session, and a step left half-done did not stand out there.

`PLAN.md` does that job: the steps the agent proposed, **itemised, with state**.

### Scope — what goes in, what does not

Every job made of **three or more steps** goes into the tree, written down
before the steps are carried out — when that is not possible, see *Retroactive
plans*. What does not:

| Goes in | Stays out |
|---|---|
| A multi-step fix, feature, migration, analysis | One-command work (read a file, fix a line) |
| A plan presented to and approved by the user | The conversation itself — that is the session record's job |
| Multi-step work the agent runs on its own | An idea for future work — that is `BACKLOG.md`'s job |

The reason for the threshold is concrete: in a tree that lists every micro-step,
the entry that actually needs intervention becomes invisible. The tree's value
is in its sparseness.

**It changes no other flow.** Session records are kept as before, the backlog is
ticked as before, tasks change folders as before. `PLAN.md` replaces none of
them; it **refers** to them. The same fact is not held in two places: if a step
closes a backlog entry, the step links to that entry rather than copying its
text.

### Schema

```markdown
# PLAN.md — Task Tree

## P-002 — <newest plan on top>
...

## P-001 — <plan title>
- **Date:** 2026-08-13
- **Source:** S-2026-08-13-status-summary
- **Status:** open
- **Related:** B-097, SEC-010

- [x] P-001.1 — <step> · ✅ 2026-08-13
- [ ] P-001.2 — <step>
  - [x] P-001.2.1 — <sub-step> · ✅ 2026-08-13
  - [ ] P-001.2.2 — <sub-step>
- [ ] ~~P-001.3 — <step>~~ · ⨯ **Cancelled (2026-08-13):** <reason>
```

| Field | Required | Description |
|---|---|---|
| `Date` | yes | The day the plan was opened |
| `Source` | yes | ID of the session that produced the plan |
| `Status` | yes | `open` · `completed` · `cancelled` |
| `Related` | no | Record IDs the plan touches (`B-`, `SEC-`, `T-`…) |
| `Derived` | no | (v1.26) `true` → the plan was derived from the record after the job ended |

Rules:

1. **Numbering.** A plan is `P-<three digits>`, a step is a dotted extension
   (`P-001.2`), a sub-step one dot further (`P-001.2.1`). The tree structure is
   built with **indentation** (two spaces). Numbers are never reused; a
   cancelled step's number stays vacant.
2. **State marks.** `- [ ]` to do, `- [x]` done; a cancelled step keeps the
   `- [ ]` box, is written **struck through**, and **carries its reason**. No
   step is cancelled without one: a reasonless cancellation is a gap that will
   not answer "why was this not done" six months later.
3. **Ticked immediately.** A step is marked the moment it is finished, not saved
   up for the end of the session (same reasoning as `BACKLOG.md`).
4. **No deletion.** A completed plan and a cancelled step both stay in the file
   (R-004). A closed plan stays where it is; **a new plan goes on top**, so that
   in a plain markdown reader what is live is what you see first.
5. **A plan's status is written, not derived from its steps.** When every step
   is done, set `Status: completed`. The two can drift, and that is accepted
   deliberately: a derived status cannot express "every step is done but the job
   is not".
6. **The file is optional.** A hub without `PLAN.md` does not violate the
   contract; it is created with the first multi-step plan. Every tool reading it
   treats the file's **absence** as a normal state (R-008: new fields and files
   do not break existing hubs).
7. **A step line is short.** A line says *what was done*; **why** it was done
   goes to the record it links to (session, backlog, knowledge). Cramming the
   reasoning into the step line turns the tree into a wall of text on a phone,
   and the one question the tree exists to answer — "which step are we on" —
   goes unanswered again.

### Retroactive plans (v1.26)

A job whose multi-step nature became clear only **after it ended** also goes
into the tree; its plan is written then and carries `Derived: true`.

This clause closes a measured gap. In 1.25 the rule only said "steps are written
before they are carried out", which left an agent that noticed late with two
options: **make them up** (forbidden) or **skip** (what happened). The result
was the second — trees stayed empty, including in the very hub that wrote the
contract (S-2026-08-15-gorev-kapsami, deviation note).

The distinction is sharp and does not work in reverse:

| What happened | Does it go in the tree |
|---|---|
| Steps were **derived from a record** (session, commit, backlog) | ✅ `Derived: true` |
| Steps are **not remembered**, written because they sound plausible | ✗ not written |

So what is permitted is **derivation**, not invention. That is why `Source`
matters even more in a retroactive plan: it is the only place showing where the
steps were read off. A step that cannot be derived is not written — an
incomplete tree beats a false one.

The same distinction already lives in the hub: `reconstructed: true` on session
records (v1.6), and the "this summary was derived from its own record" note on
summaries written later. Not a new concept — an existing pattern moved to the
tree.

> **A retroactive plan is born closed.** It describes a job whose steps are
> already finished, so it is written with `Status: completed` (or `cancelled`).
> An open plan cannot be retroactive: the steps of unfinished work can still be
> written in advance.

**Placement.** The "new plan on top" rule (4) is for *live* work; a retroactive
plan is born closed, so it is written **among the closed plans, in date order**,
not on top. Otherwise a job from six months ago would bury the work left half
done today — exactly what the rule exists to prevent. Numbering still runs in
sequence: the number says when it was **written**, the date says when it was
**done**.

## 15. Links — moving between documents (v1.25)

Hub records refer to each other by ID: a session mentions `SEC-010`, a backlog
entry rests on `L-042`. Until now those references were **plain text** — the
reader had to find the file and search for the ID inside it.

The rule: **a reference to another record is written as a link.**

```markdown
[SEC-010](SECURITY.md#SEC-010)
[L-042](knowledge/lessons.md#L-042)
[T-011](tasks/done/2026-08-13-make-repo-public.md)
```

- The **path** is relative to the hub root (`SECURITY.md`,
  `knowledge/lessons.md`). From a file in a subfolder an ordinary relative path
  works too (`../SECURITY.md`).
- The **anchor is the record's ID** — not the heading text. Why: headings get
  rewritten, IDs do not. A heading-based anchor dies silently every time the
  heading is edited.
- The anchor points at the **first line** where the ID occurs in the target
  document. That line need not be a heading; in `BACKLOG.md` records are list
  items.

> **The limit on GitHub — accepted deliberately.** GitHub derives the anchor
> from the **whole heading** (`#sec-010--release-builds-are-signed-…`), so
> `#SEC-010` does not jump to the section there: the link opens the right file
> and the page starts from the top. Scrolling to the section is
> **app-specific**. The alternative was embedding `<a id="...">` before every
> record: clutter that makes the markdown unreadable, not worth buying a scroll
> in one reader out of two.

### When to link

The agent is **expected to use this**; the rule is: the first time a record's ID
appears in a document it is written as a link, and repeats within the same
document stay plain. The reasoning runs both ways — an unlinked reference sends
the reader off to hunt for a file, while linking every repeat turns the text
into blue noise.

Where it is particularly expected:

- from `PLAN.md` steps to the record they close (`B-126`, `T-011`),
- from a session record to the records written in that session,
- from a `BACKLOG.md` entry to the task or security record that closes it,
- from a record's "Source" field to the source itself.

Adding a link **is not mandatory** and a missing link is not a contract
violation; links are never manufactured at the cost of what a record says.
