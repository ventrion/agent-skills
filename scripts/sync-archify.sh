#!/usr/bin/env bash
# Sync the archify suite with its upstream repository.
# All logic lives in sync-suite.sh; this wrapper just names the suite.
# Usage: scripts/sync-archify.sh [--push] [REF]
set -euo pipefail
exec "$(dirname "${BASH_SOURCE[0]}")/sync-suite.sh" archify "$@"
