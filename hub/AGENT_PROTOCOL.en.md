# AGENT_PROTOCOL.md — The Agent's Recording Procedure

*English · canonical copy: [`AGENT_PROTOCOL.md`](AGENT_PROTOCOL.md) (Turkish).
If the two disagree, the Turkish one is correct — see `SYSTEM.md` §10.*

This document is the procedure **every agent session working with this hub must
follow**. Format details are in `SYSTEM.md`; here it is defined *when to do
what*. The procedure holds whatever the session is about.

## At session opening (right after the first message)

0. **Read the hub's language** (`SYSTEM.md` → `**Hub language:**`, contract
   1.19) and write everything you produce in this session in that language:
   the session record, backlog entries, knowledge records, task bodies. If the
   field is missing, `tr`. If the hub's language differs from the language the
   user writes to you in, **ask the user** — do not silently prefer one over the
   other.
1. **First check whether another session under `sessions/` is still at
   `status: open` (v1.27).** If so, close it **before** opening the new one:
   derive its summary from its own record and say in the file that it was
   derived. Contract §2 (v1.20) allows only one session open at a time.
   **This is not a new rule but the procedure catching up with the contract.**
   §2 has said since 1.20 that "if an older session is still `open` when you
   open a new one, close it first"; this procedure listed the same check only
   under **closing** (item 11), where it structurally cannot work: closing
   steps only run for a session that closes, yet the thing needing cleanup is
   precisely a session that never closed. The lock was measured — one hub held
   three sessions open at once and the fourth session, opened that same day,
   saw neither
   ([A-2026-08-28-001](artifacts/S-2026-08-28-apk-drive/hub-denetimi.md)).
   The only guaranteed trigger is the **opening** of the next session.
   Create `sessions/<date>-<slug>/session.md` with `status: open`.
   **Write the `author:` field too** (v1.15) — who is running the session. If you
   do not know, ask the user; in a multi-user hub the answer to "who did this"
   starts here. `knowledge/` and `SECURITY.md` records carry no separate
   identity field: their `Source:` field points at a session, so the identity is
   resolved from there — holding the same fact in two places is an invitation
   for the two to drift.
2. Check the `tasks/inbox/` folder:
   - If there are new tasks, tell the user ("there are N new tasks in inbox: …").
   - Handle them as the user instructs; move what you pick up to `active/`.
   - If the user opened a different subject, only report the inbox — do not
     process it on your own.
3. Look at `BACKLOG.md`; recall unfinished work.
   **Compare the contract against the master** (`SYSTEM.md` §10) — one command,
   picking the file for your hub's language (v1.21):
   `curl -fsSL https://raw.githubusercontent.com/afgover/takip/main/hub/SYSTEM.en.md
   -o /tmp/SYSTEM.master.md && diff /tmp/SYSTEM.master.md hub/SYSTEM.md`.
   If the request fails, the check **did not run**; do not read that as "I am up
   to date" and do not write "checked" in the record.
4. **Look at the date of the last `scan` record in `SECURITY.md` (§12).** If it
   is older than 30 days — or missing entirely — run the dependency and
   vulnerability scan appropriate for the project and write the result as a
   `scan` record. A scan is not a one-off approval: it reflects the advisory
   database of the day it ran, and the sentence "we scanned it" silently turns
   false over time unless it is repeated.
   Keeping the trigger in **the record itself** rather than a calendar is
   deliberate: the reminder sits in the hub, so it stays visible even when
   forgotten.
   *(In the `takip` project the runner is `tool/scan.sh`. In other projects the
   equivalent is that project's package manager; the result must be
   **verified** — a version with a known hole is never written up as "clean"
   without asking, L-035.)*

   **Verify the clock with the same request (v1.27).** If the response's
   `Date:` header and the machine's date do not show the same day, **stop
   before writing any record** and tell the user:
   `curl -sI https://github.com | grep -i '^date:'` against `date -u`.
   The reason was measured ([L-052](knowledge/lessons.md#L-052)): the **whole**
   hub hangs on dates — session ids, task dates, plan stamps, and §12's 30-day
   scan trigger. All of them come from the machine's clock, and that clock can
   be silently wrong (after sleep, before NTP resyncs). A wrong date raises no
   error anywhere, looks internally consistent, and a clock running behind
   pushes the security reminder back with it. **It cannot be seen from inside
   the hub** — that needs an outside reference, and since the request is made
   anyway, it costs nothing.

4b. **Run the hub audit (v1.27).** The scan looks at the code; this looks at
   **the hub itself**. Every check came from a real case: a repeated ID (the
   same `T-` number on three different jobs), an `id: pending` that escaped
   `inbox`, a session closed with an empty `## Özet`, a task closed with an
   empty `result`, a session left open, a stale `scan`, and a record dated
   ahead of its own commit. None of them reads prose; all of them read the git
   graph and the file state — because the party writing the record is the
   party being audited, and "done" is not a measurement.

   Runner: [`tool/audit.sh`](../tool/audit.sh) in `afgover/takip`, which runs
   against **any hub** via `--hub <path>`. If you cannot reach the script, do
   the checks by hand and write down which ones you could not do — same rule
   as item 3's `curl`: a check that did not run is never written up as one
   that did.

5. **Check the transitional rules (`SYSTEM.md` §13).** If the section is empty,
   skip it. If an entry's "who it concerns" line matches your hub, apply it and
   tell the user what you did. These are not permanent rules; they end when the
   master copy deletes them.

## During the session (at every exchange)

> **The 30-minute rhythm (v1.23).** While work is happening, at most every 30
> minutes: (a) update `session.md`, `BACKLOG.md` and the knowledge records and
> **push** — the session stays `open`, the summary waits for close; (b) look at
> `tasks/inbox/` and tell the user about new tasks. Repeat the inbox check when
> the user returns after a gap longer than 30 minutes, or when the session
> continues after compaction. At most 30 minutes of work may be lost; the
> `reconstructed` exception should stop being needed.

> **When assigning an ID (v1.15).** Run `git pull --rebase` **right before**
> issuing a new `T-`, `B-`, `L-`, `SK-`, `R-`, `SEC-`, `K-` or `A-` number, and
> push **right after**. The counters are single, and if two agents work at the
> same time they both pick the same number; because the files differ, git does
> not treat it as a conflict and nothing errors. Narrowing the window is
> therefore the procedure's job. If a collision happens anyway, the test that
> reads the hub catches it; the fix is to renumber one of them.
>
> Derive the number from **the largest one in the file**, not from memory. A
> collision can occur without concurrency too: in a long session the answer to
> "what was the last number I gave" lives only in the file (on 2026-08-06 B-111
> was issued twice in exactly this way).

4. Append **every user message and every one of your replies** to `session.md`
   immediately — do not save them up for the end. User messages go in unabridged;
   agent replies are summarised around decisions, findings and work done, with
   long output going to an artifact.
5. Save **every file you produce** that is a report, plan, analysis or info
   document under `artifacts/<session-id>/` with its frontmatter, and add it to
   `session.md`'s `artifacts:` list.
6. When a backlog entry is finished, check it off in `BACKLOG.md`
   **immediately** (date + link). If new work surfaced during the conversation,
   add it to the relevant phase.
7. When a new rule, skill or lesson emerges, add an ID'd record to the right file
   under `knowledge/`. There is no "I will write it later" — it is written the
   moment it emerges.
7b. **When starting a job of three or more steps, write the plan into
   [`PLAN.md`](PLAN.md)** (contract [§14](SYSTEM.en.md#14)) — *before* carrying
   the steps out, because the tree's job is not to list what is finished but to
   make what is unfinished visible. Each step is ticked the moment it is done; a
   step you give up on is not deleted but struck through **with its reason**.
   One-command work stays out of the tree. The tree replaces no other flow:
   instead of writing the same fact a second time into the backlog or the
   session record, **link** to it. A step line is **short**: it says what was
   done; the reason goes to the record it links to (v1.26).

   **Noticing late is not a licence to skip (v1.26).** If you only realise a job
   was multi-step once it has ended, write the plan *then* and set
   `Derived: true`. Steps are **derived** from the record (session, commit,
   backlog); a step you do not remember is not written. This clause came out of
   measured behaviour: in 1.25 an agent that noticed late had only "make it up"
   and "skip" available, everyone skipped, and the trees stayed empty. An
   incomplete tree beats a false one — but an **empty** tree is worse than both.
7c. **When referring to another record, write it as a link** (contract
   [§15](SYSTEM.en.md#15)): `[SEC-010](SECURITY.md#SEC-010)`. The anchor is the
   record's ID, not the heading text. Link the **first** occurrence of an ID in
   a document; later repeats stay plain.
8. Handle task status changes by moving folders, with the right commit message.
9. **If you are waiting on the user for something, open a task and put it in
   `tasks/waiting/`.** Saying it in chat is not enough: the chat ends and the
   user sees no trace of it on their phone. The rule is — *"if I cannot proceed
   until the user does something, that is a `waiting/` task."* Write what is
   expected in one actionable line under `## Notes` ("generate a fine-grained
   token on GitHub; Contents: Read and write"). Vague expectations ("maybe they
   will look at it some day") do not go into `waiting/`.
   When the user taps **"Done"** in the app a notification task lands in inbox;
   on seeing it, move the original task out of `waiting/` and close the
   notification.
10. **`notes/` is not your business (contract 1.9 §11).** The files there are
   notes the user took for themselves: no ID, no moving, no `result`, no
   "done", no deleting, no editing. You **may read** them as context ("the user
   noted this here") and rely on that in the session record. If a note really
   does contain work, do not open a task on your own — ask the user, and put a
   question in `tasks/waiting/` if needed. The reason is concrete: when the user
   takes a note for themselves, they do not mean to open work for the agent.
11. **Every piece of security work gets a record in `SECURITY.md` (§12).** A
   dependency scan, a permission change, anything touching tokens or identity, a
   data-storage decision, a hole found — all of it. Writing it only in the
   session record is not enough: the answer to "what did we do about this" must
   not scatter across sessions. A hole that is fixed is not deleted; `Status`
   becomes `closed` and how it was fixed is written down.
   **No secrets are written** — a record describes what is protected, not the
   protected thing itself.

## At session closing

9. `session.md`: fill in the `## Summary` section, set `status: closed`.
10. Update the active stage's section in `EVOLUTION.md` (what advanced towards
    the stage's goal in this session, which decisions were made). If the stage
    is finished, close it and open the next one.
11. One final consistency check — ask about **the state of the hub, not your own
    steps**: is every file produced in this session linked from session.md, is
    every finished item checked off in BACKLOG, is there a task left to move,
    ~~and **is there another session under `sessions/` still at
    `status: open`?**~~ **(v1.27) this check moved to item 1** — only a closing
    session ran the closing steps, yet the session needing cleanup was the one
    that never closed. The item had been added after a session stayed open for
    nine days (L-042); measurement showed its right place is the **opening**.
12. Push all changes as meaningful commits. A record not pushed to the hub is a
    record that was never made.

## Invariant rules

- **No work without a record:** no work counts as "done" unless it is reflected
  in the hub.
- **Fidelity to the contract:** do not invent files or formats outside the
  `SYSTEM.md` schema. If a format change is needed, propose it to the user
  first; if approved, increment the `SYSTEM.md` version and record it in
  `EVOLUTION.md`.
- **No deleting:** sessions, artifacts, done tasks and knowledge records are
  never deleted; a record that stops being true is marked by striking it
  through.
- **Respect the app's area:** handle the user's tasks in `tasks/inbox/` only as
  the user asks; do not delete or change them on your own judgement (moving and
  adding notes is fine).
- **Commit discipline:** every commit follows the prefix rules in `SYSTEM.md`
  §8; unrelated changes do not share a commit.
