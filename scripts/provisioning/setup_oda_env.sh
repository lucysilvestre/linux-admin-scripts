#!/usr/bin/env bash
# setup_oda_env.sh - Configure base environment for Oracle Database Appliance (ODA)-like servers.
#
# Usage:
#   sudo ./setup_oda_env.sh [--force] [--timezone America/Edmonton] [--disable-firewalld]
#
# Defaults:
#   DRY_RUN=true (prints actions; does not execute). Use --force to apply changes.
#
# Actions (configurable via variables below):
#   - Create OS groups and users (idempotent)
#   - Enable repos and install packages (yum/dnf)
#   - Configure NFS mounts for /dbadmin and /backups
#   - Prepare /u01 hierarchy (optional mkfs guarded by DRY_RUN)
#   - Enable services (sendmail, zabbix-agent2, chronyd)
#   - Optional: realm discovery/join (domain join) – disabled by default
#   - Optional: firewalld adjustments or disable (off by default)
#
# Exit codes:
#   0 = success
#   1 = invalid arguments
#   2 = prerequisites missing
#   3 = runtime error
#
# Notes:
#   - Review and set variables below BEFORE running.
#   - Keep secrets (passwords/keys) OUT of this script.
#   - Tested on OL8/RHEL8-like systems; adapt as needed.

set -Eeuo pipefail

########################
# Configurable variables
########################

DRY_RUN=true
DISABLE_FIREWALLD=false
DO_REALM_JOIN=false          # domain join OFF by default
TIMEZONE_DEFAULT="America/Edmonton"

# Domain/Directory (example placeholders)
REALM_DOMAIN="EXAMPLE.DOMAIN"
REALM_USER="admin.user"     # directory admin for join (no password here)

# NFS mounts (use TEST-NET IPs or hostnames)
NFS_SERVER="192.0.2.10"     # placeholder for docs
NFS_DBADMIN_PATH="/volume1/dbadmin"
NFS_BACKUPS_PATH="/volume1/nfs_backups"

MOUNT_DBADMIN="/dbadmin"
MOUNT_BACKUPS="/backups"

# Chrony/NTP
CHRONY_SERVER="192.0.2.20"  # placeholder
ENABLE_CHRONY=true

# /u01 volume (mkfs is DANGEROUS; guarded by DRY_RUN)
BLOCK_DEVICE="/dev/sdb"
DO_FORMAT_U01=false

# Zabbix repo (example for EL8)
ENABLE_ZABBIX_REPO=true
ZABBIX_REPO_RPM="https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-latest.el8.noarch.rpm"

# EPEL repo
ENABLE_EPEL=true
EPEL_RPM="https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"

# Package set
PACKAGES=(
  libnsl libnsl.i686 libnsl2 libnsl2.i686
  oracle-database-preinstall-19c.x86_64
  mutt tree screen rsync unixODBC dos2unix sendmail mailx rlwrap gparted htop
  zabbix-agent2 chrony nfs-utils
)

# OS groups (name:gid)
OS_GROUPS=(
  "oinstall:54321"
  "dba:54322"
  "oper:54323"
  "backupdba:54324"
  "dgdba:54325"
  "kmdba:54326"
  "asmdba:54327"
  "asmoper:54328"
  "asmadmin:54329"
  "racdba:54330"
  "admgroup:1003"
)

# OS users (username:uid:group_list) -> primary = first group; supplementaries = remaining
OS_USERS=(
  "oracle:54321:oinstall,dba,oper,backupdba,dgdba,kmdba,asmdba,asmadmin,racdba"
  "grid:54331:oinstall,dba,asmadmin,asmdba,asmoper,racdba"
  # examples (neutralized):
  "techadmin:1002:admgroup,wheel"
  "opsuser:1003:admgroup,wheel"
)

########################
# Logging
########################

LOG_DIR="/var/log/installation"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/setup_oda_env_$(date +%Y.%m.%d_%H%M%S).log"

log()    { printf '[%s] %s\n' "$(date +%F_%T)" "$*" | tee -a "$LOG_FILE"; }
run()    { if $DRY_RUN; then log "DRY-RUN: $*"; else eval "$@" | tee -a "$LOG_FILE"; fi; }
exists() { command -v "$1" >/dev/null 2>&1; }

trap 'log "ERROR at line $LINENO"; exit 3' ERR

log "===== Starting setup (DRY_RUN=$DRY_RUN) ====="
log "Log file: $LOG_FILE"

########################
# Parse flags
########################
TZ_TO_SET="$TIMEZONE_DEFAULT"

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --force) DRY_RUN=false; shift ;;
    --disable-firewalld) DISABLE_FIREWALLD=true; shift ;;
    --timezone) TZ_TO_SET="${2:-$TIMEZONE_DEFAULT}"; shift 2 ;;
    *) log "Unknown argument: $1"; exit 1 ;;
  case_esac=true
  esac
done

########################
# Prereqs
########################
if ! exists yum && ! exists dnf; then
  log "Neither yum nor dnf found. Aborting."
  exit 2
fi

PKG_MGR="yum"
exists dnf && PKG_MGR="dnf"

########################
# Helper: idempotent add group/user
########################
ensure_group() {
  local name="$1" gid="$2"
  if getent group "$name" >/dev/null; then
    log "Group exists: $name"
  else
    log "Create group: $name (gid:$gid)"
    run "groupadd -g '$gid' '$name'"
  fi
}

ensure_user() {
  local username="$1" uid="$2" groups_csv="$3"
  if id "$username" >/dev/null 2>&1; then
    log "User exists: $username"
    return
  fi

  IFS=',' read -r -a glist <<< "$groups_csv"
  local primary="${glist[0]}"
  local supplementary=""
  if (( ${#glist[@]} > 1 )); then
    supplementary="$(IFS=','; echo "${glist[*]:1}")"
  fi

  # ensure groups exist
  for g in "${glist[@]}"; do
    getent group "$g" >/dev/null || run "groupadd '$g'"
  done

  if [[ -n "$supplementary" ]]; then
    log "Create user: $username (uid:$uid, -g $primary, -G $supplementary)"
    run "useradd -m -u '$uid' -g '$primary' -G '$supplementary' -s /bin/bash '$username'"
  else
    log "Create user: $username (uid:$uid, -g $primary)"
    run "useradd -m -u '$uid' -g '$primary' -s /bin/bash '$username'"
  fi

  # password policy: non-expiring
  run "chage -I -1 -m 0 -M 99999 -E -1 '$username'"
  run "chmod 700 '/home/$username'"
}

########################
# Clean old logs (>5d)
########################
run "find '$LOG_DIR' -name 'setup_oda_env_*' -mtime +5 -delete"

########################
# Timezone
########################
if exists timedatectl; then
  log "Set timezone to $TZ_TO_SET"
  run "timedatectl set-timezone '$TZ_TO_SET'"
else
  log "timedatectl not found; skipping timezone"
fi

########################
# Repos
########################
if $ENABLE_ZABBIX_REPO; then
  log "Enable Zabbix repo"
  run "$PKG_MGR install -y '$ZABBIX_REPO_RPM'"
fi

if $ENABLE_EPEL; then
  log "Enable EPEL repo"
  run "$PKG_MGR install -y '$EPEL_RPM'"
fi

run "$PKG_MGR repolist"

########################
# Packages
########################
log "Install packages: ${PACKAGES[*]}"
# handle local RPM oracle-database-preinstall-19c if provided in /tmp
if [[ -f /tmp/oracle-database-preinstall-19c.x86_64.rpm ]]; then
  run "$PKG_MGR install -y /tmp/oracle-database-preinstall-19c.x86_64.rpm"
fi
# install all (ignore missing local RPM if not present)
run "$PKG_MGR install -y ${PACKAGES[*]}" || true
run "$PKG_MGR clean all"

########################
# Users & Groups
########################
for def in "${OS_GROUPS[@]}"; do
  name="${def%%:*}"
  gid="${def##*:}"
  ensure_group "$name" "$gid"
done

for def in "${OS_USERS[@]}"; do
  IFS=':' read -r username uid groups_csv <<< "$def"
  ensure_user "$username" "$uid" "$groups_csv"
done

########################
# NFS mounts (/dbadmin, /backups)
########################
log "Prepare NFS mounts"
run "mkdir -p '$MOUNT_DBADMIN' '$MOUNT_BACKUPS'"
run "chown -R oracle:dba '$MOUNT_DBADMIN' '$MOUNT_BACKUPS'"
run "chmod 770 '$MOUNT_DBADMIN' '$MOUNT_BACKUPS'"

# mount commands
run "mount -t nfs ${NFS_SERVER}:${NFS_DBADMIN_PATH} '$MOUNT_DBADMIN'"
run "mount -t nfs ${NFS_SERVER}:${NFS_BACKUPS_PATH} '$MOUNT_BACKUPS'"

# fstab entries (idempotent)
add_fstab() {
  local line="$1"
  grep -qxF "$line" /etc/fstab || run "printf '%s\n' \"$line\" >> /etc/fstab"
}
add_fstab "${NFS_SERVER}:${NFS_DBADMIN_PATH}  ${MOUNT_DBADMIN}  nfs  defaults,_netdev  0 0"
add_fstab "${NFS_SERVER}:${NFS_BACKUPS_PATH}  ${MOUNT_BACKUPS}  nfs  defaults,_netdev  0 0"

########################
# /u01 volume (DANGEROUS)
########################
if $DO_FORMAT_U01; then
  log "Formatting $BLOCK_DEVICE as ext4 and preparing /u01 (DANGEROUS)"
  run "mkfs -t ext4 '$BLOCK_DEVICE'"
fi

run "mkdir -p /u01/app/19.0.0.0/grid /u01/app/grid /u01/app/oracle"
run "chown -R grid:oinstall /u01"
run "chown oracle:oinstall /u01/app/oracle"
run "chmod -R 775 /u01"
run "chmod -R g+s /u01"

########################
# Services
########################
log "Enable services (sendmail, zabbix-agent2)"
run "systemctl enable --now sendmail || true"
run "systemctl enable --now zabbix-agent2 || true"

if $ENABLE_CHRONY; then
  log "Configure chrony"
  if [[ -f /etc/chrony.conf ]]; then
    # add server if not present
    grep -q "$CHRONY_SERVER" /etc/chrony.conf || run "sed -i '1iserver $CHRONY_SERVER iburst' /etc/chrony.conf"
  fi
  run "systemctl enable --now chronyd.service"
fi

########################
# Transparent Hugepages (check only; do not change here)
########################
if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
  run "cat /sys/kernel/mm/transparent_hugepage/enabled"
fi

########################
# Firewalld (optional)
########################
if $DISABLE_FIREWALLD; then
  log "Disabling firewalld (not generally recommended)"
  run "systemctl disable --now firewalld || true"
else
  # Example: allow NTP if using firewalld
  if systemctl is-active firewalld >/dev/null 2>&1; then
    log "Opening NTP service via firewalld"
    run "firewall-cmd --permanent --add-service=ntp"
    run "firewall-cmd --reload"
  fi
fi

########################
# Realm (optional; OFF by default)
########################
if $DO_REALM_JOIN; then
  if exists realm; then
    log "Realm discover: $REALM_DOMAIN"
    run "realm discover '$REALM_DOMAIN'"
    log "Realm join (interactive password prompt)"
    run "realm join --user='$REALM_USER' '$REALM_DOMAIN'"
    run "realm list"
  else
    log "'realm' not found; skipping domain join"
  fi
fi

########################
# OS Update & Clean
########################
log "Final OS update & cleanup"
run "$PKG_MGR -y update || true"
run "$PKG_MGR clean all || true"

log "===== Completed setup (DRY_RUN=$DRY_RUN). Use --force to apply. ====="

