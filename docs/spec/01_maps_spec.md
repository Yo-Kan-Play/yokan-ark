# マップ用コンテナサービス 要件仕様書

この仕様書は ARK ASA マップコンテナ（サーバーコンテナ）の要求仕様を定義します。
この仕様書は Bot の実装を含みません。

## 1. 目的

1つのコンテナイメージで複数マップを起動できるようにします。
マップごとの違いは `MAP_ID / SESSION_NAME / PORT` に限定します。
全マップの永続化マウントを 1 本に統一します。
全マップ共通の INI を 1 箇所で管理します。

## 2. 入力（環境変数）

マップコンテナは次の環境変数を必須とします。

- `MAP_ID`（例: `TheCenter_WP`）
- `SESSION_NAME`（例: `Yokan Ark The Center`）
- `PORT`（例: `7777`）

マップコンテナは次の環境変数を任意とします。

- `PERSIST_ROOT`（既定: `/persist`）
- `CLUSTER_ID`（既定: `yokan-ark`）
- `MAX_PLAYERS`（既定: `10`）
- `ENABLE_DEBUG`（既定: `0`）
- `EXTRA_ASA_START_PARAMS`（既定: 空）

## 3. 出力（ポート）

マップコンテナは次のポートを使用します。

- ゲームポート（UDP）: `PORT`
- クエリポート（UDP）: `PORT + 1`（必要な場合だけ公開）
- RCON ポート（TCP）: `PORT + 19243`

マップ割り当ては 10 刻みを推奨します。
例は次です。

- 7777
- 7787
- 7797

## 4. 永続化（/persist）

マップコンテナはホストの 1 ディレクトリを `/persist` にマウントします。
マップコンテナは `/persist` 配下で次を使用します。

- 共通 INI: `/persist/common/ini/WindowsServer/`
- クラスタ共有: `/persist/cluster-shared/`
- マップ固有: `/persist/maps/<MAP_ID>/`

マップ固有の保存先は次のように分離します。

- `/persist/maps/<MAP_ID>/server-files`
- `/persist/maps/<MAP_ID>/Steam`
- `/persist/maps/<MAP_ID>/steamcmd`
- `/persist/maps/<MAP_ID>/config`

## 5. 共通 INI の適用ルール

マップコンテナは起動時に次を行います。

1. `/persist/common/ini/WindowsServer/GameUserSettings.ini` を
   `/home/gameserver/server-files/ShooterGame/Saved/Config/WindowsServer/GameUserSettings.ini` にコピーします。
2. `RCONPort` を `PORT + 19243` に上書きします。
3. `SessionName` は `SESSION_NAME` を優先し、必要な場合に上書きします。

## 6. サーバー起動

マップコンテナは `ASA_START_PARAMS` を組み立てて `/usr/bin/start_server` を実行します。
マップコンテナは `?listen` を付与します。

## 7. rootless Podman 前提

- マップコンテナは rootless Podman で動作します。
- マップコンテナは `:Z` を前提にしません。
- ホスト側永続ディレクトリは実行ユーザーが書き込みできるように所有権を調整します。
