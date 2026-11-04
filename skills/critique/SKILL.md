---
name: critique
description: Adversarially review a diff, plan, or files with one critic agent per lens, and apply the accepted fixes when /implement calls
when_to_use: >-
  When the user wants work torn apart rather than surveyed. Trigger phrases: "what is wrong
  with this", "review this adversarially", "find the bugs", "critique my plan". Also invoked
  by the plan and implement skills.
argument-hint: "[target] [--base <ref>] [--plan <pad>] [--integration <slug>]"
---

# Critique

Try to break something. This is not a survey. Each lens agent answers one question about the
target. A finding must survive a refutation pass before it reaches the user.

This skill is a front end. It resolves the target, the intent, and the output mode.
`references/critique/run.md` runs every lens, and this skill carries no lens text of its own.

It runs standalone. `/plan` calls it on a draft plan, and `/implement` calls it on each milestone
diff. A pull request belongs to `/review-pr`, which reads the PR body as intent.

## Step 1 — Resolve the target

| `$ARGUMENTS` | Target |
|---|---|
| *(empty)* | the working tree diff; falls back to `<default>...HEAD` — resolved from `origin/HEAD`, never hardcoded — if the tree is clean |
| `plan/<slug>`, `research/<slug>`, or a pad id | that pad, a target that holds no code |
| one or more paths | those files |
| `--base <ref>` | diff against that ref instead |
| `--integration <slug>` | every landed milestone of that plan, together |
| `--pr <N>` | none: say that `/review-pr <N>` reviews a pull request, and stop |

`--plan <pad>` resolves no target of its own. It carries the intent, per step 2.

State what you resolved before you proceed. If the target is empty — clean tree, no changes —
say so and stop rather than reviewing nothing.

**Resolve `--integration <slug>` before you spawn anything.** No other target names its refs
indirectly, so this is the one target you assemble:

1. Read every `plan:<slug>:milestone:<m>:branch:<repo>` key. Each value is one branch, and the key
   names the milestone and the repository it belongs to. `/implement` deletes these keys at Close,
   which runs after this pass.
2. Take each repository's container path from the plan pad's `**Repos**:` line. `--plan` carries
   that pad, and `/implement` always passes it.
3. Fetch, then diff each branch against the base its own milestone cut from:
   ```bash
   git --git-dir="<container>/.git" fetch origin
   git --git-dir="<container>/.git" diff <base>..<branch>
   ```
   That base is `origin/HEAD`, or the predecessor milestone's branch where the milestones stack in
   that repository. One ref cannot serve two repositories that stack differently.

The target is every one of those diffs together. **Use the bare repository, never a worktree.**
An earlier milestone's teardown removed the worktree of every repository the last milestone did
not touch. A bare repository reads a branch without a checkout, so it reaches all of them.

Stop and say so where a key is absent, or where a branch does not resolve. A partial target
answers `Plan completeness` wrongly, and that lens is why this pass exists.

**Resolve the names here.** `run.md` names every pad and process from two segments:

```
  slug   the plan's slug. Where no plan resolved, a lowercase slug of the target:
         `working-tree`, or the path with `/` as `-`
  pass   the milestone `/implement` is shipping, plus the repository name where that
         milestone spans more than one; `integration` for `--integration`; `standalone`
         otherwise
```

`/implement` calls this skill once per repository per milestone, and once more after the last one
pushes. The repository belongs in the pass for the same reason the milestone does. Two
repositories in one milestone would otherwise write one pad twice.

Omit the pass, and M2's pads overwrite M1's. `run.md` archives every pad after the merge, so that
overwrite leaves no trace. Tag every pad `transient`, and `plan:<slug>` where a plan resolved.

**Resolve the runtimes here.** The critique roster is their only source. When `/implement` calls,
use the roster `/implement` passed, including its `--critique` override and any edit at its gate.
Never re-read the plan's roster. Without a caller's roster, the runtime is Claude.

That roster names a model and an effort per critic. Take the runtime each model runs on, once
each. `list_agent_tools` resolves each one to an enabled runtime. Stop and say so where one
resolves to none. Never hardcode a roster, and ask no roster question.

`run.md` runs every lens agent on Claude whenever the roster includes Claude. The lens file's
`tier` entry for the agent's runtime sets its model and effort. The roster's other runtimes run
the refuters.

## Step 2 — Resolve the intent

Each lens file names its intent per target kind, in its `intent` frontmatter. This skill
supplies the `plan:` kind.

- **`--plan <pad>`** resolves that plan pad. The intent is the slices of the work items this
  milestone carries when `/implement` calls, and every slice otherwise. An `--integration` pass
  reads the whole plan.
- **No `--plan`** supplies no intent. `run.md` drops every lens that checks the target against
  one, and names each in the ledger's header. A standalone `/critique src/foo.php` has nothing to
  check requirements against.

**A plan-pad target is its own intent.** `/critique plan/<slug>` reads the pad's slices as its
`plan:` intent, with no `--plan` flag. That target holds no code, so name its lens set for
`run.md`: correctness, failure-modes, security, and claims. Add requirements-fidelity, which
checks the slices against the plan's own `## Overview`.

**A lens drops silently only when the caller offered no `--plan`.** When a caller offered
`--plan` and the pad does not resolve, stop and say so. Never drop a lens quietly on a pad you
cannot read. Resolve the pad before anything spawns.

The proof commands come from the same pad. When `/implement` calls, they are the proof commands of
the work items this milestone carries. `run.md` reruns them after the fixes land.

## Step 3 — Choose the output mode

| Caller and target | Mode |
|---|---|
| `/implement`, on a milestone diff | `apply`: each accepted fix lands in this milestone's worktrees, uncommitted |
| `--integration`, whoever called | `report`: write the remedy, and edit nothing |
| anything else | `report`: write the remedy, and edit nothing |

**A standalone critique edits nothing, because the request covered a review only.**

**In `apply` mode, the critique runner reworks.** It applies an in-design batch 1 fix itself,
after the filter, then reruns batch 1. The rework lands uncommitted in this milestone's worktree,
and `/implement` step 5 commits it.

**An `--integration` pass reports the remedy and edits nothing, whoever called it.** Every
milestone it reviews already shipped its PRs. A finding against M1 cannot land on M1's branch. That
branch already carries an open or merged PR. Write it into whatever tree stands open, and M1's fix
lands on another milestone's branch.

Never write into the user's stable `main` worktree. `rules/solo-agent-orchestration.md` keeps a
worker out of the user's tree, and `pr-first-contributions` forbids a commit on the default branch.
An accepted remedy therefore lands as a follow-up milestone, and `/implement` proposes one.

**In `apply` mode, each systemic finding also reaches the plan pad.** Append it to the pad's
`## Proposed edits` section, with `scratchpad_append_section` or `scratchpad_edit`. Where the pad
has no such section, create it at the end of the pad.

**A `proposed edit:` line stays in the ledger too.** `/implement` carries the ledger into
`Landed`, so the user reads every proposed edit there.

## Step 4 — Run the engine

Read `references/critique/run.md` in full, then run it with what steps 1 to 3 resolved:

- the target: the diff text itself, or the exact refs and container paths;
- the intent: the `plan:` kind with the resolved slices, or none;
- the lens set: the catalog in `references/critique/lenses/`, the plan-pad set from step 2 for a
  `plan/<slug>` target, or the integration set for `--integration`;
- the output mode, where a rework lands, and the proof commands;
- the runtimes the roster names;
- the slug, the pass, and the tags.

`run.md` owns the agents, the batches, the refutation pass, the merge, the filter, the ledger, and
every escalation. Add nothing to its procedure, and do not paraphrase it.

`/plan` and `/implement` receive the ledger rather than the raw findings, so nobody triages a
finding twice.
