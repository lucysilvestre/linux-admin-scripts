#!/usr/bin/env bash
# check_memory.sh - Check available memory percent and alert.
#
# Usage:
#   ./check_memory.sh [threshold_percent]
#   ./check_memory.sh 20
#
# Exit codes:
#   0 = ok (available% >= threshold)
#   1 = warn/crit (available% < threshold)
#
# Notes:
#   - Uses MemAvailable from /proc/meminfo.

set -Eeuo pipefail

THRESHOLD="${1:-20}"  # alert if available% < threshold

mem_total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_avail_kb=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
avail_pct=$(( 100 * mem_avail_kb / mem_total_kb ))

if (( avail_pct < THRESHOLD )); then
  echo "MEMORY LOW: ${avail_pct}% available (< ${THRESHOLD}%)"
  exit 1
fi

echo "MEMORY OK: ${avail_pct}% available (>= ${THRESHOLD}%)"

