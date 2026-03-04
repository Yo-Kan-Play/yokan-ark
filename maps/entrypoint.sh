#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[yokan-entrypoint] $*" >&2
}

die() {
  echo "[yokan-entrypoint][ERROR] $*" >&2
  exit 1
}

# --- Required map-specific env ---
: "${MAP_ID:?MAP_ID is required (e.g. TheCenter_WP)}"
: "${SESSION_NAME:?SESSION_NAME is required (e.g. Yokan Ark The Center)}"
: "${PORT:?PORT is required (e.g. 7777)}"

# --- Common env (same across maps; optional overrides) ---
PERSIST_ROOT="${PERSIST_ROOT:-/persist}"
COMMON_INI_DIR="${COMMON_INI_DIR:-/shared/ini/WindowsServer}"
CLUSTER_ID="${CLUSTER_ID:-yokan-ark}"
MAX_PLAYERS="${MAX_PLAYERS:-10}"
ENABLE_DEBUG="${ENABLE_DEBUG:-0}"
EXTRA_ASA_START_PARAMS="${EXTRA_ASA_START_PARAMS:-}"

# Port derivation (to avoid collisions when multiple maps run at once)
# - Game port: PORT (udp)
# - RCON port: PORT + 19243 (tcp)  => 7777 -> 27020
# - Query port: PORT + 1 (udp)     (optional; not always used)
RCON_PORT=$((PORT + 19243))
QUERY_PORT=$((PORT + 1))

# Persistent layout (single mount: /persist)
MAP_ROOT="${PERSIST_ROOT}/maps/${MAP_ID}"

# Internal fixed paths used by base image
SERVER_FILES="/home/gameserver/server-files"
STEAM_DIR="/home/gameserver/Steam"
STEAMCMD_DIR="/home/gameserver/steamcmd"
STEAMAPPS_DIR="/home/gameserver/steamapps"
CONFIG_DIR="/home/gameserver/.config"
CLUSTER_LINK="/home/gameserver/cluster-shared"

# Map-local targets
MAP_SERVER_FILES="${MAP_ROOT}/server-files"
MAP_STEAM="${MAP_ROOT}/Steam"
MAP_STEAMCMD="${MAP_ROOT}/steamcmd"
MAP_STEAMAPPS="${MAP_ROOT}/steamapps"
MAP_CONFIG="${MAP_ROOT}/config"

# Shared cluster directory (shared across ALL maps)
CLUSTER_DIR="${PERSIST_ROOT}/cluster-shared"

mkdir -p "${MAP_SERVER_FILES}" "${MAP_STEAM}" "${MAP_STEAMCMD}" "${MAP_STEAMAPPS}" "${MAP_CONFIG}"
mkdir -p "${CLUSTER_DIR}"

# Replace internal paths with symlinks into /persist
rm -rf "${SERVER_FILES}" "${STEAM_DIR}" "${STEAMCMD_DIR}" "${STEAMAPPS_DIR}" "${CONFIG_DIR}" "${CLUSTER_LINK}"
ln -s "${MAP_SERVER_FILES}" "${SERVER_FILES}"
ln -s "${MAP_STEAM}" "${STEAM_DIR}"
ln -s "${MAP_STEAMCMD}" "${STEAMCMD_DIR}"
ln -s "${MAP_STEAMAPPS}" "${STEAMAPPS_DIR}"
ln -s "${MAP_CONFIG}" "${CONFIG_DIR}"
ln -s "${CLUSTER_DIR}" "${CLUSTER_LINK}"

# --- Apply common INI templates (copy into map-local config) ---
# Target path that ARK reads by default:
#   /home/gameserver/server-files/ShooterGame/Saved/Config/WindowsServer/GameUserSettings.ini
# We keep common templates in a read-only bind mount:
#   /shared/ini/WindowsServer/*.ini
# and copy them into each map before start.

INI_DST_DIR="${SERVER_FILES}/ShooterGame/Saved/Config/WindowsServer"
INI_DST_GUS="${INI_DST_DIR}/GameUserSettings.ini"

mkdir -p "${INI_DST_DIR}"

shopt -s nullglob
common_ini_files=("${COMMON_INI_DIR}"/*.ini)
if (( ${#common_ini_files[@]} > 0 )); then
  for src in "${common_ini_files[@]}"; do
    cp -f "${src}" "${INI_DST_DIR}/$(basename "${src}")"
  done
else
  log "Common INI files not found at ${COMMON_INI_DIR}/*.ini"
  log "Continuing without template copy."
fi
shopt -u nullglob

# --- Minimal per-map overrides to avoid collisions ---
# We override RCONPort in GameUserSettings.ini if present.
# SessionName is set via ASA_START_PARAMS for reliability.
if [[ -f "${INI_DST_GUS}" ]]; then
  if grep -qE '^RCONPort=' "${INI_DST_GUS}"; then
    sed -i -E "s/^RCONPort=.*/RCONPort=${RCON_PORT}/" "${INI_DST_GUS}"
  else
    if grep -qE '^\[ServerSettings\]' "${INI_DST_GUS}"; then
      # Insert right after [ServerSettings]
      sed -i -E "/^\[ServerSettings\]/a RCONPort=${RCON_PORT}" "${INI_DST_GUS}"
    else
      echo "RCONPort=${RCON_PORT}" >> "${INI_DST_GUS}"
    fi
  fi
fi

# Escape double quotes for SessionName
SESSION_ESC="${SESSION_NAME//\"/\\\"}"

# Build ASA_START_PARAMS (base image expects this env)
# Note:
# - ?listen is required for dedicated server.
# - ClusterDirOverride uses the fixed path that we link to /persist/cluster-shared.
export ENABLE_DEBUG
export ASA_START_PARAMS="${MAP_ID}?listen?SessionName=\"${SESSION_ESC}\"?Port=${PORT}?RCONPort=${RCON_PORT}?RCONEnabled=True -WinLiveMaxPlayers=${MAX_PLAYERS} -clusterid=${CLUSTER_ID} -ClusterDirOverride=\"${CLUSTER_LINK}\" ${EXTRA_ASA_START_PARAMS}"

log "MAP_ID=${MAP_ID}"
log "SESSION_NAME=${SESSION_NAME}"
log "PORT=${PORT} (udp)"
log "RCON_PORT=${RCON_PORT} (tcp)"
log "QUERY_PORT=${QUERY_PORT} (udp, optional)"
log "PERSIST_ROOT=${PERSIST_ROOT}"
log "CLUSTER_ID=${CLUSTER_ID}"

exec /usr/bin/start_server
