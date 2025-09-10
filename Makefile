SHELL := /usr/bin/env bash
.PHONY: lint test

lint:
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not installed"; exit 0; }
	shellcheck scripts/**/*.sh

test:
	@echo "Running smoke tests..."
	bash tests/smoke.sh
