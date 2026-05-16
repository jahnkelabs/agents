#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${AGENTS_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
RULES_SRC="${REPO_ROOT}/cursor/rules"
RULES_DEST="${HOME}/.cursor/rules"

if [[ ! -d "${RULES_SRC}" ]]; then
  echo "error: rules directory not found: ${RULES_SRC}" >&2
  exit 1
fi

mkdir -p "${RULES_DEST}"

installed=0
shopt -s nullglob
for rule in "${RULES_SRC}"/*.mdc; do
  name="$(basename "${rule}")"
  ln -sfn "${rule}" "${RULES_DEST}/${name}"
  echo "linked ${RULES_DEST}/${name} -> ${rule}"
  installed=$((installed + 1))
done
shopt -u nullglob

if [[ "${installed}" -eq 0 ]]; then
  echo "error: no rules installed from ${RULES_SRC}" >&2
  exit 1
fi

# Remove retired skill symlinks
rm -f "${HOME}/.cursor/skills/pr-first-contributions"
rm -f "${HOME}/.cursor/skills/testing-philosophy"

echo "installed ${installed} rule(s)"
