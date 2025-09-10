#!/usr/bin/env bash
# linux_healthcheck.sh - Print a quick Linux health snapshot in JSON.
# Usage: scripts/monitoring/linux_healthcheck.sh
# Exit codes: 0 on success, 1 on error.
set -Eeuo pipefail

hostname=$(hostname || echo "unknown")
kernel=$(uname -r || echo "unknown")
uptime_s=$(cut -d. -f1 /proc/uptime 2>/dev/null || echo "0")
loadavg=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || echo "0 0 0")
mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
mem_free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
disk_root=$(df -hP / | awk 'NR==2{print $5}' | tr -d '%')

printf '{
'
printf '  "hostname": "%s",
' "$hostname"
printf '  "kernel": "%s",
' "$kernel"
printf '  "uptime_seconds": %s,
' "$uptime_s"
printf '  "loadavg": "%s",
' "$loadavg"
printf '  "mem_total_kb": %s,
' "$mem_total"
printf '  "mem_available_kb": %s,
' "$mem_free"
printf '  "disk_root_used_pct": %s
' "${disk_root:-0}"
printf '}
'
