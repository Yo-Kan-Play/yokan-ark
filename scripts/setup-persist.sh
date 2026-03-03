#!/usr/bin/env bash
set -euo pipefail

PERSIST_HOST_PATH="${1:-/srv/yokan-ark/persist}"

mkdir -p "${PERSIST_HOST_PATH}/common/ini/WindowsServer"
mkdir -p "${PERSIST_HOST_PATH}/cluster-shared"
mkdir -p "${PERSIST_HOST_PATH}/maps"

# Copy common INI templates from repo into persist.
cp -f "./shared/ini/WindowsServer/GameUserSettings.ini" "${PERSIST_HOST_PATH}/common/ini/WindowsServer/GameUserSettings.ini"

if [[ -f "./shared/ini/WindowsServer/Game.ini" ]]; then
  cp -f "./shared/ini/WindowsServer/Game.ini" "${PERSIST_HOST_PATH}/common/ini/WindowsServer/Game.ini"
fi

echo "Prepared persist directory: ${PERSIST_HOST_PATH}"
