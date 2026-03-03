#!/usr/bin/env bash
set -euo pipefail

# Enable rootless podman socket for the current user.
# This is required for a Discord Bot container to control podman via the API.

systemctl --user enable --now podman.socket

echo "Enabled: podman.socket (user)"
echo "Socket path (typical): /run/user/$(id -u)/podman/podman.sock"
