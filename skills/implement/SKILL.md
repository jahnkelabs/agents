---
name: implement
description: Execute an approved plan as Solo-orchestrated waves, critique the result, and present it
argument-hint: "[plan/<slug>]"
disable-model-invocation: true
---

# Implement

Orchestrate execution of an approved plan. You own git, todo lifecycle, and worker
coordination. Workers write code and nothing else.

The plan declares **work items**. This skill groups them into **tasks** — one worker, one todo,
one scratchpad, one model tier — and gates that roster before anything spawns. Tasks then run to
completion without per-task review gates. Workers escalate on **deviation**, not on completion —
see [Escalation](#escalation).

## Input

- **A plan pad** (`plan/<slug>` or an id) — the normal case
- **No arguments** — list active plan pads via `scratchpad_list(tags=["plan"])` and ask
- **Existing todos for the slug** — this is a resumed run. The todos *are* the decomposition, so
  reuse them rather than decomposing again; pick up where the incomplete tasks are

Read the pad fully. If none exists, send the user to `/plan`.

Use whichever Solo project is currently selected, consistent with `/plan`.

## Setup

Skip anything the `/plan` fork already confirmed — do not re-ask what was just settled.

1. **Decompose the work items into tasks.** Items marked `same-worker` share a task. Items marked
   `after` land in a later wave. Items whose `**Files**:` overlap never run concurrently.
   Everything else is free, so group for coherence rather than for a worker count — a task that
   spans one subsystem is easier to brief and easier to verify than one assembled to fill a slot.
2. **Assign each task a model and effort tier.** These are not inherited from the session. Judge
   by what the task actually demands: mechanical edits against precise line references are not the
   same work as a rewrite that must preserve a behavioral contract, and should not cost the same.
   `list_agent_tools` resolves the runtime; `--model` and `--effort` vary within it.
3. **Gate the roster.** This is an approval stop, not an announcement.
   ```
   5 workers, 2 waves.

     wave 1
       A  rules/output-discipline.md, rules/yagni.md          opus · xhigh
          Author two rules from scratch, matching house style across three
          existing files, with a clause that must be byte-identical in both.
       B  rules/pr-first-contributions.md                     opus · xhigh
          Rewrite 166 lines to ~90 while preserving fifteen behavioral
          imperatives, each stated exactly once.
       C  skills/{grill,stash,recall}/SKILL.md                sonnet · medium
          Three localized edits against precise line references.
     wave 2
       D  README.md                                           sonnet · high
          Read the wave-1 diff and reconcile every claim it falsified.

   Critique at the end: <models>.

   Adjust any model, effort, or grouping, or approve as proposed.
   ```
   **The summary is the justification.** A task described as "three localized edits against
   precise line references" argues for its tier on its face; one described as "preserve fifteen
   imperatives while cutting 46% of the file" argues for a different one. Write the summary so the
   tier follows from it, and never add a separate rationale field.

   Grouping is adjustable, not just tiers — seeing the roster is exactly when it becomes obvious
   that two tasks should be one, or that one is doing too much.

   Offer the enabled runtimes for the end-of-run critique in the same gate. One stop, not two.
   Never hardcode a roster.
4. **Create the branch** in each target repo, off whatever `origin/HEAD` points to — never a
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
   `kv_set(key="plan:<slug>:branch:<repo>", value="<branch>")` — keys are lowercase, so a slug
   carrying an uppercase timestamp must be normalized before use.
5. **Create the todos** — one per approved task. The body carries the **task spec**: the work
   items it covers, their files, and their verification. This is not a copy of the plan; the plan
   holds work items and the todo holds the grouping, which exists nowhere else. The worker reads
   its own todo, so this is the only place the spec needs to be written.
   ```
   todo_create(title="<task>: <name>", body=<task spec>,
               tags=["plan:<slug>", "project:<repo>", "task:<letter>"])
   todo_add_blocker(todo_id=<dependent>, blocker_id=<prerequisite>)
   ```

Then run unattended through every wave.

## Wave execution

Workers are Solo agents, per `solo-agent-orchestration`. Nothing below works otherwise — a
vendor sub-agent cannot hold a lock, own a todo, or wake this session when it finishes.

Call `whoami` once and keep the returned `process_id`. Every worker needs it to signal back.

For each wave, for each task in it:

1. `todo_update(todo_id, status="in_progress")`
2. Spawn at the approved tier, with the constraints enforced rather than requested:
   ```
   spawn_agent(agent_tool_id=<runtime>, name="<task>-<slug>", extra_args=[
     "--model", "<approved model>",
     "--effort", "<approved effort>",
     "--permission-mode", "auto",
     "--settings", '{"permissions":{"deny":["Bash(git add:*)","Bash(git commit:*)",
                     "Bash(git push:*)","Bash(git checkout:*)","Bash(git switch:*)",
                     "Bash(git reset:*)","Bash(git stash:*)"]}}',
     "--append-system-prompt", "<the preamble below>"])
   ```
   `auto` keeps the worker from stalling on its actual job while leaving the requests that matter
   reviewable — required on every Claude worker per `solo-agent-orchestration`, where a Codex
   runtime takes `--approve-for-me --no-alt-screen` instead. Never `bypassPermissions`, and never
   `acceptEdits`.

   The deny list, not the permission mode, makes the git prohibition structural. A worker that
   *cannot* stage is safer than one asked not to, and cross-commits between workers sharing a tree
   are silent when they happen.
3. `send_input(process_id, input=<agent_instructions + the assignment below>)`

The **preamble**, passed once via `--append-system-prompt` and identical for every worker in the
wave:

```
You are a Solo agent implementing one task of an approved plan.

Working directory: <absolute repo path>. Stay inside it.

Do not write any file outside your task's declared paths — needing to is a deviation.
Do not create or complete todos, or write KV. Write only your own report scratchpad.
Git writes are denied at the permission layer; the orchestrator owns git.

When stuck, or when finishing would mean departing meaningfully from the task as written:
record what you found and stop. Do not improvise a fix, expand scope, or proceed down an
unapproved path. Stopping is correct behavior here, not failure.

Lock and KV keys must be lowercase — normalize any path before using it as a key.
```

The **assignment**, passed via `send_input` and different for every worker:

```
Your task is Solo todo <id>. Read it — it carries your work items, their files, and their
verification. The full plan is scratchpad <id> if you need surrounding context.

Prior waves: <what already landed, or "this is the first wave">

Before you touch anything, lock each file you will modify:
  lock_acquire(key="path:<lowercased declared path>", lease_ttl_seconds=3600)
If a lock is unavailable, stop and escalate — do not wait or work around it.

1. Read every file your task names, fully, before changing anything
2. Make the changes
3. Run the task's automated verification
4. Write your report to scratchpad "<slug>/<task>" — what you did, verification output, and
   anything you found that the task did not anticipate. Begin the report with "ESCALATION:" if
   you are stopping rather than finishing.
5. Release your locks
6. Signal completion as your last act:
     timer_set(delay_ms=0, delivery_process_id=<orchestrator process_id>,
               body="Task <letter> complete. Report in <slug>/<task>. <clean|escalated>.")
```

4. **Wait for the workers to signal.** Each one wakes this session directly when it finishes.
   Arm one idle timer per wave as the dead-worker fallback only:
   ```
   timer_fire_when_idle_all(processes=[<pids>], max_wait_ms=<generous guard>,
     body="Wave <N> guard expired. Any worker that has not signalled has died, hung, or
           failed to finish — investigate before treating it as complete. Check each
           task's scratchpad and process status.")
   ```
   Do not treat that timer as the completion signal. It has no debounce, and a worker thinking at
   length is indistinguishable from a finished one — see `solo-agent-orchestration`.
5. When every task in the wave has signalled, `scratchpad_find` for `ESCALATION` across the
   wave's report pads before reading any of them in full. If none matched, read only what you
   need to write the commit messages.
6. **Commit each completed task separately**, staging only its declared paths:
   ```bash
   cd <repo path>
   git add <task's declared paths>
   git commit -m "<type>(<scope>): <task summary>"
   ```
   Never `git add -A` — another task's work may be in the tree.
7. `todo_complete(todo_id, completed=true)` for each task that finished.
8. `close_process(process_id)` for each worker.

## Escalation

A worker escalates when it cannot self-resolve, or when finishing would mean deviating
meaningfully from what was approved. Writing an undeclared path counts as a deviation.

**In-flight workers in the same wave finish.** They hold disjoint file scopes and have no
dependencies on each other, so nothing is building on the problem.

The worker's report scratchpad is the durable record, and its completion signal says whether it
escalated. The wave join is where it surfaces, and the only place it surfaces — by the time you
present, every escalation has been resolved or the run stopped here. At the join, stop and show
the whole wave together:

```
Wave <N> complete — one task needs discussion.

  A  ✓ committed
  B  ⚠ escalated — <what the worker found>
  D  ✓ committed
  C  ⊘ blocked behind B

The plan assumed <X>; the code actually does <Y>.
Options: <adjust the plan / different approach / drop the work item>
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
  Tasks:   <N> committed
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
