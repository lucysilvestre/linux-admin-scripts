#!/usr/bin/env bash
# cleanup_tmp.sh - Clean old files from temporary directories.
#
# Usage:
#   TARGET=/tmp DAYS=7 ./cleanup_tmp.sh
#
# Env vars:
#   TARGET - directory to clean (default: /tmp)
#   DAYS   - delete files older than N days (default: 7)
#
# Exit codes:
#   0=ok, 1=error

set -Eeuo pipefail

TARGET="${TARGET:-/tmp}"
DAYS="${DAYS:-7}"

if [[ ! -d "$TARGET" ]]; then
  echo "ERROR: target not found: $TARGET"; exit 1
fi

find "$TARGET" -type f -mtime "+$DAYS" -print -delete
find "$TARGET" -type d -empty -mtime "+$DAYS" -print -delete || true

echo "OK: cleaned $TARGET (older than ${DAYS}d)"

