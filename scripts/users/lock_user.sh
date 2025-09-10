#!/usr/bin/env bash
# lock_user.sh - Lock a user account to prevent logins (idempotent).
#
# Usage:
#   sudo ./lock_user.sh <username>
#
# Exit codes:
#   0=ok, 1=args, 2=user missing

set -Eeuo pipefail

USER_NAME="${1:-}"
if [[ -z "$USER_NAME" ]]; then echo "Usage: $0 <username>"; exit 1; fi
id "$USER_NAME" &>/dev/null || { echo "Error: user '$USER_NAME' not found"; exit 2; }

passwd -l "$USER_NAME"
chage -E0 "$USER_NAME" || true
echo "Locked user: $USER_NAME"

