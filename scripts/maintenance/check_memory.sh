#!/usr/bin/env bash
# check_memory.sh - Check memory utilization and alert if above thresholds.
#
# Usage:
#   WARN=75 CRIT=90 ./check_memory.sh
#
# Exit codes:
#   0=ok, 1=warn, 2=crit, 3=error

set -Eeuo pipefail

WARN="${WARN:-75}"
CRIT="${CRIT:-90}"

read -r mem_total mem_avail < <(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END{print t, a}' /proc/meminfo || echo "")
if [[ -z "${mem_total:-}" || -z "${mem_avail:-}" ]]; then
  echo "ERROR: cannot read /proc/meminfo"; exit 3
fi

mem_used_pct=$(awk -v t="$mem_total" -v a="$mem_avail" 'BEGIN{printf "%.0f", (100*(t-a)/t)}')

status=0; level="OK"
if (( mem_used_pct >= CRIT )); then status=2; level="CRIT"
elif (( mem_used_pct >= WARN )); then status=1; level="WARN"
fi

echo "$level: Memory used ${mem_used_pct}% (warn=${WARN} crit=${CRIT})"
exit $status

