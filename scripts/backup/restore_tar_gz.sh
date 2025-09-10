#!/usr/bin/env bash
# restore_tar_gz.sh - Restore a .tar.gz archive into a target directory.
#
# Usage:
#   ARCHIVE=/path/to/file.tar.gz TARGET=/restore/here ./restore_tar_gz.sh
#
# Exit codes:
#   0=ok, 1=arg error, 2=missing file/dir

set -Eeuo pipefail

ARCHIVE="${ARCHIVE:-}"
TARGET="${TARGET:-}"

if [[ -z "$ARCHIVE" || -z "$TARGET" ]]; then
  echo "Error: set ARCHIVE=/path/to/file.tar.gz TARGET=/dir"; exit 1
fi
[[ -f "$ARCHIVE" ]] || { echo "Error: archive not found: $ARCHIVE"; exit 2; }

mkdir -p "$TARGET"
tar -xzpf "$ARCHIVE" -C "$TARGET"
echo "Restored into: $TARGET"

