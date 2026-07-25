---
name: plan
description: Research, grill, and produce an implementation plan in a Solo scratchpad
argument-hint: "[topic | research/<slug> | paths]"
disable-model-invocation: true
---

# Plan

Produce an implementation plan grounded in research, shaped by interrogating the user. Be
skeptical, thorough, and collaborative.

Three gates: **scope**, **grilling**, **approval**. The output is exactly one artifact — a
plan scratchpad containing the research above the plan it grounds. No Solo todos are created
here; phases materialize when `/implement` starts, or as tracker issues if you `/stash`.

## Input

`$ARGUMENTS` may contain any of:

- A topic or question — plan from scratch
- A research pad (`research/<slug>` or a numeric id) — from a standalone `/research`
- File paths — read fully before anything else
- A recall payload — when invoked by `/recall`

With no arguments:

> What should I plan? Give me a topic, a research pad from `/research`, or relevant context.

## Gate A — Scope and investigation

Do a cheap first pass before proposing anything: read mentioned files fully, run
`git rev-parse --show-toplevel`, and skim enough to form a real proposal.

**Solo project:** run `list_projects` and use **whichever project is currently selected**. No
path matching, no assumed name. State it in the gate.

**Target repos:** infer, and show your evidence for each. Draw on the current repo, repos named
in a research pad's target list, repos implied by `file:line` references in findings, and the
`path` of each known Solo project. Say what you excluded and why.

**Investigation:** describe what you intend to look into, not a tier. If a research pad was
supplied, read it fully first and scope the investigation to the gaps — do not re-derive what
is already known.

**Question count:** estimate how many questions gate B will ask, so the user knows what they
are in for.

```
Before I investigate — confirm or adjust:

  Solo project: <name>  (<path>)

  Repos in scope:
    <repo>  ─ <evidence>
    <repo>  ─ <evidence>

  Not included: <repo> (<why>)

  I plan to investigate (<N> parallel Solo agents):
    1. <specific question>
    2. <specific question>

  ...and I expect roughly <N> questions for you afterward.

Accept, or tell me what to add or cut.
```

## Research phase

Run the confirmed investigation following `/research`, including its worker protocol: one Solo
agent per area, joined with an idle timer, per `solo-agent-orchestration`. Workers document what
exists and write only their own per-area scratchpad; you own the plan pad.

**If a standalone research pad was supplied:** absorb its content into the plan pad under
`## Research`, then `scratchpad_archive` the source. Archiving hides without deleting, so it
stays recoverable. Add anything new your investigation turned up.

## Gate B — Grill the user

Follow `/grill`. One question at a time, each with a recommended answer, waiting for a response
before continuing. Do not batch.

Look up anything discoverable — filesystem, git, APIs, tools. Only put genuine *decisions* to
the user.

Order questions by dependency: whichever answer changes the most other answers goes first.
Design forks are simply nodes in this tree, not a separate gate. When an answer invalidates
something already settled, say so and revisit it.

Length scales with the work. A two-file change may need one question; a migration may need
twenty. When the remaining questions are details the user would rather see than specify,
propose defaults, flag them as proposals, and move to gate E.

## Write the pad

Slug from `date +%Y-%m-%dT%H%M` plus a short topic.

```
scratchpad_write(
  name="plan/<slug>",
  tags=["plan", "project:<repo>"],
  content=<document below>
)
```

Record the `scratchpad_id`. Revise with `scratchpad_edit` using
`target={"type":"section","section_heading":"## ..."}` and the current `expected_revision`; on
a mismatch, re-read and retry.

```
# <Feature or task> Plan

## Research
<absorbed and newly gathered findings — Current State, Code References, Architecture>

## Overview
<what we're doing and why, in a sentence or two>

## Target Projects
- `<repo>` — <absolute path>

## Desired End State
<the outcome, and how to tell it was achieved>

## What We're NOT Doing
<explicit non-goals, to stop scope creep>

## Phase 1: <name>
**Project**: `<repo>`
**Files**: `path/one.ext`, `path/two.ext`

### Changes Required
**File**: `path/one.ext`
**Changes**: <what changes and why>

### Verification
#### Automated:
- [ ] <runnable command>

#### Manual:
- [ ] <what a human must check>

---

## Phase 2: <name>
<same structure>

## Testing Strategy
<unit, integration, manual>

## References
- Research absorbed from: <pad name and id, if any>
- Key files: <file:line>
```

Rules the rest of the workflow depends on:

- **Exactly one `**Project**:` line per phase.** A phase spanning two repos must be split.
- **`**Files**:` must list every path the phase will touch.** `/implement` computes wave
  parallelism from these, and a worker writing an undeclared path is treated as a deviation.
- **Phases that can run independently must not be written as if sequential.** Ordering is
  expressed by genuine dependency, not by numbering.

## Gate E — Approval and fork

Optionally run `/critique plan/<slug>` first and fold in what survives.

Present the plan together with how it would execute — parallelism is computable from the
declared file scopes and phase dependencies:

```
Plan: plan/<slug>  (id <n>)

Execution shape:
  wave 1 (parallel, 3 workers)
    Phase 1  <repo>  rules/*.md
    Phase 2  <repo>  commands/*.md
    Phase 4  <repo>  README.md
  wave 2 (after wave 1)
    Phase 3  <repo>  — depends on Phase 1

  Serialized: Phase 5 overlaps Phase 4 on README.md

Approve the plan and this execution shape?
```

Iterate on feedback, updating the pad each time. **Do not proceed past this gate without
explicit approval.**

Once approved:

```
Plan approved. What next?

  1. Implement now   — I'll confirm critique models and start
  2. Stash for later — park it in a tracker via /stash
  3. Leave active    — pad stays in Solo; run /implement plan/<slug> whenever
```

- **Implement now** — ask which models should run the critique (see `/critique`), then hand to
  `/implement` with the execution shape already confirmed. Do not re-ask what was just settled.
- **Stash for later** — hand to `/stash`, which proposes the tracker shape and confirms.
- **Leave active** — do nothing. The pad stays in Solo.

## Guidelines

- **Be skeptical.** Question vague requirements and verify corrections against the code rather
  than accepting them.
- **Read completely.** No `limit`/`offset` on context files.
- **Be concrete.** Every claim about current behavior carries a `file:line`.
- **No open questions in the plan.** Research it or ask. An unresolved question in an approved
  plan becomes a deviation during implementation.
- **Separate automated from manual verification.** `/implement` treats them differently.
- **Scratchpads hold documents; todos hold work.** Never duplicate the plan into a todo body.
