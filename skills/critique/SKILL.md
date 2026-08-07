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

Try to break something. This is not a survey — each worker's job is to find what is wrong,
and findings must survive scrutiny before they reach the user.

Runs standalone, and is called by `/plan` (on a draft plan) and `/implement` (on a diff).

## Step 1 — Resolve the target

| `$ARGUMENTS` | Target |
|---|---|
| *(empty)* | working tree diff; falls back to `<default>...HEAD` — resolved from `origin/HEAD`, never hardcoded — if the tree is clean |
| `plan/<slug>` or a pad id | a draft plan |
| `--roster` | `/implement`'s proposed decomposition — grouping, waves, and tiers, before anything spawns |
| one or more paths | those files |
| `--pr <N>` | that pull request (`gh pr diff <N>`) |
| `--base <ref>` | diff against that ref instead |

State what you resolved before proceeding. If the target is empty — clean tree, no changes —
say so and stop rather than reviewing nothing.

A roster is a real target because it is an approved artifact with its own failure modes: two
tasks that overlap on a file and would race, a `same-worker` constraint the grouping dropped, a
tier that does not match the work it was assigned.

## Step 2 — Choose the models

Always ask, unless the caller already supplied a roster:

```
list_agent_tools  →  Claude (3), Copilot (8), Kimi (9), ...
```

```
Which models should critique this?
  <name>, <name>, <name> available.
```

Use only enabled runtimes — never assume a fixed set. Different models have different blind
spots, which is the point: independent critics beat one critic run repeatedly.

When called by `/implement`, the roster was chosen at its setup; use it without asking again.

## Step 3 — Pick the lenses

| Lens | Applies when | Question |
|---|---|---|
| **Plan fidelity** | an approved plan exists | Does this do what was approved — and nothing more? Was anything quietly skipped, expanded, or substituted? |
| **Correctness** | always | Where does this produce a wrong result? Give concrete inputs and the wrong output. |
| **Edge cases** | always | Empty, null, concurrent, oversized, malformed. What is unhandled? What error path is untested? |
| **Security** | the target touches auth, input handling, secrets, permissions, or shells out | What is exploitable? |

Plan fidelity drops silently when there is no plan — a standalone `/critique src/foo.php` has
nothing to check fidelity against.

## Step 4 — Run the critics

One Solo worker per selected model, each running all applicable lenses over the whole target.
Per `solo-agent-orchestration` — and note that a vendor sub-agent could not run a model other
than the session's anyway, which would defeat the point of this skill:

Call `whoami` first and keep the returned `process_id` — every critic needs it to signal back.

```
spawn_agent(agent_tool_id=<id>, name="critique-<model>", extra_args=[
  "--effort", "<high or above — this is judgment work>",
  <auto-approval flag for this runtime — see below>,
  "--settings", '{"permissions":{"deny":["Bash(git add:*)","Bash(git commit:*)",
                  "Bash(git push:*)","Bash(git checkout:*)"]}}'])
send_input(process_id, input=<agent_instructions + the prompt below>)
```

The roster spans runtimes, so the auto-approval flag is the one argument that varies by runtime
rather than by critic: `"--permission-mode", "auto"` on Claude, `"--full-auto"` on Codex. It is
required on every critic, per `solo-agent-orchestration`, and the bypass modes are never used
even though a critic only reads.

Do not pass `--model`: the roster *is* the model choice, and overriding it would collapse the
independence the skill depends on. Effort is a separate axis and finding real defects rewards
raising it. The deny list keeps a critic from mutating the thing it is reviewing.

Each critic signals when it finishes; arm one idle timer as the dead-worker fallback only:

```
timer_fire_when_idle_all(processes=[<pids>], max_wait_ms=<generous guard>,
  body="Critique guard expired. Any critic that has not signalled has died or hung —
        check its scratchpad and process status before merging without it.")
```

Give each worker only the target and the approved plan — not the reasoning that produced them.
A critic that has been told why the code is good is not a critic.

```
You are reviewing <target> adversarially. Your job is to find what is wrong with it.

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
location, even when worded differently.

**Cross-model agreement is the confidence signal.** A defect two independent models find is
probably real; one only a single model raises deserves attention but ranks lower. This replaces
a separate verification stage.

**When only one model was selected**, that signal does not exist. Run a refutation pass
instead: spawn one more worker per finding, tasked with arguing the finding is *not* real,
defaulting to refuted when uncertain. Drop what it refutes.

## Step 6 — Triage serially

Present findings **one at a time**, `/grill`-style — the finding, its evidence, the decision you
need — and wait for that decision before moving to the next. Order by severity, then by
agreement. There is no batch report and no user-facing pad: a list the user has to work back
through is what this replaces.

```
Finding 1 of 6   ●  bug   `src/token.php:88`

Refresh drops the retry budget.

  Evidence  `refresh()` resets `$attempts` to 0 on entry, so three consecutive
            401s never reach the ceiling and the caller retries forever.
  Fix       thread the budget through the call instead of resetting it.

Fix it, drop it, or something else?
```

(● = models that independently flagged it)

Severity rides on every finding — `bug` (wrong behavior), `risk` (plausible failure), `nit`
(style, naming, cleanup). It is half of the ordering, so it cannot be dropped from the line.

When the last finding is decided, close with the counts and nothing else:

```
6 findings triaged — 4 to fix, 2 dropped. 4 more were refuted before triage.
```

When a refutation pass ran, report the refuted count so the user knows filtering happened, but do
not list what was refuted unless asked. With more than one model there is no refutation pass, so
the close is `<N> findings triaged — <N> to fix, <N> dropped.`

`/critique` owns this presentation. `/plan` and `/implement` receive the resulting decisions
rather than the raw findings, so nothing is triaged twice.

`close_process` every worker, and archive the per-model scratchpads. Those pads are the
worker-to-orchestrator channel `solo-agent-orchestration` requires; archiving them costs nothing
once the findings have been merged.

If nothing survives there is no decision to request, and the shape degrades to the action alone —
one line, no findings block, no closing question:

```
Critique of <target> (<models>) — nothing survived. 4 findings raised, all refuted.
```

A clean critique is a real outcome, not a failure to try hard enough.
