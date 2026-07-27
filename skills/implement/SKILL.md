---
name: implement
description: Execute an approved plan as Solo-orchestrated waves, critique the result, and present it
argument-hint: "[plan/<slug>]"
disable-model-invocation: true
---

# Implement

Orchestrate execution of an approved plan. You own git, todo lifecycle, and worker
coordination. Workers write code and nothing else.

Phases run to completion without per-phase review gates. Workers escalate on **deviation**,
not on completion — see [Escalation](#escalation).

## Input

- **A plan pad** (`plan/<slug>` or an id) — the normal case
- **No arguments** — list active plan pads via `scratchpad_list(tags=["plan"])` and ask
- **Existing todos for the slug** — this is a resumed run; skip todo creation and pick up
  where the incomplete phases are

Read the pad fully. If none exists, send the user to `/plan`.

Use whichever Solo project is currently selected, consistent with `/plan`.

## Setup

Skip anything the `/plan` fork already confirmed — do not re-ask what was just settled.

1. **Confirm the execution shape** — waves, parallelism, and serialization, computed from each
   phase's declared `**Files**:` and dependencies. Phases with disjoint file sets run in
   parallel; overlapping ones serialize.
2. **Ask which models should run the critique.** `list_agent_tools` returns the enabled
   runtimes; offer those. Never hardcode a roster.
3. **Create the branch** in each target repo, off whatever `origin/HEAD` points to — never a
   hardcoded default branch name:
   ```bash
   cd <repo path>
   DEFAULT="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
   [ -z "$DEFAULT" ] && DEFAULT="$(git remote show origin | awk '/HEAD branch/ {print $NF}')"
   [ -z "$DEFAULT" ] && { echo "cannot resolve the default branch"; exit 1; }
   git checkout "$DEFAULT" && git pull --rebase && git checkout -b <type>/<slug>
   ```
   The fallback and the abort are both load-bearing, and so is the `&&` chain — a resolution that
   yields an empty string fails the checkout, and an unchained branch cut would then root the
   branch on whatever happened to be checked out.
   `kv_set(key="plan:<slug>:branch:<repo>", value="<branch>")`
4. **Create the todos** — one per phase, so the run is visible in Solo while it happens. The body
   points at the plan; it never copies it, which `/plan` forbids outright:
   ```
   todo_create(title="Phase N: <name>", body="<phase name> — see plan/<slug> §Phase N",
               tags=["plan:<slug>", "project:<repo>", "phase:N"])
   todo_add_blocker(todo_id=<dependent>, blocker_id=<prerequisite>)
   kv_set(key="plan:<slug>:todos", value=[<ids>])
   ```

Then run unattended through every wave.

## Wave execution

Workers are Solo agents, per `solo-agent-orchestration`. Nothing below works otherwise — a
vendor sub-agent cannot hold a lock, comment on a todo, or be joined by an idle timer.

For each wave, for each phase in it:

1. `todo_lock(todo_id, lease_ttl_seconds=3600)` and
   `todo_update(todo_id, status="in_progress")`
2. `spawn_agent(agent_tool_id=<claude>)` → returns `process_id` and `agent_instructions`
3. `send_input(process_id, input=<agent_instructions + the prompt below>)`

```
You are implementing Phase <N>: <name> of an approved plan.

## Working directory
<absolute repo path>

## Your phase
<full phase text: Changes Required, Files, Verification>

## Prior phases
<what already landed, or "this is the first wave">

## Before you touch anything
Acquire a lock for each file you will modify:
  lock_acquire(key="path:<declared path>", lease_ttl_seconds=3600)
If a lock is unavailable, stop and escalate — do not wait or work around it.

## Instructions
1. Read every file named in the plan, fully, before changing anything
2. Make the changes the phase specifies
3. Run the phase's automated verification
4. Record the outcome: todo_comment_create(todo_id=<id>, body="<what you did, verification output>")
5. Release your locks: lock_release(key="path:<...>")

## Constraints
- Do NOT commit, branch, stage, or run any other git write command. The orchestrator owns git.
  Several workers share this working tree; `git add` would collide and cross-commit their work.
- Do NOT write any file outside your declared paths. Needing to is a deviation — escalate.
- Do NOT create or complete todos, or write KV. Comment on your own todo only.
- Stay inside <absolute repo path>.

## Escalation — read this carefully
If you hit something you cannot resolve on your own, or that would require a meaningful
departure from the plan above, then:
  1. todo_comment_create(todo_id=<id>, body="ESCALATION: <what you found, what the plan
     assumed, what you'd need to do differently>")
  2. Release your locks and stop.
Do NOT improvise a fix, expand scope, or proceed down an unapproved path. Stopping is correct
behavior here, not failure.
```

4. Join the wave without polling — timers are the only wake-up mechanism for Solo agents:
   ```
   timer_fire_when_idle_all(processes=[<pids>], max_wait_ms=<guard>,
     body="Wave <N> workers are idle. Read each worker's todo comments. If any begins
           with ESCALATION:, stop and present the wave. Otherwise commit completed
           phases and continue with wave <N+1>.")
   ```
5. On wake: read each phase's todo comments. An `ESCALATION:` comment is the durable record and
   the only signal — nothing is mirrored into KV, so there is no second place to check.
6. **Commit each completed phase separately**, staging only its declared paths:
   ```bash
   cd <repo path>
   git add <phase's declared paths>
   git commit -m "<type>(<scope>): <phase summary>"
   ```
   Never `git add -A` — another phase's work may be in the tree.
7. `todo_complete(todo_id, completed=true)` for each phase that finished.
8. `close_process(process_id)` for each worker.

## Escalation

A worker escalates when it cannot self-resolve, or when finishing would mean deviating
meaningfully from what was approved. Writing an undeclared path counts as a deviation.

**In-flight workers in the same wave finish.** They hold disjoint file scopes and have no
dependencies on each other, so nothing is building on the problem.

The worker's todo comment is the durable record. The wave join is where it surfaces, and the only
place it surfaces — by the time you present, every escalation has been resolved or the run stopped
here. At the join, stop and show the whole wave together:

```
Wave <N> complete — one phase needs discussion.

  Phase 1  ✓ committed
  Phase 2  ⚠ escalated — <what the worker found>
  Phase 4  ✓ committed
  Phase 3  ⊘ blocked behind Phase 2

The plan assumed <X>; the code actually does <Y>.
Options: <adjust the plan / different approach / drop the phase>
```

Do not start the next wave until this is resolved. If the plan needs changing, update the pad
so it stays the record of what was actually agreed.

Automated verification failing is not automatically an escalation — a worker that can fix it
within the plan's intent should. It escalates when the fix would require departing from the
plan.

## Critique

Once all waves are done, run `/critique` over the full diff with the models chosen at setup,
passing the approved plan so the plan-fidelity lens has something to check against.

Fold the surviving findings into what you present. Do not fix them unilaterally.

## Present

State the run, then hand the findings over one at a time. `/critique` owns that presentation and
this is the same shape — one finding, one decision, in severity order — so nothing is triaged
twice.

```
Implementation complete.

<repo>  branch <name>
  Phases:  <N> committed
  Commits: <git log --oneline "origin/${DEFAULT}"..HEAD>
  Quality gates: <results>

<N> critique findings to triage (<models>).
```

Then, for each in turn:

```
Finding 1 of <N>   ●●●  bug   `file:line`

<what is wrong, in one sentence>

  Evidence  <concrete inputs or state, and the wrong result they produce>
  Fix       <the specific change>

Fix it, drop it, or something else?
```

(● = models that independently flagged it)

Severity and the `●` count are defined in `/critique` — `bug` for wrong behavior, `risk` for a
plausible failure, `nit` for style or cleanup. Severity orders the triage, so it stays on the line.

Apply each decision as it is made and wait for the next; never ask for all of them at once. When
the last one is settled, `git commit -m "chore: address critique findings"`. Offer a re-critique
or move to close.

## Close

After approval — and only after — push and open the PR by following
`pr-first-contributions`. `/implement` adds nothing to that procedure and must not
paraphrase it: re-run the branch staleness check before pushing, confirm the quality gates passed
and the tree is clean, then open a draft PR whose title and body meet that rule's spec. If a PR
for the branch is already open, update it rather than opening a second.

Then:

- `scratchpad_archive(scratchpad_id=<plan pad>)` — it has served its purpose
- `kv_delete` every `plan:<slug>:*` key
- `close_process` any surviving workers
- Return the PR links

## Notes

- Never commit to the default branch; never push or open a PR without explicit approval
- Workers write code; the orchestrator owns git, todos, and KV
- Todo status is `open` | `in_progress` | `backlog` | `completed`; priority is `high` | `medium` | `low`
- If the plan turns out to be wrong, fix the plan and re-approve — do not let implementation
  quietly diverge from the approved record
