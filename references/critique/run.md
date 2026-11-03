# Critique: the engine

`/critique` and `/review-pr` run every critic through this file. A front end resolves the target,
the intent, and the output mode, and then hands them here. This file runs one agent per lens,
refutes every finding, merges what survives, filters it, and writes the ledger.

`rules/solo-agent-orchestration.md` carries the policy and the shapes for every agent below. This
file carries what a critique puts inside them, and it restates none of the rule's shapes.

```
select the lenses ──► batch 1 ──► refute ──┬── pass ──────────────► batch 2 ──► refute
                                           ├── in-design failure ─► rework ─► batch 1 again, 2 rounds at most
                                           └── deviation ─────────► Blocked, for the user
merge by location ──► filter, C1 to C6 ──► the ledger ──► escalate one finding per message
```

## What the front end supplies

| Input | What it carries |
|---|---|
| Target | the diff text itself, or the exact refs and container paths; never a name alone |
| Target note | a fact every agent needs about the target, or none |
| Intent | the `Intent source:` kind that applies (`concern`, `pr`, or `plan`) and the content it names, or none |
| Lens set | the catalog in `references/critique/lenses/`, or the integration set below |
| Output mode | `apply` or `report` |
| Rework | in `apply` mode, where a batch 1 rework lands |
| Proof commands | in `apply` mode, the commands that rerun after the fixes land |
| Runtimes | the runtimes that may run an agent, in order; Claude by default |
| Names | the `<slug>` and the `<pass>` that name every pad and process below, and the tags every pad carries |

## The lens files

`references/critique/lenses/` holds one file per lens, in this schema:

```
Batch:            1 | 2
Applies when:     always | <a condition on the target>
Tier:             <model> · <effort>
Question:         <the one question the lens agent answers>
Intent source:
  concern:        <what it reads from a concern pad>
  pr:             <what it reads on someone else's PR>
  plan:           <what it reads from a plan pad>
Finding:          location · concrete failure, or before and after · fix · severity
Out of mandate:   <what this lens never reports, because another lens owns it>
```

Read each lens file in full before you spawn its agent. This file restates no lens's content.

## Select the lenses

Read each lens file's `Applies when:` line against the target. `always` covers every target that
holds code. A target that holds no code, such as a draft plan, takes only the lenses whose
question it can answer.

Each agent reads the part of the intent its `Intent source:` line names. Where that part is
absent, the brief carries `none` as its intent. A lens whose question checks the target against
that intent then has nothing to check, so it drops out. Every other lens runs on the target alone.

Name every lens that did not run in the ledger's header, with its reason. When the front end
offered an intent that does not resolve, the front end stops before it reaches this file.

## Spawn one agent per lens

Call `whoami` once, and keep the returned `process_id`. Every agent needs it to signal back.

Pick each agent's runtime from the front end's list:

- A lens agent runs on the first runtime in the list.
- A refuter runs on the next runtime in the list where one exists, and on the first otherwise.

A refuter on another runtime shares less with the agent whose finding it checks.

`list_agent_tools` resolves each runtime to an enabled tool and its `tool_type`. Read
`references/runtime-<tool_type>.md` before you spawn on that runtime. Never write a launch
argument from memory. The adapter also names any startup behavior that consumes an agent's first
input.

```
spawn_agent(agent_tool_id=<id>, name="critique-<lens>-<n>-<slug>-<pass>", extra_args=[
  <the model and effort arguments, from the lens file's Tier line>,
  <the auto-approval argument from the adapter>,
  <the immutable-target arguments from the adapter>,
  <the system-prompt argument carrying the preamble, where the runtime has one>])
  → process_id, agent_instructions
```

`<n>` counts the runs of that lens in this pass, from 1. Only batch 1 reruns, so only a batch 1
lens reaches 2 or 3.

**The `Tier:` line sets the model and the effort on Claude.** On another runtime, keep that
runtime's default model. Pass the tier's effort through the argument its adapter names.

**Every agent here is an immutable-target worker.** The rule gives that posture, and the adapter
gives what each runtime can enforce for it. Where the target stays writable, say so in the brief.
Never assert a denial the runtime lacks. Never use a bypass mode, even though the agent only
reads.

Create each agent's scratch directory before you spawn it. The rule derives its path from the
agent's name.

When a spawn fails, read the adapter, correct the arguments, and retry once. Report a second
failure under `Failed`, and never loosen a flag.

### The brief pad

Write one brief pad per agent, per the rule's **The worker brief pad**. Tag it `transient`, with
the front end's tags.

```
  ## Solo context   agent_instructions, pasted verbatim; the agent's process id; the project id
  ## Objective      answer the lens question; the lens file's absolute path, to read in full;
                    the target as the front end supplied it, with its target note; the intent
                    the lens file's Intent source line names for this target, or "none"; the
                    adversarial-review caveat below
  ## Boundaries     the repository path the target belongs to; the target is immutable; run no
                    git write command; write only the agent's scratch directory (absolute) or
                    its report pad; when stuck, record and stop; the preamble, where the runtime
                    takes no system-prompt argument
  ## Tool guidance  report each finding in the lens file's Finding shape; report nothing its
                    Out of mandate line excludes; never say "add tests" without naming the
                    untested path; be specific and harsh, because a vague concern is noise
  ## Output format  the report channel below, and the ESCALATION: marker
  ## Completion     the rule's timer_set call; on the file channel, none
```

Give each agent the target, its lens file, and the intent. Withhold the reasoning behind the work.
An agent that already knows why the code is good is no longer a critic.

**The adversarial-review caveat.** An agent asked to find gaps reports some even when the work is
sound, because that is the assignment. Tell each agent to report only what answers its lens
question. A report with no finding is a correct result.

Send only the pointer, per the rule's **The pointer shape**. Spawn every agent in a batch before
you wait for any of them.

### The report channel

A lens agent writes its report to a Solo scratchpad named `critique/<slug>/<pass>/<lens>-<n>`,
with no H1. It then signals completion per the rule.

**A runtime that cannot write to Solo uses a file instead.** Codex is one. On codex-cli 0.166.0,
its reads work when they pass `project_id`. Its writes fail with
`Could not identify your Solo process`. An agent on such a runtime takes this channel:

- Its pointer reads the brief with `scratchpad_read(scratchpad_id=<id>, project_id=<project id>)`.
  The pointer drops the `whoami()` step, and the agent stops only when that read fails.
- It writes its report to `critique-report.md` in its scratch directory.
- The file's last line is `REPORT COMPLETE`.
- It sends no completion signal, because it cannot.

**The idle guard is that agent's completion signal.** A guard that fires prompts a read of the
file. Only the `REPORT COMPLETE` line confirms that the agent finished. A file without it belongs
to an agent still at work, or to a dead one.

### The guard

Write one guard pad per batch, and one per refutation round, per the rule's **The guard pad**.
Its watch list carries one row per agent: process id, name, lens, and report channel. The channel
is the report pad's name, or the report file's absolute path.

Arm the guard once the agents produce output:

```
timer_fire_when_idle_all(processes=[<pids>], max_wait_ms=<generous guard>,
  body="Critique guard fired for <pass>, batch <b>.
        An agent that never signalled is a failure to investigate, not a completion.
        Procedure: scratchpad_read(scratchpad_id=<guard pad id>)")
  → timer_id
```

Check the return value. An entirely idle watch list returns `already_satisfied` and creates no
timer.

The guard pad carries one more branch, for the file channel. A file that ends with
`REPORT COMPLETE` means that agent finished. Where the file lacks that line and the process still
runs, re-arm with `timer_fire_when_idle_any` on that process alone. That call ignores an
already-idle process and waits for a new idle transition.

Keep the returned `timer_id`. Cancel the guard once every agent in it has confirmed completion, by
signal or by file. A guard you leave armed fires later, about agents that finished long ago.

Then run `scratchpad_find` for `ESCALATION` across the report pads, and search each report file
for it. An agent that escalated could not answer its question. Treat its lens as not run, and name
it in the ledger's header.

## Batch 1, then the rework loop

Batch 1 holds every applicable lens whose file reads `Batch: 1`. Spawn its agents together, and
wait for all of them. Refute each finding they raise before you decide anything about it.

Sort each finding that survives refutation by what its fix changes:

- **The code alone.** The fix stays inside the approved design and the map. In `apply` mode, it
  goes back to the caller for rework, at the place the front end named.
- **The design or the map.** The fix departs from what the user approved. Stop, and put it to the
  user as a deviation, under `Blocked`. Batch 2 waits for the answer.
- **Nothing in this target.** The finding is systemic, per its scope below. It becomes a proposed
  map edit, and it blocks nothing.

Run the filter below on each in-design finding before its rework. A finding that matches a
criterion escalates first, and its rework waits for the user's answer.

After the rework, batch 1 runs again over the reworked target, with fresh agents. An agent that
saw the first round tends to check its own findings rather than the target.

**Two rework rounds is the limit.** Batch 1 therefore runs at most three times: once, and once
after each round. A third run that still fails stops the critique under `Blocked`.

**In `report` mode, nothing reworks.** Batch 1's surviving findings enter the merge, and batch 2
starts at once. A deviation still reaches the ledger, marked `deviation:`.

## Batch 2

Batch 2 starts once batch 1 passes. No in-design failure stays open, and the user has answered
every deviation.

Batch 2 holds every other applicable lens. Spawn all of its agents at once, one per lens, and wait
for all of them. Refute each finding, then merge both batches.

Batch 2 waits, because a rework changes the code it reads. A third batch would add nothing. A shape
finding rarely invalidates a behavior finding.

## The refutation pass

Every finding gets one refutation pass. That pass replaces cross-model agreement as the evidence
that a defect is real.

First drop each finding that lacks a location, a concrete failure or a before and after, or a fix.
No refuter runs on it.

Spawn one refuter per remaining finding, as soon as its batch completes:

- Name it `refute-<k>-<slug>-<pass>`, where `<k>` numbers this pass's findings from 1.
- Run it at the `Tier:` of the lens that raised the finding.
- Brief it with the target, the finding, and that lens's `Question:` line.
- Give it nothing from the lens agent's reasoning.

Tell the refuter to argue that the finding is *not* real. It argues that the failure cannot occur,
or that the before and after behave the same. It returns `real` or `refuted`, with its ground in one
sentence.

**A refuter defaults to refuted when it is uncertain.** Drop every finding it refutes, and count
the drops for the ledger's header.

Its report pad is `critique/<slug>/<pass>/refute-<k>`. The report channel and the guard work as
they do for a lens agent.

## Merge by location

Collect the surviving findings of both batches. Match findings that describe the same defect at
the same location, even when the wording differs. Keep one, and name every lens that raised it.
Two findings at one location that describe different defects stay separate.

**A behavior fix applies before a shape fix on the same line.** A behavior fix changes what the
code does. A shape fix changes how the code reads, and it leaves the behavior alone. Apply the
behavior fix first, then read the line again. Apply the shape fix only where it still fits the
changed line.

## The scope of a finding

Every finding carries `scope: local` or `scope: systemic`. Only the root-cause lens raises a
systemic finding, and its lens file says when. Every other finding is local.

**A systemic finding gets no local patch.** It becomes a proposed map edit: one new concern that
removes the cause. The ledger carries it on a `proposed edit:` line, and the front end says where
that line goes. A local patch would fix one symptom and keep the cause off the map.

## Filter, then escalate what the user must decide

You decide almost every finding yourself. Six criteria escalate a finding to the user, and three
grounds never do. The ledger discloses every decision either way.

**Default: fail toward accepting.** Accept any finding that matches no criterion below.

Real runs back this default. Serial triage cost about 115 human turns across 8 runs for about
176 findings. Delegated triage cost about 20 turns across 14 runs for about 260.

**What acceptance does depends on the output mode.** In `apply` mode, apply each accepted local
fix, then rerun the proof commands and the test suite. In `report` mode, write the remedy and edit
nothing.

When a rerun fails, find the fix that broke it, and undo that one edit. Its ledger line then reads
`remedy:`, and it names the check that failed.

**In `report` mode, no finding escalates on its own.** Nobody applies its fix, so no question waits
on it. A finding that matches a criterion carries a `criterion:` line in the ledger instead.

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
third of findings, and that reading would rebuild serial triage.

### The three anti-criteria

Each one is a prohibition. Never escalate a finding on one of these grounds.

- **Severity `nit`.** The corpus presented 16 nits and fixed 16. The user questioned none.
- **Cross-model agreement.** `1b15feba` finding 1 carried three-model agreement, and the user
  delegated it anyway. Two two-model findings turned out to be no findings at all.
- **A verifiable mismatch between two artifacts with one mechanical fix.** The user accepted
  about 60 of about 120 individually presented findings with a single word.

### The ledger

Report one line per decision, ranked by criticality. Criticality means a wrong result outranks a
plausible failure, which outranks a nit.

```
Ledger — <target> (<n> lenses, <r> findings refuted)
Not run: security, the diff touches no auth; requirements-fidelity, no intent

  bug    `src/token.php:88`    correctness   scope: local
         refresh drops the retry budget
         fixed: threaded the budget through the call
         declined: reset it in the caller — the caller cannot see the ceiling

  risk   `src/client.php:30`   root-cause    scope: systemic
         three clients each retry a 401 without a bound
         proposed edit: one retry policy that every HTTP client shares

  nit    `src/auth.php:40`     simplicity    scope: local
         `$tok` shadows the outer binding
         fixed: renamed it to `$refreshed`
```

Every line names its severity, its location, the lenses that raised it, and its scope. Severity is
`bug` (wrong behavior), `risk` (plausible failure), or `nit` (style, naming, cleanup). Severity
ranks the ledger, so never drop it from a line.

Carry the declined alternative wherever more than one fix existed, and give its reason in one
clause. Omit that line where only one fix existed.

The `fixed:` line reads `remedy:` wherever the run applied nothing. That covers `report` mode and
a fix that a rerun undid. In `report` mode, a line also carries `criterion:` where a criterion
matched, and `deviation:` where the fix departs from the approved design.

**The ledger is the only surface where a remedy choice stays correctable.** C6 escalates a genuine
tie alone, so every other choice between two fixes reaches the user here.

**A ledger with nothing critical in it carries no reserved heading.** Report it and stop.
`rules/chat-vocabulary.md` reserves a heading for a message the user must act on. A ledger of
accepted findings asks for nothing.

### Escalate one finding per message

Take the most critical first. `rules/chat-vocabulary.md` forbids two questions in one message, and
it gives the decision format every escalation takes. The filter keeps the escalated count low,
which makes one question per message affordable.

Pick the heading by what stopped:

- **C1 to C5** carry a proposal you already formed, so each takes `Approve`.
- **C6** carries options you cannot rank, so it takes `Deciding`, through the question tool.
- **A batch 1 deviation**, and a third batch 1 run that still fails, take `Blocked`.

Every escalation carries the four block fields, one section per option, and a
`**Recommendation:**` line with its ground. A C6 recommendation names the ground it rests on,
because the stated grounds do not rank the fixes.

An `Approve` for one C1 finding:

> **Approve — `src/token.php:88`**
>
> - **Found:** refresh drops the retry budget at `src/token.php:88`. The fix assumes a ceiling of
>   3, and no code in the repository states one: C1.
> - **Deciding:** whether to fix on an assumed ceiling. No lookup in the repository settles it.
> - **Criticality:** medium. It shapes one call path.
> - **Reversible:** yes. One commit undoes the fix.
>
> **A. Fix it as proposed**
>
> - **Pros:** three consecutive 401s stop retrying.
> - **Cons:** the ceiling of 3 rests on an assumption.
> - **Risks:** a real ceiling below 3 still lets the gateway reject the last retry.
> - **Constraints:** the change stays inside `src/token.php`.
>
> **Example:**
>
> ```php
> return $this->refresh($token, budget: $budget - 1);
> ```
>
> **B. Drop the finding**
>
> - **Pros:** no change rests on an unverified fact.
> - **Cons:** three consecutive 401s retry forever.
> - **Risks:** an expired token loops until the process dies.
> - **Constraints:** none.
>
> **Recommendation:** A. A bounded loop with a wrong bound fails less often than an unbounded one.
>
> Fix it as proposed, or drop it?
>
> ⏸ waiting on you: fix `src/token.php:88` as proposed, or drop the finding

## The integration lenses

The front end selects this set for an integration pass, and nothing else selects it. Each question
needs more than one milestone's diff to answer. These lenses have no lens files.

They run without batches and without rework: one agent per lens, all four at once, at
`opus · high`. Their intent is the plan pad, and the pass runs in `report` mode.

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

**No question appears in both sets.** The catalog checks one target at a time. Plan completeness
asks whether every slice landed somewhere, which no single target answers.

## Clean up

`close_process` every agent this pass spawned. Archive every brief pad, guard pad, and report pad
of the pass. They carry agent-to-agent traffic, and the ledger already holds what the user reads.

If nothing survives, no ledger exists and no decision waits. Report the action alone: one line, no
findings block, and no closing question.

```
Critique of <target> (<n> lenses) — nothing survived. 4 findings raised, all refuted.
```

A clean critique is a real outcome, not a failure to try hard enough.
