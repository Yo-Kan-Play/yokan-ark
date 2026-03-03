# yokan-ark

Ubuntu Server 上の rootless Podman で、ARK: Survival Ascended (ASA) Dedicated Server を運用するためのリポジトリです。

このリポジトリは compose を使いません。
このリポジトリは「1マップ = 1コンテナ」で運用します。
このリポジトリは「1つのサーバーイメージ」で複数マップを起動します。

## ディレクトリ構成

- `yokan-ark/maps/`  
  ASA サーバー用イメージと entrypoint を置きます。
- `yokan-ark/bot/`  
  Discord Bot 用コンテナの雛形を置きます。Bot のソースコードは含みません。
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

## クイックスタート（手動）

1) イメージをビルドします。

```bash
cd yokan-ark
./scripts/build-image.sh maps yokan-ark-maps:latest
./scripts/build-image.sh bot  yokan-ark-bot:latest
```

2) 永続ディレクトリを作成します。

```bash
sudo mkdir -p /srv/yokan-ark/persist
sudo chown -R "$USER:$USER" /srv/yokan-ark/persist

./scripts/setup-persist.sh /srv/yokan-ark/persist
```

3) マップコンテナを「停止状態」で作成します。

```bash
./scripts/create-map-container.sh TheCenter_WP "Yokan Ark The Center" 7777 yokan-ark-maps:latest /srv/yokan-ark/persist
./scripts/create-map-container.sh ScorchedEarth_WP "Yokan Ark Scorched Earth" 7787 yokan-ark-maps:latest /srv/yokan-ark/persist
```

4) 起動と停止を実行します。

```bash
./scripts/start-map.sh TheCenter_WP
./scripts/stop-map.sh  TheCenter_WP
```

## 共通 INI の管理

- 共通テンプレートは `shared/ini/WindowsServer/` に置きます。
- `scripts/setup-persist.sh` がホスト側の `/srv/yokan-ark/persist/common/ini/WindowsServer/` にコピーします。
- `maps/entrypoint.sh` が起動時に共通 INI を各マップへコピーします。
- `maps/entrypoint.sh` が起動時に `RCONPort` をマップごとに上書きします。

## Discord Bot の雛形

- Bot の Dockerfile は `bot/Dockerfile` にあります。
- Bot の entrypoint は `bot/entrypoint.sh` にあります。
- Bot の設定例は `bot/config.example.yml` にあります。
- Bot の設定ファイルは `bot/config.yaml` を想定します（git 管理しません）。

## ドキュメント

- `docs/ARCHITECTURE.md`
- `docs/spec/01_bot_spec.md`
- `docs/spec/01_maps_spec.md`
