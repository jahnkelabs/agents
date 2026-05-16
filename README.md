# agents

Centralized configuration for AI coding agents (skills, rules, commands, hooks).

## Layout

| Path | Purpose |
|------|---------|
| `cursor/rules/` | Cursor rules → `~/.cursor/rules/` (global, always-on) |
| `cursor/skills/` | Reserved for optional on-demand skills |
| `cursor/commands/` | Slash commands (optional) |
| `cursor/hooks/` | Cursor hooks (optional) |
| `shared/` | Agent-agnostic reference docs (optional) |
| `scripts/` | Install scripts |

Reserved for future use: `claude/`, `codex/`, `opencode/`.

## Install (Cursor)

From this repository:

```bash
./scripts/install-cursor.sh
```

This symlinks each `cursor/rules/*.mdc` file into `~/.cursor/rules/`. Re-run after adding rules or cloning on a new machine.

Override the repo root:

```bash
AGENTS_REPO=/path/to/agents ./scripts/install-cursor.sh
```

After install, confirm in **Cursor Settings → Rules** that each rule shows **Always Apply**.

If rules do not appear, import via **Settings → Rules → Remote Rule (GitHub)** pointing at `jahnkelabs/agents` ([Cursor docs](https://cursor.com/docs/context/rules)).

## Rules

| Rule | Description |
|------|-------------|
| [pr-first-contributions](cursor/rules/pr-first-contributions.mdc) | PR-first git workflow with conventional titles and squash-merge descriptions |
| [testing-philosophy](cursor/rules/testing-philosophy.mdc) | Contract-first tests through production entry points; refactor-resistant |
