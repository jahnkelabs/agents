---
name: stash
description: Move active work out of Solo and into a durable tracker
argument-hint: '[plan/<slug> | "an idea"]'
disable-model-invocation: true
effort: medium
---

# Stash

Solo holds what you are actively working on. A tracker holds what outlives the session — an
idea to return to, or a large plan whose phases each get their own cycle later.

`/stash` moves work across that boundary. It is always explicit; nothing stashes on its own.

## Step 1 — Resolve what to stash

| `$ARGUMENTS` | Payload |
|---|---|
| *(empty)* | the active plan pad; if several, list them and ask |
| `plan/<slug>` or a pad id | that pad |
| a quoted string | a loose idea, no pad involved |

## Step 2 — Resolve the tracker

Check which tracker MCPs are connected and read the matching adapter in
`~/.claude/references/` — `linear.md`, `jira.md`, and so on. The adapter defines that tracker's
object model and field mapping; this command owns the semantics.

One tracker available: use it, and say which. Several: ask. None: stop and say so — there is
nowhere to stash to.

## Step 3 — Propose the shape, and confirm

Shape follows the payload:

**A loose idea** → one issue. No project, no milestones.

```
Stash to <tracker>:

  issue  "<title>"
    team        <team>
    state       <triage/backlog state>
    description <the idea, plus where it came from>

Confirm?
```

**A phased plan** → a project, a document holding the plan body, and one issue per phase with
dependencies preserved.

```
Stash to <tracker>:

  project   "<plan title>"
  document  plan body (research + plan)
  issues
    ☐ Phase 1: <name>          <repo>
    ☐ Phase 2: <name>          <repo>   blocked by Phase 1
    ☐ Phase 3: <name>          <repo>   blocked by Phase 2

Confirm?
```

Read phases **from the pad**, not from Solo todos — an approved plan that was never implemented
has no todos.

Nothing is written before the user confirms. These are real objects in a shared system;
cleaning them up is more work than declining a proposal.

## Step 4 — Write

Follow the adapter. Create parents before children, then set dependencies once every issue has
an id. Verify the dependency graph after writing — most trackers model these as directed
relations that are easy to set backwards.

If a write fails partway, stop and report exactly what was created. Do not retry blindly and do
not roll back silently.

## Step 5 — Clean up Solo

The work has left the active set.

1. Append the refs to the pad so it records where the work went:
   ```
   ## Stashed
   <date> → <tracker>
   project  <ref or name>
   <ID>     Phase 1: <name>
   <ID>     Phase 2: <name>
   ```
2. `scratchpad_archive(scratchpad_id=<pad>)` — hidden, not deleted, recoverable
3. **Delete phase todos only if they exist.** A freshly approved plan has none. A plan stashed
   mid-implementation does — `todo_delete` each one. Do not mark them complete; the work did
   not get done, it moved.
4. `kv_delete` every `plan:<slug>:*` key
5. If a branch exists with committed work, say so and leave it alone. Stashing the plan does
   not discard code.

## Step 6 — Report

The pad already holds every ref. In chat, say what was written, where it went, and what the user
can do next — not the per-phase list again:

```
Stashed to <tracker> — project <link>, <N> phase issues, refs appended to the pad.
Solo: pad archived, <N> todos removed. Recall any of it with /recall <ID>.
```

## Notes

- Never stash without confirming the shape first
- Phases come from the pad, todos are incidental
- Archiving is reversible; deleting todos is not, which is why todos are the smaller loss
- A stash is not a commit — code already committed to a branch stays there
