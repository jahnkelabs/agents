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

State what you resolved before you proceed. If the target is empty — clean tree, no changes —
say so and stop rather than reviewing nothing.

A roster is a real target, because an approved artifact has its own failure modes. Two tasks
may overlap on a file and race. The grouping may drop a `same-worker` constraint. A tier may
not match the work it carries.

## Step 2 — Choose the models

Always ask, unless the caller already supplied a roster:

```
list_agent_tools  →  Claude (3), Copilot (8), Kimi (9), ...
```

```
Which models should critique this?
  <name>, <name>, <name> available.
```

Use only enabled runtimes — never assume a fixed set. Each model misses different defects,
which is the point. Independent critics find more defects than one critic that you run repeatedly.

When `/implement` calls this skill, it already chose the roster at setup. Use that roster, and
do not ask again.

**One roster serves a whole run.** `/implement` chooses it once, then reuses it for every
milestone critique and for the integration pass. Two milestones critiqued by different rosters
produce findings nobody can compare.

## Step 3 — Pick the lenses

Two lens sets exist, and the target picks one. A milestone's diff takes the per-milestone set. A
pass over a whole plan's landed milestones takes the integration set. Run one set, never both.

### Per-milestone lenses

| Lens | Applies when | Question |
|---|---|---|
| **Plan fidelity** | an approved plan exists | Does this milestone do what its slices approved — and nothing more? Did the work quietly skip, expand, or substitute anything? |
| **Correctness** | always | Where does this produce a wrong result? Give concrete inputs and the wrong output. |
| **Edge cases** | always | Empty, null, concurrent, oversized, malformed. What does the code not handle? Which error path has no test? |
| **Security** | the target touches auth, input handling, secrets, permissions, or shells out | What is exploitable? |

Drop the plan fidelity lens silently when there is no plan. A standalone `/critique src/foo.php`
has nothing to check fidelity against.

### Integration lenses

Run this set only over a whole plan's landed milestones. Each question needs more than one
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

**No question appears in both sets.** Per-milestone fidelity asks whether one milestone's diff
matches its own slices. Integration completeness asks whether every slice landed somewhere.
Neither question answers the other.

## Step 4 — Run the critics

Spawn one Solo worker per selected model. Each worker runs all applicable lenses over the whole
target. Use `spawn_agent`, per `solo-agent-orchestration`. A vendor sub-agent can run only the
session's model, and this skill needs more than one.

Call `whoami` first and keep the returned `process_id` — every critic needs it to signal back.

```
spawn_agent(agent_tool_id=<id>, name="critique-<model>", extra_args=[
  <the effort argument, at high or above — this is judgment work>,
  <the auto-approval and git-denial arguments from the adapter>])
send_input(process_id, input=<agent_instructions + the prompt below>)
```

The roster spans runtimes, so read an adapter per critic rather than once. `list_agent_tools`
returns a `tool_type` for each. Read `references/runtime-<tool_type>.md` and use the arguments it lists.
Each adapter also names the startup behavior that eats a worker's first input, and what its
runtime cannot enforce. Never use a bypass mode, even though a critic only reads.

Do not pass a model argument: the roster *is* the model choice. An override would remove the
independence this skill depends on. Raise the effort: it is a separate setting, and a higher
effort finds more real defects. The deny list stops a critic from mutating the target it reviews.

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
<plan text, or "none — this is a standalone review">

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
- Write your findings to a scratchpad named "critique/<target-slug>/<your model>"
- Signal completion as your last act:
    timer_set(delay_ms=0, delivery_process_id=<orchestrator process_id>,
              body="Critique <model> done. Findings in critique/<target-slug>/<model>.")

Be specific and be harsh. Vague concerns are noise.
```

## Step 5 — Merge

Read each worker's scratchpad. Match findings that describe the same defect at the same
location, even when the wording differs.

**Cross-model agreement is evidence that a finding is real.** Two independent models rarely
invent one defect. Use agreement to decide what survives the merge.

**Agreement does not decide what reaches the user.** Step 6's criteria do that, and none of them
names agreement. `1b15feba` finding 1 carried three-model agreement, and the user delegated it
anyway.

**When you select only one model**, that evidence does not exist. Run a refutation pass instead.
Spawn one more worker per finding, and tell it to argue that the finding is *not* real. It
defaults to refuted when it is uncertain. Drop what it refutes.

## Step 6 — Filter, then escalate what the user must decide

You decide almost every finding yourself. Six criteria escalate a finding to the user, and three
grounds never do. The ledger discloses every decision either way.

**Default: fail toward accepting.** Accept any finding that matches no criterion below, and
apply the remediation it recommends.

Real runs set that default. The user overrode serial triage 13 times between 2026-08-04 and
2026-08-23, every time as the reply to `Finding 1 of N`. Serial triage cost about 115 human turns
across 8 runs for about 176 findings. Delegated triage cost about 20 turns across 14 runs for
about 260.

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

**The ledger is the only surface where a remedy choice stays correctable.** C6 escalates a
genuine tie alone, so every other choice between two fixes reaches the user here.

**A ledger with nothing critical in it carries no reserved heading.** Report it and stop.
`rules/chat-vocabulary.md` reserves a heading for a message that needs a reply, and a ledger of
accepted findings needs none.

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
