# Research Note: progress-yaml-concurrency

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Topic:** progress-yaml-concurrency
- **Researcher:** researcher (single instance — concurrency observation only)
- **Created at:** 2026-04-29T03:00:00Z
- **Scope:** 1:N 許容方針 (Intent Spec Q1 確定 / 1 マイルストーン:N workflow サイクル) のもとで、`docs/dev-roadmap/<roadmap-id>/roadmap-progress.yaml` を **複数の `dev-workflow` サイクルが同時更新** する場合の競合回避手法を比較し、Step 3 architect が選定できる素材を提供する。**やらない**: 既存スキル構造の包括精査 (別 researcher 担当) / 再開プロトコル (別 researcher 担当) / retrospective 流用 (別 researcher 担当) / 設計確定 (Step 3 architect)。

## 調査対象

Intent Spec の未解決事項 #4 (`docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:151`) が定義する「複数の `dev-workflow` サイクルが同一マイルストーンに紐付いて並行進行する場合の `roadmap-progress.yaml` 同時更新の競合回避ルール」を、(a) 競合発生シナリオ整理、(b) 既存運用での並行更新事例、(c) 4 案 (git マージ任せ / 追記専用構造 / ファイル分割 / シリアライズ規則) の比較、(d) 1:N 想定下の実運用頻度推定、(e) スキーマ再検証、の 5 論点で評価する。

成果物 `references/roadmap-progress-yaml.md` の必須セクション「`dev-workflow` 側からの更新プロトコル」(intent-spec.md:54 / intent-spec.md:108) における「並行サイクル時の競合回避」記述を、Step 3 で 1 案に確定するための判断材料を作成することが目的。

## 発見事項

### F1. 1 マイルストーン:N サイクルの 1:N 許容方針が前提 (Intent Spec Q1 確定)

- **F1.1**: `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:142` に「Q1〜Q5 確定 (1:1 推奨 / 1:N 許容、…)」と記録。**1:N が運用上ありうる**ことが確定済み (例: 同一マイルストーンに対して「実装サイクル」と並行で「ホットフィックス的な追加サイクル」が起動)。
- **F1.2**: 同 intent-spec.md:78 (Step 3 Execution 行) で「`roadmap-progress.yaml` の状態追跡 (dev-workflow 側の自動更新 + Main の補完更新)」と明記。**書き手は dev-workflow サイクル本体 + 当該サイクルの Main 補完更新の二系統**であり、ロードマップ側 `dev-roadmap` は能動的書き手にならない (intent-spec.md:81 / intent-spec.md:92)。
- **F1.3**: 同 intent-spec.md:91 で「**CI / 外部システム連携による自動同期は導入しない**。dev-workflow サイクルが yaml を編集してコミットする以上の自動化機構は持たない」と非スコープ宣言。**外部ロックサービス (Redis, Consul 等) や CI 排他制御は使えない**。

### F2. 競合発生シナリオは 2 タイプに整理できる

#### F2.1 同一ブランチ・時系列衝突 (シリアライズ可能)

- 1 つの作業ブランチ上でサイクル A → B が時系列に commit する場合は、git の通常 fast-forward で衝突しない。
- ただし「サイクル A の Step 5 完了 commit」と「サイクル B の Step 3 完了 commit」が**同じ progress.yaml の異なる行**を編集する場合、後発側は git pull + rebase が必要になるが、人間/Main が逐次操作する限り**実害は出にくい**。

#### F2.2 別ブランチ並行 → merge 衝突 (本研究の主題)

- リポジトリの実運用は worktree + feature branch + PR merge: `git worktree list` 出力上、現在 4 つの worktree (`/Users/totto2727/proj/monorepo`, `/Users/totto2727/proj/monorepo-old`, `.claude/worktrees/dazzling-meandering-pudding`, `.claude/worktrees/inherited-humming-summit`) が同時並行で活性化されている (本セッション開始時の git 出力)。
- merge 履歴 (本セッション冒頭の `git log --merges`) も多数の `Merge pull request` を確認: PR ベースの並行作業が**現実に発生**している運用。
- 1:N で同一マイルストーンに対して **別ブランチで並行する 2 サイクル A, B** が動くと、A も B も `roadmap-progress.yaml` の**同一マイルストーンセクション**を書き換えるため、PR マージ時に YAML レベルで衝突する可能性が高い。これが本研究で回避すべき**主たる衝突類型**。

### F3. 既存 `progress.yaml` の並行更新事例: 同一サイクル内の field-add 衝突は観測済み、複数サイクル間衝突は未観測

- **F3.1**: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md:29` (本セッションで `ggrep -n "progress" retrospective.md` 経由確認) に「**progress.yaml の artifacts セクションでキー重複エラーが 2 回発生** (task_plan, self_review)。新フィールド追加時に既存 null フィールドを残してしまった。pre-commit hook (yaml syntax check) で検出されたため迷彩はないが、commit を 1 回追加する手間が生じた」とあり、**pre-commit hook で YAML 構文を検査している**ことが確認できる。
- **F3.2**: 同 retrospective.md:55 に対策「**progress.yaml 編集時は新フィールド追加と既存 null 削除を 1 回の Edit でセット**にする運用」とあり、これは**単一サイクル内の人為ミス**対策で並行更新衝突対策ではない。
- **F3.3**: `docs/dev-workflow/` 配下の commit ログ (`/tmp/claude/dev-workflow-log.txt`) を確認すると、`2026-04-29-add-dev-roadmap-skill` / `2026-04-29-retro-cleanup` / `2026-04-29-integrate-self-review-into-external` の 3 サイクルが**同日に並行進行**しているが、いずれも `<identifier>` 直下の独立した `progress.yaml` を編集するのみで**同一 yaml ファイルを共有していない**ため衝突は発生していない。**roadmap-progress.yaml は構造的にこの保護を失う**点に留意が必要。

### F4. 既存 `progress.yaml` には append-only 性のあるリスト型フィールドが既に多数存在

`plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml` (本セッションで全文 Read) より:

- L8 `completed_steps: []` (append-only — ステップ完了ごとに追記されるのみ)
- L15 `pending_gates: []` (削除あり — ゲート解消時に除外)
- L18 `active_specialists: []` (running/blocked のみ残す。完了時に除外)
- L27 `blockers: []` (解消時に削除)
- L44 `user_approvals: []` (append-only)
- L50 `rollbacks: []` (append-only)

`plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md` (全文 Read):

- L34-39: `completed_steps` は時系列で記録 (append-only)
- L80-84: `user_approvals` は承認/却下の履歴 (append-only)
- L84-87: `rollbacks` は履歴 (append-only)

→ **既存 `progress.yaml` は完全な「最新状態のスナップショット」ではなく「最新スナップショット + イベント履歴」のハイブリッド構造**。append-only セクションは git 視点で「異なる行を追加する」操作になるため、複数編集者が同時に異なる要素を追加しても**通常 3-way merge で自動マージできる**特性を既に持つ。

### F5. git の 3-way merge が YAML リストに対して持つ性質

- **F5.1**: git のマージは行ベース。YAML リストの新規アイテムを末尾に append する操作は、別ブランチの append 操作と**異なる行**になるため、ヒューリスティック上は自動マージ可能。ただし**両ブランチが同じ末尾位置に append すると "both added" として衝突マーカが出る**。
- **F5.2**: `roadmap-progress.yaml` がマイルストーン状態 (`status: in_progress` / `completed`) のような**スカラ値の上書き**を含む場合、サイクル A が `in_progress` → `completed` に更新したのと同時にサイクル B が `in_progress` → `in_progress` (no-op) する程度なら問題ないが、**両方が異なる値に書き換える**シナリオは確実に衝突する。
- **F5.3**: `pre-commit` hook が YAML syntax を検査している (F3.1 由来) ため、merge 衝突マーカが残った状態の commit は**機械的に阻止される**。これは「衝突を放置して push される事故」を構造的に防ぐ重要なセーフティネット。

### F6. 既存 git-workflow スキルにファイルロック機構はない

- `plugins/totto2727/skills/git-workflow/SKILL.md` (全文 Read): GPG 署名・Conventional Commits・stash ベースの安全削除・branch-split-workflow を扱うが、**ファイルロックや排他更新の規定はない**。
- 規律としてあるのは「One command at a time」「Error handling: on conflicts, push failures, or git errors: halt, report current state, and request instructions」(L65-66) のみ。**衝突発生時は止めて報告**が現運用の唯一の規範。

### F7. dev-workflow が定める「中断・再開できるサイクル管理」は **1 サイクル = 1 progress.yaml** 前提

- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:36` (全文 Read): "**Commit-Based Resumability**: サイクルの成果物と進捗記録は `docs/dev-workflow/<identifier>/` に集約し、**各ステップ完了時に必ずコミット**する"
- 同 L107-185 (成果物保存構造): 各 `<identifier>` ごとに**独立ディレクトリ**に集約することで他サイクルとの疎結合を担保している。
- **`roadmap-progress.yaml` はこの設計原則に対する例外**: 1 ファイルを N サイクルが共有する。Intent Spec が「最小限変更」(intent-spec.md:56-65) を強調していることと併せ、**例外を増やさないようにシンプルに収める方向**が望ましい。

### F8. リポジトリは worktree + feature branch + PR merge ワークフロー

- `git worktree list` 出力 (本セッション): 4 worktree が並列存在。
- `git log --all --merges` (本セッション): `Merge pull request #85`, `#90`, `#88`, `#86`, `#84` 等が連続。**PR マージは恒常的に発生**。
- → **別ブランチで roadmap-progress.yaml を編集 → PR でマージ** の経路が現実的最頻パターンになる。

## 引用元

- Intent Spec 本文: `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:54` / `:78` / `:81` / `:91` / `:92` / `:108` / `:142` / `:151`
- 既存 progress テンプレート: `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml:8` (`completed_steps`) / `:15` (`pending_gates`) / `:18` (`active_specialists`) / `:27` (`blockers`) / `:44` (`user_approvals`) / `:50` (`rollbacks`)
- 既存 progress 書き方ガイド: `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md:11` (更新タイミング) / `:34-39` (`completed_steps`) / `:57-59` (`blockers`) / `:80-84` (`user_approvals`) / `:84-87` (`rollbacks`)
- 既存サイクル retrospective: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md:29` (キー重複インシデント) / `:55` (運用対策)
- dev-workflow 主スキル: `plugins/dev-workflow/skills/dev-workflow/SKILL.md:36` (Commit-Based Resumability) / `:710-779` (ステップ完了時のコミット規約) / `:621-635` (セッション再開時)
- shared-artifacts 主スキル: `plugins/dev-workflow/skills/shared-artifacts/SKILL.md:107-134` (成果物保存構造)
- git-workflow スキル: `plugins/totto2727/skills/git-workflow/SKILL.md:58-66` (Universal Rules)
- 並行サイクル運用の git 証跡: `/tmp/claude/dev-workflow-log.txt` (本研究で生成、`git log --since="2026-04-26" -- "docs/dev-workflow/"`)
- worktree 状態証跡: 本セッション冒頭 `git worktree list` 出力

## 設計への含意

### 4 案の比較表 (Step 3 architect 向け判断材料)

評価軸: (1) 一意性 = 衝突回避効果、(2) 実装コスト = template / reference / SKILL 追加分量、(3) Intent Spec の「最小限変更」原則 (intent-spec.md:56) との整合、(4) Mermaid 依存グラフ表示の維持、(5) 人間可読性。

| 観点               | A. git マージ任せ                                    | B. 追記専用 events 構造                                 | C. ファイル分割 (1 milestone = 1 file)        | D. シリアライズ規則 (lock ファイル)         |
| ------------------ | ---------------------------------------------------- | ------------------------------------------------------- | --------------------------------------------- | ------------------------------------------- |
| 一意性 (衝突回避)  | △ スカラ書き換えで衝突。リスト末尾も "both added"    | ◎ events 配列への append のみ。同位置 append は稀      | ○ ファイル単位で隔離。1 ms 内 N 並行は残課題  | △ git 環境ではアドバイザリのみ・強制不可    |
| 実装コスト         | ◎ 何も追加しない (運用ルール 1 行)                   | ○ schema に `events: []` 追記 + 集計ルール明記         | △ ディレクトリ構造変更 + 集約ビュー要検討     | ✗ lock ファイル仕様 + 取得/解放手順 + 失敗時清掃の文書化大                  |
| 最小限変更整合     | ◎                                                    | ○ events 1 セクション増加で済む                         | △ 単一ファイル前提が崩れる                    | ✗ 新規概念 (lock) を持ち込む                |
| Mermaid 図示維持   | ◎ 既存どおり markdown 内で記述可                     | ◎ events と並列でマイルストーン定義は変えない          | △ 全体図は集約スクリプトに依存しがち          | ◎ 影響なし                                  |
| 人間可読性         | ○ 通常運用は読みやすい (衝突時のみ煩雑)              | ○ 履歴が見える分むしろ追跡しやすい (progress.yaml 同型) | △ 全体俯瞰には N ファイル open 必要           | ○ lock 状態を読む必要が出る分やや低下       |
| 既存 progress.yaml との整合 | ◎ 同等                                       | ◎ `completed_steps` / `user_approvals` 等と同型      | ✗ 1 ファイル原則を破る                        | ✗ 既存 yaml には lock 概念がない            |
| 1:N 想定下の頑健性 | △ 1:N 頻発時に衝突が増える                           | ◎ N が増えても線形に events が増えるだけ                | ○ N ms 並行に強い (1 ms の同時 N サイクルは残課題) | ○ ただし lock 取り損ねると無効化           |

### 推奨案: **B. 追記専用 events 構造** (Step 3 architect が選定する第一候補として推奨)

#### 推奨根拠

1. **既存 `progress.yaml` の設計と同型** (F4): `completed_steps` / `user_approvals` / `rollbacks` 等は既に append-only 履歴セクションとして定着しており、新規概念を増やさず**既存スキーマパターンの自然な拡張**として `events: []` を導入できる。intent-spec.md:56「既存スキルへの最小限変更」原則と整合。
2. **git 3-way merge との親和性** (F5.1): events が「(イベントタイプ, タイムスタンプ, ペイロード) のオブジェクト」を**末尾追記**する形であれば、別ブランチからの追記は異なる行になり、3-way merge で自動マージが成立しやすい。両ブランチが**まったく同時刻に同位置に追記**したケースのみ衝突するが、その場合も `pre-commit` hook の YAML syntax 検査 (F3.1 / F5.3) で commit が機械的に阻止されるため、未解決衝突が main に流入する事故を二重に防げる。
3. **マイルストーン状態 (`status`) の最終値はイベント畳み込みで導出** (= **single source of truth = events**) とすれば、サイクル A と B が同時に `status: in_progress → completed` を上書き合うシナリオが**構造的に消える** (両者は別 event を append するだけ)。これは案 A の最大の弱点を解消する。
4. **Mermaid 依存グラフは別レイヤ** (`milestones[].depends_on` 等の不変フィールド): events と分離してマイルストーン定義部分は**ロードマップ作成時点で確定**させる構造にすれば、人間が読む時の俯瞰性も保たれる (intent-spec.md:124 制約「Mermaid コードブロックで表現可」と整合)。
5. **1:N 頻度推定**: F8 の運用 (worktree + PR merge 恒常) と Intent Spec Q1 確定 (1:N 許容) を踏まえると、**roadmap 配下では 2〜3 サイクルが部分的に並行することは常態化**すると推定 (推測。直接の観測値はない)。案 A だけでは長期的に衝突発生確率が無視できない。

#### 推奨スキーマ (Step 3 で詳細化される素材)

```yaml
roadmap_id: <roadmap-id>
created_at: <ISO8601>
updated_at: <ISO8601>

milestones: # ロードマップ作成時に planner が確定。以後は不変
  - id: <ms-id>
    title: <定性的到達点>
    depends_on: [<ms-id>, ...]

# 並行サイクルが書き込むのは events のみ (append-only)
events:
  - at: <ISO8601>
    cycle: <dev-workflow identifier>
    milestone: <ms-id>
    type: cycle_started | step_completed | cycle_completed | blocked | resumed
    payload:
      step: <ステップ名> # type=step_completed のみ
      summary: <短いサマリ>

# 派生ビュー (人間 / Main の俯瞰用、events から導出可能なキャッシュ)
# 任意。書き手は最後に書いた者で OK (eventually consistent)
status_view:
  - milestone: <ms-id>
    state: planned | in_progress | completed | blocked | cancelled
    cycles: [<identifier>, ...]
    last_event_at: <ISO8601>
```

要点:

- **書き手 (dev-workflow サイクル) は events のみを append する規律**を守れば衝突しない (sub-section ごとに独立行として追記)。
- `status_view` は**派生ビュー**でありどのサイクルが上書きしても OK。merge 衝突が起きた場合は events から再生成して上書きする復旧ルールにすれば**自己修復可能**。
- マイルストーン定義 (`milestones`) は roadmap-planner が Step 2 で書いた後は不変 → 並行サイクルは触らないので衝突しない。

### スキーマフィールド再検証 (Intent Spec 論点 5)

論点 5 の各候補フィールドについて、案 B 採用前提で評価:

| フィールド                                       | 採否    | 理由                                                                                            |
| ------------------------------------------------ | ------- | ----------------------------------------------------------------------------------------------- |
| マイルストーン状態 (planned/active/...)          | 採用    | ただし**派生ビュー**(`status_view`) として保持。書き手の競合を許容するため衝突は実害なし        |
| 対応 workflow identifier (リスト)                | 採用    | `status_view[*].cycles` で 1:N を表現。events からも再生成可                                    |
| イベントログ                                     | **必須**| 案 B の中核。`events: []` トップレベル                                                         |
| `started_at` / `updated_at` / `completed_at`     | 採用    | roadmap 全体の時系列メタ。ただし `completed_at` は events の最終 cycle_completed から導出可能   |
| 1:N の表現                                       | 採用    | `status_view[*].cycles` を配列で持つだけ。フラットな `cycle_id: foo` は不採用                   |

### 副次的含意 (Step 3 architect への注意喚起)

- **`pre-commit` hook の YAML syntax 検査は維持必須** (F3.1 / F5.3): 案 B でも残存衝突マーカが押し込まれない最後の砦になる。Step 6 Implementation で hook 設定を変更しないこと。
- **events ペイロードに秘匿情報を載せない**: payload は短いサマリに限定し、PII / 内部 URL / トークン等を含めない (specialist-common 「秘匿情報の取り扱い」と整合)。
- **events の最大サイズ運用**: 長期的にロードマップが完了した後に events が肥大化する可能性。Step 3 で「ロードマップ完了時 (Step 4 Retrospective) に events を圧縮 (時系列のままサマリ化) するか、そのまま履歴として保持するか」を判定すること推奨。本研究では**保持推奨** (履歴価値が高く、サイズ増加は線形)。
- **マージ衝突発生時のリカバリ手順**を `references/roadmap-progress-yaml.md` に明記すること: ① events セクションの衝突マーカを取り除く、② 両ブランチの events を時系列でマージ、③ status_view を events から再生成、④ commit。**dev-workflow/SKILL.md の「Blocker 発生時」フロー** (`plugins/dev-workflow/skills/dev-workflow/SKILL.md:611-619`) と整合させる。

## 残存する不明点

1. **派生ビュー `status_view` を実体として持つか、毎回再生成 (オンザフライ) するか**: 持てば人間可読性 ◎ だが書き手競合の対象になる (実害なしの設計だが冗長)、持たなければ可読性のため Mermaid 図示時にスクリプト/手動再生成が必要。**Step 3 architect の判断**。本 researcher は「持つ + eventually consistent」を推奨するが、確定はしない。
2. **events のスキーマ詳細 (type の列挙、payload 形)**: Intent Spec 上は `cycle_started` / `step_completed` / `cycle_completed` の 3 種で必要十分とみられるが、`blocked` / `resumed` / `cancelled` 等を含めるかは Step 3 で確定。
3. **roadmap-planner (Step 2) が `events: []` 初期値を書く責務か、最初の dev-workflow サイクルが書くか**: roadmap-progress.yaml の初期化責務がまだ未定義。Intent Spec 上は roadmap-planner が milestones まで書き、events は dev-workflow サイクルから追記が自然と推測されるが、Step 3 で明文化が必要。
4. **events の時系列が一意でないケース** (同一秒に複数 events が異なるサイクルから push される): タイムスタンプだけでなく `id: <uuid>` 等の追加要素で一意化が必要か、ISO8601 ms 精度で十分か。**Step 3 で明示**を推奨。本研究は ms 精度で十分と推測 (推測)。
5. **既存 retrospective.md のキー重複対策 (F3.1) を roadmap-progress.yaml にも適用するか**: events 構造なら field-add 衝突は構造的に発生しないため、既存対策の準用は不要と推測。Step 3 で確認。
6. **1:N の実頻度 (定量推定)**: 本研究では「頻発する」と定性推定したのみ (F8 運用の状況証拠)。サイクル開始日数をベースにした統計は取っていない。Step 3 architect が「頻度を理由に案 B を採る」と書く場合は、定性記述 + 「将来観測する」程度の表現を推奨。
