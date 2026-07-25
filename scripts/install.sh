#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${AGENTS_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
DEST="${HOME}/.claude"
BACKUP_DIR="${DEST}/backups"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'USAGE'
Usage: install.sh

Symlinks this repository's Claude Code configuration into ~/.claude/:

  ~/.claude/rules       -> rules/
  ~/.claude/commands    -> commands/
  ~/.claude/references  -> references/

Idempotent: existing symlinks are repointed, and any real file or directory
in the way is moved to ~/.claude/backups/ first.

This repository does not manage ~/.claude/settings.json or ~/.claude/CLAUDE.md.

Override the repo root with AGENTS_REPO=/path/to/agents.
USAGE
  exit 0
fi

# Symlink source -> dest, preserving anything real that is already there.
link() {
  local source="$1" dest="$2"

  if [[ ! -e "${source}" ]]; then
    echo "error: source missing: ${source}" >&2
    exit 1
  fi

  if [[ -L "${dest}" ]]; then
    local current
    current="$(readlink "${dest}")"
    if [[ "${current}" == "${source}" ]]; then
      echo "  already linked: ${dest}"
      return
    fi
    echo "  repointing: ${dest} (was ${current})"
    rm -f "${dest}"
  elif [[ -e "${dest}" ]]; then
    mkdir -p "${BACKUP_DIR}"
    local backup
    backup="${BACKUP_DIR}/$(basename "${dest}").$(date +%s)"
    mv "${dest}" "${backup}"
    echo "  backed up: ${dest} -> ${backup}"
  fi

  ln -sfn "${source}" "${dest}"
  echo "  linked: ${dest} -> ${source}"
}

mkdir -p "${DEST}"

echo "Installing Claude Code configuration..."
for dir in rules commands references; do
  link "${REPO_ROOT}/${dir}" "${DEST}/${dir}"
done

echo ""
echo "Installed. Rules apply to every session; commands are available as slash commands."
echo "/plan, /implement, /critique, /stash and /recall require the Solo MCP server."
echo "/stash and /recall additionally require a tracker MCP (see references/)."
