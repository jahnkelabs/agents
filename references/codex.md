# Codex runtime adapter

Launch arguments and startup behavior for a Codex worker spawned through Solo's `spawn_agent`.
`rules/solo-agent-orchestration.md` carries the policy. This file carries the flags.

Read this before you spawn a Codex worker. A wrong flag fails the launch immediately, so the
cost of not reading it is a visible error rather than a silent one.

## Required arguments

| Argument | Why |
|---|---|
| `--approve-for-me` | Auto-approval. Routes approval requests through automatic review |
| `--no-alt-screen` | Makes the worker visible to `get_process_output` |

Never pass `--dangerously-bypass-approvals-and-sandbox`. It removes review from a process that
runs unattended, which is the exact situation the review exists for.

## Flag notes

`--approve-for-me` already implies the `workspace-write` sandbox. Codex rejects it outright
alongside `-s/--sandbox`, so pass it alone.

`--full-auto` no longer exists on `codex` or on `codex exec`, as of codex-cli 0.147.0, verified
2026-08-08. It fails the launch with `error: unexpected argument '--full-auto' found`.
`codex exec` has no `-a/--ask-for-approval` at all.

**Check the installed version before you trust this table.** Run `codex --version`. On
codex-cli 0.146.0 and earlier, `--approve-for-me` does not exist and the launch fails with
`error: unexpected argument '--approve-for-me' found`. On those versions the equivalent pair is
`-a never -s read-only` for a read-only worker, or `-a never` with a writable sandbox for a
worker that edits. Both stay inside the prohibition on bypass modes.

## The trust prompt consumes the first input

A Codex worker's first launch in an untrusted directory consumes its first input. `codex` asks
*Do you trust the contents of this directory?* before it accepts anything else. No approval flag
dismisses that question, because `--approve-for-me` governs command approvals rather than
workspace trust.

Pre-trust the directory. Add `[projects."<absolute path>"]` with `trust_level = "trusted"` to
`~/.codex/config.toml`, or pass it per launch:

```
-c 'projects."<absolute path>".trust_level="trusted"'
```

If you cannot pre-trust the directory, answer `1` with `send_input` before you send the
assignment.

## Why `--no-alt-screen` matters

Without it the TUI writes to the alternate screen and `get_process_output` returns nothing. The
worker then exits on its own after about thirty seconds, and that exit looks like a silent crash.
