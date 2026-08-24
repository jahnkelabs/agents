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
plan scratchpad. It leads with the plan and keeps the research in an appendix. This skill
creates no Solo todos. `/implement` composes the slices into milestones when it starts, or
`/stash` turns them into tracker issues.

## Input

`$ARGUMENTS` may contain any of:

- A topic or question — plan from scratch
- A research pad (`research/<slug>` or a numeric id) — from a standalone `/research`
- File paths — read fully before anything else
- A recall payload — when invoked by `/recall`

With no arguments:

> What should I plan? Give me a topic, a research pad from `/research`, or relevant context.

## Gate A — Scope and investigation

Do a cheap first pass before you propose anything. Read mentioned files fully, resolve each
repository's container path, and skim enough to form a real proposal.

**Resolve the container with the one derivation `/worktree` states.** See
`skills/worktree/SKILL.md`, under `## Derive the container from any worktree`. Use it verbatim and
write no second copy. `git rev-parse --show-toplevel` is the wrong command here: it returns
`<container>/main` in a converted repository, and `/worktree cut` then refuses the container as a
plain clone.

**Solo project:** run `list_projects` and use **whichever project is currently selected**. No
path matching, no assumed name. State it in the gate.

**Target repos:** infer, and show your evidence for each. Draw on the current repo and on the
repos a research pad's target list names. Draw on repos implied by `file:line` references in
findings, and on the `path` of each known Solo project. Say what you excluded and why.

**Tree staleness:** run a real `git fetch` in each repo in scope. Report how far each tree sits
behind its default branch, as a number of commits. Report `0` for a current tree. A claim that
the tree is current is not a number, so it does not count.

**Investigation:** describe what you intend to look into, not a tier. If the user supplied a
research pad, read it fully first. Scope the investigation to the gaps, and do not re-derive
what you already know.

**Decisions:** name each decision you expect to put to the user at gate B. A list of decisions
tells the user what the grilling costs. A count of questions does not, and the count ran 1.43×
low across twenty runs.

**Approve — /plan scope**

```
Before I investigate — confirm or adjust:

  Solo project: <name>  (<path>)

  Repos in scope:
    <repo>  ─ <evidence>                    <N> commits behind <default>
    <repo>  ─ <evidence>                    <N> commits behind <default>

  Not included: <repo> (<why>)

  I plan to investigate (<N> parallel Solo agents):
    1. <specific question>
    2. <specific question>

  Decisions I expect to put to you:
    1. <the decision, in a phrase>
    2. <the decision, in a phrase>

Accept this scope, or tell me which repo or question to add or cut.
```

⏸ waiting on you: accept the `/plan` scope, or name what to change

## Research phase

Run the confirmed investigation following `/research`, including its worker protocol. Spawn one
Solo agent per area and join them with an idle timer, per `solo-agent-orchestration`. Workers
document what exists and write only their own per-area scratchpad; you own the plan pad.

**If the user supplied a standalone research pad:** absorb its content into the plan pad under
`### Research` in the appendix. Then `scratchpad_archive` the source. The archive hides the pad
without deleting it, so the pad stays recoverable. Add anything new your investigation found.

## Gate B — Grill the user

Follow `/grill`. Ask one question at a time, and wait for the answer before you ask the next.
`rules/chat-vocabulary.md` gives the shape of a question, including the mandatory
recommendation. Point at that rule rather than restating it, and never batch two questions.

**The heading opens the gate once.** The first question carries `Deciding` for a choice, or
`Approve` for a proposal you already formed. Every later question inside this open gate carries no
heading. A grilling asks many questions, and one heading each would stop the heading staying rare.

**Every question carries the footer**, whether or not it carries a heading. Every question waits
for the user, and the footer is the only mark that says so.

The remaining questions may turn out to be details the user would rather see than specify. In
that case, propose defaults, flag them as proposals, and move to gate E.

## The census

Run the inbound-reference census before you write the pad. It is a required step, not a
thoroughness reminder. Every slice must declare every path it touches. The census finds the
paths you did not think of.

Take each file a slice changes, and each symbol it renames or removes. Search for three kinds of
inbound reference:

```
caller     every site that imports, calls, includes, or spawns the thing you change
test       every test that exercises it, by name or through its public entry point
standard   every rule, ADR, README, or skill whose text your change makes false
```

Record every path the search returns in that slice's `**Files**:` list. A hit in another
repository belongs to another slice, because a slice covers exactly one repository.

The third kind is the one that gets missed. A change to a rule falsifies the README table that
describes it. No import points from one to the other, so grep the prose as well as the code.

Nineteen of thirty sessions shipped an incomplete `**Files**:` list, and one run reported ten
affected waves of fourteen. The census now decides what ships in parallel, not only who edits
what. `/implement` composes milestones from slices, and file overlap between two milestones
forces them into sequence.

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

**Repos**: `<name>` — <absolute container path>

One line per repo when more than one is in scope. The path is the container gate A derived, not
`<container>/main`.

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

The plan leads and the evidence follows. One `**Repos**:` line carries the container path
`/implement` needs to cut each milestone's worktree. Each slice verifies itself. There is no
separate testing section, so unit, integration, and manual checks all sit under that slice's
`### Verification`.

**A work item is a slice.** A slice is narrow and vertical: one coherent change, in exactly one
repository, that stands on its own. It says what changes and why, never who runs it. Worker
count, order, and model belong to the schedule. That schedule rests on facts that exist only at
execution time, so `/implement` decides it.

Shape each slice so `/implement` can compose milestones from it:

```
  slice       one worker's unit of work. Narrow, vertical, one repository.
  milestone   a consumable chunk of a plan, sequenced in a DAG. May span
              repositories. The unit of delivery.
  wave        the concurrency schedule inside a milestone, from file overlap.
```

A plan declares slices and nothing above them. `/implement` groups slices into milestones,
orders the milestones, and schedules each milestone's waves. Do not group slices to suit a worker
count, and do not number them to imply sequence.

Rules the rest of the workflow depends on:

- **`**Files**:` must list every path the slice will touch.** The census above is how you get
  that list right. `/implement` computes milestone boundaries, worker grouping, and wave
  parallelism from these. A worker that writes an undeclared path deviates from its task. This is
  the one field nobody can infer later.
- **`**Constraint**:` is optional and has exactly two forms.** Use `same-worker as <item>` when
  two items must not drift apart. Two examples: a shared clause that has to stay byte-identical,
  and a rename and its call sites. Use `after <item>` for a genuine dependency, such as
  documenting a result. Anything else is scheduling and does not belong here.
- **`after` also feeds the milestone DAG.** `/implement` aggregates every `after` in the plan
  onto the milestones that hold the two slices. That aggregate becomes the order the milestones
  ship in, so an `after` you add for convenience delays delivery.
- **Split any slice that spans two repos.** Each slice belongs to exactly one repo in the
  `**Repos**:` list. A slice that straddles two repositories joins neither milestone cleanly.

## Gate E — Approval and fork

Optionally run `/critique plan/<slug>` first and fold in what survives.

Present the design — the slices, their file scopes, and any constraint that ties two together:

**Approve — `plan/<slug>`**

```
Plan: plan/<slug>  (id <n>)

  <name>            rules/*.md
  <name>            skills/*.md        same-worker as <name>
  <name>            README.md          after everything above

  Not included: <thing> (<why>)

Approve the plan?
```

⏸ waiting on you: approve `plan/<slug>`, or name the slice to change

**No milestones, no waves, no worker count, no models here.** `/implement` composes and
schedules those at decomposition, against facts that are current then, and gates them
separately. A plan that fixes the schedule forces an approval on evidence nobody has yet.

Iterate on feedback and update the pad each time. **Do not proceed past this gate without
explicit approval.**

Once the user approves:

**Deciding — what happens to `plan/<slug>`**

```
Plan approved. What next?

  1. Implement now   — I'll confirm critique models and start
  2. Stash for later — park it in a tracker via /stash
  3. Leave active    — pad stays in Solo; run /implement plan/<slug> whenever
```

⏸ waiting on you: pick one of the three for `plan/<slug>`

Recommend one of the three, and say why. `rules/chat-vocabulary.md` makes the recommendation
mandatory.

- **Implement now** — ask which models should run the critique (see `/critique`), then hand to
  `/implement`. That skill composes the slices into milestones and gates that roster separately.
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
