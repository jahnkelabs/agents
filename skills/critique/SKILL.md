---
name: critique
description: Adversarially review a diff, plan, files, or PR using multiple models as independent critics
when_to_use: >-
  When the user wants work torn apart rather than surveyed. Trigger phrases: "what is wrong
  with this", "review this adversarially", "find the bugs", "critique my plan". Also invoked
  by the plan and implement skills.
argument-hint: "[target]"
model: opus
---

# Critique

Try to break something. This is not a survey — each worker's job is to find what is wrong,
and findings must survive scrutiny before they reach the user.

Runs standalone, and is called by `/plan` (on a draft plan) and `/implement` (on a diff).

## Step 1 — Resolve the target

| `$ARGUMENTS` | Target |
|---|---|
| *(empty)* | working tree diff; falls back to `main...HEAD` if the tree is clean |
| `plan/<slug>` or a pad id | a draft plan |
| one or more paths | those files |
| `--pr <N>` | that pull request (`gh pr diff <N>`) |
| `--base <ref>` | diff against that ref instead |

State what you resolved before proceeding. If the target is empty — clean tree, no changes —
say so and stop rather than reviewing nothing.

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

One Solo worker per selected model, each running all applicable lenses over the whole target:

```
spawn_agent(agent_tool_id=<id>, name="critique-<model>")
send_input(process_id, input=<agent_instructions + the prompt below>)
timer_fire_when_idle_all(processes=[<pids>], max_wait_ms=<guard>,
  body="Critique workers are idle. Collect each one's findings from its scratchpad,
        merge by agreement, and report.")
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
- Write your findings to a scratchpad named "critique/<target-slug>/<your model>", then stop

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

## Step 6 — Report

```
Critique of <target>  (<models>)

●●● bug   `src/token.php:88` — refresh drops the retry budget
          → 3 consecutive 401s exhaust it; pass the budget through
●●  risk  `src/kernel.php:41` — error path swallows the cause
          → wrap rather than replace
●   nit   `src/resolver.php:12` — name says "get", the method writes

(● = models that independently flagged it)

Refuted and dropped: 4 findings
```

Order by severity, then by agreement. Report the dropped count so the user knows filtering
happened, but do not list what was refuted unless asked.

`close_process` every worker, and archive the per-model scratchpads.

If nothing survives, say so plainly. A clean critique is a real outcome, not a failure to
try hard enough.
