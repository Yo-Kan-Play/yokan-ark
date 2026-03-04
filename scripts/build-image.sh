#!/usr/bin/env bash
set -euo pipefail

# Build container images.
#
# Usage:
#   ./scripts/build-image.sh                 # builds maps image (default tag)
#   ./scripts/build-image.sh <TAG>           # builds maps image with TAG
#   ./scripts/build-image.sh maps yokan-ark-maps:latest
#   ./scripts/build-image.sh bot yokan-ark-bot:latest

TARGET="maps"
TAG="yokan-ark-maps:latest"

if [[ $# -ge 1 ]]; then
  case "$1" in
    maps|bot)
      TARGET="$1"
      shift
      ;;
    *)
      # Backward compatible: first arg is treated as maps tag
      TAG="$1"
      shift
      ;;
  esac
fi

if [[ $# -ge 1 ]]; then
  TAG="$1"
  shift
fi

case "${TARGET}" in
  maps)
    podman build -f maps/Dockerfile -t "${TAG}" maps
    ;;
  bot)
    podman build -f bot/Dockerfile -t "${TAG}" bot
    ;;
  *)
    echo "Unknown target: ${TARGET}" >&2
    exit 1
    ;;
esac

echo "Built ${TARGET}: ${TAG}"
