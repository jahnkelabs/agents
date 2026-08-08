---
description: Fan out with Solo agents, never a vendor's native sub-agent mechanism; workers signal their own completion and report to a durable surface
---

# Solo agent orchestration

When work is delegated to a parallel worker, that worker is a **Solo agent**—spawned through the Solo MCP server. Never the host runtime's own sub-agent mechanism: Claude's Task tool, Codex's sub-agents, or any other vendor's in-process worker.

## Default policy

- **Default:** every spawned worker is a Solo agent via `spawn_agent`, even for a quick read-only lookup.
- **Exceptions:** only when the user explicitly asks for the vendor mechanism.
- **Solo unavailable:** say so and either do the work inline or stop. A fan-out that quietly changed mechanism is the failure this rule exists to prevent.
- **Scope:** this governs delegation, not every tool call. It applies whether the fan-out comes from a skill, from an explicit request ("check these five services in parallel"), or from your own judgment that a job splits—but reading a few files yourself is not fan-out.

## Why

| | |
|---|---|
| **Visible and addressable** | A Solo worker appears in the UI, survives the turn that spawned it, and can be inspected, re-prompted, or killed later. A vendor sub-agent is a black box that returns one blob of text and vanishes. |
| **Model choice** | A Solo agent launches with whatever model and effort its job needs, and can run a different runtime than the session. Vendor sub-agents are locked to the session's vendor and its settings. |
| **Coordination primitives** | Solo workers hold locks, comment on todos, write KV and scratchpads. That is what makes parallel writes to a shared tree safe and escalation legible. |
| **Portability** | The workflow does not become a bet on one vendor's agent features. |

## The shape

1. `list_agent_tools` — resolve the runtime. Never hardcode a roster or an id.
2. `spawn_agent(agent_tool_id=<id>, name="<role>-<slug>", extra_args=[…])` → `process_id`, `agent_instructions`. See **Capability, not compliance** below for what belongs in `extra_args`.
3. `send_input(process_id, input=<agent_instructions + the assignment>)` — the returned instructions must be prepended, or the worker does not know it is a Solo agent.
4. The worker does its job, writes its report to the **durable surface** it was given, and signals completion as its last act.
5. On the signal, read the durable surface. Never scrape process output for content.
6. `close_process(process_id)` for every worker. A join that leaves processes open leaks them.

## Workers signal completion

A worker's last act is to wake the orchestrator directly:

```
timer_set(delay_ms=0, delivery_process_id=<orchestrator process_id>,
          body="<task> complete. Report in <scratchpad>. <clean|escalated>.")
```

**The worker knows when it is finished; nothing else does.** Push the signal rather than watching for its absence—the orchestrator's job is to receive completions, not to infer them.

Every worker prompt therefore carries the orchestrator's own `process_id`, which `whoami` returns.

## Idle timers are the fallback, not the signal

`timer_fire_when_idle_all(processes=[<pids>], max_wait_ms=<guard>, body=…)` still has one job: catching the worker that dies, hangs, or never signals. Give `max_wait_ms` a real guard value and say in the body that a worker which never signalled is a failure to investigate rather than a completion.

Idle detection cannot carry more weight than that, for three reasons:

- **There is no debounce.** The timer fires on the first detected idle transition. No parameter changes this—`timer_fire_when_idle_all` accepts only `processes`, `max_wait_ms`, `body`, `delivery_process_id`, `metadata`, and `project_id`, and Solo ignores unknown keys silently rather than rejecting them.
- **Thinking looks like finishing.** Idle state is derived from terminal output, and a worker reasoning at length emits none.
- **Already-idle is treated as satisfied.** For `..._all`, processes already idle when the timer is scheduled count as satisfied, and an entirely idle watch list returns `already_satisfied` with **no timer created**—so scheduling immediately after `spawn_agent`, before workers produce output, can mean never waking at all. For `..._any` the opposite holds: already-idle processes are ignored and the timer waits for a new transition.

**The timer body is an instruction, not a note.** It arrives as a fresh turn and is acted on literally, so every branch the orchestrator must take on wake belongs inside it. Guidance that lives only in the surrounding prose will not be read.

## Capability, not compliance

`spawn_agent` takes `extra_args`—per-launch arguments appended to the resolved command without mutating the agent tool's saved defaults. Three uses matter.

**Match the worker to the job.** `--model` and `--effort` are set per worker, not inherited from the session. A mechanical edit against precise line references and a rewrite that must preserve a behavioral contract are not the same job and should not cost the same.

**Launch every worker in auto-approval mode.** This is fixed per runtime and is not a per-wave judgment call:

| Runtime | Required `extra_args` | Never |
|---|---|---|
| Claude | `"--permission-mode", "auto"` | `bypassPermissions`, `dontAsk`, `acceptEdits` |
| Codex (interactive `codex`—what `spawn_agent` launches) | `"--approve-for-me", "--no-alt-screen"` | `--dangerously-bypass-approvals-and-sandbox` |

Both let a worker proceed through ordinary work without stalling on a prompt while a reviewer still sees the requests that matter. `--approve-for-me` routes approval requests through automatic review and already implies the `workspace-write` sandbox—it is rejected outright when passed alongside `-s/--sandbox`, so pass it alone. `--full-auto` no longer exists on either `codex` or `codex exec` as of codex-cli 0.147.0 (verified 2026-08-08); it fails the launch immediately with `error: unexpected argument '--full-auto' found`, and `codex exec` has no `-a/--ask-for-approval` at all. The bypass modes remove that review from a process running unattended, which is exactly the situation the review exists for; `acceptEdits` is the older Claude setting and is no longer used. Read-only assignments are not an exception—a worker's brief says what it intends to do, not what it is able to do.

**A Codex worker's first launch in an untrusted directory consumes its first input.** `codex` asks *Do you trust the contents of this directory?* before it accepts anything else, and no approval flag dismisses it—`--approve-for-me` governs command approvals, not workspace trust. Pre-trust the directory instead, as `[projects."<absolute path>"]` with `trust_level = "trusted"` in `~/.codex/config.toml` or per launch via `-c 'projects."<absolute path>".trust_level="trusted"'`; failing that, answer `1` with `send_input` before sending the assignment. `--no-alt-screen` is what makes any of this visible: without it the TUI writes to the alternate screen, `get_process_output` returns nothing at all, and the worker exits on its own after about thirty seconds looking like a silent crash.

**Enforce what would otherwise be a request.** A `--settings` deny list makes the git prohibition structural: `'{"permissions":{"deny":["Bash(git add:*)","Bash(git commit:*)","Bash(git push:*)","Bash(git checkout:*)"]}}'`. A worker that cannot run `git add` is safer than one asked not to, and cross-commits between workers sharing a tree are silent when they happen and expensive to untangle afterward. This is the mechanism that constrains a worker—never a downgraded permission mode, and never a raised one.

**Carry the invariant preamble in `--append-system-prompt`.** Working directory, what must not be touched, and what to do when stuck are identical across every worker in a wave; only the assignment differs. Putting the constant half in the system prompt shortens each `send_input` and makes the constraints harder to drop by accident.

## Every worker prompt carries

Split by what varies. The **preamble**, passed once via `--append-system-prompt`, carries the working directory as an absolute path with an instruction to stay inside it; what must not be touched—git writes, undeclared paths, todos it does not own, KV; and what to do when stuck, which is to record what it found and stop, because improvising past the brief is the expensive failure and stopping is correct behavior rather than giving up.

The **assignment**, passed via `send_input`, carries the one job this worker owns, where to write its report, and the orchestrator's `process_id` to signal on completion. When the job is already written down—a todo, a work item—the assignment points at it rather than restating it.

Workers do one job and report. The orchestrator owns git, todo lifecycle, KV, and the synthesized artifact.

**Lock and KV keys are lowercase.** Solo rejects uppercase in both, so a key built from a path—`path:skills/plan/SKILL.md`—or from a timestamped slug fails outright. Normalize to lowercase when the key is generated, and pin that normalization in the preamble: two workers lowercasing the same path differently would hold non-colliding locks on one file, and the mutual exclusion would fail silently.

**Reports go to scratchpads.** Solo's own split is todos for ownership, blockers, locks, and state; scratchpads for findings and reports. One scratchpad per worker, and `scratchpad_find` for the escalation marker across all of them before reading any in full.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| Vendor sub-agent for fan-out | Invisible, unaddressable, single-vendor, no locks or todos |
| "Spawn N parallel agents" with no mechanism named | Falls through to the vendor default—name `spawn_agent` explicitly |
| Workers running git writes in a shared tree | `git add` from two workers cross-commits their work |
| Treating an idle timer as the completion signal | No debounce, and a thinking worker is indistinguishable from a finished one |
| Scheduling an idle timer before workers produce output | An all-idle watch list returns `already_satisfied` and creates no timer |
| Reading a worker's result from process output | Rendered rows, capped and wrapped—fine for a sentinel, lossy for a report |
| Every worker at the session's model and effort | A one-line edit and a contract-preserving rewrite are not the same job |
| Spawning without an explicit approval mode | The runtime default is a prompt nobody is watching, and the worker stalls unattended |
| Reaching for `bypassPermissions` or `--dangerously-bypass-approvals-and-sandbox` | Strips review from the one process running with nobody watching it |
