---
description: Fan out with Solo agents, never a vendor's native sub-agent mechanism; spawn, join on an idle timer, collect from a durable surface
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
| **Model choice** | A Solo agent can run a different runtime than the session—Copilot, Kimi, whatever is enabled. Vendor sub-agents are locked to the session's vendor, which makes multi-model work impossible. |
| **Coordination primitives** | Solo workers hold locks, comment on todos, write KV and scratchpads. That is what makes parallel writes to a shared tree safe and escalation legible. |
| **Portability** | The workflow does not become a bet on one vendor's agent features. |

## The shape

1. `list_agent_tools` — resolve the runtime. Never hardcode a roster or an id.
2. `spawn_agent(agent_tool_id=<id>, name="<role>-<slug>")` → `process_id`, `agent_instructions`
3. `send_input(process_id, input=<agent_instructions + your prompt>)` — the returned instructions must be prepended, or the worker does not know it is a Solo agent.
4. `timer_fire_when_idle_all(processes=[<pids>], max_wait_ms=<guard>, body="<what to do on wake>")` — **timers are the only wake-up mechanism.** Never poll status in a loop.
5. On wake, collect results from the **durable surface** the worker wrote: a scratchpad, a todo comment, or KV. Do not scrape process output.
6. `close_process(process_id)` for every worker. A join that leaves processes open leaks them.

Always give `max_wait_ms` a real guard value. A worker that hangs must surface as a slow join, not a dead session.

## Every worker prompt carries

- **Working directory** — absolute path, plus an instruction to stay inside it
- **One job** — the single question or phase this worker owns
- **Where to write results** — the exact scratchpad name or todo id
- **What it must not touch** — git writes, undeclared paths, todos it does not own, KV
- **What to do when stuck** — record what it found and stop. Improvising past the brief is the expensive failure, and stopping is correct behavior rather than giving up.

Workers do one job and report. The orchestrator owns git, todo lifecycle, KV, and the synthesized artifact.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| Vendor sub-agent for fan-out | Invisible, unaddressable, single-vendor, no locks or todos |
| "Spawn N parallel agents" with no mechanism named | Falls through to the vendor default—name `spawn_agent` explicitly |
| Workers running git writes in a shared tree | `git add` from two workers cross-commits their work |
