# アーキテクチャ

このリポジトリは、ARK: Survival Ascended (ASA) Dedicated Server を rootless Podman で運用するための構成を提供します。
このリポジトリは compose を使いません。
このリポジトリは 1 マップを 1 コンテナとして運用します。

## 目的

- 1つのサーバーイメージで複数マップを起動できるようにします。
- マップごとの違いを `MAP_ID / SESSION_NAME / PORT` に限定します。
- 永続化マウントを全マップで 1 本に統一します。
- 全マップ共通の INI 設定を 1 箇所で管理します。
- Discord Bot が Podman socket 経由でコンテナを起動停止できる前提で構成します。
  - Bot の実装は `bot/` 配下に含みます。
  - Bot は Go で実装し、Podman socket を直接利用します。

## コンポーネント

### 1) maps: ASA サーバーイメージ

- 位置: `maps/`
- Dockerfile: `maps/Dockerfile`
- entrypoint: `maps/entrypoint.sh`

maps イメージは `mschnitzer/asa-linux-server` をベースにします。
maps entrypoint は起動時に次を行います。

- `/persist` の中でマップごとの永続領域を作成します。
- 固定パス（例: `/home/gameserver/server-files`）を symlink で `/persist/maps/<MAP_ID>/...` に向けます。
- 共通 INI を `/persist/common/ini/WindowsServer/` からコピーします。
- `RCONPort` を `PORT + 19243` で上書きします。
- `ASA_START_PARAMS` を組み立てて `/usr/bin/start_server` を実行します。

### 2) shared: 共通テンプレート

- 位置: `shared/`
- 共通 INI: `shared/ini/WindowsServer/`

`shared/` の内容は、`scripts/setup-persist.sh` がホスト側の永続領域にコピーします。

### 3) 永続データ（ホスト）

ホスト側の 1 ディレクトリを `/persist` にマウントします。
推奨パスは `/srv/yokan-ark/persist` です。

- 共通テンプレート配置: `/persist/common/ini/WindowsServer/`
- クラスタ共有: `/persist/cluster-shared/`
- マップごとの永続領域: `/persist/maps/<MAP_ID>/`

### 4) bot: Discord Bot コンテナ

- 位置: `bot/`
- Dockerfile: `bot/Dockerfile`
- entrypoint: `bot/entrypoint.sh`
- 設定例: `bot/config.example.yml`

Bot は次を担当します。

- Discord スラッシュコマンド受付（`/ark start|stop|status|save|backup|scan|players|maps|broadcast`）
- Podman socket 経由で map コンテナの create/start/stop/inspect/stats
- RCON 経由で `saveworld` / `ListPlayers` / `ServerChat`
- 無人停止、定期バックアップ、自動アナウンス、pre_shutdown

Bot は Podman socket をマウントしてコンテナを制御する前提です。
Bot の要求仕様は `docs/spec/01_bot_spec.md` にまとめます。

## ポート方針

- ゲームポートは 10 刻みで割り当てます。例: 7777, 7787, 7797
- RCON ポートは `PORT + 19243` で導出します。
- クエリポートは `PORT + 1` で導出します（必要な場合だけ公開します）。

## rootless Podman 方針

- `:Z` は使いません。
- ホスト側の永続ディレクトリは、実行ユーザーが書き込みできるように所有権を調整します。
