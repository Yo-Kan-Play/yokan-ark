#!/usr/bin/env bash
set -euo pipefail

PERSIST_HOST_PATH="${1:-/srv/yokan-ark/persist}"

mkdir -p "${PERSIST_HOST_PATH}/cluster-shared"
mkdir -p "${PERSIST_HOST_PATH}/maps"

echo "Prepared persist directory: ${PERSIST_HOST_PATH}"
