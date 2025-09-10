#!/usr/bin/env bash
# create_ftp_user.sh - Create a new FTP/SFTP user with secure defaults
#
# Usage:
#   sudo ./create_ftp_user.sh <username>
#
# Notes:
#   - Requires group 'sftpgroup' to exist
#   - Updates chroot list at /etc/vsftpd.chroot_list
#   - Prompts for password at the end
#
# Exit codes:
#   0 = success
#   1 = invalid arguments
#   2 = user already exists

set -Eeuo pipefail

USER_NAME=${1:-}

if [[ -z "$USER_NAME" ]]; then
  echo "Usage: $0 <username>"
  exit 1
fi

# Check if user already exists
if id "$USER_NAME" &>/dev/null; then
  echo "Error: user '$USER_NAME' already exists."
  exit 2
fi

echo "***** Starting creation of user: $USER_NAME *****"

# Create FTP user in group sftpgroup
useradd "$USER_NAME" -g sftpgroup

# Set password to never expire
chage -I -1 -m 0 -M 99999 -E -1 "$USER_NAME"

# Prepare home directory
mkdir -p "/home/$USER_NAME/files"
chown -R "$USER_NAME:sftpgroup" "/home/$USER_NAME/files"
chmod -R 700 "/home/$USER_NAME"

# Set default home directory
usermod "$USER_NAME" -d "/home/$USER_NAME/files"

# Add user to chroot list for FTP access
echo "$USER_NAME" >> /etc/vsftpd.chroot_list

# Assign password
echo "Assigning password for new user $USER_NAME"
passwd "$USER_NAME"

echo "***** User $USER_NAME has been created successfully *****"

