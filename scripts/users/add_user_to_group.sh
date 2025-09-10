#!/usr/bin/env bash
# add_user_to_group.sh - Add an existing user to an existing group (idempotent).
#
# Usage:
#   sudo ./add_user_to_group.sh <username> <group>
#
# Exit codes:
#   0=ok, 1=args, 2=no user, 3=no group

set -Eeuo pipefail

USER_NAME=${1:-}
GROUP_NAME=${2:-}

if [[ -z "$USER_NAME" || -z "$GROUP_NAME" ]]; then
  echo "Usage: $0 <username> <group>"; exit 1
fi

id "$USER_NAME" &>/dev/null || { echo "Error: user '$USER_NAME' not found"; exit 2; }
getent group "$GROUP_NAME" >/dev/null || { echo "Error: group '$GROUP_NAME' not found"; exit 3; }

# Check membership
if id -nG "$USER_NAME" | tr ' ' '\n' | grep -qx "$GROUP_NAME"; then
  echo "User '$USER_NAME' already in group '$GROUP_NAME' (nothing to do)"; exit 0
fi

usermod -a -G "$GROUP_NAME" "$USER_NAME"
echo "Added '$USER_NAME' to group '$GROUP_NAME'"

