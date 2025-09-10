#!/usr/bin/env bash
# check_cpu.sh - Check average CPU utilization and alert if above thresholds.
#
# Usage:
#   WARN=70 CRIT=90 ./check_cpu.sh
#
# Env vars:
#   WARN  - warning threshold (default: 75)
#   CRIT  - critical threshold (default: 90)
#
# Exit codes:
#   0=ok, 1=warn, 2=crit, 3=error

set -Eeuo pipefail

WARN="${WARN:-75}"
CRIT="${CRIT:-90}"

usage_idle=$(mpstat 1 1 2>/dev/null | awk '/Average/ && $NF ~ /[0-9.]+/ {print $NF}')
if [[ -z "${usage_idle:-}" ]]; then
  # Fallback to top if mpstat is unavailable
  usage_idle=$(top -bn1 | awk -F',' '/Cpu\(s\)/ {gsub(/.*id, /,"",$4); gsub(/ id.*/,"",$4); print $4}' || echo "")
fi

if [[ -z "${usage_idle:-}" ]]; then
  echo "ERROR: unable to read CPU idle%"; exit 3
fi

# Convert idle% to used%
cpu_used=$(awk -v idle="$usage_idle" 'BEGIN{printf "%.0f", (100 - idle)}')

status=0; level="OK"
if (( cpu_used >= CRIT )); then status=2; level="CRIT"
elif (( cpu_used >= WARN )); then status=1; level="WARN"
fi

echo "$level: CPU used ${cpu_used}% (warn=${WARN} crit=${CRIT})"
exit $status

