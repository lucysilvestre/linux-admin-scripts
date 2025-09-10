#!/usr/bin/env bash
# disk_space_check.sh - Check filesystem usage and alert via exit code.
# Usage:
#   THRESHOLD_WARN=80 THRESHOLD_CRIT=90 scripts/monitoring/disk_space_check.sh
# Exit: 0=ok, 1=warn, 2=crit, 3=error
set -Eeuo pipefail
THRESHOLD_WARN=${THRESHOLD_WARN:-80}
THRESHOLD_CRIT=${THRESHOLD_CRIT:-90}

status=0
while read -r fs size used avail pct mount; do
  used_pct=${pct%%%}
  if (( used_pct >= THRESHOLD_CRIT )); then
    echo "CRIT: $mount at ${used_pct}%"
    status=2
  elif (( used_pct >= THRESHOLD_WARN )); then
    echo "WARN: $mount at ${used_pct}%"
    status=${status:-1}
    [[ $status -lt 1 ]] && status=1 || true
  fi
done < <(df -hP | awk 'NR>1{print $1,$2,$3,$4,$5,$6}')

exit $status
