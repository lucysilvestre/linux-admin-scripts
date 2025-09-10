#!/usr/bin/env bash
# expire_user.sh - Set an account expiration date (YYYY-MM-DD).
#
# Usage:
#   sudo ./expire_user.sh <username> <YYYY-MM-DD>
#
# Exit codes:
#   0=ok, 1=args, 2=user missing

set -Eeuo pipefail

USER_NAME="${1:-}"
DATE="${2:-}"

if [[ -z "$USER_NAME" || -z "$DATE" ]]; then
  echo "Usage: $0 <username> <YYYY-MM-DD>"; exit 1
fi

id "$USER_NAME" &>/dev/null || { echo "Error: user '$USER_NAME' not found"; exit 2; }
chage -E "$DATE" "$USER_NAME"
echo "User '$USER_NAME' expiration set to $DATE"

