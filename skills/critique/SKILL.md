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

## Step 3 — Pick the lenses

| Lens | Applies when | Question |
|---|---|---|
| **Plan fidelity** | an approved plan exists | Does this do what the plan approved — and nothing more? Did the work quietly skip, expand, or substitute anything? |
| **Correctness** | always | Where does this produce a wrong result? Give concrete inputs and the wrong output. |
| **Edge cases** | always | Empty, null, concurrent, oversized, malformed. What does the code not handle? Which error path has no test? |
| **Security** | the target touches auth, input handling, secrets, permissions, or shells out | What is exploitable? |

Drop the plan fidelity lens silently when there is no plan. A standalone `/critique src/foo.php`
has nothing to check fidelity against.

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
returns a `tool_type` for each. Read `references/<tool_type>.md` and use the arguments it lists.
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

## Step 5 — Merge and rank

Read each worker's scratchpad. Match findings that describe the same defect at the same
location, even when the wording differs.

**Cross-model agreement is the confidence signal.** A defect that two independent models find
is probably real. A defect that one model raises deserves attention, but it ranks lower. This
replaces a separate verification stage.

**When you select only one model**, that signal does not exist. Run a refutation pass instead.
Spawn one more worker per finding, and tell it to argue that the finding is *not* real. It
defaults to refuted when it is uncertain. Drop what it refutes.

## Step 6 — Triage serially

Present findings **one at a time**, `/grill`-style — the finding, its evidence, the decision you
need. Wait for that decision before you present the next finding. Order by severity, then by
agreement. There is no batch report and no user-facing pad. This skill replaces the batch list
that the user must then read through.

```
Finding 1 of 6   ●  bug   `src/token.php:88`

Refresh drops the retry budget.

  Evidence  `refresh()` resets `$attempts` to 0 on entry, so three consecutive
            401s never reach the ceiling and the caller retries forever.
  Fix       thread the budget through the call instead of resetting it.

Fix it, drop it, or something else?
```

(● = models that independently flagged it)

Every finding carries a severity — `bug` (wrong behavior), `risk` (plausible failure), `nit`
(style, naming, cleanup). Severity is half of the ordering, so never drop it from the line.

When the user decides the last finding, close with the counts and nothing else:

```
6 findings triaged — 4 to fix, 2 dropped. 4 more were refuted before triage.
```

When a refutation pass ran, report the refuted count, so the user knows that you filtered
findings. Do not list the refuted findings unless the user asks. With more than one model there
is no refutation pass. Then the close is `<N> findings triaged — <N> to fix, <N> dropped.`

`/critique` owns this presentation. `/plan` and `/implement` receive the resulting decisions
rather than the raw findings, so nobody triages a finding twice.

`close_process` every worker, and archive the per-model scratchpads. Those pads are the
worker-to-orchestrator channel that `solo-agent-orchestration` requires. They cost nothing to
archive after you merge the findings.

If nothing survives, there is no decision to request. Report the action alone — one line, no
findings block, no closing question:

```
Critique of <target> (<models>) — nothing survived. 4 findings raised, all refuted.
```

A clean critique is a real outcome, not a failure to try hard enough.
