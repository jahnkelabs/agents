#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${AGENTS_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
SKILLS_SRC="${REPO_ROOT}/cursor/skills"
SKILLS_DEST="${HOME}/.cursor/skills"

if [[ ! -d "${SKILLS_SRC}" ]]; then
  echo "error: skills directory not found: ${SKILLS_SRC}" >&2
  exit 1
fi

mkdir -p "${SKILLS_DEST}"

installed=0
for skill in "${SKILLS_SRC}"/*/; do
  [[ -d "${skill}" ]] || continue
  name="$(basename "${skill}")"
  if [[ ! -f "${skill}/SKILL.md" ]]; then
    echo "warning: skipping ${name} (no SKILL.md)" >&2
    continue
  fi
  ln -sfn "${skill}" "${SKILLS_DEST}/${name}"
  echo "linked ${SKILLS_DEST}/${name} -> ${skill}"
  installed=$((installed + 1))
done

if [[ "${installed}" -eq 0 ]]; then
  echo "error: no skills installed from ${SKILLS_SRC}" >&2
  exit 1
fi

echo "installed ${installed} skill(s)"
