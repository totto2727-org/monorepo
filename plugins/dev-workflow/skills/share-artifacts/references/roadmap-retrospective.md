# Reference: `roadmap-retrospective.md` の書き方

## 目的

`dev-roadmap` の Step 4 (Roadmap Retrospective) で**ロードマップ全体を振り返り**、配下の各 `dev-workflow` サイクルの `retrospective.md` を集約しつつ、roadmap 固有の論点 (マイルストーン達成度総括 / 依存グラフ妥当性 / roadmap 固有改善案) を統合する。次に類似ロードマップを起こす際に活かせる**戦略レベルの知見**を抽出することがゴール。

`references/retrospective.md` (workflow 用) を**参考リファレンス**としつつ、roadmap 文脈固有の以下セクションを必ず含める:

- マイルストーン達成度の総括 (`roadmap-progress.yaml.milestones[]` の最終状態を一覧化)
- 依存グラフ妥当性の振り返り (Step 2 で確定した DAG が実運用上妥当だったか)
- 配下 `dev-workflow` retrospective の集約 (1 段落 / 各サイクル)
- roadmap 固有の改善案 (`roadmap-progress.yaml` スキーマ拡張提案、ステップ単位反映の scope out 方針再評価、マイルストーン分割粒度等)

## 作成者 / 作成タイミング

- **作成者:** `roadmap-retrospective-writer` Specialist (単一インスタンス)
- **作成ステップ:** `dev-roadmap` Step 4 (Roadmap Retrospective)
- **承認:** Main 判定 (ユーザーには情報共有のみ。`references/retrospective.md` (workflow 用) と同方針)

## ファイル位置 (集約形式 + `roadmap-` prefix 命名規則)

`docs/retrospective/roadmap-<roadmap-id>.md`

`docs/retrospective/` 配下は `dev-workflow` retrospective と `dev-roadmap` retrospective が**フラット集約**で共存する (`docs/adr/` と同パターン)。両者の名前空間衝突は **roadmap 側に `roadmap-` prefix を付与**することで回避する:

| 種別                        | 保存先                                       | 例                                            |
| --------------------------- | -------------------------------------------- | --------------------------------------------- |
| `dev-workflow` 個別サイクル | `docs/retrospective/<identifier>.md`         | `docs/retrospective/auth-foundation.md`       |
| `dev-roadmap` ロードマップ  | `docs/retrospective/roadmap-<roadmap-id>.md` | `docs/retrospective/roadmap-oauth-rollout.md` |

この `roadmap-` prefix 命名規則は本ドキュメントおよび `dev-roadmap/SKILL.md` で重複明記する (集約形式で workflow と roadmap が同居するディレクトリでの命名衝突回避)。

`gls docs/retrospective/roadmap-*.md` で roadmap retrospective を一括抽出可能。将来ファイル数が増えて検索性が劣化した時点で `docs/retrospective/roadmap/<roadmap-id>.md` のサブディレクトリ分離方式へ機械的に移行できる余地を残す (本バージョンでは prefix 案を採用)。

## ライフサイクル

`references/retrospective.md` (workflow 用) と同様、roadmap retrospective も**揮発的な報告ボックス**として運用する。永続記録すべき判断は ADR (General mode `docs/adr/` / Roadmap mode `docs/roadmap/<roadmap-id>/adr/`、モード判定は `share-adr/SKILL.md`) に切り出してから retrospective を削除する。

| 種別                  | 保存先                                              | ライフサイクル                                             |
| --------------------- | --------------------------------------------------- | ---------------------------------------------------------- |
| ADR                   | `docs/adr/` または `docs/roadmap/<roadmap-id>/adr/` | 永続。`confirmed: true` 化後は不変                         |
| Roadmap Retrospective | `docs/retrospective/roadmap-<roadmap-id>.md`        | 揮発。次ロードマップ起票時に改善案項目が消化されたら削除可 |

ただし `dev-roadmap` は `dev-workflow` よりも長期スパンで起票されるため、削除頻度は workflow より低い。直近 1〜2 ロードマップ分は残しておくことを推奨する。

## 各セクションの書き方

### ロードマップ概要

`roadmap.md` の目的に対してロードマップ全体として何を達成したかを 1〜3 段落で。配下サイクル数と総経過期間を冒頭に示すと俯瞰しやすい。

### マイルストーン達成度の総括

`roadmap-progress.yaml.milestones[]` の最終状態を一覧化する。テーブル列例:

- `Milestone ID`
- `Title`
- `Final Status` (`completed` / `blocked` / `cancelled` / etc.)
- `達成判定の根拠` (`milestones/<milestone-id>.md` の「到達点 (定性)」と照らし合わせて記述)
- `関連 dev-workflow <identifier>` (`workflow_identifiers[]` から転記)

`completed` 以外のマイルストーン (例: `blocked` のまま終了、`cancelled`) については、判定の経緯と次ロードマップへの引き継ぎ事項を **本セクションまたは「次サイクルへの引き継ぎ」** に明記する。

### 依存グラフ妥当性の振り返り

Step 2 で確定したマイルストーン依存 DAG が、実運用を経てなお妥当であったかを振り返る。観点:

- **想定どおり機能した依存**: 起点・収束点が適切だった、並列実行が想定どおりに運用できた
- **不要だった依存**: 後から見ると A → B が無くても進んでいた、不必要に直列化していた
- **不足していた依存**: 暗黙に依存していたが DAG に無かったため後続サイクルで手戻りが発生
- **並列度の実効**: 理論並列度 (DAG の幅) vs 実際の並列起動サイクル数 (= ユーザーが手動起動した同時並行数)

ここで指摘された妥当性の課題は、次ロードマップ起票時の `roadmap-planner` への申し送り事項となる。

### 配下 dev-workflow retrospective の集約

配下の各 `dev-workflow` サイクルの `docs/retrospective/<identifier>.md` を **1 段落 / 各サイクル** で要約する。各段落には以下を含める:

- サイクル `<identifier>`
- 紐付くマイルストーン id (`progress.yaml.roadmap.milestone.id` から特定)
- そのサイクル単独で目立った良かった点 / 課題 (1〜2 件まで、詳細は元 retrospective を参照させる)
- 当該サイクルの retrospective へのリンク (相対パス)

**目的は集約による俯瞰**であり、配下 retrospective を逐字転記しないこと (元 retrospective が一次ソース)。集約段落は「ロードマップ全体の流れの中でこのサイクルがどう機能したか」を読者に伝える視点で書く。

### roadmap 固有の改善案

ロードマップ層への改善案のみを書く。配下サイクル内で完結する改善案 (例: `dev-workflow` Step 6 のテスト戦略改善) は当該サイクルの retrospective に既に書かれているため、ここでは戦略レベルに統合・抽象化したもののみを書く。

#### 含めるべき観点

- **`roadmap-progress.yaml` スキーマ拡張提案**: 本バージョンで scope out している `events` 配列 / `last_step` フィールド / status_view 派生ビュー / ms 精度タイムスタンプ等の追加が必要か (`references/roadmap-progress-yaml.md` 「拡張ポイント」と整合)
- **マイルストーン分割粒度の振り返り**: 1:N サイクルの妥当性、想定サイクル数の見積り精度、再分割が必要だったマイルストーン
- **ステップ単位反映の必要性 ((b) scope out 方針の再評価)**: 実運用を経て workflow 側の各ステップ完了時に `roadmap-progress.yaml` を更新する必要が判明したか
- **`dev-roadmap` ↔ `dev-workflow` 連携プロトコル**: 双方向 ID 参照、`progress.yaml.roadmap` ネスト構造、書き手の非対称性 (workflow → roadmap が常態) が運用上の問題なく機能したか

各改善案はアクション粒度まで分解する (`references/retrospective.md` (workflow 用) の品質基準を踏襲: 「〜を改善する」ではなく「〜のときに〜する」)。

### 次サイクルへの引き継ぎ

次に類似のロードマップを起こす場合に活かせる知見、再利用可能なマイルストーンパターン、避けるべき落とし穴を記述する。本セクションが**他ロードマップへの最大の伝達経路**になるため、汎用化された記述にする (本ロードマップ固有の固有名詞をなるべく避ける、または抽象化する)。

### ユーザー承認ゲートの振り返り

`dev-roadmap` のユーザー承認ゲートは 3 つ (Step 1: Roadmap Intent / Step 2: Milestone Decomposition / Step 4: Roadmap Retrospective)。各ゲートで承認 / 却下 / 修正要求の履歴を記録し、却下があった場合は原因を振り返る。

### コスト / 時間

- ロードマップ全体の経過日数 (Step 1 開始 〜 Step 4 完了)
- 配下 `dev-workflow` サイクル数 (`workflow_identifiers[]` の総数)
- 並列度の実効 (同時に進行していた配下サイクル数のピーク値)
- roadmap 系 Specialist の起動回数 (`roadmap-analyst` / `roadmap-planner` / `roadmap-retrospective-writer`)

## 品質基準

`references/retrospective.md` (workflow 用) の品質基準を継承しつつ、roadmap 固有の追加基準:

| ✅ よい                                                                                          | ❌ 悪い                                                    |
| ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------- |
| 配下 `dev-workflow` retrospective が**全件**集約段落として要約されている                         | 一部サイクルの retrospective が言及されていない            |
| マイルストーン達成度の総括テーブルが `roadmap-progress.yaml.milestones[]` と一致                 | テーブルが古い状態のまま、または yaml と表記揺れ           |
| 依存グラフ妥当性が「想定どおり」「不要」「不足」「並列度実効」の 4 観点で書かれている            | 「依存グラフは概ね機能した」など抽象的な感想で終わっている |
| 改善案がロードマップ層に純化されている (戦略レベル)                                              | 配下サイクル内の戦術的改善案を重複転記している             |
| `cancelled` / `blocked` で終わったマイルストーンの判定経緯が明記されている                       | 未達マイルストーンが言及されていない、または判定根拠が不明 |
| ファイル位置が `docs/retrospective/roadmap-<roadmap-id>.md` に従っている                         | prefix `roadmap-` が抜けている、ディレクトリが間違っている |
| 観測データ (`roadmap-progress.yaml` のタイムスタンプ・workflow_identifiers) から因果分析している | 印象論・感想で終わっている                                 |

## データソース (入力として必要)

- `docs/roadmap/<roadmap-id>/roadmap.md` (目的・スコープ・依存グラフ)
- `docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md` 全件 (各マイルストーン定義 / 到達点)
- `docs/roadmap/<roadmap-id>/roadmap-progress.yaml` (最終状態、タイムスタンプ、workflow_identifiers 一覧)
- 配下の各 `dev-workflow` サイクルの `docs/retrospective/<identifier>.md` 全件 (集約対象)
- 配下の各 `dev-workflow` サイクルの `docs/workflow/<identifier>/progress.yaml` (詳細進捗を辿る場合)

## 関連成果物

- **入力:** ロードマップ全成果物 (`roadmap.md` / `milestones/*.md` / `roadmap-progress.yaml`) + 配下 `dev-workflow` サイクルの全 retrospective
- **出力先:** `docs/retrospective/roadmap-<roadmap-id>.md` (リポジトリに永続保存。次ロードマップ起票時に改善案を消化したら削除可)
- **反映先:** 改善案は次ロードマップの `roadmap.md` / `dev-roadmap` プラグインの更新 / `roadmap-progress.yaml` スキーマ拡張に直接つながる
- **関連:** `references/retrospective.md` (workflow 用、本ドキュメントの参考リファレンス)、`references/roadmap.md`、`references/milestone.md`、`references/roadmap-progress-yaml.md`
