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
plan scratchpad leading with the plan, with the research it rests on in an appendix. No Solo
todos are created here; work items are grouped into tasks when `/implement` starts, or become
tracker issues if you `/stash`.

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
`### Research` in the appendix, then `scratchpad_archive` the source. Archiving hides without
deleting, so it stays recoverable. Add anything new your investigation turned up.

## Gate B — Grill the user

Follow `/grill`. One question at a time, each with a recommended answer, waiting for a response
before continuing. Do not batch.

When the remaining questions are details the user would rather see than specify, propose
defaults, flag them as proposals, and move to gate E.

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
`target={"type":"section","section_heading":"## ..."` or `"### ..."}` and the current `expected_revision`; on
a mismatch, re-read and retry.

```
# <Feature or task> Plan

**Repos**: `<name>` — <absolute path>

One line per repo when more than one is in scope.

## Overview
<the outcome we're after, why, and how we will know it was achieved>

## What We're NOT Doing
<explicit non-goals, to stop scope creep>

## Work item: <name>
**Files**: `path/one.ext`, `path/two.ext`

`path/one.ext` — <what changes and why>
`path/two.ext` — <what changes and why>

### Verification
#### Automated:
- [ ] <runnable command>

#### Manual:
- [ ] <what a human must check>

---

## Work item: <name>
**Files**: `path/three.ext`
**Constraint**: same-worker as <other item>

<same structure>

## Appendix

### Research
<absorbed and newly gathered findings — current state, architecture, each with `file:line`>

### References
- Research absorbed from: <pad name and id, if any>
```

The plan leads and the evidence follows. One `**Repos**:` line carries the absolute path
`/implement` needs to place its workers. Each item verifies itself — there is no separate testing
section, so unit, integration, and manual checks all go under that item's `### Verification`.

**A work item is a coherent change, not a unit of execution.** It says what changes and why.
How many workers run it, in what order, on which model — that is scheduling, it depends on
facts that only exist at execution time, and `/implement` decides it. Do not group items to
suit a worker count, and do not number them to imply sequence.

Rules the rest of the workflow depends on:

- **`**Files**:` must list every path the item will touch.** `/implement` computes worker
  grouping and wave parallelism from these, and a worker writing an undeclared path is treated
  as a deviation. This is the one field that cannot be inferred later.
- **`**Constraint**:` is optional and has exactly two forms.** `same-worker as <item>` when two
  items must not drift apart — a shared clause that has to stay byte-identical, a rename and its
  call sites. `after <item>` for a genuine dependency, such as documenting a result. Anything
  else is scheduling and does not belong here.
- **An item spanning two repos must be split.** Each item belongs to exactly one repo in the
  `**Repos**:` list.

## Gate E — Approval and fork

Optionally run `/critique plan/<slug>` first and fold in what survives.

Present the design — the work, its file scopes, and any constraint that ties two items together:

```
Plan: plan/<slug>  (id <n>)

  <name>            rules/*.md
  <name>            skills/*.md        same-worker as <name>
  <name>            README.md          after everything above

  Not included: <thing> (<why>)

Approve the plan?
```

**No waves, no worker count, no models here.** Those are computed at decomposition from facts
that are current at that moment, and `/implement` gates them separately. A plan that fixes the
schedule forces an approval on evidence nobody has yet.

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
  `/implement`, which decomposes the work items into workers and gates that roster separately.
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
