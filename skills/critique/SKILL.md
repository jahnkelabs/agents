---
name: critique
description: Adversarially review a diff, plan, files, or PR using multiple models as independent critics
when_to_use: >-
  When the user wants work torn apart rather than surveyed. Trigger phrases: "what is wrong
  with this", "review this adversarially", "find the bugs", "critique my plan". Also invoked
  by the plan and implement skills.
argument-hint: "[target]"
---

# Critique

Try to break something. This is not a survey — each worker must find what is wrong. A finding
must survive scrutiny before it reaches the user.

This skill runs standalone. `/plan` calls it on a draft plan, and `/implement` calls it on a diff.

## Step 1 — Resolve the target

| `$ARGUMENTS` | Target |
|---|---|
| *(empty)* | the working tree diff; falls back to `<default>...HEAD` — resolved from `origin/HEAD`, never hardcoded — if the tree is clean |
| `plan/<slug>` or a pad id | a draft plan |
| `--roster` | `/implement`'s proposed decomposition — grouping, waves, and tiers, before anything spawns |
| one or more paths | those files |
| `--pr <N>` | that pull request (`gh pr diff <N>`) |
| `--base <ref>` | diff against that ref instead |
| `--integration <slug>` | every landed milestone of that plan, together |
| `--plan <pad>` | modifier — pairs an approved plan with the target the other arguments resolve |

State what you resolved before you proceed. If the target is empty — clean tree, no changes —
say so and stop rather than reviewing nothing.

`--plan` resolves no target of its own, and it carries the plan the fidelity lens checks against.
`/implement` always passes it. Resolve the pad before you spawn anything. A pad id you cannot
read is a stop, never a silent drop — see step 3.

`--integration` is the only target that takes the integration lens set. `/implement`'s milestone
loop is its caller, and it calls once the last milestone has pushed.

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

**Resolve the critic report pad name here.** Each critic writes to
`critique/<slug>/<milestone-or-integration>/<model>`. The three segments resolve like this:

```
  slug                       the plan's slug. Where no plan resolved, a lowercase slug of the
                             target: `pr-42`, `working-tree`, or the path with `/` as `-`
  milestone-or-integration   the milestone `/implement` is shipping, plus the repository name
                             where that milestone spans more than one; `integration` for
                             `--integration`; `roster` for `--roster`; `standalone` otherwise
  model                      the critic's model name, from the roster
```

`/implement` calls this skill once per repository per milestone, and once more after the last one
pushes. A three-milestone, one-repository run with a two-critic roster therefore writes eight
critic pads. The repository belongs in the middle segment for the same reason the milestone does.
Two repositories in one milestone would otherwise write one pad twice.

Omit the middle segment, and M2's pad overwrites M1's. Step 6 archives every pad after the merge,
so that overwrite leaves no trace.

A roster is a real target, because an approved artifact has its own failure modes. The roster
fidelity lens in step 3 names them.

## Step 2 — Choose the models

Always ask, unless the caller already supplied a roster:

```
list_agent_tools  →  Claude (3), Copilot (8), Kimi (9), ...
```

**Deciding — the critique roster**

```
found:        <n> enabled runtimes — <name>, <name>, <name>
decision:     each model misses different defects, and only you know the budget
two or more   cross-model agreement, which is evidence that a defect is real
one           cheaper, and a refutation pass stands in for the agreement evidence
```

Which models should critique this? I recommend <the models>, because <the ground>.

⏸ waiting on you: name the models for this critique

Use only enabled runtimes — never assume a fixed set. Each model misses different defects,
which is the point. Independent critics find more defects than one critic that you run repeatedly.

When `/implement` calls this skill, it already chose the roster at setup. Use that roster, and
do not ask again.

**One roster serves a whole run.** `/implement` chooses it once, then reuses it for every
milestone critique and for the integration pass. Two milestones critiqued by different rosters
produce findings nobody can compare.

## Step 3 — Pick the lenses

Two lens sets exist. **The per-target set is the default**, and it serves every target step 1
resolves. The integration set serves `--integration` alone. Run one set, never both.

### Per-target lenses

| Lens | Applies when | Question |
|---|---|---|
| **Plan fidelity** | `--plan` resolved a plan | Does this target do what its slices approved — and nothing more? Did the work quietly skip, expand, or substitute anything? |
| **Roster fidelity** | the target is `--roster` | Do two tasks overlap on a file and race? Did the grouping drop a `same-worker` constraint? Does a tier match the work it carries? |
| **Correctness** | always | Where does this produce a wrong result? Give concrete inputs and the wrong output. |
| **Edge cases** | always | Empty, null, concurrent, oversized, malformed. What does the code not handle? Which error path has no test? |
| **Security** | the target touches auth, input handling, secrets, permissions, or shells out | What is exploitable? |

Correctness, edge cases, and security read a draft plan as readily as a diff. A plan that
specifies a wrong result carries a correctness defect.

**Plan fidelity drops silently only when the caller offered no `--plan`.** A standalone
`/critique src/foo.php` has nothing to check fidelity against. When a caller offered `--plan` and
the pad does not resolve, stop and say so. Never drop the lens quietly on a pad you cannot read.

### Integration lenses

`--integration <slug>` selects this set, and nothing else does. Each question needs more than one
milestone's diff to answer.

| Lens | Question |
|---|---|
| **Cross-milestone contract drift** | Does a caller one milestone changed still match a callee another milestone changed? |
| **Plan completeness** | Did every slice the plan declared land in some milestone? |
| **Claim consistency** | Do two milestones state one fact two ways? |
| **Stack coherence** | Do the branches stack in the order the milestones shipped? |

**The integration pass may not raise a finding that lives wholly inside one milestone's diff.**
The per-milestone pass already ran that finding through the filter, and the user already decided.
Drop it rather than present it. One run had to drop a finding by hand as
`re-litigating the disabled-step export semantics, which you and I already settled`.

**No question appears in both sets.** Plan fidelity asks whether one target matches its own
slices. Integration completeness asks whether every slice landed somewhere. Neither question
answers the other.

## Step 4 — Run the critics

Spawn one Solo worker per selected model. Each worker runs all applicable lenses over the whole
target. Use `spawn_agent`, per `solo-agent-orchestration`. A vendor sub-agent can run only the
session's model, and this skill needs more than one.

Call `whoami` first and keep the returned `process_id` — every critic needs it to signal back.

```
spawn_agent(agent_tool_id=<id>, name="critique-<model>", extra_args=[
  <the effort argument, at high or above — this is judgment work>,
  <the auto-approval argument from the adapter>,
  <the immutable-target arguments from the adapter — writable scratch, unwritable
   target, unrestricted reads>])
send_input(process_id, input=<agent_instructions + the prompt below>)
```

The roster spans runtimes, so read an adapter per critic rather than once. `list_agent_tools`
returns a `tool_type` for each. Read `references/runtime-<tool_type>.md` and use the arguments it lists.
Each adapter also names the startup behavior that eats a worker's first input, and what its
runtime cannot enforce. Never use a bypass mode, even though a critic only reads.

Do not pass a model argument: the roster *is* the model choice. An override would remove the
independence this skill depends on. Raise the effort: it is a separate setting, and a higher
effort finds more real defects.

**Every critic is an immutable-target worker.** `rules/solo-agent-orchestration.md` carries that
class and what each runtime can enforce for it. Read it, then read the adapter. One runtime scopes
writes by directory and blocks the target structurally. Another scopes them by tool. A worker
denied the editing tools still writes the target through the shell. Where the target stays
writable, say so in the prompt. Never assert a denial the runtime lacks.

The prompt below carries the immutable-target, scratch-only, and no-git rules in its `## Rules`
block. They reach the critic whether the runtime enforces them or not. On a runtime that cannot
bound them, the prompt is the only place they exist. Never drop them from it.

Each critic signals when it finishes; arm one idle timer as the dead-worker fallback only:

```
timer_fire_when_idle_all(processes=[<pids>], max_wait_ms=<generous guard>,
  body="Critique guard expired. Any critic that has not signalled has died or hung —
        check its scratchpad and process status before merging without it.")
  → timer_id
```

Keep the returned `timer_id`. When the last critic signals, `timer_cancel(timer_id=<id>)` before
you merge findings. A guard you leave armed fires later and arrives as an instruction about
critics that finished long ago.

Give each worker only the target and the approved plan — not the reasoning that produced them.
A critic that already knows why the code is good is no longer a critic.

```
Review <target> adversarially. Your job is to find what is wrong with it.

## Target
<diff, plan text, or file contents>

## Approved plan
<the plan `--plan` resolved, or "none — the caller offered none">

## Lenses
Work through each of these separately:
<the applicable lenses and their questions>

## For each finding, report
- severity: bug (wrong behavior) | risk (plausible failure) | nit (style, naming, cleanup)
- location: file:line
- claim: what is wrong, in one sentence
- failure: concrete inputs or state → the wrong result. If you cannot produce one, say so —
  it is probably not a bug.
- fix: the specific change

## Rules
- Do not suggest features, refactors, or improvements beyond the target's scope
- Do not report "consider adding tests" without naming the specific untested path
- A finding you cannot demonstrate is a nit at best. Say which it is.
- Write no file outside <the critic's scratch directory, absolute>. Your Solo scratchpad is the one exception.
- The target is immutable. Read it; never edit it, add a file to it, or delete one from it.
- Run no git write anywhere — no `add`, no `commit`, no `checkout`, no `stash`.
- Your permission layer may not enforce these three rules. They hold whether it enforces them or not.
- Write your findings to the scratchpad named "<the pad name step 1 resolved>"
- Signal completion as your last act:
    timer_set(delay_ms=1, delivery_process_id=<orchestrator process_id>,
              body="Critique <model> done. Findings in <that same pad name>.")

Be specific and be harsh. Vague concerns are noise.
```

## Step 5 — Merge

Read each worker's scratchpad. Match findings that describe the same defect at the same
location, even when the wording differs.

**Cross-model agreement raises confidence, and it drops nothing.** Every merged finding enters
step 6, whether one critic found it or every critic did.

**Agreement cannot gate the merge, because each model misses different defects.** That is why the
roster holds more than one. A finding one critic found alone carries no agreement. Nothing refutes
it either, because the refutation pass below covers a one-model roster only. Gating on agreement
discards exactly the findings a multi-model roster exists to produce.

This is not a hypothetical. One run overrode that gate by hand. Following it would have dropped
most of the findings the fix wave then applied.

**Agreement is no evidence in the other direction either.** Step 6's criteria decide what reaches
the user, and none of them names agreement. `1b15feba` finding 1 carried three-model agreement,
and the user delegated it anyway. Two two-model findings turned out to be no findings at all.

**When you select only one model**, no agreement signal exists at all. Run a refutation pass
instead. Spawn one more worker per finding, and tell it to argue that the finding is *not* real.
It defaults to refuted when it is uncertain. Drop what it refutes.

## Step 6 — Filter, then escalate what the user must decide

You decide almost every finding yourself. Six criteria escalate a finding to the user, and three
grounds never do. The ledger discloses every decision either way.

**Default: fail toward accepting.** Accept any finding that matches no criterion below.

Real runs set that default. The user overrode serial triage 13 times between 2026-08-04 and
2026-08-23, every time as the reply to `Finding 1 of N`. Serial triage cost about 115 human turns
across 8 runs for about 176 findings. Delegated triage cost about 20 turns across 14 runs for
about 260.

**What acceptance does depends on who called.** A standalone critique reports the remedy and edits
nothing, because the request covered a review only. `/critique --pr 42` that rewrites the local
tree exceeds what the user asked for. When `/implement` calls on a milestone diff, apply each
accepted fix before that skill re-verifies and pushes.

**An `--integration` pass reports the remedy and edits nothing, whoever called it.** Every
milestone it reviews already shipped its PRs. A finding against M1 cannot land on M1's branch. That
branch already carries an open or merged PR. Write it into whatever tree stands open, and M1's fix
lands on another milestone's branch.

Never write into the user's stable `main` worktree. `rules/solo-agent-orchestration.md` keeps a
worker out of the user's tree, and `pr-first-contributions` forbids a commit on the default branch.
An accepted remedy therefore lands as a follow-up milestone, and `/implement` proposes one.

### The six criteria

Each criterion is a test you apply to one finding. Escalate only on a yes.

- **C1 — the fix rests on a fact you cannot verify.** Check the premise before the remedy.
  `cc3da3e8` 5/26 asserted `No ECR tag exists`, and that premise was false.
- **C2 — the fix needs the user to act outside the repository.** `ee524d20` 4/11 committed the
  user to `handle the tagging and release`.
- **C3 — the fix is irreversible, or visible outside the repository.** The fix at `ee524d20`
  8/11 read `Push it`.
- **C4 — the fix changes a default posture.** The user answered `cc3da3e8` 22/26 with
  `I'd rather start with strict rule enforcement`.
- **C5 — the fix changes who decides, or who merges.** The user answered `ee524d20` Security 3/3
  with `You MUST open a PR and allow me to review and merge it myself`.
- **C6 — two or more fixes exist, and you cannot rank them on stated grounds.** A genuine tie
  only.

**C6 covers a genuine tie and nothing wider.** When you can argue for one fix, take it and
disclose the alternative in the ledger. `More than one plausible fix exists` holds for roughly a
third of findings, and that reading would rebuild serial triage. The corpus's largest cluster was
a different remedy than the one recommended — 15 findings, 7 of them in `9fd97382`.

### The three anti-criteria

Each one is a prohibition. Never escalate a finding on one of these grounds.

- **Severity `nit`.** The corpus presented 16 nits and fixed 16. The user questioned none.
- **Cross-model agreement.** `1b15feba` finding 1 carried three-model agreement, and the user
  delegated it anyway. Two two-model findings turned out to be no findings at all. Both critics
  lacked context the user had already given.
- **A verifiable mismatch between two artifacts with one mechanical fix.** The user accepted
  about 60 of about 120 individually presented findings with a single word.

### The ledger

Report one line per decision, ranked by criticality. Criticality means a wrong result outranks a
plausible failure, which outranks a nit.

```
Ledger — <target> (<models>)

  bug    `src/token.php:88`   refresh drops the retry budget
         fixed: threaded the budget through the call
         declined: reset it in the caller — the caller cannot see the ceiling

  risk   `src/auth.php:12`    the 401 path retries without a bound
         fixed: bounded the loop

  nit    `src/auth.php:40`    `$tok` shadows the outer binding
         fixed: renamed it to `$refreshed`
```

Carry the declined alternative wherever more than one fix existed, and give its reason in one
clause. Omit that line where only one fix existed.

The `fixed:` line reads `remedy:` wherever the run applied nothing. That covers a standalone
critique and every `--integration` pass.

**The ledger is the only surface where a remedy choice stays correctable.** C6 escalates a
genuine tie alone, so every other choice between two fixes reaches the user here.

**A ledger with nothing critical in it carries no reserved heading.** Report it and stop.
`rules/chat-vocabulary.md` reserves a heading for a message the user must act on. A ledger of
accepted findings asks for nothing.

### Escalate one finding per message

Take the most critical first. `rules/chat-vocabulary.md` forbids two questions in one message.
The filter keeps the escalated count low, which is what makes one question per message
affordable.

C1 through C5 carry a proposal you already formed, so each takes `Approve`. C6 carries options
you cannot rank, so it takes `Deciding`. A C6 recommendation names the ground it rests on,
because the stated grounds do not rank the two fixes.

```
**Approve — `src/token.php:88`**

  found:      refresh drops the retry budget — C1, the ceiling is unverifiable
  decision:   the fix assumes a ceiling of 3, and no code in the repository states one
  fix it      threads the budget through the call, on an assumed ceiling
  drop it     three consecutive 401s retry forever

Fix it as proposed, or drop it? I recommend fixing it.
```

⏸ waiting on you: fix `src/token.php:88` as proposed, or drop the finding

Every finding carries a severity — `bug` (wrong behavior), `risk` (plausible failure), `nit`
(style, naming, cleanup). Severity ranks the ledger, so never drop it from a line.

`/critique` owns the filter, the ledger, and this presentation. `/plan` and `/implement` receive
the ledger rather than the raw findings, so nobody triages a finding twice.

`close_process` every worker, and archive the per-model scratchpads. Those pads are the
worker-to-orchestrator channel that `solo-agent-orchestration` requires. They cost nothing to
archive after you merge the findings.

If nothing survives, there is no ledger and no decision to request. Report the action alone —
one line, no findings block, no closing question:

```
Critique of <target> (<models>) — nothing survived. 4 findings raised, all refuted.
```

A clean critique is a real outcome, not a failure to try hard enough.
