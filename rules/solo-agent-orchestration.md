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
timer_set(delay_ms=0, delivery_process_id=<orchestrator process_id>,
          body="<task> complete. Report in <scratchpad>. <clean|escalated>.")
```

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

**Read the runtime's adapter in `references/` before you spawn it.** Each runtime names its own flags, and those change between releases. `references/claude.md` and `references/codex.md` map each policy in this rule to the flag that implements it.

**An adapter also records what its runtime cannot do.** A policy here is a requirement, not a promise that every runtime can meet it. Codex has no per-command deny list and no system-prompt append, so on that runtime two of the policies below degrade. Read the adapter before you rely on a guarantee.

**Deny git writes at the permission layer.** A worker that cannot run `git add` is safer than a worker you asked not to. Two workers that share a tree can cross-commit each other's work. That failure is silent, and it costs a lot of time to undo. Where a runtime denies per command, deny the git write commands and nothing broader. A runtime that offers only a coarse sandbox cannot make this structural. Give each worker its own tree, or accept the risk knowingly and say so.

**Carry the invariant preamble once, where the runtime allows it.** Three things are identical across every worker in a wave. They are the working directory, what a worker must not touch, and what to do when stuck. Only the assignment differs. A runtime with a system-prompt argument takes the constant half there, which shortens each `send_input` and makes the constraints harder to drop by accident. A runtime without one carries the preamble in every prompt.

## Every worker prompt carries

Split the prompt by what varies.

Pass the **preamble** once through the runtime's system-prompt argument, or in every prompt where the runtime has none. It carries the working directory as an absolute path, with an instruction to stay inside it. It names what the worker must not touch: git writes, undeclared paths, todos it does not own, and KV. It also says what to do when stuck, which is to record what it found and stop. A worker that improvises past its brief is the expensive failure. A worker that stops behaves correctly.

Pass the **assignment** via `send_input`. It carries the one job this worker owns and where to write its report. It also carries the orchestrator's `process_id`, which the worker signals on completion. A todo or a work item may already state the job. The assignment then points at it rather than restating it.

**Check whether the worker already has the rules.** A Claude worker loads `~/.claude/rules/` the same way the parent session does, so restating a rule in its prompt wastes tokens. A Codex worker loads `AGENTS.md` from the working directory and never sees these rules, so a rule it must follow reaches it only through its prompt. The runtime's adapter says which. Assume nothing: a worker that silently lacks a constraint you believe it has is the failure this check prevents.

Workers do one job and report. The orchestrator owns git, todo lifecycle, KV, and the synthesized artifact.

**Lock and KV keys are lowercase.** Solo rejects uppercase in both. A key from `path:skills/plan/SKILL.md` or from a timestamped slug fails outright. Normalize the key to lowercase when you generate it, and pin that normalization in the preamble. Two workers could lowercase one path differently and hold two locks on one file. The mutual exclusion would then fail silently.

**Reports go to scratchpads.** Solo splits the two surfaces. Todos carry ownership, blockers, locks, and state. Scratchpads carry findings and reports. Give each worker one scratchpad. Run `scratchpad_find` for the escalation marker across all of them before you read any in full.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| Vendor sub-agent for fan-out | Invisible, unaddressable, single-vendor, no locks or todos |
| "Spawn N parallel agents" with no mechanism named | The runtime uses its own default, so name `spawn_agent` explicitly |
| Workers running git writes in a shared tree | `git add` from two workers cross-commits their work |
| Treating an idle timer as the completion signal | No debounce, and a thinking worker looks like a finished one |
| Scheduling an idle timer before workers produce output | An all-idle watch list returns `already_satisfied` and creates no timer |
| Reading a worker's result from process output | Rendered rows, capped and wrapped: fine for a sentinel, incomplete for a report |
| Every worker at the session's model and effort | A one-line edit and a contract-preserving rewrite are not the same job |
| Spawning without an explicit approval mode | The runtime default is a prompt nobody watches, and the worker stalls unattended |
| Using `bypassPermissions` or `--dangerously-bypass-approvals-and-sandbox` | Removes review from the one process nobody watches |
