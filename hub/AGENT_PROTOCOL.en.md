# AGENT_PROTOCOL.md — The Agent's Recording Procedure

*English · canonical copy: [`AGENT_PROTOCOL.md`](AGENT_PROTOCOL.md) (Turkish).
If the two disagree, the Turkish one is correct — see `SYSTEM.md` §10.*

This document is the procedure **every agent session working with this hub must
follow**. Format details are in `SYSTEM.md`; here it is defined *when to do
what*. The procedure holds whatever the session is about.

## At session opening (right after the first message)

> **One command (v1.28, Ö1):** the measurable part of the items below runs in
> a **single call** via [`tool/acilis.sh`](../tool/acilis.sh) — clock,
> contract diff, scan age, open sessions, inbox/waiting, open BACKLOG items
> and the hub audit. The reason was measured
> ([A-2026-08-30-001](artifacts/S-2026-08-30-uc-gorev/token-maliyeti.md)):
> the main cost of opening is the number of turns — every tool call carries
> the whole context again. Two invariants: the script is **the source of the
> digest, not its authority** — drill into the file itself on any doubt; and
> an item shown as "KOŞMADI/did not run" is **done by hand**, never written
> up as checked (L-035). Without the script, run the items one by one; the
> items below are the definition and the script is only their implementation.

> **Sync first (v1.36).** At opening, **before** any record is read from the
> hub and reported to the user, run `git pull --rebase`; `tool/acilis.sh`
> measures whether the local copy contains the remote's latest commit and
> says so if it does not. Every finding read from a stale copy is stale and
> nothing errors — on 2026-10-09 a copy was 225 commits behind and a security
> scan that was really two days old was reported as "32 days, stale". The
> rule was written in 1.34 for Claude Projects hubs only (§16); but **any**
> hub's local copy can fall behind: the phone app writes tasks straight to
> GitHub, and work also runs from other machines or cloud sessions. The
> script was already measuring this in every hub; the rule now matches it.

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
   **Exception — continuation session (v1.35, `SYSTEM.en.md` §2):** if the
   user's first message is only the project name it means "let's continue";
   do not ask what it means. If a session is open, do not close it and do not
   open a new one: append to it under a `### [devam] <date>` heading,
   summarise where it left off, and carry on. If the open session is older
   than 2 days, first ask "continue this session, or close it and open a new
   one?". If no session is open, open a new one as below and summarise where
   the last session left off. The other opening items (2–5) run either way.
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
   - **Event files** (`tags: [comment]` or `[assign]`, contract §4, v1.37)
     are not tasks: they get no ID and are not taken up as work. They are
     applied to their target and moved to `tasks/events/`. Since they carry
     no decision they do not wait for the user's instruction — the one
     exception to the item above — but they are reported separately from the
     task count ("2 comments, 1 assignment applied"). If a comment asks the
     agent for something, applying it is not enough; tell the user as well.
3. Look at `BACKLOG.md` **selectively** (v1.28, Ö2): extract open items with
   `grep -nE '^- \[ \] (\*\*)?B-' BACKLOG.md` (v1.34: also catches backlogs
   that write the item number in bold, `- [ ] **B-123**`) — the whole file (~17k tokens) is not
   read at opening. Two guards: (a) if the pattern returns empty on a
   non-empty file, the format may have changed — **look by hand**, never
   write "no open work"; (b) the lines are summaries: before **acting** on an
   item, read its body — preconditions live there (measured example: B-098's
   "real demand" precondition existed only in its body).
   Recall unfinished work.
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

## In a Projects environment (v1.34)

If there is no `ORTAM.md` at the hub root, skip this section — the hub is
classic and the items above and below apply unchanged. If `ORTAM.md` says
`projects` ([§16](SYSTEM.md#16)) the items stay the same, with only these
differences:

- **Opening:** run `tool/acilis.sh --hub <hub path>` in one call (the
  script lives in a clone of `afgover/takip`). Item 1's "close the session
  left open" applies only to **classic** sessions and to thread sessions
  untouched for **more than 7 days**; another thread's open session is not
  touched.
- **Sync first:** the general rule in the opening block (v1.36); in
  Projects it is needed most often, because several threads share one
  folder.
- **Session record:** every thread opens its own `session.md`
  (`surface: projects`, `thread: <root message id>`) and keeps it at once,
  as in item 4. The inbox/waiting state is reported in the thread's first
  reply.
- **Waiting on the user:** ask in the thread **and** open the `waiting/`
  task from item 9 (with a `thread:` field) — the user may answer from the
  app, offline too.
- **Shared working tree:** re-read a file right before editing it; add
  only your own files to a commit, by path (no `git add -A`); commit right
  after assigning an ID; `git pull --rebase` before pushing.
- **Coordinator (v1.38, [§16](SYSTEM.md#16)):** does not write to the
  hub and opens no session; it hands work over in a brief. The record
  belongs to the thread. The rule lives in the project instructions.
- **Shared code folder (v1.38):** before changing code, check the branch
  and `git status`; if another thread has changes or owns the branch, do
  not switch branches — say so.
- **Plan:** for work that finishes in one thread the thread's status
  checklist is enough; a plan spanning several threads or days goes into
  `PLAN.md`.
- **Closing:** when the thread's work is done (the user took the last step
  or the thread was resolved), the closing items below run for that
  thread's session.

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
>
> **"Largest" is not the neighboring entry (v1.31).** The file is NOT in
> chronological order: newer entries can land in between, so the entry above
> where you're adding often does not carry the largest number. Derive the
> number by scanning the whole file, and check for collisions after adding:
>
> ```
> grep -oE '\*\*B-[0-9]+\*\*' hub/BACKLOG.md | sort -u | tail -1   # largest
> grep -oE '\*\*B-[0-9]+\*\*' hub/BACKLOG.md | sort | uniq -d      # collision
> ```
>
> The second command should return nothing; if it returns something, renumber
> the entry written later and fix its **cross-references in the body** too.
> The same pattern applies to the other counters — substitute `T-`, `L-`,
> `SK-`, `R-`, `SEC-`, `K-`, `A-` for `B-` and look at the relevant file. `T-`
> counters live in task files' frontmatter, so the pattern there is
> `^id: T-[0-9]+` (on 2026-09-19 `vault_takip` issued B-123/B-124 twice this
> way — the rule was already there, what was missing was where to look for
> "the largest").

> **Search when you enter a topic (v1.33).** Before starting a job, decision
> or proposal, search what the hub already says about it:
> [`tool/ara.sh`](../tool/ara.sh) `<topic words>` (`--hub <path>` for another
> hub). **Read the body** of the top results; the line is a summary. The reason
> was measured: the hub is strong at writing and weak at reading back — more
> than half of the artifacts are never mentioned again after the day they were
> born ([B-145](BACKLOG.md#B-145)), the lesson and backlog files run to tens of
> KB, and grep neither ranks nor understands Turkish suffixes and letters. The
> script runs without a service: each run reads the hub and builds BM25 in
> memory; a query typed on an English keyboard finds Turkish text. If a result
> is marked `[yerine geçildi → ...]` (superseded) or `[geçersiz]` (invalid),
> move on to the record the mark points to. Not run at opening — its cost pays
> off once the topic is known. If you cannot reach the script, search with
> `grep -ri` and keep in mind that the search was unranked.

4. Append **every user message and every one of your replies** to `session.md`
   immediately — do not save them up for the end. User messages go in unabridged;
   agent replies are summarised around decisions, findings and work done, with
   long output going to an artifact.
   **In Claude Code this item is also enforced by a hook (v1.33):**
   [`tool/hub-guard.sh`](../tool/hub-guard.sh) `--stop` stops the agent once at
   the end of a turn if the open session's record was not updated during that
   turn. Left to memory, the rule was broken in two sessions in a row
   ([L-059](knowledge/lessons.md#L-059)). Where the guard is not installed the
   item applies unchanged.
5. Save **every file you produce** that is a report, plan, analysis or info
   document under `artifacts/<session-id>/` with its frontmatter, and add it to
   `session.md`'s `artifacts:` list.

   **The writing format is binding (v1.29, [§3](SYSTEM.md#3)).** Artifacts are
   read in the app on a phone, and the rules were derived by measuring that
   renderer's limits: markdown (HTML is not drawn), at most three heading
   levels, at most three columns per table, no paths or code inside cells,
   markers from the ASCII vocabulary (`[BLOCKER]`, `[MISSING]`, `[DONE]`,
   `[UNVERIFIED]`, `[RISK]`, `[DECISION]`), no emoji, lines under 80
   characters. Run [`tool/artifact-lint.sh <file>`](../tool/artifact-lint.sh)
   before committing; if the script is unavailable, walk §3's checklist by
   hand and **write in the record that it could not be run**.

   **No output longer than a screen is left in the chat.** A report,
   comparison or review becomes a file first; the user gets the link and a
   summary of at most five lines. The reason is structural, not stylistic:
   chat does not enter the hub, files do. An unwritten report never happened
   as far as the next session is concerned.
6. When a backlog entry is finished, check it off in `BACKLOG.md`
   **immediately** (date + link). If new work surfaced during the conversation,
   add it to the relevant phase.
7. When a new rule, skill or lesson emerges, add an ID'd record to the right file
   under `knowledge/`. There is no "I will write it later" — it is written the
   moment it emerges. If the new record refines or extends an older one, also
   write the `Superseded by:` field on the older record ([§5](SYSTEM.md#5),
   v1.33).
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

   **A task born directly in `done/` (v1.32).** The `inbox → active → done`
   flow makes sense when there's a **handoff gap** between the request being
   seen and being picked up. If the user asks for something in a live
   session and the agent finishes it **in that same session**, no such gap
   ever exists; writing the task file to `inbox/` first only to immediately
   move it to `active/` and then to `done/` doesn't do anything but mimic
   the flow. In that case the file can be created directly in `done/`, with
   full frontmatter (including `result`). The test is **whether a handoff
   happened**, not where the request came from — if the user opens a task
   and it's left pending (a different `assignee`, or the agent can't finish
   it), the flow starts from `inbox` as usual.
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

- **GitHub Actions limit reached: run the gates locally (v1.40, main
  rule):** the user is on GitHub's free plan. Actions minutes are shared
  across the account and reset at the start of each month. If a CI job fails
  within seconds without getting a runner (`runner_id: 0`, no steps, log 404;
  GitHub's message "recent account payments have failed or your spending
  limit needs to be increased") and **other projects'** latest runs or `main`
  fail the same way, the limit is used up. The failure is not in the code:
  1. Run the gates CI runs **locally**: the project instructions' full
     regression command, type check, analysis and tests, plus the build when
     the work affects packaging. Do everything you can on your own machine.
     Write the result in one PR comment and in the session record.
  2. Red CI then does not hold the work and is not a blocker on its own. But
     the record says "CI did not run (Actions limit), gates passed locally";
     it never says "CI green". Work is not done until the local gates pass.
  3. While the limit is reached, no re-runs, empty commits or PR close and
     reopen: the result does not change. When the limit resets at the start
     of the month, re-run the failed jobs of open PRs once.
  4. If only one project fails, or a job gets a runner and fails in a step,
     it is not the limit; find the root cause.

  *Measured case (2026-10-22):* in Copilot, PR #10, #11 and `main` jobs
  failed in 2–3 s with no logs. The user: "I'm on the free plan right now;
  if work stopped in every project, the limit is full; carry on yourselves
  as far as possible" (`Copilot#S-2026-10-22-rota-degisikligi-navaid`).
- **No sending from the user's email (v1.39, main rule):** nothing is sent
  from the user's email accounts (personal Gmail or any connected mailbox;
  through a connector, SMTP or any other route): no new messages, replies or
  forwards. If it is truly unavoidable, ask the user first and wait for an
  explicit "yes"; an earlier permission does not cover the next one. Email to
  members or customers goes only when the user asks, through the project's own
  sending channel (portfoy.info: Resend as contact@portfoy.info,
  `financer#R-013`).

  *Measured case (2026-10-19):* an apology email to a member was sent from the
  user's personal address through the Gmail connector. The user: "don't send
  anything from my email; if it is really needed, ask without fail"
  (`financer#S-2026-10-19-sifre-sifirlama-ekrani`).
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
- **Repo prefix on record numbers (v1.30):** inside your own hub, IDs are
  written **bare** (`B-219`); when referring to another hub, they carry a
  **prefix** (`financer#B-219`). Number spaces are per hub: the same number
  means two different pieces of work in two hubs.

  *Measured case (2026-09-06):* in `DataSources`, `B-219` was a watchdog fix;
  in `financer` the same number was a lot-splitting fix. financer wrote a bare
  `B-219` to the other side and the two were confused. Neither side had broken
  the rule **inside its own hub** — the rule was missing only for **writing
  across**. The convention was in effect but was never written down.

  An unwritten convention, even one in active use, does not exist for whoever
  arrives next.
