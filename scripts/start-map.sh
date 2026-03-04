#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <MAP_ID>" >&2
  exit 1
fi

MAP_ID="$1"
NAME="yokan-ark-${MAP_ID}"

podman start "${NAME}"
echo "Started: ${NAME}"
