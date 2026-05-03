# Reference: `roadmap-progress.yaml` の書き方

## 目的

`dev-roadmap` のロードマップ全体および配下マイルストーン群の**進捗を機械可読な形で永続化**する。`progress.yaml` がサイクル単位の真のソースであるのと同様、`roadmap-progress.yaml` はロードマップ単位の真のソースとして機能する。

**最小限の責務**: 本バージョンのスキーマは「マイルストーン ↔ `dev-workflow` サイクル `<identifier>` の紐付け」と粗粒度ステータス (`planned` / `active` / `completed` / `blocked` / `cancelled`) のみを保持する。**細かい進捗 (現在ステップ名、ゲート状況、詳細イベント履歴) は持たない**。必要時は `milestones[].workflow_identifiers[]` 経由で `docs/workflow/<identifier>/progress.yaml` を辿って取得する。

## ファイル位置 (1:1 対応の例外)

`docs/roadmap/<roadmap-id>/roadmap-progress.yaml`

`templates/roadmap-progress.yaml` (拡張子 `.yaml`) と本 reference (`references/roadmap-progress-yaml.md`、拡張子 `.md`) は **1:1 対応の例外 3 件目**。既存例外 (`templates/progress.yaml` ↔ `references/progress-yaml.md`) と同じ命名パターンに従う。詳細は `shared-artifacts/SKILL.md` の 1:1 例外リストを参照。

## 作成者 / 更新者

- **作成者:** `roadmap-analyst` Specialist (Step 1 で初期化、`milestones: []` は空)
- **更新者 (Step 2):** `roadmap-planner` Specialist (`milestones[]` を確定、ロードマップ全体 `status: active` に遷移)
- **更新者 (Step 3):** 配下の **各 `dev-workflow` サイクル Main** (自律更新、本ドキュメント「`dev-workflow` 側からの更新プロトコル」セクションが規範)
- **更新者 (Step 4):** `roadmap-retrospective-writer` Specialist (ロードマップ全体 `status: completed` に遷移)

## スキーマ全体構造

```yaml
roadmap_id: <roadmap-id>
title: <短い説明>
status: planned | active | completed # ロードマップ全体
created_at: <ISO8601 秒精度>
updated_at: <ISO8601 秒精度>

milestones:
  - id: <milestone-id>
    title: <短い説明>
    status: planned | active | completed | blocked | cancelled
    depends_on: [] # マイルストーン依存 (id 配列、DAG)
    workflow_identifiers: [] # 紐付き dev-workflow サイクル (1:N 許容)
    notes: null # 任意の補足 (default null)
```

## 各フィールドの書き方

### `roadmap_id` / `title` / `status` (ロードマップ全体)

| フィールド   | 書き方                                                                                                 |
| ------------ | ------------------------------------------------------------------------------------------------------ |
| `roadmap_id` | `docs/roadmap/<roadmap-id>/` ディレクトリ名と一致させる。kebab-case 推奨 (例: `2026-q2-oauth-rollout`) |
| `title`      | `roadmap.md` のタイトル (1 行) と一致させる                                                            |
| `status`     | 3 値: `planned` (Step 1〜2 進行中) / `active` (Step 3 進行中) / `completed` (Step 4 完了)              |

ロードマップ全体 `status` の遷移タイミング:

- `planned`: Step 1 (`roadmap-analyst` が初期化)
- `planned → active`: Step 2 完了時 (`roadmap-planner` が `milestones[]` 確定と同時に遷移)
- `active → completed`: Step 4 完了時 (`roadmap-retrospective-writer` が `docs/retrospective/roadmap-<roadmap-id>.md` 生成と同時に遷移)

### `created_at` / `updated_at`

- ISO8601 **秒精度** (例: `2026-04-29T00:00:00Z`)。ms 精度は不要 (events 配列を持たないため同一秒の競合に依存しない)
- `created_at`: 初期化時固定、以降変更しない
- `updated_at`: 任意のフィールドを書き換えるたびに最新の ISO8601 に書き換える

### `milestones[]`

| サブフィールド         | 書き方                                                                                                                                              |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                   | kebab-case 推奨 (例: `ms-01-foundation`)。`milestones/<id>.md` ファイル名 basename と一致させる。**Step 2 確定後は immutable**                      |
| `title`                | 短い説明 (1 行)。`milestones/<id>.md` のタイトルと一致させる                                                                                        |
| `status`               | 5 値: `planned` / `active` / `completed` / `blocked` / `cancelled`。サイクル開始時 `planned → active`、完了時 `active → completed` のスカラ書き換え |
| `depends_on`           | 先行完了が必要なマイルストーン id の配列。DAG 維持。Step 2 確定後は immutable                                                                       |
| `workflow_identifiers` | 紐付き `dev-workflow` サイクル `<identifier>` の配列 (1:N 許容)。**append-only 運用** (削除しない、不要になった場合は `notes` 等で説明)             |
| `notes`                | 任意の補足 (default `null`)。スキーマを将来拡張する自由領域。PII / トークン / 内部 URL を入れない (`specialist-common` §9 と整合)                   |

#### `id` 命名規則の推奨例

- 順序を示したい場合: `ms-NN-<short-name>` (例: `ms-01-foundation`、`ms-02-token-refresh`)
- 機能領域でグルーピング: `<area>-<short-name>` (例: `auth-foundation`、`auth-token-refresh`)
- ロードマップごとに統一すること (混在を避ける)

#### `status` 遷移ルール

| 遷移                 | タイミング                                                                                                                    |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `planned → active`   | 配下 `dev-workflow` サイクル開始時 (Main が `progress.yaml` 初期化と同タイミングで遷移、本ドキュメント「更新プロトコル」参照) |
| `active → completed` | 配下 `dev-workflow` サイクル完了時 (= `dev-workflow` Step 9 Retrospective 完了時)。1:N の場合は最終状態判定をユーザーに委ねる |
| `* → blocked`        | 配下サイクルが解消困難な Blocker に遭遇した際、Main 判断で遷移                                                                |
| `* → cancelled`      | ロードマップ Step 2 / Step 3 中にユーザー判断でマイルストーンを取消した場合                                                   |

#### `workflow_identifiers[]` の追記/削除規則

- **追記のみ運用**: 配下 `dev-workflow` サイクル開始時に `<identifier>` を append。git 3-way merge で自動マージ親和性が高い
- **削除しない**: 紐付けは履歴として残す。当該サイクルが取消された場合は当該サイクル側の `progress.yaml.status: cancelled` で表現し、`workflow_identifiers[]` からは削除しない
- **重複追記の禁止**: 同一 `<identifier>` が複数回現れない (set semantics)。並行ブランチで同時 append が発生した場合のマージ規則は本ドキュメント「並行サイクル時の競合回避」参照

## `dev-workflow` 側からの更新プロトコル

本セクションは `roadmap-progress.yaml` 運用の中核ルール。`progress.yaml.roadmap` が non-null のサイクル (= 上位 roadmap のマイルストーンに紐付いた `dev-workflow` サイクル) は、自身の進行に応じて本ファイルを**自律的に更新**する責務を持つ。詳細プロトコルは `dev-workflow/SKILL.md` の「`roadmap-progress.yaml` 更新プロトコル」セクション (独立トップレベル) に書かれており、本セクションはそれを `references/roadmap-progress-yaml.md` 側で 3 観点 (何を / いつ / どう書くか) に整理して再掲する。

### 何を — 更新対象フィールド

| 更新対象                              | 性質                                                                                                      |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `milestones[].status`                 | スカラ書き換え。`planned → active` (サイクル開始時) / `active → completed` (サイクル完了時) の 2 遷移のみ |
| `milestones[].workflow_identifiers[]` | append-only。サイクル開始時に自身の `<identifier>` を 1 回だけ追記                                        |
| `updated_at`                          | 任意の更新と同時に最新 ISO8601 (秒精度) に書き換え                                                        |

更新**しない**フィールド (immutable または 他 Specialist の責務):

- `roadmap_id` / `title` / `created_at` (初期化時固定)
- ロードマップ全体 `status` (`roadmap-planner` / `roadmap-retrospective-writer` の責務)
- `milestones[].id` / `title` / `depends_on` (Step 2 確定後 immutable)
- `milestones[].notes` (`roadmap-planner` の起票時または Main の補完更新の責務)

### いつ — 更新タイミング

ユーザー単純化方針 (「紐付けだけできれば良い」) に基づき、本バージョンでは以下 **2 タイミングのみ**で更新する:

| タイミング             | 詳細                                                                                                                                                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **(a) サイクル開始時** | `progress.yaml` 初期化と同タイミング (`dev-workflow/SKILL.md` 「ワークフロー開始時」ステップ 4')。該当 `milestones[].status` を `planned → active` に遷移、`milestones[].workflow_identifiers[]` に自身の `<identifier>` を append、`updated_at` を更新 |
| **(c) サイクル完了時** | **`dev-workflow` Step 9 Retrospective 完了時** (9 ステップ体系)。該当 `milestones[].status` を `active → completed` に遷移、`updated_at` を更新                                                                                                         |

#### 本バージョンで scope out するタイミング: (b) 各ステップ完了時の進捗サマリ反映

`dev-workflow` の各ステップ完了時に `roadmap-progress.yaml` を更新することは**本バージョンでは行わない (scope out)**。理由:

- 細かい進捗は `docs/workflow/<identifier>/progress.yaml` を見れば辿れる (二重管理を避ける)
- 更新タイミングを 2 点に絞ることで並行更新の競合可能性が劇的に低下する
- 不足が判明した場合、将来別サイクルで `events` 配列追加 / `last_step` フィールド追加 等の段階的拡張が可能

### どう書くか — 値の遷移ルール / コミット粒度 / 並行サイクル時の競合回避

#### 値の遷移ルール

- `status` はスカラ書き換え (`planned → active` / `active → completed`)。`completed` への遷移は不可逆 (戻したい場合は Main 判断 + ユーザー確認 + `notes` への記録)
- `workflow_identifiers[]` は append のみ (削除しない)。set semantics を保つため重複追記は不可
- `updated_at` は ISO8601 秒精度。タイムゾーンは UTC (`Z` サフィックス) 推奨

#### コミット粒度 (`dev-workflow/SKILL.md` のコミット規約と整合)

- **(a) サイクル開始時** の `roadmap-progress.yaml` 更新: `progress.yaml` 初期化コミットに**同梱** (別コミットを切らない)
- **(c) サイクル完了時** の `roadmap-progress.yaml` 更新: `dev-workflow` Step 9 Retrospective 完了コミットに**同梱**
- コミットメッセージ例:
  - 開始時: `docs(dev-workflow/<identifier>): initialize cycle (linked to roadmap <roadmap-id> milestone <milestone-id>)`
  - 完了時: `docs(dev-workflow/<identifier>): close cycle with retrospective (roadmap milestone <milestone-id> completed)`
- **`git add` は明示的にパス指定** (`-A` / `.` 禁止、`specialist-common` Git ガードレールと整合)

#### 並行サイクル時の競合回避

並行する複数の `dev-workflow` サイクルが同一 `roadmap-progress.yaml` を更新しうる構造のため、衝突対策が必要。本バージョンは **git 3-way merge 任せ** (最小スキーマ採用 + 単純マージ方針: `status` のスカラ書き換えと `workflow_identifiers[]` の append-only に限定し、衝突耐性をスキーマレベルで確保する):

| 競合シナリオ                                                                                 | 発生確率                                                   | 対策                                                                                                          |
| -------------------------------------------------------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| 別ブランチで同一マイルストーンの `status` を別の値 (例: `completed` vs `blocked`) に書き換え | 低 (2 サイクル完了が同時刻 + 別ブランチで起こるケースのみ) | `pre-commit` hook の YAML syntax 検査で衝突マーカ残存を阻止。Specialist は独断で解消せず Main に Blocker 報告 |
| `workflow_identifiers[]` への追記が両ブランチで同位置に発生                                  | 極低 (append であり通常は異なる行)                         | git 3-way merge で自動マージ。「両方追加」競合になった場合のみ手動で**両者を残す形 (set union)** でマージ     |
| `notes` の同時書き換え                                                                       | 極低 (本バージョンでは更新責務がほぼない)                  | 通常の 3-way merge                                                                                            |

#### マージ衝突発生時のリカバリ手順

1. 衝突マーカ (`<<<<<<<` / `>>>>>>>`) が `pre-commit` hook で検出された場合、コミットが阻止される
2. Specialist は独断で解消せず Main に Blocker として報告 (`specialist-common` §4 ケース B)
3. Main は以下を実行:
   1. 該当マイルストーンの `status` 論理整合性を確認 (例: 両ブランチが `completed` を主張するなら `completed` 採用、片方が `blocked` なら状況に応じてユーザー判断)
   2. `workflow_identifiers[]` は両ブランチの追加分を**両方残す (set union)**
   3. `updated_at` を再生成 (現時刻の ISO8601)
   4. 通常コミット (`docs(dev-roadmap/<roadmap-id>): resolve concurrent updates`)

### 適用条件 — `roadmap == null` のスキップ規則

- `progress.yaml.roadmap == null` のサイクル (= 独立サイクル) は本プロトコルを完全にスキップする
- `progress.yaml.roadmap` が non-null かつ `progress.yaml.roadmap.milestone.id` が存在する場合のみ本プロトコルが発動する
- `roadmap` ブロックは存在するが `milestone.id` が欠損している場合は不正状態として Blocker 報告 (上位スキーマ違反)

詳細は `references/progress-yaml.md` の `roadmap` セクションを併せて参照。

## 品質基準

| ✅ よい                                                                                                    | ❌ 悪い                                                 |
| ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| `yq` / 任意の YAML パーサで syntax error なく parse 可能                                                   | インデント不整合・タブ混在・コロン後スペース欠落        |
| 必須フィールド (`roadmap_id` / `title` / `status` / `created_at` / `updated_at` / `milestones`) が全て存在 | 必須フィールドが欠損                                    |
| `status` 値が enum に収まっている (`planned` / `active` / `completed` / `blocked` / `cancelled`)           | enum 外の値 (`done` / `progress` 等) が混入             |
| `milestones[].depends_on[]` が DAG (循環なし)                                                              | 循環依存が混入 (Mermaid 依存グラフでも検出可能)         |
| `workflow_identifiers[]` が set semantics を保っている (重複なし)                                          | 同一 `<identifier>` が複数回現れる                      |
| `updated_at` が更新のたびに書き換えられている                                                              | 古いまま放置されている                                  |
| `roadmap_id` / マイルストーン `id` が `roadmap.md` / `milestones/<id>.md` と完全一致                       | 表記揺れ (例: `ms-01_foundation` vs `ms-01-foundation`) |

## 関連成果物

- **入力なし** (Step 1 で `roadmap-analyst` が初期化、以降は本プロトコルに沿って更新)
- **連携:**
  - `roadmap.md` (タイトル / マイルストーン一覧と一致)
  - `milestones/<milestone-id>.md` (id / title / depends_on / workflow_identifiers と一致)
  - `progress.yaml.roadmap` ブロック (双方向参照、`references/progress-yaml.md` 参照)
  - `dev-workflow/SKILL.md` の「`roadmap-progress.yaml` 更新プロトコル」セクション (本プロトコルの規範元)
- **後続:** `roadmap-retrospective-writer` が Step 4 で本ファイルを参照し、ロードマップ全体 `status: completed` に遷移
