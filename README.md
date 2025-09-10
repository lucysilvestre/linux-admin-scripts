# linux-admin-scripts
![CI](https://github.com/lucysilvestre/linux-admin-scripts/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

Practical Bash scripts for Linux system administration: monitoring, backups, maintenance, networking, and user management.  
A curated collection of scripts that reflect real-world sysadmin tasks, following best practices and automation principles.

---

## Why
System administrators constantly repeat similar tasks: creating users, rotating logs, checking disk space, verifying connectivity, etc.  
This repository centralizes those scripts into a reusable toolkit that is:

-  **Practical** – tested in real environments (RHEL, Oracle Linux, CentOS, Ubuntu)  
-  **Idempotent** – safe to run multiple times without breaking things  
-  **Secure** – never stores secrets, encourages least privilege  
-  **Documented** – each script includes usage, exit codes, and prerequisites  

Perfect as a reference for day-to-day Linux administration.

---

## Contents
- `scripts/users/` – user & group management (`create_user.sh`, `bulk_create_users.sh`, …)  
- `scripts/monitoring/` – health checks & observability helpers (CPU, memory, disk, ports)  
- `scripts/maintenance/` – cleanup, patch helpers, log rotation  
- `scripts/network/` – connectivity and inventory checks  
- `scripts/backup/` – simple backup/restore helpers (rsync, tar/gzip)  
- `scripts/security/` – hardening snippets (SSH permissions, sudo checks)  
- `scripts/provisioning/` – environment setup for servers (e.g., `setup_oda_env.sh`)  
- `tests/` – smoke tests (Bats-compatible)

---

## Quick start
Run directly from the repo:

```bash
# lint (requires shellcheck)
make lint

# healthcheck: outputs CPU/memory/disk in JSON
scripts/monitoring/linux_healthcheck.sh

# disk usage alert (non-zero exit if thresholds exceeded)
THRESHOLD_WARN=80 THRESHOLD_CRIT=90 scripts/monitoring/disk_space_check.sh

# backup /etc into timestamped archive under /tmp/backups
SRC=/etc DEST=/tmp/backups scripts/backup/backup_dir_rsync.sh

# create a local user with safe defaults
sudo scripts/users/create_local_user.sh demo-user
