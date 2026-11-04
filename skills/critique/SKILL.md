---
name: critique
description: Adversarially review a diff, a concern's documents, or files with one critic agent per lens, and apply the accepted fixes when /implement calls
when_to_use: >-
  When the user wants work torn apart rather than surveyed. Trigger phrases: "what is wrong
  with this", "review this adversarially", "find the bugs", "critique my design". Also invoked
  by the implement skill.
argument-hint: "[target] [--base <ref>] [--concern <map-slug>/<concern>]"
---

# Critique

Try to break something. This is not a survey. Each lens agent answers one question about the
target. A finding must survive a refutation pass before it reaches the user.

This skill is a front end. It resolves the target, the intent, and the output mode.
`references/critique/run.md` runs every lens, and this skill carries no lens text of its own.

It runs standalone. `/implement` calls it on each concern's diff. A pull request belongs to
`/review-pr`, which reads the PR body as intent.

## Step 1 — Resolve the target

| `$ARGUMENTS` | Target |
|---|---|
| *(empty)* | the working tree diff; falls back to `<default>...HEAD` — resolved from `origin/HEAD`, never hardcoded — if the tree is clean |
| a `requirements.md`, `design.md`, or research file path | that document, a target that holds no code |
| one or more paths | those files |
| `--base <ref>` | diff against that ref instead |
| `--pr <N>` | none: say that `/review-pr <N>` reviews a pull request, and stop |

`--concern <map-slug>/<concern>` resolves no target of its own. It carries the intent, per step 2.

State what you resolved before you proceed. If the target is empty — clean tree, no changes —
say so and stop rather than reviewing nothing.

**Resolve the names here.** `run.md` names every pad and process from two segments:

```
  slug   `<map-slug>-<concern>` where a concern resolved. Otherwise a lowercase slug of
         the target: `working-tree`, or the path with `/` as `-`
  pass   the repository name where the concern spans more than one; `concern` for a
         concern in one repository; `standalone` otherwise
```

`/implement` calls this skill once per repository the concern touches. The repository belongs in
the pass, because two repositories in one concern would otherwise write one pad twice.

Omit the pass, and the second call's pads overwrite the first's. `run.md` archives every pad
after the merge, so that overwrite leaves no trace. Tag every pad `transient`, and
`map:<map-slug>` and `concern:<map-slug>-<concern>` where a concern resolved.

**Resolve the runtimes here.** The critique roster is their only source. When `/implement` calls,
use the roster `/implement` passed, including its `--critique` override.
Never re-read a roster from elsewhere. Without a caller's roster, the runtime is Claude.

That roster names a model and an effort per critic. Take the runtime each model runs on, once
each. `list_agent_tools` resolves each one to an enabled runtime. Stop and say so where one
resolves to none. Never hardcode a roster, and ask no roster question.

`run.md` runs every lens agent on Claude whenever the roster includes Claude. The lens file's
`tier` entry for the agent's runtime sets its model and effort. The roster's other runtimes run
the refuters.

## Step 2 — Resolve the intent

Each lens file names its intent per target kind, in its `intent` frontmatter. This skill
supplies the `concern` kind.

- **`--concern <map-slug>/<concern>`** resolves the concern's `requirements.md` and `design.md`
  under `<docs_dir>/maps/<map-slug>/<concern>/`. The intent is those two documents. Where
  `implementation.md` holds `## Deviations`, that section joins the intent of every lens whose key
  names `requirements.md` or `design.md`. Each entry is a departure the user approved, and it names
  the document it departs from, which does not record it. Where `implementation.md` holds
  `## Decided` sections, pass them to `run.md` as settled escalations.
- **No `--concern`** supplies no intent. `run.md` drops every lens that checks the target against
  one, and names each in the ledger's header. A standalone `/critique src/foo.php` has nothing to
  check requirements against.

**A design or requirements target is its own intent.** `/critique <concern>/design.md` reads that
document as the `concern` intent, with no `--concern` flag. That target holds no code, so name its
lens set for `run.md`: correctness, failure-modes, security, and claims. Add requirements-fidelity
where the target is `design.md`, which checks the design against the concern's `requirements.md`.

**A lens drops silently only when the caller offered no `--concern`.** When a caller offered
`--concern` and a document does not resolve, stop and say so. Never drop a lens quietly on a
document you cannot read. Resolve both documents before anything spawns.

The proof commands come from the same documents. When `/implement` calls, they are the proof
commands in `requirements.md`. `run.md` reruns them after the fixes land.

## Step 3 — Choose the output mode

| Caller and target | Mode |
|---|---|
| `/implement`, on a concern's diff | `apply`: each accepted fix lands in this concern's worktrees, uncommitted |
| anything else | `report`: write the remedy, and edit nothing |

**A standalone critique edits nothing, because the request covered a review only.**

**In `apply` mode, the critique runner reworks.** It applies an in-design batch 1 fix itself,
after the filter, then reruns batch 1. The rework lands uncommitted in this concern's worktrees,
and `/implement` commits it.

Never write into the user's stable `main` worktree. `rules/solo-agent-orchestration.md` keeps a
worker out of the user's tree, and `pr-first-contributions` forbids a commit on the default branch.

**In `apply` mode, each systemic finding also becomes a proposed map edit.** Record it as the next
entry under `## Proposed map edits` in the concern document of the stage that called. When
`/implement` calls, that document is `implementation.md`. `skills/map/SKILL.md` gives the entry's
shape under `## Proposed map edits`. A systemic finding names a new concern, and `/map` applies or
declines it. This skill never writes `map.md`.

**In `apply` mode, each deviation the user accepts also enters the concern's deviations.** Record
it under `## Deviations` in `implementation.md`, and name the document it departs from. A resumed
critique then reads it as intent.

**A standalone critique writes the finding to the ledger only.**

**A `proposed edit:` line stays in the ledger too.** `/implement` carries the ledger into
`Landed`, so the user reads every proposed edit there.

## Step 4 — Run the engine

Read `references/critique/run.md` in full, then run it with what steps 1 to 3 resolved:

- the target: the diff text itself, or the exact refs and container paths;
- the intent: the `concern` kind with the resolved documents, or none;
- the settled escalations from `## Decided`, or none;
- the lens set: the catalog in `references/critique/lenses/`, or the document set from step 2 for
  a `requirements.md` or `design.md` target;
- the output mode, where a rework lands, and the proof commands;
- the runtimes the roster names;
- the slug, the pass, and the tags.

`run.md` owns the agents, the batches, the refutation pass, the merge, the filter, the ledger, and
every escalation. Add nothing to its procedure, and do not paraphrase it.

`/implement` receives the ledger rather than the raw findings, so nobody triages a finding twice.
