# yokan-ark

[English](README.en.md)

Ubuntu Server 上の rootless Podman で、ARK: Survival Ascended (ASA) Dedicated Server を運用するためのリポジトリです。
DiscordBot を通して複数マップを管理することができます。

このリポジトリは compose を使いません。
このリポジトリは「1マップ = 1コンテナ」で運用します。
このリポジトリは「1つのサーバーイメージ」で複数マップを起動します。

## ディレクトリ構成

- `yokan-ark/maps/`  
  ASA サーバー用イメージと entrypoint を置きます。
- `yokan-ark/bot/`  
  Discord Bot (Go) の実装とコンテナ定義を置きます。
- `yokan-ark/shared/`  
  全マップ共通の設定テンプレートを置きます。
- `yokan-ark/scripts/`  
  手動検証・初期セットアップ用のスクリプトを置きます。
- `yokan-ark/docs/`  
  設計資料を置きます。

## 重要な決め事

- ゲームポートは 10 刻みで割り当てます。例: 7777, 7787, 7797
- RCON ポートは `PORT + 19243` で導出します。例: 7777 -> 27020
- クエリポートは `PORT + 1` で導出します。必要な場合だけ公開します。
- rootless Podman 運用では `:Z` を使いません。
- rootless Podman 運用では persist マウントに `:U` を付けます。

## クイックスタート（手動）

1) イメージをビルドします。

```bash
cd yokan-ark
./scripts/build-image.sh maps yokan-ark-maps:latest
./scripts/build-image.sh bot  yokan-ark-bot:latest
```

2) 永続ディレクトリを作成します。

```bash
sudo mkdir -p persist
sudo chown -R "$USER:$USER" ./persist

./scripts/setup-persist.sh ./persist
```

3) マップコンテナを「停止状態」で作成します。

```bash
./scripts/create-map-container.sh TheCenter_WP "Yokan Ark The Center" 7777 yokan-ark-maps:latest ./persist true rw,U yokan-ark
./scripts/create-map-container.sh ScorchedEarth_WP "Yokan Ark Scorched Earth" 7787 yokan-ark-maps:latest ./persist false rw,U yokan-ark
```

4) 起動と停止を実行します。

```bash
./scripts/start-map.sh TheCenter_WP
./scripts/stop-map.sh  TheCenter_WP

# 既存コンテナが権限エラーで起動しない場合は再作成
./scripts/create-map-container.sh TheCenter_WP "Yokan Ark The Center" 7777 yokan-ark-maps:latest ./persist true rw,U yokan-ark
```

## 共通 INI の管理

- 共通テンプレートは `shared/ini/WindowsServer/` に置きます。
- マップコンテナ作成時に `shared/ini/WindowsServer` を read-only で `/shared/ini/WindowsServer` にマウントします。
- `maps/entrypoint.sh` は起動時に `/shared/ini/WindowsServer/*.ini` を各マップへコピーします（INI追加にも自動対応）。
- `maps/entrypoint.sh` は起動時に `GameUserSettings.ini` の `RCONPort` だけをマップごとに上書きします。

## Discord Bot の雛形

- Bot の Dockerfile は `bot/Dockerfile` にあります。
- Bot の entrypoint は `bot/entrypoint.sh` にあります。
- Bot の設定例は `shared/config.example.yaml` にあります。
- Bot の設定ファイルは `shared/config.yaml` を想定します（git 管理しません）。

## Discord Bot の実行（Podman）

1) rootless Podman socket を有効化します。

```bash
./scripts/enable-rootless-podman-socket.sh
```

2) Bot 設定を作成します。

```bash
cp shared/config.example.yaml shared/config.yaml
```

3) `shared/config.yaml` の `podman.socket_path` を実行環境に合わせます。
   例: `/run/user/1000/podman/podman.sock`

  併せて次も確認してください。
  - `podman.persist_container_path`: Botコンテナ内から見える persist のパス
  - `podman.shared_ini_host_path`: mapコンテナに read-only マウントする共通INIのホストパス
  - `server_defaults.rcon_host`: コンテナ運用では `host.containers.internal` を推奨
  - 開発時に反映を速くしたい場合は `discord.command_guild_id` にテスト用 Guild ID を設定

4) Bot コンテナを起動します。

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

## ドキュメント

- `docs/ARCHITECTURE.md`
- `docs/spec/01_bot_spec.md`
- `docs/spec/01_maps_spec.md`
