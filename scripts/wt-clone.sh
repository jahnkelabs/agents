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

Clone-capable filesystems: apfs on macOS, btrfs and xfs on Linux. The
Linux clone runs cp --reflink=always, which fails loudly rather than
falling back.

The destination must not exist. Exit status is 0 only when the copy
reached it.

Measured on APFS: a 500 MB clone took 0.00s and consumed 0 MB, against
0.19s and 500 MB for a plain copy. Diverging 100 MB of that clone then
consumed 100 MB. A recursive clone runs at roughly 5,000 files per
second, so time scales with file count rather than with bytes.
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

if [[ -e "${DEST}" ]]; then
  echo "error: destination exists, refusing to overwrite: ${DEST}" >&2
  exit 1
fi

DEST_PARENT="$(dirname "${DEST}")"

if [[ ! -d "${DEST_PARENT}" ]]; then
  echo "error: destination directory missing: ${DEST_PARENT}" >&2
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

SOURCE_DEVICE="$(device_id "${SOURCE}")"
DEST_DEVICE="$(device_id "${DEST_PARENT}")"
SOURCE_FS="$(filesystem_type "${SOURCE}")"

MODE=copy
REASON=""

if [[ "${SOURCE_DEVICE}" != "${DEST_DEVICE}" ]]; then
  REASON="different volumes (${SOURCE_FS} device ${SOURCE_DEVICE} to device ${DEST_DEVICE})"
elif [[ "${SOURCE_FS}" != "apfs" && "${SOURCE_FS}" != "btrfs" && "${SOURCE_FS}" != "xfs" ]]; then
  REASON="filesystem ${SOURCE_FS:-unknown} does not support cloning"
else
  MODE=clone
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

if ! cp "${CP_ARGS[@]}" -- "${SOURCE}" "${DEST}"; then
  echo "error: ${MODE} failed: ${SOURCE} -> ${DEST}" >&2
  exit 1
fi

if [[ ! -e "${DEST}" ]]; then
  echo "error: ${MODE} reported success but ${DEST} is missing" >&2
  exit 1
fi

echo "wt-clone: ${MODE}: ${SOURCE} -> ${DEST} (${SOURCE_FS})" >&2
