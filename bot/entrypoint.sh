#!/usr/bin/env bash
set -euo pipefail
echo "[yokan-ark-bot] Placeholder container."
echo "[yokan-ark-bot] Bot source code is not included yet."
echo "[yokan-ark-bot] Mount your config at /config/config.yaml and implement the bot in /app/src."
# Keep container alive so systemd/quadlet can manage it during early development.
tail -f /dev/null
