# linux-admin-scripts
![CI](https://github.com/lucysilvestre/linux-admin-scripts/actions/workflows/ci.yml/badge.svg)
Linux administration scripts and runbooks (backup, monitoring, maintenance, and networking).

## Why
A practical, well-documented collection you can show to recruiters and use day-to-day.

## Contents
- `scripts/monitoring/` – health checks & observability helpers
- `scripts/maintenance/` – cleanup, patch helpers, log tools
- `scripts/network/` – quick connectivity and inventory checks
- `scripts/backup/` – simple backup/restore helpers
- `tests/` – smoke tests (Bats-compatible)

## Quick start
```bash
# lint (requires shellcheck)
make lint

# run a healthcheck (prints JSON)
scripts/monitoring/linux_healthcheck.sh

# disk usage alert (exit non-zero if thresholds exceeded)
THRESHOLD_WARN=80 THRESHOLD_CRIT=90 scripts/monitoring/disk_space_check.sh

# tar/gzip a directory to timestamped archive in /tmp/backups
SRC=/etc DEST=/tmp/backups scripts/backup/backup_tar_gz.sh
```

## Requirements
- Bash 4+
- Optional: `shellcheck` for linting, `jq` for pretty JSON

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security
Never commit secrets. Read [SECURITY.md](SECURITY.md).
