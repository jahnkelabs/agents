# agents

Centralized configuration for AI coding agents (skills, rules, commands, hooks).

## Layout

| Path | Purpose |
|------|---------|
| `cursor/skills/` | Cursor Agent skills → `~/.cursor/skills/` |
| `cursor/rules/` | Cursor rules (optional) |
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

This symlinks each skill under `cursor/skills/<name>/` into `~/.cursor/skills/<name>/`. Re-run after adding skills or cloning on a new machine.

Override the repo root:

```bash
AGENTS_REPO=/path/to/agents ./scripts/install-cursor.sh
```

## Skills

| Skill | Description |
|-------|-------------|
| [pr-first-contributions](cursor/skills/pr-first-contributions/) | PR-first git workflow with conventional titles and squash-merge descriptions |
| [production-shaped-tests](cursor/skills/production-shaped-tests/) | Contract-first tests through production entry points; refactor-resistant |
