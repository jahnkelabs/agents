# Claude runtime adapter

Launch arguments and startup behavior for a Claude worker spawned through Solo's `spawn_agent`.
`rules/solo-agent-orchestration.md` carries the policy. This file carries the flags that
implement it.

## Policy to flag

| Policy in the rule | Claude flag |
|---|---|
| Launch in auto-approval mode | `"--permission-mode", "auto"` |
| Never use a bypass mode | never `bypassPermissions`, `dontAsk`, or `acceptEdits` |
| Deny git writes structurally | `"--settings", '{"permissions":{"deny":[…]}}'` |
| Match the worker to the job | `"--model", "<tier>"` and `"--effort", "<tier>"` |
| Carry the invariant preamble | `"--append-system-prompt", "<preamble>"` |

## Auto-approval

`auto` lets a worker work through ordinary steps without stalling on a prompt, and a reviewer
still sees the requests that matter.

`acceptEdits` is the older setting and nobody uses it now. The bypass modes remove review from a
process that runs unattended, which is the exact situation review exists for. A read-only
assignment is not an exception.

Every value here is a valid flag. A wrong one launches cleanly and changes the worker's safety
posture in silence. You cannot discover this fact by trying it.

## The deny list

```
"--settings", '{"permissions":{"deny":["Bash(git add:*)","Bash(git commit:*)",
                "Bash(git push:*)","Bash(git checkout:*)"]}}'
```

Claude denies per command pattern. This is what makes the git prohibition structural rather than
requested, and it is finer-grained than any sandbox mode.

## Model and effort

`--model` takes `opus`, `sonnet`, or `haiku`. `--effort` takes `low`, `medium`, `high`, or
`xhigh`. A worker inherits neither from the session, so set both per worker.

## A worker inherits the rules

A spawned Claude worker loads `~/.claude/rules/` the same way the parent session does, before it
reads either the preamble or the assignment. A worker asked to introspect its own context
reported every rule file present, each attributed to its repository path. Neither launch flag
supplied them.

Never restate a rule in a Claude worker prompt. State the job and the constraints specific to
this task.

**This is Claude-specific.** Another runtime has its own instruction-loading path, or none. Check
that runtime's adapter before you assume a worker knows anything.
