---
name: research
description: Investigate a codebase with parallel agents and write the findings to a Solo scratchpad
when_to_use: >-
  When the user wants to understand how something works across a codebase and wants the
  findings written down rather than explained in chat. Trigger phrases: "how does X work",
  "map the Y subsystem", "trace this flow". Read-only.
argument-hint: "[question or area]"
---

# Research

Investigate a codebase and produce a factual map of what exists. This skill runs standalone, and
it is also the research phase inside `/plan`.

## Your only job is to document what exists

- Do NOT suggest improvements, critique the implementation, or propose future work
- Describe what exists, where it lives, how it works, and how the pieces connect
- Your output is a description, not a review

If the user invokes it with no arguments:

> What would you like me to research? Give me a question or an area of the codebase.

## Step 1 — Establish scope, and confirm it

Do one cheap first pass before you spawn any worker. Read any files the user mentioned fully —
no limit/offset. Run `git rev-parse --show-toplevel`, and skim enough structure to form a
proposal.

Determine the Solo project with `list_projects`, then use **whichever project is currently
selected**. Do not match paths or assume a name. Confirm it in the gate, so the user catches a
wrong scope before you write anything.

Check for prior work before you investigate: `scratchpad_list(query="<topic keywords>")`. If an
existing research pad covers this, read it and extend it. Do not duplicate it.

Then present the gate:

```
Before I investigate — confirm or adjust:

  Solo project: <name>  (<path>)

  Repos in scope:
    <repo>  ─ <evidence: current repo / N code refs / named in request>

  Not included: <area> (<why>)

  I plan to investigate (<N> parallel Solo agents):
    1. <specific question>
    2. <specific question>

Accept, or tell me what to add or cut.
```

Scale the investigation to the question. A narrow lookup deserves one agent; mapping a
subsystem deserves several. State what you are *not* looking at, and why. A wrong omission is
easier to catch than a wrong inclusion.

## Step 2 — Investigate

Fan out with Solo agents, per `solo-agent-orchestration`. Never use the host runtime's own
sub-agent mechanism.

Build the slug first — `date +%Y-%m-%dT%H%M` plus a short topic, e.g.
`2026-04-05T1423-jwt-auth`. Workers name their pads under it, and step 4 reuses it.

Resolve the runtime once with `list_agent_tools` and use the Claude entry unless the user named
another. Call `whoami` and keep the returned `process_id` — every worker needs it to signal back.
Then, per confirmed area:

```
spawn_agent(agent_tool_id=<id>, name="research-<area-slug>", extra_args=[
  "--model", "<tier for this area>", "--effort", "<tier for this area>",
  "--permission-mode", "auto",
  "--settings", '{"permissions":{"deny":["Bash(git add:*)","Bash(git commit:*)",
                  "Bash(git push:*)","Bash(git checkout:*)"]}}'])
  → process_id, agent_instructions
send_input(process_id, input=<agent_instructions + the prompt below>)
```

Pass `auto` on every Claude worker, per `solo-agent-orchestration`. A read-only assignment is
not a reason to drop it, and never a reason to raise it to `bypassPermissions`. On a Codex
runtime the equivalent is `--approve-for-me --no-alt-screen`.

Research is read-only, so the deny list costs nothing. It also stops a worker from mutating the
tree it must describe. Tier by area: tracing one call path is not the same job as mapping a
subsystem's conventions.

```
Research one area of: <topic>.

## Working directory
<absolute repo path>

## Your area
<the one specific question this worker owns>

## Your only job is to document what exists
Document what IS, not what SHOULD BE. No improvements, no critique, no proposed work.

## Instructions
1. Read the files you need fully — no limit/offset
2. Report file paths, line numbers, and factual descriptions of how the pieces connect
3. Note which repo each finding belongs to when more than one is in scope
4. Write your findings to a scratchpad named "research/<slug>/<area-slug>"
5. Signal completion as your last act:
     timer_set(delay_ms=0, delivery_process_id=<orchestrator process_id>,
               body="Area <area-slug> done. Findings in research/<slug>/<area-slug>.")

## Constraints
- Read-only: no edits, no branches, no commits, no other git write command
- Do not create todos or write KV
- Write only your own scratchpad — the orchestrator owns the research pad
- Stay inside <absolute repo path>
```

Workers signal when they finish. Arm one idle timer per run as the dead-worker fallback only.
The timer has no debounce. It cannot distinguish a thinking worker from a finished one, per
`solo-agent-orchestration`:

```
timer_fire_when_idle_all(processes=[<pids>], max_wait_ms=<generous guard>,
  body="Research guard expired. Any area that has not signalled has died or hung —
        check its scratchpad and process status before synthesizing without it.")
```

Workers write only their own findings pad. You own the research pad.

## Step 3 — Synthesize

On wake, read every worker's scratchpad. Connect findings across components, and keep every
`file:line` reference. Resolve a contradiction by reading the code again rather than by picking
one report.

Then `close_process` each worker and archive its per-area scratchpad — the synthesized pad
replaces them.

## Step 4 — Write the pad

Reuse the slug built in step 2.

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
under `### Research` in the plan pad's `## Appendix`.

```
# Research: <topic>

**Date**: <YYYY-MM-DD>
**Repos**: `<name>` — <absolute path>

## Summary
<the answer to the question asked>

## Current State
- <finding> (`path/to/file.ext:123`)
- <how it connects to the next thing> (`other/file.ext:45-67`)

## Architecture
<patterns, conventions, and design actually found — not recommended>

## Open Questions
<what the code could not answer; omit if none>
```

Every Current State bullet carries an inline `file:line` — that is the only place references
live. Group by repo when more than one is in scope.

## Step 5 — Report

Report the action, the location, and the decision needed. Do not report the findings — the user
reads the pad.

```
Researched <topic> — <N> areas, <N> Solo agents.

  Pad: research/<slug>  (id <n>)

Next: /plan research/<slug> to plan from it, or /critique research/<slug> to challenge it.
```

## Follow-ups

Extend the same pad rather than creating another:

- New material under an existing heading → `scratchpad_append_section`
- A section replacement → `scratchpad_edit` with
  `target={"type":"section","section_heading":"## ..."` or `"### ..."}` and the current `expected_revision`
- A dated addition at the end → `scratchpad_append`

On a revision mismatch, re-read and retry — something else touched the pad.

## Notes

- Read mentioned files fully before spawning anything
- Read-only: no branches, no commits, no code changes
- No todos — research precedes tracked work
- The pad must stand alone. `/plan` may read it in a session that has none of this context
