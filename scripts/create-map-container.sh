#!/usr/bin/env bash
set -euo pipefail

# Creates a STOPPED container for one ARK map.
# Bot will do the same later via podman socket.

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <MAP_ID> <SESSION_NAME> <PORT> [IMAGE_TAG] [PERSIST_HOST_PATH] [PUBLISH_QUERY(true|false)] [VOLUME_OPTS] [CLUSTER_ID] [SHARED_INI_HOST_PATH]" >&2
  exit 1
fi

MAP_ID="$1"
SESSION_NAME="$2"
PORT="$3"
IMAGE_TAG="${4:-yokan-ark-maps:latest}"
PERSIST_HOST_PATH="${5:-/srv/yokan-ark/persist}"
PUBLISH_QUERY="${6:-true}"
VOLUME_OPTS="${7:-rw,U}"
CLUSTER_ID="${8:-yokan-ark}"
SHARED_INI_HOST_PATH="${9:-$(dirname "${PERSIST_HOST_PATH}")/shared/ini/WindowsServer}"

NAME="yokan-ark-${MAP_ID}"
RCON_PORT=$((PORT + 19243))
QUERY_PORT=$((PORT + 1))

# NOTE:
# - Rootless podman does not need :Z on Ubuntu Server.
# - :U is enabled by default so container user can write to host persist path.
VOLUME_SPEC="${PERSIST_HOST_PATH}:/persist:${VOLUME_OPTS}"
SHARED_INI_VOLUME_SPEC="${SHARED_INI_HOST_PATH}:/shared/ini/WindowsServer:ro"

podman rm -f "${NAME}" >/dev/null 2>&1 || true

CREATE_ARGS=(
  --name "${NAME}"
  -e MAP_ID="${MAP_ID}"
  -e SESSION_NAME="${SESSION_NAME}"
  -e PORT="${PORT}"
  -e CLUSTER_ID="${CLUSTER_ID}"
  -e COMMON_INI_DIR="/shared/ini/WindowsServer"
  -v "${VOLUME_SPEC}"
  -v "${SHARED_INI_VOLUME_SPEC}"
  -v /etc/localtime:/etc/localtime:ro
  -p "${PORT}:${PORT}/udp"
  -p "${RCON_PORT}:${RCON_PORT}/tcp"
)

if [[ "${PUBLISH_QUERY}" == "true" ]]; then
  CREATE_ARGS+=( -p "${QUERY_PORT}:${QUERY_PORT}/udp" )
fi

podman create \
  "${CREATE_ARGS[@]}" \
  "${IMAGE_TAG}" >/dev/null

echo "Created container (stopped): ${NAME}"
echo "  Cluster  : ${CLUSTER_ID}"
echo "  Shared INI: ${SHARED_INI_HOST_PATH} -> /shared/ini/WindowsServer (ro)"
echo "  Game UDP : ${PORT}"
if [[ "${PUBLISH_QUERY}" == "true" ]]; then
  echo "  Query UDP: ${QUERY_PORT} (enabled)"
else
  echo "  Query UDP: ${QUERY_PORT} (disabled)"
fi
echo "  RCON TCP : ${RCON_PORT}"
