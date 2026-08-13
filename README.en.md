# takip

*[Türkçe](README.md) · **English***

A way of working with an AI agent in which **what was discussed, what was
decided and what was done** does not get lost. It has two parts:

- **The contract** (`hub/SYSTEM.md`) — defines which file the agent writes each
  piece of work to, and in what shape. Session records, tasks, decisions,
  lessons learned, security log.
- **The app** (`lib/`) — a Flutter client for reading those records from your
  phone and assigning the agent work from there.

The carrier between them is **GitHub itself**. No backend, no server, no
account: the app talks directly to `api.github.com` and the data lives in your
own repository.

## Why

Work with an agent long enough and the conversation ends — and "why did we do
it this way" ends with it. Notes scatter, half-finished work is forgotten, and
the next session starts with an agent that knows nothing.

The answer here is simple: **work that is not reflected in the hub does not
count as done.** The agent writes every session, every decision and every task
to the repository; you read it from your phone, open tasks, mark things up and
take notes.

## How it works

```
      phone (Flutter)               GitHub                     agent
  ┌───────────────────┐        ┌──────────────────┐      ┌─────────────────┐
  │ open a task       │──PUT──▶│  <project>_takip │◀────▶│ read, do work,  │
  │ read / mark up    │◀─GET───│    hub/          │      │ record, push    │
  │ take a note       │        │                  │      │                 │
  └───────────────────┘        └──────────────────┘      └─────────────────┘
```

A task's **status is its folder**: `tasks/inbox → active → waiting → done`.
`waiting/` is special — that is where the agent waits for something from you,
and it shows up on your phone instead of disappearing into a chat log.

A multi-step job is also written into `hub/PLAN.md` as a **task tree**: which
step is done, which is still open, which was cancelled and why. The session
record tells you what was discussed; the tree shows at a glance where the work
currently stands.

The app can write to only two places in the hub: `tasks/inbox/` (the agent's
work queue) and `notes/` (your own notes). This is not left to a runtime check —
the write gate takes a file *name*, not a path, and picks the folder from a
closed set.

## Language

A hub has **one language**, chosen when it is set up. Three things follow it:
the contract (the agent's reference), the app's interface, and every record
created from then on. It is declared in the `**Hub language:**` field of
`hub/SYSTEM.md`.

The reason the option exists is so that people who speak other languages can use
this. Changing it later does not act retroactively — existing records stay in
the language they were written in.

> **What "English" covers, stated plainly:** the contract
> ([`SYSTEM.en.md`](hub/SYSTEM.en.md)), the protocol
> ([`AGENT_PROTOCOL.en.md`](hub/AGENT_PROTOCOL.en.md)), this README and the
> [setup instruction](hub/artifacts/reference/setup-instruction.en.md) are all
> available in English, and an English hub fetches the English variants.
>
> The Turkish copies remain **canonical**: if the two disagree, the Turkish one
> is correct and the English one has a translation bug. Not because it is
> better — because a system with two authorities drifts, and nobody notices
> while it does.
>
> Still Turkish inside an English hub: the category **values** stored in records
> (`gorev`, `duzeltme`, `tartisma`…). Those are data, not prose — translating
> them would leave one hub carrying two spellings of the same category. The app
> shows their labels translated.

## Repository layout

This repository hosts itself: the app's code and the takip project's own hub
live in the same place.

| Location | Role |
|---|---|
| `lib/` | App code |
| `hub/SYSTEM.md` | The format contract — **master copy**, other projects update from here |
| `hub/SYSTEM.en.md` · `hub/AGENT_PROTOCOL.en.md` | The English variants an English hub fetches |
| `hub/AGENT_PROTOCOL.md` | The agent's recording procedure |
| `hub/artifacts/reference/setup-instruction.en.md` | Setup instruction for a new project (English) |
| `hub/` (the rest) | This project's own memory: sessions, tasks, backlog, lessons |
| `tool/install.sh` | In-place install to a device (does not wipe data) |
| `tool/scan.sh` | Security scan: vulnerabilities, secrets, Android config |

Each project is tracked in **its own** repository: `<project>_takip`, with the
hub content under that repository's `hub/` folder.

## Using it on your own project

1. Create a private `<project>_takip` repository on GitHub.
2. Scope your token to it (fine-grained, Contents: Read and write).
3. Hand your agent
   [`setup-instruction.en.md`](hub/artifacts/reference/setup-instruction.en.md)
   as-is. It will do the rest — for a brand-new project as well as one with
   history (which it reconstructs from evidence and records with
   `reconstructed: true`).
4. Add the repository in the app.

## Running it

```bash
flutter pub get
flutter test
flutter run
```

To install on a device, use this instead of `flutter install`:

```bash
bash tool/install.sh
```

That script only ever runs `adb install -r` and never uninstalls the package —
`flutter install` falls back to uninstall-and-reinstall on failure, which wiped
the token stored on the device.

## Status and limits

Version 0.1.0. In daily use, but written with **single-user assumptions**:

- **Android** only; iOS has never been tried.
- Authentication is a **personal access token**. It is kept only in the device's
  secure storage and never written to a file, a commit or a log. The app warns
  when given a classic (`ghp_`) token but **cannot tell whether a fine-grained
  token was created with "All repositories"** (`SEC-012`, an open record). For
  general distribution the right answer is a GitHub App / OAuth, tracked as
  `B-061`.
- The offline copy on the device is unencrypted (`SEC-007`, a consciously
  accepted risk). Cloud backup of it is switched off (`SEC-009`).
- Release builds are still signed with the Android **debug** key (`SEC-010`) —
  fine for installing on your own device, not for sharing a build.

The full security history is in [`hub/SECURITY.md`](hub/SECURITY.md): measures
taken, known holes and outstanding work, all in one place.

## Contract version

Currently **1.25**. Every hub carries its own copy, and at each session opening
the agent compares it with the master and updates if it is behind
(`SYSTEM.md` §10). If the versions match but the content differs — divergence —
nothing is overwritten: that is a case a version-number-only check cannot see,
and it has actually happened.

## Development

Layers point one way: `lib/github/` (pure GitHub REST) → `lib/hub/` (the
contract layer) → `lib/features/` (screens). `github/` knows nothing about the
contract; `hub/` knows nothing about the UI.

`TODO(B-0xx)` markers in the code map to entries in `hub/BACKLOG.md`. Lessons
learned are numbered `L-0xx` in `hub/knowledge/lessons.md`, and code comments
cite those numbers — so you can read why a given line is written the way it is.

## Licence

MIT — see [LICENSE](LICENSE).
