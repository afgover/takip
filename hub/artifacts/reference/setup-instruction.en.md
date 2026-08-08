---
id: A-2026-08-08-001
session: none
type: info
title: "Agent setup instruction — build the hub, reconstruct the history, follow the protocol"
created: 2026-08-08T00:00:00Z
contract: "1.21"
language: en
translated_from: hub/artifacts/reference/agent-kurulum-talimati.md
---

# Agent Setup Instruction

**Give this document to your agent.** When connecting a project to the takip
system, the user pastes it as-is; the agent does the rest.

> **This is the English edition.** The canonical source is the Turkish
> [`agent-kurulum-talimati.md`](agent-kurulum-talimati.md) in `afgover/takip`.
> When the two disagree, the Turkish one wins — not because it is better, but
> because a system with two authoritative copies drifts, and drift here is
> silent (see the contract, §10).
>
> Written against **contract 1.21**. If the contract itself is newer, the
> contract wins — see §1.

---

## Your assignment

You will set up a **takip hub** in the `<owner>/<project>_takip` repository,
and from then on you will record every piece of work you do on that project
there.

The hub is the project's memory: session records, tasks, decisions, lessons
learned, security history and the roadmap all live there. The user reads it
from an app on their phone and assigns you work from there. **Work that is not
reflected in the hub does not count as done.**

You are in one of two situations:

- **A — New project.** No work exists yet. Go §0 → §1 → §2 → §5.
- **B — Project with history.** The project has been running for months; it has
  code, commits, documents, maybe old conversations. Go §0 → §1 → §2 →
  **§3 (reconstruct the history)** → §5.

In case B, **§3 is not optional.** Setting up an empty hub and saying "I'll
record everything from now on" writes off every decision the project has made
so far; the first time the user asks "why did we do it this way?" there will be
no answer.

---

## 0. Ask for the language — **do this first** (contract 1.19)

A hub has **one language**, decided at setup. Three things follow it: the
contract and protocol (your reference), the app's interface, and every record
created from that point on (body headings included).

**Ask the user and wait for the answer.** You may propose the language you are
speaking, but do not proceed without confirmation: the language can be changed
later but **it does not act retroactively** — existing records stay in the
language they were written in. So this looks like a cheap decision and turns
expensive later.

> "Which language should this hub use? The contract, the app interface and
> every record from now on will be in it. Supported: `tr`, `en`."

Once you have the answer:

1. Fetch the **variant of the contract in that language** (§1).
2. Write the code into the `**Hub language:**` field at the top of
   `hub/SYSTEM.md`.
3. Write **everything** you produce in the hub in that language: session
   records, backlog items, knowledge entries, task bodies.

If the field is missing, `tr` is assumed. That is a default, not a preference:
every hub created before the field existed was Turkish. When setting up a new
hub, **always** write the field — leaving it out silently binds an
English-speaking user to a Turkish hub.

**The app cannot change this field.** Its write area is limited to
`tasks/inbox/` and `notes/` (R-001), so the language is a decision you make at
setup. If the user wants to change it later, they come to you again.

> **What "English" covers, stated plainly (contract 1.21):** the contract and
> the protocol both exist in English (`SYSTEM.en.md`, `AGENT_PROTOCOL.en.md`)
> and an English hub fetches those. The **canonical** copy is still the Turkish
> one: if the two ever disagree, the Turkish one is correct and the English one
> has a translation bug — report it instead of acting on it. That is not about
> which language is better; it is that a system with two authorities drifts and
> nobody notices while it does (L-022, lived).
>
> Still Turkish in an English hub: the category **values** written into records
> (`gorev`, `duzeltme`, `tartisma`…) and the security `Type` values. Those are
> data, not prose — translating them would make the same hub carry two spellings
> of one category. Their labels are shown translated in the app.

---

## 1. Fetch the contract and check its version

Two files never change from project to project; they are copied from the master
**as-is**:

- `hub/SYSTEM.md` — the format contract
- `hub/AGENT_PROTOCOL.md` — your recording procedure

Master copy: `afgover/takip` → `hub/`.

**Fetch the variant matching the language chosen in §0** (contract 1.21).
Whichever one you fetch, it is stored under the plain name — a hub's own files
never carry a language suffix, so every path in the contract stays the same in
every language:

```bash
# Hub language: en
curl -fsSL https://raw.githubusercontent.com/afgover/takip/main/hub/SYSTEM.en.md \
  -o hub/SYSTEM.md
curl -fsSL https://raw.githubusercontent.com/afgover/takip/main/hub/AGENT_PROTOCOL.en.md \
  -o hub/AGENT_PROTOCOL.md

# Hub language: tr → same commands without the .en suffix
```

### At every session opening: compare the version

```bash
# Hub language: en — use SYSTEM.md for a tr hub
curl -fsSL https://raw.githubusercontent.com/afgover/takip/main/hub/SYSTEM.en.md \
  -o /tmp/SYSTEM.master.md && diff /tmp/SYSTEM.master.md hub/SYSTEM.md
```

- **Empty diff** — your copy is identical to the master. Nothing to do.
- **Non-empty diff** — compare the `**Contract version:**` lines:
  - **Yours is older:** overwrite both files from the master, create any folders
    the new version introduces, commit as
    `system: contract <old> → <new> updated`, add a one-line note to
    `EVOLUTION.md`, and tell the user in one sentence what changed.
  - **Yours is newer:** do **not** overwrite. Someone changed it locally
    without updating the master. Tell the user and offer to move the change to
    the master.
  - **Same version, different content — divergence.** This is the dangerous one
    and a version-number check alone cannot see it. Two hubs took the same
    number for different changes. Do not overwrite: show the user the
    difference, move the local addition into the master, bump the master's
    version, then update. This has actually happened (L-022).
- **The request failed** — the check **did not run**. Do not read that as "I am
  up to date" and do not write "contract checked" into your record. A check that
  did not run is not a check that passed.

Change the contract **only in the master copy**. If a project needs something
new, propose it to the user first; if approved, bump the version in
`afgover/takip` and other hubs will pick it up at their next session.

---

## 2. Build the skeleton

```
hub/
  SYSTEM.md
  AGENT_PROTOCOL.md
  BACKLOG.md
  EVOLUTION.md
  SECURITY.md
  sessions/
  artifacts/
  tasks/inbox/      active/      waiting/      done/
  notes/
  knowledge/rules.md   skills.md   lessons.md
```

Git does not track empty directories, so put a `README.md` in each folder that
explains what belongs there. The app also uses these to distinguish real records
from helper files — files named `README.md` or starting with `_` are skipped.

Commit: `system: hub skeleton created (contract 1.19)`

---

## 3. Reconstruct the history (case B only)

### 3.1 Read before you write

Evidence sources, in order of reliability:

1. **Commit history** — dates and what actually changed. The hardest evidence.
2. **Documents in the repository** — READMEs, design notes, TODOs.
3. **Issues / PRs**, if any.
4. **What the user tells you** — ask, but mark it as their account.

Do not invent. If you cannot date something, say so; if you are unsure whether
a decision was made, ask (§3.5).

### 3.2 Write reconstructed sessions

Group the history into meaningful stretches and write one session record per
stretch, with `reconstructed: true` in the frontmatter. That flag is not an
exception to "no work outside the record" — it is honesty about how the record
was produced: a retroactive record cannot claim the timestamp accuracy of a
live one. Timestamps may be omitted or approximate.

Commits: `session(S-...): recorded retroactively (reconstructed)`

### 3.3 Rebuild `EVOLUTION.md`

Split the project into phases with what each aimed at, what was decided and how
it ended. Decisions get `K-xxx` ids.

### 3.4 Rebuild `BACKLOG.md`

Everything already done goes in checked, with its date. Everything still open
goes in unchecked. Completed work is never deleted — it stays in the list.

### 3.5 Put what you don't know into `waiting/`

Reconstruction always produces questions only the user can answer. Do not ask
them in chat and move on — **each one is a `waiting/` task.** Chat closes; the
hub does not.

### 3.6 Backfill `knowledge/` and `SECURITY.md`

Lessons the project has already learned (`L-xxx`), rules it follows (`R-xxx`),
reusable procedures (`SK-xxx`). Anything security-related — dependency scans,
permission changes, token handling, known holes — goes into `SECURITY.md` as an
id'd record (§7).

### 3.7 Summarise for the user

Say what you reconstructed, what you could not, and what you put into
`waiting/`. Reconstruction is a claim; the user is the one who can falsify it.

---

## 4. The session loop

1. Create `sessions/<date>-<slug>/session.md` with `status: open` and an
   `author:` field (who is running the session).
2. Check `tasks/inbox/` and report new tasks to the user. Handle them only if
   the user asks; move what you handle into `active/`.
3. Look at `BACKLOG.md` for unfinished work.
4. Check the date of the last `tarama`/`scan` record in `SECURITY.md`. If it is
   older than 30 days — or missing — run the dependency/vulnerability scan
   appropriate for the project and record the result.
5. **Append every user message and every reply to `session.md` as it happens.**
   Do not save it up for the end. User messages verbatim; your replies
   summarised around decisions, findings and work done.
6. Long outputs (reports, plans, analyses) go to `artifacts/<session-id>/` with
   frontmatter, and are linked from `session.md`.
7. When closing: fill in `## Summary`, set `status: closed`, update the active
   phase in `EVOLUTION.md`, and push everything. **An unpushed record is not a
   record.**

> **Assigning ids.** Before issuing a new `T-`, `B-`, `L-`, `SK-`, `R-`, `SEC-`,
> `K-` or `A-` number, `git pull --rebase`; push immediately after. Counters are
> global, and if two agents run at once both pick the same number — the files
> differ, so git does not call it a conflict and nothing errors. Derive the
> number from **the file**, not from memory.

---

## 5. The task loop — status is the folder

```
tasks/inbox/     new: the user (app) or you added it, not handled yet
tasks/active/    you picked it up, work in progress
tasks/waiting/   you are waiting on the user — the ball is theirs
tasks/done/      finished (archive — never deleted)
```

Moving between folders is **your** job only; the app never moves a file.
A move is delete-old + write-new, committed as `task(T-001): active → done`.

### `waiting/` — the most commonly skipped part

**If the user has to do something, open a task and put it in `waiting/`.**
Saying it in chat is not enough: chat closes and the user sees no trace on their
phone. The rule is — *"if I cannot proceed until the user acts, this is a
`waiting/` task."*

Write what you expect in `## Notes`, in one actionable line ("create a
fine-grained token on GitHub; Contents: Read and write"). Vague expectations
("they might look at it some day") do not belong in `waiting/`; that task stays
in `active/`.

**If you are asking a question rather than requesting work, offer options:**

```yaml
options: ["I'll create a fine-grained token", "Stay with classic", "Later"]
multi: false                 # true → the user can pick more than one
```

The app then shows the choices instead of the "Done" button; the user picks and
may add a free-text note. The answer lands in `inbox/` tagged `waiting-answer`.
One task = one question: an answered question is closed, and if the
conversation needs to continue you open a new `waiting/` task.

---

## 6. What comes from the app

The app writes to **only two** places (R-001): `tasks/inbox/` and `notes/`. It
never touches another folder and never moves files. One exception: the user can
delete a record they created that is still sitting in `inbox/` — once you move
it to `active/` it is yours.

### Records created from a document selection

The user can select text in any document and create a record. These land in
`inbox/` as normal tasks but carry three extra fields: `source` (which
document), `quote` (verbatim excerpt), `mark` (yellow/red/green/blue). The body
also states **where** it came from: repository, file path, section heading — so
you can go straight there instead of searching the whole hub.

`category` says what it is and **determines how you handle it**:

| Category | What is expected of you |
|---|---|
| `gorev` / task | Do the work |
| `yorum` / comment | Take it as a note; usually no work to do |
| `duzeltme` / correction | The quoted place is wrong — **fix the `source` document**, then close the record |
| `tartisma` / discussion | An open question — answer it, and use `waiting/` if you need the user |

The mark is derived from the record, not stored separately: if you move the
record to `done/`, the mark disappears from the document too. So finish a
`correction` before you close it.

### `notes/` — the user's own notes

If the user chooses "Add note" instead, the record does **not** go under
`tasks/`; it goes to `notes/<login>/`.

**This folder is not your work.** No assigning ids, no moving, no writing
`result`, no "done", no deleting, no editing. You may **read** them as context
("the user noted this here") and rely on that in your session record. If a note
really contains work, do not open a task on your own initiative: ask the user,
and put a question in `waiting/` if needed.

The distinction is the user's intent: a task says "you do this", a note says
"let me remember this".

A `bookmark` mark **never** becomes a task, even with a note attached — "let me
find this place later" is not an assignment.

---

## 7. `SECURITY.md` — the security log

**Every** security-related piece of work gets an id'd record here: scans run,
measures taken, known holes, security work still to do. Same format as
`knowledge/`, with two extra fields:

```markdown
## SEC-001 — Short title
- **Date:** 2026-08-03
- **Kind:** scan | measure | open | todo
- **Status:** open | closed
- **Source:** S-2026-08-03-...
- **Description:** ...
```

Rules:

- Writing it only into the session record is not enough — the answer to "what
  did we do about this?" must not be scattered across sessions.
- A resolved hole is **never deleted**: set `Status: closed` and write how it
  was resolved underneath.
- `todo` records also go into `BACKLOG.md`; if the two disagree, `BACKLOG.md`
  is the source of truth.
- **Never write a secret.** No token, password, key or private URL goes into
  this file — or any hub file. A record describes *what is protected*, never the
  protected thing itself.

---

## 8. Commit messages

```
session(S-...): session opened / record updated / session closed
session(S-...): recorded retroactively (reconstructed)
task(T-001): added to inbox / active → waiting / active → done
artifact(A-...): <title> added
backlog: B-014 completed
evolution: Phase 1 closed
knowledge: L-003 added
note: added / deleted (app)
security: SEC-005 added / SEC-002 closed
system: contract updated to 1.1
```

Unrelated changes do not share a commit. The app reads the commit history
through these prefixes and shows it to the user as an activity feed. **Do not
invent prefixes:** anything not on this list counts as a "code commit" and
appears that way. If you need a new record type, its prefix goes into the
contract (§8) first.

---

## 9. Rules that never bend

- **No work outside the record.** Anything not pushed to the hub did not happen.
- **No deleting.** Sessions, artifacts, `done/` tasks, knowledge and security
  records are never removed; an invalidated record is ~~struck through~~ with
  the reason written next to it.
- **Loyalty to the contract.** Do not invent files or formats outside the
  `SYSTEM.md` schema. If a format change is needed, propose it to the user
  first; if approved, bump the version in the master and record it in
  `EVOLUTION.md`.
- **Respect the app's territory.** Handle user tasks in `tasks/inbox/` only as
  the user directs; never delete or alter them on your own judgement (moving
  and adding notes are fine).

---

## 10. What to learn from the user in the first session

- Which language should the hub be in? (§0 — ask this first)
- What is this project, and what is it for?
- Which decisions are settled, and which are still open?
- What is currently unfinished?
- Is there anything they consider secret that must not enter the hub?

Put anything you cannot answer into `waiting/` rather than guessing.

---

## 11. Checklist before you finish

- [ ] `SYSTEM.md` and `AGENT_PROTOCOL.md` copied from the master; version
      checked; `**Hub language:**` written
- [ ] All folders exist and each has a `README.md`
- [ ] Case B: history reconstructed, sessions marked `reconstructed: true`
- [ ] `EVOLUTION.md` and `BACKLOG.md` reflect the real state
- [ ] Every question whose answer lies with the user is a separate `waiting/`
      task
- [ ] Everything is pushed
- [ ] The user has been told, in one paragraph, what was set up and what is
      waiting for them
