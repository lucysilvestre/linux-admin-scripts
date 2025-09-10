#!/usr/bin/env bash
# create_local_user.sh - Create a local Linux user with safe defaults.
#
# Usage:
#   sudo ./create_local_user.sh <username> [--shell /bin/bash] [--group mygroup] [--no-password]
#
# Exit codes:
#   0 = success
#   1 = invalid arguments
#   2 = user already exists
#
# Notes:
#   - If --no-password is omitted, this will prompt to set a password.
#   - Will create the group if it does not exist.

set -Eeuo pipefail

USERNAME="${1:-}"
SHELL_BIN="/bin/bash"
PRIMARY_GROUP=""
NO_PASSWORD=false

[[ -n "$USERNAME" ]] || { echo "Usage: $0 <username> [--shell /bin/bash] [--group mygroup] [--no-password]"; exit 1; }

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --shell) SHELL_BIN="${2:-/bin/bash}"; shift 2 ;;
    --group) PRIMARY_GROUP="${2:-}"; shift 2 ;;
    --no-password) NO_PASSWORD=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if id "$USERNAME" &>/dev/null; then
  echo "Error: user '$USERNAME' already exists."
  exit 2
fi

# Ensure group exists (if provided)
if [[ -n "$PRIMARY_GROUP" ]]; then
  getent group "$PRIMARY_GROUP" >/dev/null || groupadd "$PRIMARY_GROUP"
  useradd -m -s "$SHELL_BIN" -g "$PRIMARY_GROUP" "$USERNAME"
else
  useradd -m -s "$SHELL_BIN" "$USERNAME"
fi

# Password policy: non-expiring
chage -I -1 -m 0 -M 99999 -E -1 "$USERNAME"

# Home permissions (private)
chmod 700 "/home/$USERNAME"

# Optional password
if ! $NO_PASSWORD; then
  echo "Set password for '$USERNAME':"
  passwd "$USERNAME"
fi

echo "User '$USERNAME' created."

