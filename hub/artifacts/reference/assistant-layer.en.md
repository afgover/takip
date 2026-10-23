---
id: A-2026-10-24-002
session: none
type: info
title: "The assistant layer — running several hubs on your own"
created: 2026-10-23T23:50:00Z
contract: "1.41"
language: en
translated_from: hub/artifacts/reference/asistan-katmani.md
---

# The assistant layer

## Summary

An example layout for someone who runs several projects alone. Each
project keeps its own hub; on top of them sits an assistant that reads the
hubs and plans the day. The assistant owns no project and carries the
user's answers through the app's gate. The binding rules are in
`SYSTEM.md` §17; this document only explains.

## The problem it solves

The tracking method records one project well. As projects multiply, the
bottleneck stops being the record and becomes the user's attention:

- Each hub keeps its own pending questions; nowhere shows the total. The
  app, too, lists pending work only for the active repository.
- Questions pile up and age. In one measured case twelve hubs held 117
  questions, more than half of them older than 30 days.
- Paused projects are quietly forgotten; contract updates do not reach
  them until a session opens there.
- "What should I do today?" is answered by hand every morning, hub by hub.

## Layout

There are four parts; the first two already belong to the method.

1. **Project hubs.** Unchanged. Each project's agent keeps writing to its
   own hub.
2. **The tracking app.** Reading on the phone, answering questions with
   options in one tap, adding tasks and notes.
3. **The assistant's repository.** It carries three things:
   - a registry: which hubs are read, each project's status (active,
     paused, archived), the daily time target;
   - a summary script: refreshes the hubs and produces one briefing;
   - the assistant's own hub, inside the repository under `hub/`.
4. **The conversation surface.** Where you talk to the assistant: a chat
   environment with threads and scheduled tasks (Claude Projects in the
   example). The morning briefing arrives there as a routine.

Decision: instead of writing a new mobile app, the existing chat
environment was used. What was missing was not an interface; it was the
logic that reads the hubs and prioritises. The tracking app stays for
reading and quick answers.

## Daily flow

1. **Morning, routine.** The summary script refreshes every hub with
   `git pull --ff-only` and produces the briefing: inbox, desk work,
   questions to answer on the phone, a project board, a weekly reminder
   for paused projects. This run opens no session (§17).
2. **During the day, phone.** Questions that carry `options` are answered
   in one tap in the tracking app. The briefing lists them separately, so
   short breaks away from the desk are used too.
3. **At the desk.** Work that needs a computer. The briefing proposes the
   first three by priority and age; the daily time target lives in the
   registry.
4. **If the answer goes to the assistant.** When the user says "B for that
   question" in the chat, the assistant writes the answer into that
   project's `tasks/inbox/` folder, in the app's schema and with the field
   `via: asistan`. The project's agent handles it at its next session as
   if it came from the app.

## The write boundary and why

In another hub the assistant moves no task, assigns no ID, ticks no
backlog item and opens no session. The reasons:

- **Ownership.** A project's record belongs to that project's agent. Two
  writers collide in the same files and counters (`T-`, `B-`) get issued
  twice.
- **An audited gate.** The app's write area (`tasks/inbox/`, `notes/`) is
  already narrow, conflict-free and the place every agent reads at
  opening. The assistant opens no new channel.
- **No copies.** Projects' questions are not copied into the assistant's
  `waiting/` folder; a question held in two places gets two answers.

## Setup

1. Open a repository for the assistant. If it is personal, keep it
   **private**: the summaries carry the contents of several hubs.
2. Install the hub inside the repository (`hub/`) with
   `setup-instruction.en.md`. If you work with Projects, `ORTAM.md` says
   `projects`.
3. Write the registry: for each hub, the path of its local clone and the
   project's status.
4. Write the summary script: refresh, read, sort, write. It never writes to
   project hubs.
5. Set up the morning routine. The output goes to the chat and is not
   committed.
6. Add the assistant's repository to the tracking app as well; make sure
   your token covers it.

## Pitfalls

- **Stale clones.** A number read from a hub that could not be refreshed
  is wrong and raises no error. The summary must mark such hubs clearly.
- **Schema drift.** Hubs drift from the schema over time (e.g.
  `priority: medium`, a `created` without a time). The reader should be
  tolerant, report the drift and not fix it.
- **Priority inflation.** Every agent sets `high` by its own measure;
  across hubs, priority alone is not enough to sort. Age and the deadline
  (`due`) count too.
- **Repeated answers.** One question can be answered from the app and from
  the assistant. The assistant checks the inbox before writing; on a
  conflict the agent asks the user (§4).
- **Routine noise.** A routine that opens a session every morning produces
  hundreds of empty records a year; a read-only run opens none.
- **CI triggers.** If the hub lives in a code repository, every record
  commit may trigger CI; exclude `hub/**` from the triggers.
- **Privacy.** The briefing is as confidential as the most restricted hub
  it reads.

## Conclusion

The assistant adds no new record type to the method; it reads the hubs
that already exist and manages the user's attention. The only thing it
writes is the user's own words, and it writes them through the app's gate.
For a hub without an assistant nothing changes.
