# yokan-ark

[日本語](README.md)

This repository contains files to run ARK: Survival Ascended (ASA) Dedicated Server on Ubuntu Server using rootless Podman. It allows managing multiple maps via a Discord bot.

This repository does not use compose.
It operates on the principle of "one map = one container".
It uses a single server image to launch multiple map instances.

## Directory structure

- `yokan-ark/maps/`
  Contains the ASA server image and the entrypoint.
- `yokan-ark/bot/`
  Contains the Discord bot (Go) implementation and container definition.
- `yokan-ark/shared/`
  Contains configuration templates shared across maps.
- `yokan-ark/scripts/`
  Contains scripts for manual testing and initial setup.
- `yokan-ark/docs/`
  Contains design documents.

## Important decisions

- Game ports are assigned in increments of 10, e.g. 7777, 7787, 7797
- RCON port is derived as `PORT + 19243`, e.g. 7777 -> 27020
- Query port is derived as `PORT + 1` and is only exposed when needed
- For rootless Podman operation, do not use `:Z`
- For rootless Podman operation, add `:U` to persist mounts

## Quickstart (manual)

1) Build images:

```bash
cd yokan-ark
./scripts/build-image.sh maps yokan-ark-maps:latest
./scripts/build-image.sh bot  yokan-ark-bot:latest
```

2) Create the persist directory:

```bash
sudo mkdir -p persist
sudo chown -R "$USER:$USER" ./persist

./scripts/setup-persist.sh ./persist
```

3) Create map containers in stopped state:

```bash
./scripts/create-map-container.sh TheCenter_WP "Yokan Ark The Center" 7777 yokan-ark-maps:latest ./persist true rw,U yokan-ark
./scripts/create-map-container.sh ScorchedEarth_WP "Yokan Ark Scorched Earth" 7787 yokan-ark-maps:latest ./persist false rw,U yokan-ark
```

4) Start and stop:

```bash
./scripts/start-map.sh TheCenter_WP
./scripts/stop-map.sh  TheCenter_WP

# If an existing container fails to start due to permission errors, recreate it
./scripts/create-map-container.sh TheCenter_WP "Yokan Ark The Center" 7777 yokan-ark-maps:latest ./persist true rw,U yokan-ark
```

## Managing shared INI files

- Shared templates are placed in `shared/ini/WindowsServer/`.
- When creating a map container, `shared/ini/WindowsServer` is mounted read-only at `/shared/ini/WindowsServer`.
- `maps/entrypoint.sh` copies `/shared/ini/WindowsServer/*.ini` to each map at startup (it automatically handles added INI files).
- `maps/entrypoint.sh` overwrites only the `RCONPort` in `GameUserSettings.ini` per map at startup.

## Discord Bot

- Bot Dockerfile: `bot/Dockerfile`
- Bot entrypoint: `bot/entrypoint.sh`
- Example bot config: `shared/config.example.yaml`
- Bot expects config at `shared/config.yaml` (not tracked in git)

## Running the Discord Bot (Podman)

1) Enable the rootless Podman socket:

```bash
./scripts/enable-rootless-podman-socket.sh
```

2) Create a bot config:

```bash
cp shared/config.example.yaml shared/config.yaml
```

3) Adjust `shared/config.yaml` for your environment, e.g. `podman.socket_path` like `/run/user/1000/podman/podman.sock`
   Also check:
   - `podman.persist_container_path`: path to `persist` as seen inside the bot container
   - `podman.shared_ini_host_path`: host path mounted read-only into map containers
   - `server_defaults.rcon_host`: for containerized operation, `host.containers.internal` is recommended
   - For faster dev reflection, set `discord.command_guild_id` to a test Guild ID

4) Run the bot container:

```bash
podman run --rm --name yokan-ark-bot \
  -e DISCORD_TOKEN=xxxxxxxx \
  -e ARK_RCON_PASSWORD=xxxxxxxx \
  -e R2_ENDPOINT=https://<accountid>.r2.cloudflarestorage.com \
  -e R2_ACCESS_KEY_ID=xxxxxxxx \
  -e R2_SECRET_ACCESS_KEY=xxxxxxxx \
  -v "$PWD/shared/config.yaml:/config/config.yaml:ro" \
  -v "/run/user/$(id -u)/podman/podman.sock:/run/user/$(id -u)/podman/podman.sock" \
  -v "./persist:./persist:ro" \
  -v "./backups/local:./backups/local:rw" \
  yokan-ark-bot:latest
```

## Documentation

- `docs/ARCHITECTURE.md`
- `docs/spec/01_bot_spec.md`
- `docs/spec/01_maps_spec.md`
