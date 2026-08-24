---
name: implement
description: Execute an approved plan as a loop of milestones, each landing its own PRs
argument-hint: "[plan/<slug>]"
disable-model-invocation: true
---

# Implement

Orchestrate execution of an approved plan. You own git, todo lifecycle, and worker
coordination. Workers write code and nothing else.

The plan declares **slices**. This skill composes them into **milestones**, and each milestone
ships its own PRs before the next one starts.

```
  slice       one worker's unit of work. Narrow, vertical, one repository.
  milestone   a consumable chunk of a plan, sequenced in a DAG. May span
              repositories. The unit of delivery.
  wave        the concurrency schedule inside a milestone, from file overlap.
```

A **task** is one worker, one todo, one report scratchpad, one model tier. A task carries one
slice, or several that must not drift apart. Workers escalate on **deviation**, not on
completion — see [Escalation](#escalation).

## Input

- **A plan pad** (`plan/<slug>` or an id) — the normal case
- **No arguments** — list active plan pads via `scratchpad_list(tags=["plan"])` and ask
- **Existing todos for the slug** — this is a resumed run. The todos *are* the composition, so
  reuse them rather than composing again. Pick up at the first milestone with open tasks.

Read the pad fully. If none exists, send the user to `/plan`.

Use whichever Solo project is currently selected, consistent with `/plan`.

## Speaking

`rules/chat-vocabulary.md` reserves the headings and the footer. Speak on four occasions and no
others: a gate, a milestone landing, an escalation, and a failure. The rest of the run is
silent.

Narrate no worker completion and no wave boundary. Worker traffic drove 78% of the assistant
turns in one run, and none of it needed a reply.

## Compose the milestones

Skip anything the `/plan` fork already confirmed — do not re-ask what the user just settled.

1. **Compose milestones from the plan's slices.** A milestone's outcome is one sentence with no
   `and`. Add slices while that sentence stays true. Open a new milestone once the sentence needs
   an `and`. That is the whole test.

   A milestone may span repositories. It then lands **one PR per repository it touches**. Each
   of those PR titles states the milestone's outcome, scoped to its repository.
2. **Order the milestones into a DAG.** Aggregate every slice's `after` constraint onto the
   milestones that hold the two slices. That aggregate is the dependency half of the order.

   **File overlap forces ordering, never parallelism.** Add an edge for every file two milestones
   share. Two milestones that touch one file run in sequence, whatever their `after` constraints
   allow. The second branch would otherwise carry a conflict the user never approved.
3. **Schedule the waves inside each milestone.** Slices marked `same-worker` share one task.
   Slices marked `after` land in a later wave. Slices whose `**Files**:` overlap never run
   concurrently. Everything else is free. Group for coherence rather than for a worker count. A
   task that spans one subsystem is easier to brief and verify than one assembled to fill a slot.
4. **Assign each task a model and effort tier.** A task does not inherit these from the session.
   Judge by what the task actually demands. Mechanical edits against precise line references are
   not the same work as a rewrite that must preserve a behavioral contract. The two should not
   cost the same. `list_agent_tools` resolves the runtime, and model and effort vary within it.
5. **Gate the roster.** This is an approval stop, not an announcement. Milestones and their PR
   titles come first. Waves and tiers come second, inside the milestone that holds them.

   **Approve — roster for `plan/<slug>`**

   ```
   3 milestones, 5 workers.

     M1  reserve a chat vocabulary for messages that need a reply
         agents  feat(rules): reserve a chat vocabulary for messages that need a reply
         wave 1
           A  rules/chat-vocabulary.md                       opus · xhigh
              Author one rule from scratch, matching house style across six
              existing files.
         wave 2
           B  skills/{research,recall,stash}/SKILL.md        sonnet · medium
              Three localized edits against precise line references.

     M2  give every milestone its own provisioned worktree
         agents  feat(worktree): cut and provision one worktree per milestone
         after M1 — both touch README.md
         wave 1
           C  skills/worktree/SKILL.md, scripts/wt-clone.sh  opus · xhigh
              Author a skill and a helper script, with a measured filesystem
              pre-check the exit code cannot replace.

     M3  deliver each milestone as its own PRs
         agents  feat(skills): deliver each milestone as its own PRs
         after M2 — both touch README.md
         wave 1
           D  skills/{plan,implement}/SKILL.md               opus · xhigh
              Rewrite two skills onto one delivery vocabulary that must not
              drift between them.
           E  rules/pr-first-contributions.md                sonnet · high
              Add stacked-PR guidance to a general rule without turning it
              into an appendix.

     Concurrent stacks: 1. All three milestones touch README.md, so they
     ship in sequence.

     Critique per milestone: <models> — from the plan.
     Sandbox: <runtime> cannot deny a worker's git writes.
   ```

   Adjust any milestone boundary, model, effort, or grouping, or approve as proposed.

   ⏸ waiting on you: approve the roster, or name what to change

   **The summary is the justification.** One task reads "three localized edits against precise
   line references". Another reads "a rewrite of two skills onto one vocabulary". Each summary
   argues for a different tier by itself. Write the summary so the tier follows from it, and never
   add a separate rationale field.

   **Bound the parallelism by the machine as well as by the DAG.** Each milestone stack runs its
   own containers, volumes, and network. Concurrent stacks therefore consume the machine's memory
   and disk in proportion. State how many stacks you propose to run at once, as the block above
   does. The user adjusts that count here.

   State no ceiling. This skill runs on more than one machine, so any figure is false on the
   others. The user knows what the machine holds; the skill does not.

   The user can adjust boundaries, not just tiers. The roster is where a milestone that does two
   things becomes obvious. It is also where two milestones that should be one become obvious.

   **The critique roster comes from the plan.** `/plan` selects it before it hands off, and the
   pad records it. Restate it in this gate as a line the user can change, and do not ask again.
   One run holds one roster, or nobody can compare its milestone findings. Ask for a roster only
   when a directly invoked plan carries none, and then ask inside this gate. One stop, not two.
   `list_agent_tools` resolves the enabled runtimes. Never hardcode a roster.

   **Disclose a runtime that cannot deny a worker's git writes.** An editing worker needs that
   denial per worker. `rules/solo-agent-orchestration.md` carries the posture and the disclosure
   it demands, and the adapter names what each runtime can enforce. Read both before you propose a
   runtime. Where one cannot deny them, include the `Sandbox` line above and name the exposure.
   Two workers in one tree cross-commit each other's work. Omit that line where every runtime in
   the roster denies them. Do not restate a flag, and never promise a denial the roster cannot
   give.
6. **Create the todos** — one per approved task, tagged with its milestone. The body carries the
   **task spec**: the slices it covers, their files, and their verification. This is not a copy of
   the plan. The plan holds slices; the todo holds the grouping, which exists nowhere else. The
   worker reads its own todo, so this is the only place the spec belongs.
   ```
   todo_create(title="<task>: <name>", body=<task spec>,
               tags=["plan:<slug>", "milestone:<m>", "project:<repo>", "task:<letter>"])
   todo_add_blocker(todo_id=<dependent>, blocker_id=<prerequisite>)
   ```
   Keys and tags are lowercase. Lowercase any slug that carries an uppercase timestamp.

   **Every automated check must be able to fail.** Run each check against the pre-change tree
   before you write it into the spec, and record the output there. A check that already passes
   needs a mutation proof. Copy the file to a scratch path, break what the check tests, and record
   the failure on the copy. Never mutate the repository for a proof. Mark a check `unverifiable`
   where neither route works, and say why.

   Two checks in the corpus could never fire. `grep -rn 'App\\Models'` searched for two literal
   backslashes. `grep -ci Test` matched an unrelated domain string. Both read as passing evidence.

## The milestone loop

Run the milestones in DAG order. One pass through this loop ships one milestone. The next pass
starts again at step 1.

1. **Cut a worktree and branch for each repository the milestone touches.** Run
   `/worktree cut <repo> <milestone>`. That skill owns the layout, the provisioning, the container
   naming, and the refusal on a plain clone. Add nothing to its procedure and do not paraphrase
   it.

   The base is `origin/HEAD`, or the predecessor milestone's branch in that repository when the
   milestones stack in one repository.

   ```
   kv_set(key="plan:<slug>:milestone:<m>:branch:<repo>", value="<branch>")
   ```

   `/worktree` records the tree path under `plan:<slug>:milestone:<m>:worktree:<repo>`. Both keys
   carry the milestone and the repository. One plan holds several branches per repository. One
   milestone cuts one worktree per repository. Omit the repository, and the second cut overwrites
   the first. Teardown then leaks a worktree with its stack running.
2. **Re-check the census in the worktree.** The plan's `**Files**:` lists came from a census at
   plan time. Repeat that census now for this milestone's slices, in the tree you just cut.
   `/plan` names what it searches for: the caller, the test, and the standard your change
   falsifies.

   **Escalate on drift.** A path the census now returns, and the plan does not declare, is a
   deviation. Stop and put it to the user. Do not widen a task's declared paths yourself.
3. **Run the milestone's waves.** See [Wave execution](#wave-execution). Every worker works
   inside the worktree of the repository its slices belong to. Each wave commits its own tasks at
   its join, so no task commit follows the last wave.
4. **Critique this milestone's diff.** Name the base explicitly, and pass the plan:
   ```
   /critique --base <the milestone's effective base> --plan <the plan pad>
   ```
   The effective base is the ref step 1 cut from. That is `origin/HEAD`, or the predecessor
   milestone's branch where the milestones stack. Without `--base`, `/critique` falls back to the
   default branch and reviews the predecessor's diff as this milestone's. It then re-raises
   findings the user already settled.

   Use the roster the plan supplied. `/critique` does not ask again.
5. **Apply the filter and present what survives.** `/critique` owns the filter, the ledger, and
   the presentation of a finding. Point at it and add nothing. Fix no finding unilaterally.

   **Commit the remedies.** `/critique` applies each accepted fix in this milestone's worktrees,
   and it leaves them uncommitted. Commit them here, once per repository, before the push gate:
   ```bash
   git add <the paths the ledger's fixes touched>
   git commit -m "fix(<scope>): apply the critique remedies for milestone <m>"
   ```
   This is the one commit outside a wave join. Skip it, and the push gate counts commits over a
   dirty tree.
6. **Gate the push.** `pr-first-contributions` forbids a push without explicit approval, and this
   gate is where you ask. Re-run its staleness check first.

   **Approve — push milestone `<m>`**

   ```
     <repo>   <N> commits   base <branch>   "<the PR title>"
     <repo>   <N> commits   base <branch>   "<the PR title>"

     Quality gates: <results>
   ```

   ⏸ waiting on you: approve the push for milestone `<m>`
7. **Push and open one PR per repository the milestone touches.** Follow
   `pr-first-contributions`, which owns the stacked-PR base and the title spec. Update an open PR
   rather than opening a second one.
8. **Announce the landing.** It reports and does not block.

   **Landed — `<milestone>`**

   ```
   <the milestone's outcome, in one sentence>

     <repo>   <PR url>   <N> commits   base <the default branch>
     <repo>   <PR url>   <N> commits   base <the predecessor milestone's branch>

     Quality gates: <results>
     Critique:      <N> findings, <M> presented, <models>
   ```

   Then the ledger, in the shape `/critique` defines. `Landed` carries no footer, because the
   run continues.
9. **Tear down and clean up.** Do all four, in this order:
    ```
    timer_cancel(timer_id=<each guard armed for this milestone>)
    close_process(process_id=<each worker of this milestone>)
    lock_release for any lock a dead worker left held
    stop the stack and remove the worktree, per /worktree's teardown block
    ```
    The branch lives on the remote once the push succeeds, so the worktree is disposable. A guard
    left armed fires during a later milestone and arrives as an instruction about workers that
    finished long ago.

Then start the next milestone.

**Critique and triage block the next milestone. The user's PR review does not.** A finding that
survives the filter may change what the next milestone should do, so the loop waits for it. A PR
review does not, and the run would otherwise stall behind a human queue. Open the PR, announce
the landing, and move on.

## Wave execution

Workers are Solo agents, per `solo-agent-orchestration`. Nothing below works otherwise. A vendor
sub-agent cannot hold a lock, own a todo, or wake this session when it finishes.

Call `whoami` once and keep the returned `process_id`. Every worker needs it to signal back.

For each wave of the current milestone, for each task in it:

1. `todo_update(todo_id, status="in_progress")`
2. Spawn at the approved tier, enforcing every constraint the runtime can enforce:
   ```
   spawn_agent(agent_tool_id=<runtime>, name="<task>-<slug>", extra_args=[
     <the model and effort arguments, at the approved tier>,
     <the auto-approval argument from the adapter>,
     <the editing-worker arguments from the adapter, with any per-command git denial>,
     <the system-prompt argument carrying the preamble below, if the runtime has one>])
   ```
   `list_agent_tools` returns a `tool_type` for each runtime. Read `references/runtime-<tool_type>.md`
   and use the arguments it lists. Never write a launch argument from memory. A runtime renames
   its flags between releases, and the adapter is the only current record.

   Auto-approval keeps the worker from stalling on its actual job. It still leaves the requests
   that matter reviewable. Never use a bypass mode.

   **Every task worker is an editing worker.** `rules/solo-agent-orchestration.md` carries that
   class and what each runtime can enforce for it. A sandbox that permits a worker's edits permits
   `git add` in the same tree. Only a per-command deny list denies it, where the runtime scopes one
   to a single worker. Use that denial where the runtime has one. A worker that *cannot* stage is
   safer than one asked not to. Two workers that share a tree cross-commit silently.

   Where the runtime has no such denial, the denial does not exist. The roster gate disclosed
   that. Do not restate it here as a guarantee.

   When a spawn fails, read the adapter, correct the arguments, and retry once. Escalate on the
   second failure, and never loosen a flag to make a launch succeed.
3. `send_input(process_id, input=<agent_instructions + the assignment below>)`

The **preamble** has two halves. What a worker must not touch, and what to do when stuck, are
identical for every worker in the milestone. The working directory is not. A milestone spanning
repositories therefore passes one preamble per repository, and a slice belongs to exactly one
repository. Each worker's directory is the worktree of the repository holding its slices. Pass the
preamble through the runtime's system-prompt argument, or in every prompt where the runtime has
none.

```
You are a Solo agent implementing one task of an approved plan.

Working directory: <the worktree of the repository this task's slices sit in,
absolute>. Stay inside it.

Do not write any file outside your task's declared paths — needing to is a deviation.
Do not create or complete todos, or write KV. Write only your own report scratchpad.
The orchestrator owns git. Run no git write, whatever your permission layer allows.

When stuck, or when finishing would mean departing meaningfully from the task as written:
record what you found and stop. Do not improvise a fix, expand scope, or proceed down an
unapproved path. Stopping is correct behavior here, not failure.

Lock and KV keys must be lowercase — normalize any path before using it as a key.
```

The **assignment**, passed via `send_input` and different for every worker:

```
Your task is Solo todo <id>. Read it — it carries your slices, their files, and their
verification. The full plan is scratchpad <id> if you need surrounding context.

Prior waves: <what already landed, or "this is the first wave of this milestone">

Before you touch anything, lock each file you will modify:
  lock_acquire(lock_key="path:<lowercased absolute path>", lease_ttl_seconds=3600)
The key is the absolute path inside your worktree, not the declared relative one. Solo scopes a
lock to the project, and one project holds many repositories and many worktrees. A relative key
therefore collides with every tree that has a file of that name.
If a lock is unavailable, report which actor holds it, then stop and escalate — do not wait or
work around it.

1. Read every file your task names, fully, before changing anything
2. Make the changes
3. Run the task's automated verification. Every check must be able to fail.
   Run each one against the pre-change state first. Where a check already passes, prove it fails
   on a mutated copy under your scratch directory. Never mutate the repository for a proof.
4. Write your report to scratchpad "<slug>/<milestone>/<task>". Record what you did, the verification
   output, and anything you found that the task did not anticipate. Begin the report with
   "ESCALATION:" if you stop rather than finish.
5. Release your locks
6. Signal completion as your last act:
     timer_set(delay_ms=1, delivery_process_id=<orchestrator process_id>,
               body="Task <letter> complete. Report in <slug>/<milestone>/<task>. <clean|escalated>.")
```

**The report pad carries the milestone, not the task letter alone.** A composition may restart
task letters per milestone, so `<slug>/<task>` lets M2 task A overwrite M1 task A. That destroys
an escalation record before `## Close` reads it.

4. **Wait for the workers to signal.** Each one wakes this session directly when it finishes.
   Arm one idle timer per wave as the dead-worker fallback only:
   ```
   timer_fire_when_idle_all(processes=[<pids>], max_wait_ms=<generous guard>,
     body="Milestone <m> wave <N> guard expired. Any worker that has not signalled has died,
           hung, or failed to finish — investigate before treating it as complete. Check each
           task's scratchpad and process status.")
     → timer_id
   ```
   Do not treat that timer as the completion signal. It has no debounce, and a worker thinking at
   length is indistinguishable from a finished one — see `solo-agent-orchestration`.

   Keep the returned `timer_id`. One guard per wave means one id to hold.
5. When every task in the wave signals, `timer_cancel(timer_id=<id>)` for that wave's guard. Then
   run `scratchpad_find` for `ESCALATION` across the wave's report pads. Do this before you read
   any pad in full. If nothing matches, read only what you need for the commit messages.

Then commit the wave's tasks. **Commit each task separately, staging only its declared paths:**

```bash
cd <the worktree of the repository that task wrote in>
git add <task's declared paths>
git commit -m "<type>(<scope>): <task summary>"
```

Never `git add -A` — another task's work may be in the tree. A task that wrote in two
repositories commits once per repository. Then `todo_complete` each task, and start the next wave
of this milestone.

**The wave join is the only place a task commits.** No step after the last wave commits a task
again. A second task commit instruction stops on `nothing to commit`. Deferring it instead lets a
later wave's changes enter an earlier task's diff.

The milestone loop's critique remedies are the one exception, and step 5 owns that commit.

## Escalation

A worker escalates when it cannot self-resolve. It also escalates when finishing would mean
deviating meaningfully from what the user approved. A worker that writes an undeclared path
deviates from the task.

**In-flight workers in the same wave finish.** They hold disjoint file scopes and have no
dependencies on each other, so no other work depends on the problem.

The worker's report scratchpad is the durable record, and its completion signal says whether it
escalated. The wave join is the only place an escalation appears. Resolve every escalation before
the milestone lands, or the run stops here.

**Blocked — milestone `<m>` wave `<N>`**

```
  A  ✓ committed
  B  ⚠ escalated — <what the worker found>
  D  ✓ committed
  C  ⊘ blocked behind B

The plan assumed <X>; the code actually does <Y>.
Options: <adjust the plan / a different approach / drop the slice>
```

⏸ waiting on you: pick one option for task `B`

Do not start the next wave until you resolve this. If the plan needs a change, update the pad so
it stays the record of what the user actually agreed.

Automated verification failing is not automatically an escalation — a worker that can fix it
within the plan's intent should. It escalates when the fix would require departing from the plan.

## Close

Close the run after the last milestone lands. Every milestone already pushed its own PRs and tore
down its own worktrees, so nothing here opens a PR.

1. **Run the integration critique.** This is a step, not an option:
   ```
   /critique --integration <slug> --plan <the plan pad>
   ```
   It runs the four integration lenses with the roster the plan supplied. One of them is the
   reason this step exists: did every slice the plan declared land in some milestone? A
   per-milestone critique cannot answer that, because it sees one milestone's diff.

   Every milestone already pushed its branch, so the diffs live on the remote. Run this from the
   stable `main` worktree of each container. Step 9 of the loop removed the milestone worktrees.

   Present what survives, through `/critique`'s filter and ledger. A finding here reaches a
   milestone that already shipped. It lands as a follow-up rather than as a fix to a closed
   milestone. Escalate it as `Blocked` where it invalidates a PR the run already opened.
2. `scratchpad_archive(scratchpad_id=<plan pad>)` — it has served its purpose
3. `kv_delete` every `plan:<slug>:*` key
4. `close_process` any surviving worker
5. `git worktree prune` in each container, per `solo-agent-orchestration`
6. Return every PR URL the run opened, grouped by milestone

**The order matters.** The integration critique compares the landed branches against the plan
pad. Archive the pad first, and you remove half of that comparison.

## Notes

- Never commit to the default branch; never push or open a PR without explicit approval
- Workers write code; the orchestrator owns git, todos, and KV
- Todo status is `open` | `in_progress` | `backlog` | `completed`; priority is `high` | `medium` | `low`
- If the plan turns out to be wrong, fix the plan and re-approve. Never let implementation
  quietly diverge from the approved record
