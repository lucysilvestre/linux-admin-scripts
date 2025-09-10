#!/usr/bin/env bash
# backup_tar_gz.sh - Create a timestamped .tar.gz archive from SRC into DEST.
# Usage: SRC=/etc DEST=/tmp/backups scripts/backup/backup_tar_gz.sh
# Notes: creates DEST if missing.
set -Eeuo pipefail
SRC=${SRC:-}
DEST=${DEST:-/tmp/backups}
[[ -z "$SRC" ]] && { echo "Set SRC=/path/to/dir"; exit 1; }
mkdir -p "$DEST"
ts=$(date +%Y%m%d-%H%M%S)
name=$(basename "$SRC")
out="$DEST/${name}-${ts}.tar.gz"
tar -czpf "$out" "$SRC"
echo "Created: $out"
