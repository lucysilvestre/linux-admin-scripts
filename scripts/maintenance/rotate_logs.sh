#!/usr/bin/env bash
# rotate_logs.sh - Simple size-based log rotation.
# Usage: LOG=/var/log/myapp.log MAX_MB=50 KEEP=5 scripts/maintenance/rotate_logs.sh
set -Eeuo pipefail
LOG=${LOG:-}
MAX_MB=${MAX_MB:-50}
KEEP=${KEEP:-5}
[[ -z "$LOG" ]] && { echo "Set LOG=/path/to/log"; exit 1; }
[[ ! -f "$LOG" ]] && { echo "No log: $LOG"; exit 0; }

size_mb=$(du -m "$LOG" | awk '{print $1}')
if (( size_mb < MAX_MB )); then
  echo "OK: $LOG size ${size_mb}MB < ${MAX_MB}MB"
  exit 0
fi

i=$KEEP
while (( i > 0 )); do
  prev=$((i-1))
  [[ -f "${LOG}.${prev}.gz" ]] && mv "${LOG}.${prev}.gz" "${LOG}.${i}.gz" || true
  ((i--))
done
gzip -c "$LOG" > "${LOG}.0.gz"
: > "$LOG"
echo "Rotated $LOG (keep=$KEEP)"
