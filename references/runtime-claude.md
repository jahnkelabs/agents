# Claude runtime adapter

Launch arguments and startup behavior for a Claude worker spawned through Solo's `spawn_agent`.
`rules/solo-agent-orchestration.md` carries the policy. This file carries the flags that
implement it.

## Policy to flag

| Policy in the rule | Claude flag |
|---|---|
| Launch in auto-approval mode | `"--permission-mode", "auto"` |
| Never use a bypass mode | never `bypassPermissions`, `dontAsk`, or `acceptEdits` |
| Bound an immutable-target worker's writes | `"--settings", '{"permissions":{"deny":[…]}}'` — requested, never enforced. See below |
| Deny an editing worker's git writes | `"--settings", '{"permissions":{"deny":["Bash(git add:*)", …]}}'` — per command. See below |
| Match the worker to the job | `"--model", "<tier>"` and `"--effort", "<tier>"` |
| Carry the invariant preamble | `"--append-system-prompt", "<preamble>"` |
| Carry prose discipline where a project overrides the style | `"--settings", '{"outputStyle":"prose-discipline"}'` |

## Auto-approval

`auto` lets a worker work through ordinary steps without stalling on a prompt, and a reviewer
still sees the requests that matter.

`acceptEdits` is the older setting and nobody uses it now. The bypass modes remove review from a
process that runs unattended, which is the exact situation review exists for. A read-only
assignment is not an exception.

Every value here is a valid flag. A wrong one launches cleanly and changes the worker's safety
posture in silence. You cannot discover this fact by trying it.

## The immutable-target worker: writes requested, never bounded

Every critic, every research agent, and every retro agent is one. Pass the three editing tools
beside the four git commands:

```
"--settings", '{"permissions":{"deny":["Edit","Write","NotebookEdit",
                "Bash(git add:*)","Bash(git commit:*)",
                "Bash(git push:*)","Bash(git checkout:*)"]}}'
```

Claude denies per tool and per command pattern, which is finer-grained than any sandbox mode. It
never denies by directory, so it cannot scope a worker's writes to a scratch directory. Name that
directory in the prompt, and set the working directory to it.

**A deny list does not bound shell redirection.** Claude scopes a denial by tool and by pattern,
never by directory. A worker denied `Edit`, `Write`, and `NotebookEdit` still writes any file
through Bash, because `cat > <target>` matches no pattern above. This run's critics launched under
exactly that deny list, and they wrote the target freely.

**On Claude, a brief can only request an immutable target.**
`rules/solo-agent-orchestration.md` names that inversion: Codex bounds the same worker by
directory, and Claude cannot. A brief that relies on an unwritable target says so on this runtime.
It also carries the scratch-only, immutable-target, and no-git rules in the prompt itself.

The deny list still earns its place. It stops each `Edit`, `Write`, and `NotebookEdit` call, and
each `Bash` call its patterns match. A reviewer sees every denied call. What it does not do is
make the target unwritable.

## The editing worker: git denied per command

An editing worker changes the target, so its working directory is its milestone worktree. Drop
the three editing tools and keep the git commands:

```
"--settings", '{"permissions":{"deny":["Bash(git add:*)","Bash(git commit:*)",
                "Bash(git push:*)","Bash(git checkout:*)"]}}'
```

`references/runtime-codex.md` records that Codex has no per-worker equivalent for this. Claude
has one, and `rules/solo-agent-orchestration.md` asks for it here. The shell gap above still
applies, so the prompt carries the prohibition too.

## Model and effort

`--model` takes `opus`, `sonnet`, or `haiku`. `--effort` takes `low`, `medium`, `high`, or
`xhigh`. A worker inherits neither from the session, so set both per worker.

## A worker inherits the rules

A spawned Claude worker loads `~/.claude/rules/` the same way the parent session does, before it
reads either the preamble or the assignment. A worker asked to introspect its own context
reported every rule file present, each attributed to its repository path. Neither launch flag
supplied them.

A second path carries prose discipline. A worker receives it through the `outputStyle` key in
`~/.claude/settings.json`, not through `~/.claude/rules/`. This works because a Solo worker runs
as its own `claude` process with its own main conversation. A subagent runs its own system prompt
instead, so it would not receive a style. The style resolves from the **user** settings tier. A
project-local `.claude/settings.local.json` that names a different style outranks it, and the
`/config` picker writes exactly that tier. A worker can therefore silently lack prose discipline
in a project where someone selected a different style.

The remedy is a launch flag, not a longer prompt. Pass
`"--settings", '{"outputStyle":"prose-discipline"}'`, which Claude Code ranks above every settings
file except the managed tier. Do this whenever the working directory holds a
`.claude/settings.local.json` that names another style.

Never restate a rule in a Claude worker prompt. State the job and the constraints specific to
this task. The immutable-target rules above are the one exception, because no launch flag
enforces them here.

**This is Claude-specific.** Another runtime has its own instruction-loading path, or none. Check
that runtime's adapter before you assume a worker knows anything.
