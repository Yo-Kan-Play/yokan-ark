#!/usr/bin/env bash
set -euo pipefail

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PERSIST_HOST_PATH="${WORKSPACE_ROOT}/persist"
SHARED_INI_HOST_PATH="${WORKSPACE_ROOT}/shared/ini/WindowsServer"

# Load .env from shared/ (scripts is in ./scripts so parent is repo root)
if [ -f "$SCRIPT_DIR/../shared/.env" ]; then
  set -a
  . "$SCRIPT_DIR/../shared/.env"
  set +a
fi

podman run --rm --name yokan-ark-bot \
  -e DISCORD_TOKEN="$DISCORD_TOKEN" \
  -e ARK_RCON_PASSWORD="$ARK_RCON_PASSWORD" \
  -e YOKAN_PERSIST_HOST_PATH="$PERSIST_HOST_PATH" \
  -e YOKAN_SHARED_INI_HOST_PATH="$SHARED_INI_HOST_PATH" \
  -v "$SCRIPT_DIR/../shared/config.yaml:/config/config.yaml:ro" \
  -v "/run/user/1000/podman/podman.sock:/run/user/1000/podman/podman.sock" \
  -v "$SCRIPT_DIR/../persist:$PERSIST_HOST_PATH:ro" \
  -v "$SCRIPT_DIR/../shared/ini/WindowsServer:$SHARED_INI_HOST_PATH:ro" \
  -v "$SCRIPT_DIR/../backups:/srv/yokan-ark/backups/local:rw" \
  yokan-ark-bot:latest
