#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'USAGE'
Usage: wt-clone.sh <source> <destination>

Copies a file or a directory into a milestone worktree. It uses a
copy-on-write clone where the filesystem supports one, and a plain copy
everywhere else.

It reports the mode it chose on stderr:

  clone   source and destination share one clone-capable volume
  copy    anything else, and the reason

It checks the filesystem before it copies. macOS cp -c falls back to a
plain copy without saying so, and cp --reflink=auto does the same on
Linux. A caller that expects a clone would then consume the full size of
the source without warning.

Clone-capable filesystems: apfs on macOS. On Linux the script probes the
destination volume with a real reflink instead of reading the filesystem
name, because an xfs volume built with -m reflink=0 carries the name
without the feature. The Linux clone runs cp --reflink=always, which
fails loudly rather than falling back.

A symlinked source is resolved first, so the destination holds a real
file or directory rather than a link back into the source tree.

The destination must not exist, and a symlink there is refused even when
it dangles. The copy lands in a temporary sibling and is renamed into
place, so a failed copy leaves no partial destination to block a retry.
Exit status is 0 only when the copy reached the destination.
USAGE
  exit 0
fi

if [[ $# -ne 2 ]]; then
  echo "error: expected 2 arguments, got $#" >&2
  echo "usage: wt-clone.sh <source> <destination>" >&2
  exit 2
fi

SOURCE="$1"
DEST="$2"

if [[ ! -e "${SOURCE}" ]]; then
  echo "error: source missing: ${SOURCE}" >&2
  exit 1
fi

if [[ -L "${DEST}" ]]; then
  echo "error: destination is a symlink, refusing to write through it: ${DEST}" >&2
  exit 1
fi

if [[ -e "${DEST}" ]]; then
  echo "error: destination exists, refusing to overwrite: ${DEST}" >&2
  exit 1
fi

DEST_PARENT="$(dirname "${DEST}")"

if [[ ! -d "${DEST_PARENT}" ]]; then
  echo "error: destination directory missing: ${DEST_PARENT}" >&2
  exit 1
fi

resolve_source() {
  local path="$1" target levels=0
  while [[ -L "${path}" ]]; do
    levels=$((levels + 1))
    if [[ "${levels}" -gt 40 ]]; then
      echo "error: too many symlink levels: $1" >&2
      exit 1
    fi
    target="$(readlink "${path}")"
    if [[ "${target}" == /* ]]; then
      path="${target}"
    else
      path="$(dirname "${path}")/${target}"
    fi
  done
  if [[ -d "${path}" ]]; then
    (cd -P "${path}" && pwd -P)
  else
    printf '%s/%s\n' "$(cd -P "$(dirname "${path}")" && pwd -P)" "$(basename "${path}")"
  fi
}

if ! SOURCE="$(resolve_source "${SOURCE}")"; then
  exit 1
fi

device_id() {
  case "$(uname -s)" in
    Darwin) stat -f '%d' "$1" ;;
    *) stat -c '%d' "$1" ;;
  esac
}

filesystem_type() {
  local path="$1" mount_point
  mount_point="$(df -P "${path}" | awk 'NR==2 {out=$6; for (i=7; i<=NF; i++) out=out" "$i; print out}')"
  case "$(uname -s)" in
    Darwin)
      mount | awk -v mp="${mount_point}" '
        index($0, " on " mp " (") {
          split($0, parts, "(")
          split(parts[2], kind, ",")
          print kind[1]
          exit
        }'
      ;;
    *) stat -f -c '%T' "${path}" ;;
  esac
}

supports_reflink() {
  local dir="$1" probe status=0
  probe="$(mktemp -d "${dir}/.wt-clone-probe.XXXXXX")" || return 1
  printf 'probe' > "${probe}/a"
  cp --reflink=always "${probe}/a" "${probe}/b" >/dev/null 2>&1 || status=1
  rm -rf "${probe}"
  return "${status}"
}

SOURCE_DEVICE="$(device_id "${SOURCE}")"
DEST_DEVICE="$(device_id "${DEST_PARENT}")"
SOURCE_FS="$(filesystem_type "${SOURCE}")"

MODE=copy
REASON=""

if [[ "${SOURCE_DEVICE}" != "${DEST_DEVICE}" ]]; then
  REASON="different volumes (${SOURCE_FS} device ${SOURCE_DEVICE} to device ${DEST_DEVICE})"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  if [[ "${SOURCE_FS}" == "apfs" ]]; then
    MODE=clone
  else
    REASON="filesystem ${SOURCE_FS:-unknown} does not support cloning"
  fi
elif supports_reflink "${DEST_PARENT}"; then
  MODE=clone
else
  REASON="filesystem ${SOURCE_FS:-unknown} does not support reflinks"
fi

if [[ "${MODE}" == "clone" ]]; then
  case "$(uname -s)" in
    Darwin) CP_ARGS=(-Rpc) ;;
    *) CP_ARGS=(-a --reflink=always) ;;
  esac
else
  case "$(uname -s)" in
    Darwin) CP_ARGS=(-Rp) ;;
    *) CP_ARGS=(-a) ;;
  esac
  echo "wt-clone: warning: clone impossible, falling back to a plain copy" >&2
  echo "wt-clone: warning: reason: ${REASON}" >&2
fi

STAGE_DIR="$(mktemp -d "${DEST_PARENT}/.wt-clone.XXXXXX")"
trap 'rm -rf "${STAGE_DIR}"' EXIT
trap 'rm -rf "${STAGE_DIR}"; exit 130' INT TERM
STAGE="${STAGE_DIR}/$(basename "${DEST}")"

if ! cp "${CP_ARGS[@]}" -- "${SOURCE}" "${STAGE}"; then
  echo "error: ${MODE} failed: ${SOURCE} -> ${DEST}" >&2
  exit 1
fi

if [[ -e "${DEST}" || -L "${DEST}" ]]; then
  echo "error: destination appeared during the ${MODE}: ${DEST}" >&2
  exit 1
fi

if ! mv -- "${STAGE}" "${DEST}"; then
  echo "error: ${MODE} could not be renamed into place: ${DEST}" >&2
  exit 1
fi

if [[ ! -e "${DEST}" || -L "${DEST}" ]]; then
  echo "error: ${MODE} reported success but ${DEST} is missing or a symlink" >&2
  exit 1
fi

echo "wt-clone: ${MODE}: ${SOURCE} -> ${DEST} (${SOURCE_FS})" >&2
