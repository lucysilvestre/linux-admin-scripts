#!/usr/bin/env bash
set -Eeuo pipefail
echo "[SMOKE] healthcheck"
scripts/monitoring/linux_healthcheck.sh >/dev/null
echo "[SMOKE] disk check (no fail expected)"
THRESHOLD_WARN=101 THRESHOLD_CRIT=102 scripts/monitoring/disk_space_check.sh >/dev/null
echo "[OK] Smoke tests passed"
