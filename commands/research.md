---
description: Investigate a codebase with parallel agents and write the findings to a Solo scratchpad
model: opus
---

# Research

Investigate a codebase and produce a factual map of what exists. Runs standalone, and is also
the research phase inside `/plan`.

## Your only job is to document what exists

- Do NOT suggest improvements, critique the implementation, or propose future work
- Describe what exists, where it lives, how it works, and how the pieces connect
- You are drawing a map, not reviewing the territory

If invoked with no arguments:

> What would you like me to research? Give me a question or an area of the codebase.

## Step 1 — Establish scope, and confirm it

Before spending anything, do a cheap first pass: read any files the user mentioned (fully — no
limit/offset), run `git rev-parse --show-toplevel`, and skim enough structure to form a
proposal.

Determine the Solo project with `list_projects`, then use **whichever project is currently
selected** — do not match paths or assume a name. Confirm it as part of the gate so a wrong
scope is caught before anything is written.

Check for prior work before investigating: `scratchpad_list(query="<topic keywords>")`. If an
existing research pad covers this, read it and extend rather than duplicating.

Then present the gate:

```
Before I investigate — confirm or adjust:

  Solo project: <name>  (<path>)

  Repos in scope:
    <repo>  ─ <why: current repo / N code refs / named in request>

  I plan to investigate (<N> parallel agents):
    1. <specific question>
    2. <specific question>

  Skipping: <area> (<why>)

Accept, or tell me what to add or cut.
```

Scale the investigation to the question. A narrow lookup deserves one agent; mapping a
subsystem deserves several. State what you are *not* looking at and why — a wrong omission is
easier to catch than a wrong inclusion.

## Step 2 — Investigate

Spawn the confirmed sub-agents in parallel. Each gets one focused area and returns file paths,
line numbers, and factual descriptions.

Remind every agent: **document what IS, not what SHOULD BE.** Have each note which repo a
finding belongs to when more than one is in scope.

Sub-agents do not write to Solo. They report to you; you own the pad.

## Step 3 — Synthesize

Wait for all agents. Connect findings across components, keep every `file:line` reference, and
resolve contradictions by going back to the code rather than picking one.

## Step 4 — Write the pad

Build a slug from `date +%Y-%m-%dT%H%M` plus a short topic, e.g. `2026-04-05T1423-jwt-auth`.

**Standalone:**

```
scratchpad_write(
  name="research/<slug>",
  tags=["research", "project:<repo>"],
  content=<document below>
)
```

One `project:<repo>` tag per repo in scope. Record the returned `scratchpad_id`.

**Called from `/plan`:** do not create a pad. Return the same content for `/plan` to place
under `## Research` in the plan pad.

```
# Research: <topic>

**Date**: <YYYY-MM-DD>
**Repos**: <repo> (<path>)

## Summary
<the answer to the question asked>

## Current State
- <finding> (`file:line`)
- <how it connects to the next thing>

## Code References
- `path/to/file.ext:123` — <what is there>
- `other/file.ext:45-67` — <what is there>

## Architecture
<patterns, conventions, and design actually found — not recommended>

## Open Questions
<what the code could not answer; omit if none>
```

Group by repo when more than one is in scope.

## Step 5 — Report

Give the user a short summary, the pad name and id, and note that `/plan` accepts either form
as input. Suggest `/critique <path>` if they want the findings challenged.

## Follow-ups

Extend the same pad rather than creating another:

- New material under an existing heading → `scratchpad_append_section`
- Replacing a section → `scratchpad_edit` with
  `target={"type":"section","section_heading":"## ..."}` and the current `expected_revision`
- A dated addition at the end → `scratchpad_append`

On a revision mismatch, re-read and retry — something else touched the pad.

## Notes

- Read mentioned files fully before spawning anything
- Read-only: no branches, no commits, no code changes
- No todos — research precedes tracked work
- The pad must stand alone. `/plan` may read it in a session that has none of this context
