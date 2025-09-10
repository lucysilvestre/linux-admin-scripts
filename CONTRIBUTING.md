# Contributing
- Keep scripts **POSIX-ish** where possible; use `#!/usr/bin/env bash` and `set -Eeuo pipefail`.
- Add a brief header to each script: purpose, usage, env vars, exit codes.
- Ensure scripts are **idempotent** (safe to re-run) whenever feasible.
- Include a test in `tests/` (Bats-style `.bats` or a simple shell script).
- Run `make lint` and fix issues before pushing.
