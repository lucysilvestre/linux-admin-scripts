#!/usr/bin/env bash
# backup_dir_rsync.sh - Rsync a directory to a destination with timestamped snapshot.
#
# Usage:
#   SRC=/etc DEST=/backup ./backup_dir_rsync.sh
#
# Exit codes:
#   0 = success
#   1 = missing arguments
#   2 = rsync error
#
# Notes:
#   - Requires rsync.
#   - Creates DEST if missing.
#   - Uses a timestamped target directory.

set -Eeuo pipefail

SRC="${SRC:-}"
DEST="${DEST:-}"

[[ -n "$SRC" && -n "$DEST" ]] || { echo "Usage: SRC=/path DEST=/path $0"; exit 1; }

ts="$(date +%Y%m%d-%H%M%S)"
target="${DEST%/}/$(basename "$SRC")-${ts}"

mkdir -p "$target"
if rsync -aHAX --delete "$SRC"/ "$target"/; then
  echo "Backup OK: $target"
else
  echo "Backup FAILED"
  exit 2
fi

