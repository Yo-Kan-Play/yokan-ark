#!/usr/bin/env bash
set -euo pipefail

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env from shared/ (scripts is in ./scripts so parent is repo root)
if [ -f "$SCRIPT_DIR/../shared/.env" ]; then
  set -a
  . "$SCRIPT_DIR/../shared/.env"
  set +a
fi

podman run --rm --name yokan-ark-bot \
  -e DISCORD_TOKEN="$DISCORD_TOKEN" \
  -e ARK_RCON_PASSWORD="$ARK_RCON_PASSWORD" \
  -v "$SCRIPT_DIR/../shared/config.yaml:/config/config.yaml:ro" \
  -v "/run/user/1000/podman/podman.sock:/run/user/1000/podman/podman.sock" \
  -v "$SCRIPT_DIR/../persist:/srv/yokan-ark/persist:ro" \
  -v "$SCRIPT_DIR/../backups:/srv/yokan-ark/backups/local:rw" \
  yokan-ark-bot:latest
