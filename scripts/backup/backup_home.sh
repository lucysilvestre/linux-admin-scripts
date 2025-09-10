#!/usr/bin/env bash
# backup_home.sh - Create a timestamped tar.gz backup for a user home.
#
# Usage:
#   USERNAME=alice DEST=/backups ./backup_home.sh
#
# Env vars:
#   USERNAME - user whose home to backup (required)
#   DEST     - output folder (default: /tmp/backups)
#
# Exit codes:
#   0=ok, 1=arg error, 2=missing home

set -Eeuo pipefail

USERNAME="${USERNAME:-}"
DEST="${DEST:-/tmp/backups}"

if [[ -z "$USERNAME" ]]; then echo "Error: set USERNAME=<name>"; exit 1; fi

HOME_DIR=$(getent passwd "$USERNAME" | cut -d: -f6 || true)
if [[ -z "$HOME_DIR" || ! -d "$HOME_DIR" ]]; then
  echo "Error: home not found for user '$USERNAME'"; exit 2
fi

mkdir -p "$DEST"
ts=$(date +%Y%m%d-%H%M%S)
out="${DEST}/home-${USERNAME}-${ts}.tar.gz"

tar -czpf "$out" -C "$HOME_DIR" .
echo "Created: $out"

