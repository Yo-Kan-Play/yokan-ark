#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${CONFIG_PATH:-/config/config.yaml}"

if [[ ! -f "${CONFIG_PATH}" ]]; then
	echo "[yokan-ark-bot][ERROR] config not found: ${CONFIG_PATH}" >&2
	exit 1
fi

if [[ -z "${DISCORD_TOKEN:-}" ]]; then
	echo "[yokan-ark-bot][ERROR] DISCORD_TOKEN is required" >&2
	exit 1
fi

exec /usr/local/bin/yokan-ark-bot -config "${CONFIG_PATH}"
