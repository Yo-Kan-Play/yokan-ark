#!/usr/bin/env bash
set -euo pipefail

# Creates a STOPPED container for one ARK map.
# Bot will do the same later via podman socket.

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <MAP_ID> <SESSION_NAME> <PORT> [IMAGE_TAG] [PERSIST_HOST_PATH]" >&2
  exit 1
fi

MAP_ID="$1"
SESSION_NAME="$2"
PORT="$3"
IMAGE_TAG="${4:-yokan-ark-maps:latest}"
PERSIST_HOST_PATH="${5:-/srv/yokan-ark/persist}"

NAME="yokan-ark-${MAP_ID}"
RCON_PORT=$((PORT + 19243))
QUERY_PORT=$((PORT + 1))

# NOTE:
# - Rootless podman does not need :Z on Ubuntu Server.
# - If you hit permission errors on the host directory, try adding :U to the volume.
VOLUME_SPEC="${PERSIST_HOST_PATH}:/persist:rw"

podman rm -f "${NAME}" >/dev/null 2>&1 || true

podman create \
  --name "${NAME}" \
  -e MAP_ID="${MAP_ID}" \
  -e SESSION_NAME="${SESSION_NAME}" \
  -e PORT="${PORT}" \
  -v "${VOLUME_SPEC}" \
  -v /etc/localtime:/etc/localtime:ro \
  -p "${PORT}:${PORT}/udp" \
  -p "${QUERY_PORT}:${QUERY_PORT}/udp" \
  -p "${RCON_PORT}:${RCON_PORT}/tcp" \
  "${IMAGE_TAG}" >/dev/null

echo "Created container (stopped): ${NAME}"
echo "  Game UDP : ${PORT}"
echo "  Query UDP: ${QUERY_PORT} (optional)"
echo "  RCON TCP : ${RCON_PORT}"
