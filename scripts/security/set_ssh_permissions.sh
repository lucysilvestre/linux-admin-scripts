#!/usr/bin/env bash
# set_ssh_permissions.sh - Harden SSH directory and file permissions for a user.
#
# Usage:
#   sudo ./set_ssh_permissions.sh <username>
#
# Exit codes:
#   0 = success
#   1 = invalid arguments
#   2 = user/home not found
#
# Notes:
#   - Sets ~/.ssh perms to 700, authorized_keys to 600.
#   - Useful for fixing "unprotected private key file" errors.

set -Eeuo pipefail

USER_NAME="${1:-}"
[[ -n "$USER_NAME" ]] || { echo "Usage: $0 <username>"; exit 1; }

HOME_DIR=$(eval echo "~$USER_NAME") || true
[[ -d "$HOME_DIR" ]] || { echo "Error: home not found for '$USER_NAME'"; exit 2; }

SSH_DIR="$HOME_DIR/.ssh"
[[ -d "$SSH_DIR" ]] || mkdir -p "$SSH_DIR"

chown -R "$USER_NAME:$USER_NAME" "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ -f "$SSH_DIR/authorized_keys" ]]; then
  chown "$USER_NAME:$USER_NAME" "$SSH_DIR/authorized_keys"
  chmod 600 "$SSH_DIR/authorized_keys"
fi

echo "SSH permissions fixed for $USER_NAME."

