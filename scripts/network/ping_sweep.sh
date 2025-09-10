#!/usr/bin/env bash
# ping_sweep.sh - Quick ping sweep for a /24 network.
# Usage: NET=192.168.1 scripts/network/ping_sweep.sh
set -Eeuo pipefail
NET=${NET:-}
[[ -z "$NET" ]] && { echo "Set NET=192.168.1"; exit 1; }
for i in {1..254}; do
  ip="${NET}.${i}"
  if ping -c1 -W1 "$ip" >/dev/null 2>&1; then
    echo "UP  : $ip"
  else
    echo "DOWN: $ip"
  fi
done
