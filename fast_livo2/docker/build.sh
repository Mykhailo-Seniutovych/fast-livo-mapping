#!/usr/bin/env bash
# Build the FAST-LIVO2 docker image. Run from this directory or anywhere — the
# build context is the FAST-LIVO2 repo root (one level up).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

docker build -t fast-livo2:humble -f "${SCRIPT_DIR}/Dockerfile" "${REPO_ROOT}"
