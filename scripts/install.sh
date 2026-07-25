#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${AGENTS_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
DEST="${HOME}/.claude"
BACKUP_DIR="${DEST}/backups"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'USAGE'
Usage: install.sh

Symlinks this repository's Claude Code configuration into ~/.claude/:

  ~/.claude/rules/<name>.md     -> rules/<name>.md        (per file)
  ~/.claude/skills/<name>       -> skills/<name>/         (per skill)
  ~/.claude/references          -> references/            (whole directory)

Rules and skills are linked one at a time, so ~/.claude/rules and
~/.claude/skills stay real directories you own. Anything else you keep
there is left alone, and nothing you create locally lands in this repo.

Re-run after adding or renaming a file. Links pointing into this repo whose
source has gone are pruned; nothing else is touched.

References is a whole-directory link because it is not a Claude Code
directory -- it exists only so commands can read tracker adapters from a
stable path.

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
      echo "  already linked: ${dest##*/.claude/}"
      return
    fi
    echo "  repointing: ${dest##*/.claude/} (was ${current})"
    rm -f "${dest}"
  elif [[ -e "${dest}" ]]; then
    mkdir -p "${BACKUP_DIR}"
    local backup
    backup="${BACKUP_DIR}/$(basename "${dest}").$(date +%s)"
    mv "${dest}" "${backup}"
    echo "  backed up: ${dest##*/.claude/} -> backups/$(basename "${backup}")"
  fi

  ln -sfn "${source}" "${dest}"
  echo "  linked: ${dest##*/.claude/}"
}

# Link each entry of src_dir individually into dest_dir, then prune our own
# stale links. Entries we did not create are never touched.
#   $1 = directory name under both the repo and ~/.claude
#   $2 = "files" to link *.md, or "dirs" to link each subdirectory
link_entries() {
  local kind="$2"
  local src_dir="${REPO_ROOT}/$1" dest_dir="${DEST}/$1"

  if [[ ! -d "${src_dir}" ]]; then
    echo "error: source directory missing: ${src_dir}" >&2
    exit 1
  fi

  # An earlier version linked the whole directory. Replace that with a real
  # one -- removing the symlink does not touch the repo it points at.
  if [[ -L "${dest_dir}" ]]; then
    echo "  converting ${1}/ from a directory link to a real directory"
    rm -f "${dest_dir}"
  elif [[ -e "${dest_dir}" && ! -d "${dest_dir}" ]]; then
    mkdir -p "${BACKUP_DIR}"
    mv "${dest_dir}" "${BACKUP_DIR}/$(basename "${dest_dir}").$(date +%s)"
    echo "  backed up a file blocking ${1}/"
  fi
  mkdir -p "${dest_dir}"

  shopt -s nullglob

  if [[ "${kind}" == "dirs" ]]; then
    for src in "${src_dir}"/*/; do
      src="${src%/}"
      link "${src}" "${dest_dir}/$(basename "${src}")"
    done
  else
    for src in "${src_dir}"/*.md; do
      link "${src}" "${dest_dir}/$(basename "${src}")"
    done
  fi

  # Prune links into this repo whose source is gone (renamed or deleted).
  # Only symlinks resolving under src_dir qualify -- your own files and links
  # elsewhere are left exactly as they are.
  for dest in "${dest_dir}"/* "${dest_dir}"/.*; do
    [[ -L "${dest}" ]] || continue
    local target
    target="$(readlink "${dest}")"
    [[ "${target}" == "${src_dir}/"* ]] || continue
    if [[ ! -e "${target}" ]]; then
      rm -f "${dest}"
      echo "  pruned: ${1}/$(basename "${dest}") (source removed)"
    fi
  done

  shopt -u nullglob
}

mkdir -p "${DEST}"

echo "Installing Claude Code configuration..."
link_entries rules files
link_entries skills dirs
link "${REPO_ROOT}/references" "${DEST}/references"

# Earlier versions installed these as commands. A skill and a command of the
# same name both resolve to /name, and the skill wins -- so a leftover link
# is shadowed rather than broken, but it is still stale. Remove ours only.
if [[ -d "${DEST}/commands" && ! -L "${DEST}/commands" ]]; then
  shopt -s nullglob
  for old in "${DEST}"/commands/*.md; do
    [[ -L "${old}" ]] || continue
    target="$(readlink "${old}")"
    [[ "${target}" == "${REPO_ROOT}/commands/"* ]] || continue
    rm -f "${old}"
    echo "  removed superseded command link: commands/$(basename "${old}")"
  done
  shopt -u nullglob
  rmdir "${DEST}/commands" 2>/dev/null && echo "  removed empty commands/"
elif [[ -L "${DEST}/commands" ]] && [[ "$(readlink "${DEST}/commands")" == "${REPO_ROOT}/commands" ]]; then
  rm -f "${DEST}/commands"
  echo "  removed superseded commands/ directory link"
fi

echo ""
echo "Installed. Rules apply to every session; skills are available as slash commands."
echo "/plan, /implement, /critique, /stash and /recall require the Solo MCP server."
echo "/stash and /recall additionally require a tracker MCP (see references/)."
