#!/usr/bin/env bash
# check_port.sh - Test if a TCP port is reachable (local or remote).
#
# Usage:
#   ./check_port.sh <host> <port> [timeout_sec]
#
# Exit codes:
#   0=reachable, 1=unreachable, 2=arg error

set -Eeuo pipefail

HOST=${1:-}
PORT=${2:-}
TIMEOUT=${3:-3}

if [[ -z "$HOST" || -z "$PORT" ]]; then
  echo "Usage: $0 <host> <port> [timeout_sec]"; exit 2
fi

if command -v nc >/dev/null 2>&1; then
  if nc -z -w "$TIMEOUT" "$HOST" "$PORT"; then
    echo "OK: $HOST:$PORT reachable"; exit 0
  else
    echo "FAIL: $HOST:$PORT unreachable"; exit 1
  fi
elif command -v timeout >/dev/null 2>&1 && command -v bash >/dev/null 2>&1; then
  # Fallback using /dev/tcp
  if timeout "$TIMEOUT" bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
    echo "OK: $HOST:$PORT reachable"; exit 0
  else
    echo "FAIL: $HOST:$PORT unreachable"; exit 1
  fi
else
  echo "ERROR: need 'nc' or 'timeout' with bash /dev/tcp"; exit 1
fi

