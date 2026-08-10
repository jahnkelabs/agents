# Codex runtime adapter

Launch arguments and startup behavior for a Codex worker spawned through Solo's `spawn_agent`.
`rules/solo-agent-orchestration.md` carries the policy. This file carries the flags that
implement it, and the three policies Codex cannot implement.

Read this before you spawn a Codex worker. A wrong flag fails the launch immediately, so the
cost of not reading it is a visible error rather than a silent one.

## Policy to flag

| Policy in the rule | Codex flag |
|---|---|
| Launch in auto-approval mode | `--approve-for-me`, or `-a never` before 0.147 |
| Never use a bypass mode | never `--dangerously-bypass-approvals-and-sandbox` |
| Deny git writes structurally | **no equivalent** — see below |
| Match the worker to the job | `-m/--model`; reasoning effort through `-c` |
| Carry the invariant preamble | **no equivalent** — see below |
| Make the worker visible | `--no-alt-screen` |

## Three policies Codex cannot implement

**No per-worker deny list.** Codex controls writes per launch with `-s/--sandbox`, which takes
`read-only`, `workspace-write`, or `danger-full-access`. All three are coarse. `read-only` blocks
a worker that must edit files, and `workspace-write` permits `git add`. Two Codex workers that
share a tree can therefore cross-commit, and no launch flag prevents it. On this runtime the git
prohibition is a request rather than a structure. Keep each worker in its own tree, or accept
the risk knowingly.

Codex does have a per-command deny list, and this repository declines to use it. See
`## Execpolicy, and why this repository does not use it` below before you reach for it.

**No system-prompt append.** Codex has no `--append-system-prompt`. Instructions arrive as the
prompt argument or on stdin. The preamble and the assignment therefore travel together in
`send_input`, and the preamble cannot be set once per wave.

**No inheritance of `~/.claude/rules/`.** Codex reads `AGENTS.md` from the working directory. It
does not read this repository's rules, so a Codex worker knows none of them unless something puts
them in front of it. The point above removes the other channel. Every rule a Codex worker must
follow therefore reaches it through its `send_input` prompt, or through an `AGENTS.md` the worker
finds in the working directory.

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

## Execpolicy, and why this repository does not use it

Codex reads Starlark policy files that decide, per command, whether it may run:

```
prefix_rule(pattern=["git", "add"], decision="forbidden", justification="the orchestrator owns git")
```

`decision` is `allow`, `prompt`, or `forbidden`, and the most restrictive match wins. That is a
real per-command deny list, and it is the closest thing Codex has to what another runtime does
per launch.

**This repository does not install one.** The mechanism is global. A rule that stops a worker
staging a commit stops you staging one too, in every Codex session on the machine. Nothing
distinguishes a worker from your own terminal, so the cost lands on the person.

Verified on codex-cli 0.146.0, so a later version may move these:

- **A second file in `~/.codex/rules/` does load.** The filename does not have to be
  `default.rules`. Matching reaches the argv inside the `/bin/zsh -lc` wrapper, and the
  `justification` text reaches the worker in the rejection message.
- **A symlinked `.rules` file does not load.** A real file at the same path with the same content
  does. Rules cannot be linked out of a repository the way skills can, so installing one means
  copying it and keeping the copy fresh.
- **A project-scope `<repo>/.codex/rules/` does not load.** Not in a git repository, and not with
  `trust_level = "trusted"` either. `codex doctor` reports only `~/.codex/config.toml` as a loaded
  layer. Per-project policy would make the denial per-worker, which is the one shape worth
  having. Re-test it on a newer version before you conclude it cannot work.
- **`~/.codex/rules/default.rules` belongs to Codex.** It appends to that file as you approve
  commands. Never manage or overwrite it. An installed policy would go in its own file beside it.

`codex execpolicy check --rules <path> -- <command>` evaluates a file without running anything.
Pass `--` before the command, or its flags are read as flags to `check`.
