---
description: Fan out with Solo agents, never a vendor's native sub-agent mechanism. Workers signal their own completion and report to a durable surface
---

# Solo agent orchestration

When you delegate work to a parallel worker, that worker is a **Solo agent**. Spawn it through the Solo MCP server. Never use the runtime's own sub-agent mechanism. That rules out Claude's Task tool, Codex's sub-agents, and any other vendor's in-process worker.

## Default policy

- **Default:** Every spawned worker is a Solo agent, launched with `spawn_agent`. This holds even for a quick read-only lookup.
- **Exceptions:** Only when the user explicitly asks for the vendor mechanism.
- **Solo unavailable:** Say so, then do the work inline or stop. This rule exists to prevent one failure: a fan-out that changed mechanism without telling anyone.
- **Scope:** This rule governs delegation, not every tool call. It applies to a fan-out from a skill, and to one from an explicit request. An explicit request looks like "check these five services in parallel". It also applies when you judge that a job splits. You do not fan out when you read a few files yourself.

## Why

| | |
|---|---|
| **Visible and addressable** | A Solo worker appears in the UI and survives the turn that spawned it. You can inspect it, re-prompt it, or kill it later. A vendor sub-agent returns one block of text and then exits. You cannot inspect it. |
| **Model choice** | A Solo agent launches with the model and effort its job needs. It can also run a different runtime than the session. A vendor sub-agent runs only the session's vendor and settings. |
| **Coordination primitives** | Solo workers hold locks, comment on todos, and write KV and scratchpads. Those primitives make parallel writes to a shared tree safe, and they make an escalation visible. |
| **Portability** | The workflow does not become a dependency on one vendor's agent features. |

## The shape

1. `list_agent_tools` — resolve the runtime. Never hardcode a roster or an id.
2. `spawn_agent(agent_tool_id=<id>, name="<role>-<slug>", extra_args=[…])` → `process_id`, `agent_instructions`. See **Capability, not compliance** below for what belongs in `extra_args`.
3. `send_input(process_id, input=<agent_instructions + the assignment>)` — prepend the returned instructions, or the worker does not know that it is a Solo agent.
4. The worker does its job and writes its report to the **durable surface** you gave it. It signals completion as its last act.
5. On the signal, read the durable surface. Never scrape process output for content.
6. `close_process(process_id)` for every worker. A join that leaves processes open leaks them.

## Workers signal completion

A worker's last act is to wake the orchestrator directly:

```
timer_set(delay_ms=1, delivery_process_id=<orchestrator process_id>,
          body="<task> complete. Report in <scratchpad>. <clean|escalated>.")
```

Solo rejects a zero delay, so `1` is the smallest legal value.

**The worker knows when it is finished, and nothing else does.** Push the signal, and do not watch for its absence. The orchestrator receives completions rather than infers them.

Every worker prompt therefore carries the orchestrator's own `process_id`, which `whoami` returns.

## Idle timers are the fallback, not the signal

`timer_fire_when_idle_all(processes=[<pids>], max_wait_ms=<guard>, body=…)` has one job. It catches the worker that dies, hangs, or never signals. Give `max_wait_ms` a real guard value. In the body, state that a worker which never signalled is a failure to investigate, not a completion.

Idle detection cannot do more than that, for three reasons:

- **There is no debounce.** The timer fires on the first detected idle transition. No parameter changes this. `timer_fire_when_idle_all` accepts only `processes`, `max_wait_ms`, `body`, `delivery_process_id`, `metadata`, and `project_id`. Solo ignores an unknown key silently rather than rejecting it.
- **A thinking worker looks finished.** Solo derives idle state from terminal output, and a worker that reasons at length emits none.
- **Solo treats an already-idle process as satisfied.** For `..._all`, a process that is already idle when you schedule the timer counts as satisfied. An entirely idle watch list returns `already_satisfied` and creates **no timer**. Schedule the timer immediately after `spawn_agent`, before the workers produce output, and you may never wake at all. For `..._any` the opposite holds: Solo ignores an already-idle process, and the timer waits for a new transition.

**The timer body is an instruction, not a note.** It arrives as a fresh turn, and the orchestrator acts on it literally. Every branch the orchestrator must take on wake belongs inside the body. The orchestrator never reads guidance that lives only in the surrounding prose.

**Cancel the guard the moment the last worker signals.** `timer_fire_when_idle_all` returns a `timer_id`. Keep it, and call `timer_cancel(timer_id=<id>)` at the join, before you commit anything. A guard you leave armed still fires. It arrives as a fresh turn carrying an instruction about workers that finished long ago, and the orchestrator then acts on a stale premise. Arm one guard, hold its id, cancel it at the join: that is the whole lifecycle.

## Capability, not compliance

`spawn_agent` takes `extra_args`. Solo appends these per-launch arguments to the resolved command. They do not change the agent tool's saved defaults. Three uses matter.

**Match the worker to the job.** Set the model and the reasoning effort per worker. A worker does not inherit them from the session. A mechanical edit against precise line references is one job. A rewrite that must preserve a behavioral contract is another. The two should not cost the same.

**Launch every worker in auto-approval mode.** Each runtime fixes the mode. It is not a per-wave judgment call. Auto-approval lets a worker work through ordinary steps without stalling on a prompt. A reviewer still sees the requests that matter. A bypass mode removes that review from a process that runs unattended, which is the exact situation review exists for. A read-only assignment is not an exception. A worker's brief says what it intends to do, not what it is able to do.

**Read the runtime's adapter before you spawn it.** `list_agent_tools` returns a `tool_type` for each runtime. Read `references/runtime-<tool_type>.md`, which maps every policy in this rule to the argument that implements it. Each runtime names its own flags and renames them between releases, so never write a launch argument from memory.

**An adapter also records what its runtime cannot do.** A policy here is a requirement, not a promise that every runtime can meet it. A runtime may have no way to express one of them, and the adapter says so. Read it before you rely on a guarantee.

**Escalate a launch failure. Never loosen a flag.** When `spawn_agent` fails, read the runtime's adapter, correct the arguments, and retry once. When the second attempt fails, stop and escalate. Never relax a sandbox, drop a deny list, or reach for a bypass mode to make a launch succeed. Escalation is the terminal action, and this rule offers no fallback below it.

One session already paid for this. The third spawn attempt abandoned `spawn_agent` and launched Codex directly. It used the exact bypass flag this rule and `references/runtime-codex.md` both prohibit by name. Nothing told the retry loop when to stop, so the loop found the prohibited flag on its own.

**Bound a worker's writes by whether it edits the target.** Two classes exist. An immutable-target worker reads the target and writes only scratch. An editing worker changes the target, and its working directory is its milestone worktree. One posture does not fit both. Decide the class first, then read the runtime's adapter for the arguments.

**The immutable-target worker.** Every critic, every research agent, and every retro agent is one. Give it a writable scratch directory, an unwritable target, and unrestricted reads. A runtime that scopes writes by directory makes that structural.

**Here Codex enforces what Claude can only request.** That reverses what the two adapters otherwise suggest, so treat it as a measurement. Verified on codex-cli 0.149.0. The worker ran with its working directory set to a scratch directory, writes scoped there, and reads unrestricted:

```
  read the target        OK
  write scratch          OK
  write the target       BLOCKED — Operation not permitted
  git add in the target  BLOCKED
  man cp                 OK
```

`references/runtime-codex.md` carries the arguments that produce this.

Claude scopes writes by tool rather than by directory. **A tool deny list does not bound shell redirection.** A worker denied the file-editing tools still writes the target through the shell. This run's critics launched under exactly that deny list, and they wrote freely. On Claude the immutable target is a request rather than a structure. A brief that relies on it says so.

**The editing worker.** A sandbox that permits its edits permits `git add` in its milestone worktree. No directory-scoped posture denies git there. A per-command deny list does, where the runtime scopes one to a single worker.

Where no runtime in the roster can, the denial does not exist. **Disclose the gap rather than restate the promise.** Name the runtime that cannot enforce it, and name the exposure. Two workers in one tree cross-commit each other's work, silently, and the undo costs a lot of time. Give each worker its own tree, or accept the risk knowingly and say so.

**Carry the invariant preamble once, where the runtime allows it.** Two things are identical across every worker in a wave. They are what a worker must not touch, and what to do when stuck.

The working directory is not one of them. A milestone that spans repositories cuts one worktree per repository. A slice belongs to exactly one repository, so that milestone passes one preamble per repository. A runtime with a system-prompt argument takes the preamble there. That shortens each `send_input` and makes the constraints harder to drop by accident. A runtime without one carries the preamble in every prompt.

## One worktree per milestone

A worker never shares a working tree with the user. Cut one worktree per milestone and per repository. Cut it from a bare-plus-worktrees layout, and use these paths:

```
  container          <the repository's own path>                 at whatever depth it sits
  bare repo          <container>/.git                            `git rev-parse --is-bare-repository` returns true
  stable             <container>/main                            the user's worktree, never removed
  worktree           <container>/<plan-slug>-<milestone-slug>    one plan's worktrees sort together
  branch             <type>/<milestone-slug>                     the plan prefix stays out of the branch
  example container  ~/Code/jahnkelabs/agents
  example worktree   ~/Code/jahnkelabs/agents/<plan-slug>-<milestone-slug>
  create             test for the branch, then cut:
                       git worktree add <worktree> -b <branch> <base>   no such branch yet
                       git worktree add <worktree> <branch>             the branch already exists
                     base = origin/HEAD, or the predecessor milestone's branch when stacked
  record             kv_set plan:<slug>:milestone:<m>:worktree:<repo>
  remove             at milestone close, after a successful push
  sweep              git worktree prune at run close
```

The milestone slug is lowercase, because the KV key carries it. The `record` key carries the repository too, because one milestone cuts one worktree per repository. Without it the second cut overwrites the first, and teardown then leaks a worktree with its stack still running.

**Test for the branch before you cut.** `git worktree add -b` fails outright when the branch already exists. Two different situations produce that, and this plan's own KV record tells them apart.

- **A resume.** `plan:<slug>:milestone:<m>:branch:<repo>` already names this branch. Teardown removed the worktree and left the branch behind, so re-cut onto it. Pass no `-b`: `git worktree add <worktree> <branch>`.
- **A collision.** No KV key of this plan claims the branch, so another live plan owns it. The branch name carries the milestone slug and not the plan prefix. Two plans that both name a milestone `m1` therefore want one branch. Rename this plan's milestone, and escalate. Renaming the other plan's branch breaks its open PR.

A milestone slug is therefore unique across every live plan, and this test enforces it.

A plain clone fails loudly. Test the layout before you cut anything, and print the conversion command rather than a worktree path.

The worktree is disposable once the push succeeds, because the branch then lives on the remote. Remove it at milestone close.

A worker's working directory is its worktree, so its lock keys carry the worktree path.

**Why a worktree.** The user sits on a branch in their own tree. A worker that cannot take that branch cannot trample the user's working state. Git refuses to check out one branch in two worktrees, so the guarantee is structural rather than requested.

**The safety comes from the worktree, not from the bare repository.** A plain clone that adds worktrees beside it earns the same guarantee. This standard still requires the bare layout, for symmetry and grouping. Every tree is a peer, and one container holds them all.

## Every worker prompt carries

Split the prompt by what varies.

Pass the **preamble** through the runtime's system-prompt argument, or in every prompt where the runtime has none. It carries the working directory as an absolute path, with an instruction to stay inside it. That path is one repository's worktree, so a milestone spanning repositories passes one preamble per repository.

The preamble names what the worker must not touch: git writes, undeclared paths, todos it does not own, and KV. It also says what to do when stuck, which is to record what it found and stop. A worker that improvises past its brief is the expensive failure. A worker that stops behaves correctly.

Pass the **assignment** via `send_input`. It carries the one job this worker owns and where to write its report. It also carries the orchestrator's `process_id`, which the worker signals on completion. A todo or a work item may already state the job. The assignment then points at it rather than restating it.

**Check whether the worker already has the rules.** A runtime that loads these rules on its own makes restating them in a prompt a waste. A runtime that does not means every rule the worker must follow reaches it only through its prompt. The adapter says which, and it names the path that runtime reads. Assume nothing here: a worker that silently lacks a constraint you believe it has is the failure this check prevents.

Workers do one job and report. The orchestrator owns git, todo lifecycle, KV, and the synthesized artifact.

**A lock key carries the absolute path.** Solo scopes a lock to the project, and one project can hold many repositories. A key built from a repository-relative path such as `path:readme.md` therefore names one lock that every repository in the project shares. Two unrelated runs then collide on a file neither one touches, and the loser escalates over nothing. Build the key from the absolute path: `path:/absolute/path/to/the/file`. It needs no lookup, because the worker already knows its working directory.

**Lock and KV keys are lowercase.** Solo rejects uppercase in both. A key from `path:/Users/you/Code/repo/SKILL.md` or from a timestamped slug fails outright. Normalize the key to lowercase when you generate it, and pin that normalization in the preamble. Two workers could lowercase one path differently and hold two locks on one file. The mutual exclusion would then fail silently.

**A lock catches the writer the schedule does not know about.** Decomposition already gives every worker in a wave a disjoint file scope, so workers in one wave never contend. The lock earns its place against a second orchestration run, or a person editing the same tree. It converts a silent overwrite into a loud stop, which is why a worker that cannot acquire one escalates rather than waiting.

**Reports go to scratchpads.** Solo splits the two surfaces. Todos carry ownership, blockers, locks, and state. Scratchpads carry findings and reports. Give each worker one scratchpad. Run `scratchpad_find` for the escalation marker across all of them before you read any in full.

**`scratchpad_edit` takes two target types.** They are `section` and `line_range`, and nothing else. An invented type fails the call outright, so the report never reaches the surface. Across one session corpus 11 of 205 calls failed, and none was a revision mismatch. Four of them invented `str_replace`, `string`, or `append`.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| Vendor sub-agent for fan-out | Invisible, unaddressable, single-vendor, no locks or todos |
| "Spawn N parallel agents" with no mechanism named | The runtime uses its own default, so name `spawn_agent` explicitly |
| Workers running git writes in a shared tree | `git add` from two workers cross-commits their work |
| A tool deny list treated as a sandbox | Denying the editing tools leaves `cat > <target>` open through the shell |
| Cutting a milestone branch with `-b` and no existence test | A resumed run fails outright, because teardown left the branch behind |
| Treating an idle timer as the completion signal | No debounce, and a thinking worker looks like a finished one |
| Scheduling an idle timer before workers produce output | An all-idle watch list returns `already_satisfied` and creates no timer |
| Reading a worker's result from process output | Rendered rows, capped and wrapped: fine for a sentinel, incomplete for a report |
| Every worker at the session's model and effort | A one-line edit and a contract-preserving rewrite are not the same job |
| Spawning without an explicit approval mode | The runtime default is a prompt nobody watches, and the worker stalls unattended |
| Reaching for a runtime's bypass mode | Removes review from the one process nobody watches |
| Loosening a flag after a failed spawn | The retry loop reaches a bypass mode instead of escalating |
| A worker sharing the user's working tree | The worker edits the tree the user sits in, and their working state is collateral |
| A `scratchpad_edit` target outside `section` and `line_range` | The call fails, and the report never reaches its durable surface |
