# Research Note: resumption-protocol-adaptation

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Topic:** resumption-protocol-adaptation
- **Researcher:** researcher-resumption-protocol-adaptation
- **Created at:** 2026-04-29T00:00:00Z
- **Scope:** dev-workflow の「セッション再開時」プロトコル (`dev-workflow/SKILL.md` L620-L634) を `dev-roadmap` に適用する必要があるかを判定し、必要な場合の差分 (流用 / 修正 / 新規追加) を Step 3 architect が `dev-roadmap/SKILL.md` の再開セクション設計に直接使える粒度で明らかにする

## 調査対象

Intent Spec 「未解決事項 #2」(`docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:L149`) で示された「`dev-workflow` のセッション再開プロトコル (`progress.yaml` を読み込み文脈再構築) を roadmap 用にアダプトする必要があるかどうか」を、以下 5 論点で具体化する:

1. 既存 `dev-workflow/SKILL.md` 「5. セッション再開時」プロトコルの精査
2. roadmap の再開シナリオ (Step 1-2 完了後 / Step 3 Execution 中 / Step 4 Retrospective 中)
3. `roadmap-progress.yaml` が再開時に持つべき情報 (既存 `progress.yaml` フィールドとの差分)
4. 再開プロトコルの差分 (流用 / 修正 / 新規追加)
5. roadmap と workflow の再開順序 (進行中 workflow サイクルが残っている場合の優先度、`progress.yaml.roadmap` の活用)

スコープ外: 既存スキル構造の包括精査、retrospective 流用判定、`roadmap-progress.yaml` 競合回避、設計そのもの (Step 3 architect の責務)。

## 発見事項

### F1. 既存 dev-workflow 再開プロトコルの 8 ステップ構造

`dev-workflow/SKILL.md:L620-L634` の「5. セッション再開時」は以下 8 ステップで構成される (引用元の番号順):

1. **`progress.yaml` 読み込み** (L624)
2. **状態フィールド確認**: `current_step` / `completed_steps` / `pending_gates` / `active_specialists` / `blockers` (L625)
3. **既存成果物の全読み込み**: `intent-spec.md` / `research/*.md` / `design.md` / `task-plan.md` / `TODO.md` 等 (L626)
4. **Step 6 特殊処理**: `TODO.md` を読み込み `TaskCreate` で内部タスクリスト**完全復元**、`completed` → `completed`、`in_progress` → `pending` に戻す、TODO.md を正とする (L627-L630)
5. **前セッション Specialist は全て役割終了扱い** (L631) — `active_specialists` に `running` があってもセッション跨ぎ再利用は禁止
6. **現 `current_step` を継続する場合は新規 Specialist を起動して当該ステップを再活性化** (L632)
7. **`blockers` 再提示**: ユーザーに In-Progress 問い合わせ形式で対応方針を確認 (L633)
8. **`progress.yaml.updated_at` 更新 + 再開マーカーコミット** (L634)

### F2. ワークフロー開始時の再開検出ロジック

`dev-workflow/SKILL.md:L573-L580` の「1. ワークフロー開始時」では、ユーザー指示後の最初の判定として:

- L575: 「`docs/dev-workflow/` 配下に**再開可能なサイクルが存在しないか**確認する」
- L576-L577: 存在する場合はユーザーに再開可否を確認、`progress.yaml` を読み込んで「5. セッション再開時」の手順へ
- L578-L580: 存在しなければ新規 `<identifier>` 命名 → ディレクトリ作成 → `progress.yaml` 初期化 → Step 1 着手

つまり**再開検出 (起動時) と再開実行 (5. セッション再開時) は別セクションで定義され、前者が後者を呼び出す形**になっている。

### F3. `progress.yaml` の再開関連フィールド一覧

`shared-artifacts/templates/progress.yaml` および `shared-artifacts/references/progress-yaml.md` から、再開時に参照されるフィールドは以下 (`progress-yaml.md` L18-L86):

| フィールド | 役割 (再開時) | 必須性 |
| --- | --- | --- |
| `identifier` | サイクル一意識別子 (固定) | 必須 |
| `started_at` / `updated_at` | 開始時刻 (固定) / 最終更新時刻 (再開マーカー) | 必須 |
| `status` (`active` / `completed` / `blocked`) | サイクル全体状態 — 再開要否の一次判定 | 必須 |
| `current_step` | 「Step N: 名称」形式で再開地点を一意特定 | 必須 |
| `completed_steps` (時系列リスト) | 既完了ステップ + 成果物 — 文脈復元の索引 | 必須 |
| `pending_gates` | ユーザー承認 / Main 判定待ち項目 — 再開時の真っ先のアクション | 必須 |
| `active_specialists` (`running` / `blocked` のみ) | 役割終了扱いに変換する対象 | 必須 (空でも) |
| `blockers` | 未解決阻害要因 — 再開時にユーザー再提示 | 必須 (空でも) |
| `artifacts` (各成果物パスへの索引) | 既存成果物全読み込みの起点 | 必須 |
| `user_approvals` (履歴) | ゲート通過履歴の確認 | 必須 (履歴なら空可) |
| `rollbacks` (履歴) | ロールバック履歴 | 必須 (履歴なら空可) |

加えて Intent Spec L59 / L62 の決定により、本サイクルで `progress.yaml` に新設される **`roadmap` ネストブロック** (`{id, milestone: {id}}` または `null`) が再開時に「上位 roadmap 文脈の有無」を一意判定する鍵となる。

### F4. dev-workflow Step 6 の特殊扱い (TODO.md による完全復元)

`dev-workflow/SKILL.md:L627-L630` および `references/todo.md:L70-L76` から、Step 6 の再開だけは他ステップと異なる:

- **TODO.md が真のソース、TaskCreate が揮発ビュー** (`todo.md:L72`)
- 再開時は **TODO.md → TaskCreate の順で完全復元** (`todo.md:L75`)
- 既完了タスク (`[x]`) は `completed` 状態として、`in_progress` 中だったタスクは `pending` に戻す (前 implementer は役割終了済みのため再起動が必要、`SKILL.md:L629`)
- 齟齬発生時は **TODO.md を正として TaskCreate を修正してコミット** (`todo.md:L76`)

これは「タスクレベルの並行進行が permanent state を持つ唯一のステップ」という Step 6 の構造的特性に対応した分岐処理である。他ステップ (Step 1-5 / 7-10) は **`progress.yaml` + 当該ステップ成果物のみで再開できる単純構造**で、特殊復元処理はない。

### F5. roadmap 4 ステップ構造とゲート / Specialist 配置

Intent Spec L72-L80 の「ステップ構造 (`dev-roadmap` ワークフロー)」より、roadmap は dev-workflow 10 ステップに対して以下 **4 ステップ**で構成される:

| Step | 名称 | Specialist | Gate | 主要成果物 |
| ---- | ---- | --------- | ---- | --------- |
| 1 | Roadmap Intent | `roadmap-analyst` × 1 | User | `roadmap.md` (Intent セクション初稿) |
| 2 | Milestone Decomposition | `roadmap-planner` × 1 | User | `milestones/<milestone-id>.md` 群 + 依存グラフ |
| 3 | Execution | (新規 Specialist 起動なし。ユーザーが個別 dev-workflow サイクルを手動起動) | Main | `roadmap-progress.yaml` の状態追跡 |
| 4 | Roadmap Retrospective | `retrospective-writer` × 1 (流用) | Main | `retrospective.md` (roadmap 単位) |

特徴 (Intent Spec L81 から):

- **Step 3 は Specialist を持たない**「ユーザーがサイクルを起動していく期間を表すマーカー的なステップ」
- **dev-roadmap が能動的に dev-workflow サイクルを起動することはない** (起動はユーザー手動、自律更新のみ)
- 起動された各 dev-workflow サイクルは `roadmap != null` を検知すると `roadmap-progress.yaml` を**自律的に更新**する (Intent Spec L62-L63)

### F6. `roadmap-progress.yaml` の必須フィールド要件 (Intent Spec 由来)

Intent Spec L52-L54 / L106 / L108 から、`roadmap-progress.yaml` には以下が必須要件として書かれている:

- 「`dev-workflow` 側からの更新プロトコル」セクション (references/) で「**何を / いつ / どう書くか**」の 3 観点を全て含む (Intent Spec L54, L108 = 成功基準 #10)
- マイルストーン状態遷移: `in_progress` (サイクル開始時) / 進捗サマリ (各ステップ完了時) / `completed` (サイクル完了時) (Intent Spec L106 = 成功基準 #8)
- `roadmap == null` の場合のスキップ規則 (同 #8)
- 並行サイクル時の競合回避ルール (Intent Spec L151 未解決事項 #4 — 別 researcher 担当)

ここから逆算して、再開時に最低限読まなければならないフィールド候補は (本 researcher の推定):

- ロードマップ全体状態 (`active` / `completed` / `blocked` 等) — `progress.yaml.status` に対応
- 各マイルストーンの状態 (`planned` / `in_progress` / `completed` / `blocked` / `cancelled` 等) と対応 dev-workflow `<identifier>` 群 (1:N 許容、Q1 確定済み, Intent Spec L142)
- 各マイルストーンの `started_at` / `completed_at`
- ロードマップ自身の `roadmap_id` / `started_at` / `updated_at`

ただし**正確なフィールドリストは Step 3 Design で確定する事項**であり、本 Research Note は再開プロトコル設計の前提情報として「最低何があれば再開可能か」を整理するに留める。

### F7. `progress.yaml.roadmap` ネストブロックによる双方向参照

Intent Spec L59 / L62-L63 から、roadmap 配下の dev-workflow サイクルでは:

- **workflow 側 `progress.yaml` トップに `roadmap: {id, milestone: {id}}` が設定される** (Intent Spec L59) — workflow からの上位参照
- **roadmap 側 `roadmap-progress.yaml` には対応する dev-workflow `<identifier>` が記録される** (Intent Spec L81 「Main は対応表 ... を `roadmap-progress.yaml` で俯瞰し」より) — roadmap からの下位参照

これにより**ID 文字列ベースでの双方向参照**が成立する (Intent Spec L70「両者は独立ディレクトリで疎結合、参照は ID 文字列で行う」)。再開時はこの双方向参照を用いて文脈を相互復元できる。

### F8. workflow と roadmap のディレクトリ独立性

Intent Spec L67-L70 から:

- ロードマップ作業ディレクトリ: `docs/dev-roadmap/<roadmap-id>/`
- 既存 dev-workflow ディレクトリ: `docs/dev-workflow/<identifier>/`
- **両者は並列配置で疎結合**、`<roadmap-id>` と `<identifier>` は完全独立 (Q2 確定、Intent Spec L142)

つまり再開検出は **`docs/dev-roadmap/` と `docs/dev-workflow/` の 2 ディレクトリを独立スキャン**する必要がある。

### F9. Specialist のステップ跨ぎ禁止 / セッション跨ぎ禁止 (継承される基本方針)

`specialist-common/SKILL.md:L57-L59` および `dev-workflow/SKILL.md:L631` から:

- **1 Specialist = 1 ステップ** (`specialist-common:L57`)、別ステップに引き継がれない
- **セッション跨ぎでの再利用も禁止** (`specialist-common:L59`)
- 再開時は `active_specialists` に `running` があっても全て役割終了扱いに変換 (`SKILL.md:L631`)

Intent Spec L124-L125 より roadmap も `dev-workflow` の基本方針 (One-Shot Specialist & Within-Step Persistence 等) を全継承するため、この規律は roadmap 側にもそのまま適用される。

## 引用元

- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L573-L580` — ワークフロー開始時の再開検出ロジック (1. ワークフロー開始時)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L620-L634` — 「5. セッション再開時」プロトコル本体 (8 ステップ)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L626` — 既存成果物全読み込みの対象列挙
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L627-L630` — Step 6 特殊処理 (TODO.md ↔ TaskCreate 復元)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L631` — 前セッション Specialist 役割終了扱い
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L632` — 新規 Specialist 起動による再活性化
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L633` — Blocker 再提示 (In-Progress 問い合わせ)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L634` — 再開マーカーコミット
- `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml:L1-L55` — `progress.yaml` 全フィールド構造
- `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md:L18-L86` — 各フィールドの意味と更新タイミング
- `plugins/dev-workflow/skills/shared-artifacts/references/todo.md:L70-L76` — TODO.md ↔ TaskCreate 同期ルール
- `plugins/dev-workflow/skills/specialist-common/SKILL.md:L57-L59` — 1 Specialist = 1 ステップ / セッション跨ぎ禁止
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:L52-L54` — `references/roadmap-progress-yaml.md` の必須セクション要件
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:L59` — `progress.yaml` への `roadmap` ネストブロック追加
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:L62-L63` — `dev-workflow/SKILL.md` への追記 2 点 (起動時連携 / 自律更新プロトコル)
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:L67-L70` — ディレクトリ並列配置と疎結合
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:L72-L81` — roadmap 4 ステップ構造とゲート / Specialist 配置
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:L106` — 成功基準 #8 (`roadmap-progress.yaml` 更新プロトコル 5 点明文化)
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:L108` — 成功基準 #10 (references/roadmap-progress-yaml.md 必須 3 観点)
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:L124-L125` — `dev-workflow` 基本方針の roadmap への全継承
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:L142` — Q1 (1:N 許容) / Q2 (`<roadmap-id>` と `<identifier>` 完全独立) 確定
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:L149` — 未解決事項 #2 (本 Research Note の起点)

## 設計への含意

### I1. 結論: roadmap への再開プロトコル適用は**必要**かつ独立セクションとして記述すべき

Intent Spec の 4 ステップ構造 (F5)、`roadmap-progress.yaml` の自律更新が想定する「中断と再開」(F6, F7)、Specialist セッション跨ぎ禁止の継承 (F9, Intent Spec L124-L125) から、**roadmap 側にも再開プロトコルが必須**。Intent Spec の未解決事項 #2 (`必要があるかどうか`) に対する判定は **Yes (必要)**。

加えて、**ディレクトリ独立性** (F8) と **roadmap 4 ステップ構造の特殊性** (F5、特に Step 3 が Specialist 不在) から、dev-workflow の再開プロトコルをそのまま流用するのではなく、`dev-roadmap/SKILL.md` 内に**独立した「セッション再開時」セクション**として記述することが望ましい。

### I2. 流用できる部分 (dev-workflow と同一のまま使える 5 項目)

以下は dev-workflow の再開プロトコル (F1) からそのまま流用できる:

1. **`roadmap-progress.yaml` を真のソースとして読み込む** (F1 #1 と同型、対象ファイル名のみ差し替え)
2. **既存成果物の全読み込み** (F1 #3 と同型、対象は `roadmap.md` / `milestones/<milestone-id>.md` 群)
3. **前セッション Specialist は全て役割終了扱い** (F1 #5、Specialist 列挙が `roadmap-analyst` / `roadmap-planner` / `retrospective-writer` の 3 種類に変わるのみ、規律自体は同一)
4. **`blockers` 再提示** (F1 #7、In-Progress 問い合わせ形式の利用も同一)
5. **`updated_at` 更新 + 再開マーカーコミット** (F1 #8、対象が `roadmap-progress.yaml` に変わるのみ)

これらは「Specialist セッション跨ぎ禁止」と「成果物ベース文脈復元」という dev-workflow の基本方針 (Intent Spec L124-L125 で全継承) から自動的に導出される。

### I3. 修正が必要な部分 (3 項目)

| dev-workflow 側 (F1) | roadmap 側で必要な修正 | 理由 |
| --- | --- | --- |
| `progress.yaml` を読み込む (F1 #1) | **`roadmap-progress.yaml` を読み込む** | ファイル名 / スキーマが別物 (F6) |
| `current_step` / `completed_steps` 等を確認 (F1 #2) | **「ロードマップ全体状態 (active/completed/blocked) + 各マイルストーン状態 (planned/in_progress/completed 等) + 対応 dev-workflow `<identifier>` 群」を確認** | roadmap は単一 `current_step` でなく**マイルストーン群の進行状態の集合**で進捗を表現する (F5, F6)。roadmap 自身の `current_step` (= roadmap の Step 1〜4) と、Step 3 内のマイルストーン進行状態が**二段構造**になる |
| 新規 Specialist 起動による再活性化 (F1 #6) | **roadmap の Step (1/2/4) 再開なら新規 Specialist 起動。Step 3 (Execution) 再開時は Specialist 起動せず、進行中 dev-workflow サイクルの存在確認とユーザー再提示に分岐** | roadmap Step 3 は Specialist 不在 (F5)。再活性化対象が「次に起動すべき dev-workflow サイクル」であり Specialist ではない |

### I4. 新規追加が必要な部分 (4 項目、Step 3 Execution の特殊性に対応)

dev-workflow の再開プロトコル (F1) には対応物がなく、roadmap 用に**新規追加**が必要な手順:

#### N1. 「進行中 dev-workflow サイクルの存在確認」ステップ

Step 3 Execution 再開時は、`roadmap-progress.yaml` 内の各マイルストーン状態を走査し:

- `in_progress` 状態のマイルストーンに紐付いた dev-workflow `<identifier>` を特定
- 対応する `docs/dev-workflow/<identifier>/progress.yaml` の `status` を確認
- `status: active` のものを「進行中サイクル」として列挙

これは F5 (Step 3 は Specialist 不在) と F7 (双方向参照) に対応する新規手順。

#### N2. 「workflow 再開を roadmap 再開より優先する」ガード

I3 #N1 で進行中 workflow サイクルを検出した場合:

- **当該 workflow サイクルを先に再開する** (workflow 側の「5. セッション再開時」を呼び出し)
- workflow が完了 / 中断保留状態に達してから roadmap 側の処理を継続

理由: workflow 側は具体的タスク状態 (TODO.md / 並列 implementer 等、F4) を保持しており、これを未復元のまま roadmap レベルの判断 (次マイルストーンの起動可否等) を下すと、戦略レベルと戦術レベルの認知が分離する Intent Spec L17 の前提を破壊する。

#### N3. 「ユーザー再提示と次マイルストーン起動可否の確認」分岐

進行中 workflow サイクルがない (= 全マイルストーンが `planned` / `completed` / `blocked` のいずれか) Step 3 再開時は:

- 完了済みマイルストーン群と未着手マイルストーン群、ブロック中マイルストーン群を整理してユーザーに提示
- 次にどのマイルストーンを起動するか / 全完了なら Step 4 Retrospective に進めるかをユーザー判断で決定

これは F5 「ユーザーがサイクルを起動していく期間を表すマーカー的なステップ」という Step 3 の設計意図 (Intent Spec L81) に対応する、roadmap 固有の再開分岐。

#### N4. 「`progress.yaml.roadmap` ネストブロックからの逆引き起動シナリオ」

Intent Spec L59 / F7 の双方向参照を活かし、**dev-workflow サイクル側が先に再開を試みた場合**の補助動線:

- workflow 側 `progress.yaml.roadmap` が non-null なら、対応する `docs/dev-roadmap/<roadmap-id>/roadmap-progress.yaml` を読み込む
- 上位 roadmap 文脈をユーザーに表示 (「このサイクルはロードマップ XX のマイルストーン YY として進行中」)
- ユーザーが希望すれば roadmap 文脈も合わせて再開する

これは「workflow から roadmap への文脈復元」を可能にする補助動線で、F7 (双方向参照) の実用化として価値がある。

### I5. roadmap 側「再開時の `current_step` 概念」設計指針

roadmap の `current_step` は dev-workflow と同型の単一値 (例: 「Step 3: Execution」) で表現可能だが、Step 3 滞在中は**マイルストーン群の状態が真の進捗**となる。Step 3 設計時は以下を Step 3 architect に推奨する:

- `roadmap-progress.yaml` トップに `current_step` フィールド (1〜4 の roadmap ステップ)
- Step 3 滞在中はマイルストーン状態の集合が補完情報
- 全マイルストーンが `completed` になった時点で `current_step: Step 4: Retrospective` への自動遷移条件が整う
- ただし**自動遷移は行わず、Main がゲート判定して Step 4 を起動**する (Step 3 の Gate 判定が Main 判定であり、ユーザー判断不要のため。Intent Spec L78)

この扱いを採ると、再開時の挙動が「`current_step` を見て該当ハンドラに分岐」というシンプルな構造に保たれる (dev-workflow と同型)。

### I6. 各再開シナリオに対する具体動線 (Step 3 architect への入力)

Intent Spec 未解決事項 #2 が要求する「再開シナリオ別の挙動」を以下のとおり整理する。Step 3 architect はこれを `dev-roadmap/SKILL.md` の再開セクションに直接展開できる:

#### シナリオ A: Step 1-2 完了直後 (= Step 3 開始直前) で中断 → 再開

1. `docs/dev-roadmap/<roadmap-id>/roadmap-progress.yaml` 読み込み
2. `current_step: Step 3: Execution` を確認、`completed_steps` で Step 1-2 完了を確認
3. `roadmap.md` / `milestones/*.md` を全読み込み
4. **N3 分岐**: マイルストーン状態は全て `planned`、進行中 workflow 不在 → ユーザーに「最初のマイルストーンとしてどれから着手するか」を提示
5. ユーザー回答後は通常の手動 dev-workflow サイクル起動フローへ

#### シナリオ B: Step 3 (Execution) 進行中で中断 → 再開

1. `roadmap-progress.yaml` 読み込み、`current_step: Step 3: Execution` 確認
2. `roadmap.md` / `milestones/*.md` 全読み込み
3. **N1 実行**: `in_progress` マイルストーンに紐付く `<identifier>` 群を特定
4. 対応する `docs/dev-workflow/<identifier>/progress.yaml` の `status` を一斉走査
5. **N2 実行**: 進行中 workflow があれば**そちらを先に再開** (workflow 側「5. セッション再開時」呼び出し)
6. workflow 再開完了後、roadmap 側に戻り **N3 分岐**: 残マイルストーンの起動可否をユーザーに提示

#### シナリオ C: Step 4 (Retrospective) 進行中で中断 → 再開

1. `roadmap-progress.yaml` 読み込み、`current_step: Step 4: Retrospective` 確認
2. 全マイルストーンが `completed` 済みであることを確認 (前提条件のサニティチェック)
3. dev-workflow Step 10 と同型の処理: 既存 `retrospective.md` のドラフトがあれば読み込み、新規 `retrospective-writer` を起動 (前セッション Specialist は役割終了扱い、F9)

これらシナリオを `dev-roadmap/SKILL.md` の再開セクション末尾に分岐表として配置することで、Main が再開時に迷わない。

### I7. ワークフロー開始時の再開検出ロジック (F2 流用 + 拡張)

`dev-workflow/SKILL.md:L573-L580` (F2) と同型の再開検出を `dev-roadmap/SKILL.md` 「ワークフロー開始時」相当セクションに配置:

- `docs/dev-roadmap/` 配下に再開可能なロードマップが存在しないか確認
- 存在すればユーザーに再開可否確認、`roadmap-progress.yaml` を読み込んで「セッション再開時」セクションへ
- 存在しなければ新規 `<roadmap-id>` 命名 → ディレクトリ作成 → `roadmap-progress.yaml` 初期化 → Step 1 着手

加えて **N4 由来の補助動線**: ユーザーが個別 dev-workflow サイクルを起動しようとしている場面で、当該サイクルの `progress.yaml.roadmap` が non-null なら roadmap 文脈の存在をユーザーに通知する (workflow 側 SKILL.md の「ワークフロー開始時」セクション L573 への追記候補。ただしこの追記は本サイクルの追記スコープ外 (Intent Spec L62-L63) のため、Step 3 architect が必要性を判定して追記要否を Intent Spec に追加提案するか判断する)。

### I8. Step 3 architect への申し送り: 再開セクション骨子

上記 I1-I7 を踏まえ、`dev-roadmap/SKILL.md` の再開セクション設計骨子は以下を満たすべき:

1. **見出し**: 「セッション再開時」(dev-workflow と同名で揃える、認知負荷低減)
2. **冒頭**: dev-workflow からの全継承基本方針 (Specialist セッション跨ぎ禁止 / 成果物ベース文脈復元) を 1 段落で明示
3. **ステップ列挙**: 流用 5 項目 (I2) + 修正 3 項目 (I3) + 新規 4 項目 (I4) を統合した 12 項目程度のフラットなステップリスト
4. **末尾の分岐表**: シナリオ A / B / C (I6) を表または箇条書きで分岐動線として明示
5. **ワークフロー開始時セクション** (別セクション、I7) で再開検出を行い、当該再開セクションを呼び出す形を踏襲

加えて Step 3 architect は **`references/roadmap-progress-yaml.md` の必須セクション** (Intent Spec L54, 成功基準 #10) で「再開時に読まれるフィールドの意味」を解説する形で、再開プロトコルと yaml スキーマを連動させて記述する設計を取ると、Spec と実装が一貫する。

## 残存する不明点

### Q1. roadmap 側の `current_step` フィールドを `roadmap-progress.yaml` に持たせるか / マイルストーン状態の集合のみで表現するか

I5 で「持たせる方が再開時のハンドラ分岐がシンプル」と推奨したが、これは設計判断 (Step 3 architect の領域) のため、Step 3 で確定させる必要がある。本 Research Note は両方式の比較材料を提示するに留めた。

### Q2. ワークフロー開始時の再開検出における優先順位 (workflow 検出 vs roadmap 検出)

I7 / N4 で「workflow 側 `progress.yaml.roadmap` が non-null なら roadmap 文脈を表示」と提案したが、ユーザーが workflow を起動しようとしているのか roadmap を起動しようとしているのかは入力意図次第である。両者をユーザーに区別させる UI / 確認フローは Step 3 Design で検討する事項として残る。

### Q3. roadmap 再開時に進行中 workflow が**複数**ある場合の優先順位

N2 では「進行中 workflow サイクルを先に再開」と書いたが、1:N 許容方針 (Q1 確定、Intent Spec L142) 下で複数 workflow が同時並行する場合、どの workflow から再開するかの順序ルールが未確定。`started_at` 昇順 / ユーザー選択 / 並列再開許容 (Specialist セッション跨ぎ禁止と矛盾しないか要検証) の 3 案が候補。Step 3 Design で `roadmap-progress.yaml` 競合回避ルール (Intent Spec 未解決事項 #4、別 researcher 担当) と整合する形で確定する必要がある。

### Q4. workflow 側の「ワークフロー開始時」セクションへの追記要否

I7 / N4 で示した「workflow 起動時に上位 roadmap 文脈を通知する」動線は、本サイクルの追記スコープ (Intent Spec L62-L63 の 2 点: 起動時連携 / 自律更新プロトコル) の**前者と密接だが文言レベルでは別**である。追記要否は Step 3 Design で判定し、必要なら Intent Spec の追記項目を更新する申し送りが要る。

### Q5. roadmap の `blockers` 概念は workflow と同一定義でよいか

dev-workflow の `blockers` は「事象 + 影響 + 対応方針」を含む未解決阻害要因 (`progress-yaml.md:L57-L60`)。roadmap の `blockers` は「個別マイルストーン進行を阻むもの」と「ロードマップ全体を阻むもの」が混在しうるが、両者を区別するか単一スキーマに統合するかは設計判断 (Step 3 architect の領域)。本 Research Note では再開時に「`blockers` 再提示」(I2 #4) を流用可能と判定したが、スキーマ詳細は未確定とする。
