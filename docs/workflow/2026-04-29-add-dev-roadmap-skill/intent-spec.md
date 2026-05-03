# Intent Spec: Add `dev-roadmap` Skill as Upper-Layer Concept Above `dev-workflow`

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Author:** totto2727 (intent-analyst Specialist)
- **Created at:** 2026-04-29T00:00:00Z
- **Last updated:** 2026-04-29T07:30:00Z

## 背景

現在の `dev-workflow` プラグイン (9 ステップ / 1 サイクル = 1 機能 / 1 PR 規模、main マージ後の最新状態) は、「単一のまとまった意図を観測可能な成功基準に展開し、設計→実装→検証まで一気通貫で進める」前提で設計されている。これにより以下の構造的不足が顕在化している:

1. **大規模開発の単位不足**: 複数の `dev-workflow` サイクルに自然に分割される規模の開発 (例: 新サブシステム導入、複数モジュールの段階的リファクタ、長期的な能力獲得計画) を一段上から束ねる手段がない。サイクル間の依存関係や全体像が暗黙知になる
2. **マイルストーン設計の暗黙化**: 「先に何を実装し、次に何を実装するか」「どこで一旦立ち止まって統合検証するか」といった**戦略レベルの判断**が、初回 `dev-workflow` サイクルの Intent Spec 内に紛れ込み、後続サイクルとの接続が追跡しづらい
3. **進捗の俯瞰不能**: 既存の `progress.yaml` はサイクル内の進捗管理に閉じており、複数サイクルを跨ぐ全体進捗 (どのマイルストーンがどの `<identifier>` で実装され、どこまで完了したか) を確認する仕組みがない
4. **AWS AI-DLC 由来の構造的弱点**: `dev-workflow` は元々 1 サイクル単位で完結する設計のため、サイクルを跨ぐ計画層が原典時点で空白になっている。`dev-workflow` を独立した手法として位置づけ直した今 (`2026-04-26-dev-workflow-rename-and-flatten` ADR)、上位層を整備するのが妥当なタイミングである

ユーザーの観察として「複数のワークフローに分割して進めたい大規模な開発」が現実に発生しており、roadmap 層と workflow 層の責務分離を明示することで、戦略 (何を / どの順で / なぜ) と戦術 (どう作る / どう検証する) の認知負荷を分けて扱えるようにしたい。

## 目的

`dev-workflow` プラグイン配下に `dev-roadmap` スキルを新設し、複数の `dev-workflow` サイクルを束ねる**戦略層**として機能させる。具体的には、ロードマップ全体の世界観・スコープ境界を定義し、それを観測可能なマイルストーンに分割し、各マイルストーンの実行を `dev-workflow` サイクルに委譲する流れを成果物ベースで定義する。これにより、サイクル間の依存・順序・進捗を一元的に追跡可能にする。

**スキル名と保存先の分離**: スキル名は `dev-roadmap` / `dev-workflow` を**維持**するが、それぞれの作業ディレクトリ保存先は `docs/roadmap/<roadmap-id>/` / `docs/workflow/<identifier>/` とする (ユーザー指示)。本サイクルの実装着手時に、まず既存 `docs/dev-workflow/` を `docs/workflow/` に `git mv` してコミットする (Step 6 implementer の最初のタスクとして実施)。本 Intent Spec 内の path 表記は**全てリネーム後の新パス**を前提とする。

## スコープ

### 新規スキル

- **`plugins/dev-workflow/skills/dev-roadmap/SKILL.md`** (Main 用): roadmap 全体の進行プロトコル
  - 役割定義 (Main / Roadmap Specialist の 2 層)
  - 4 ステップ構成 (後述「ステップ構造」)
  - ゲート判定・成果物受け渡し・進捗管理 (`roadmap-progress.yaml`) のルール
  - `dev-workflow` サイクルとの接続プロトコル (マイルストーン → サイクル `<identifier>` 紐付け)

### 新規 Specialist スキル

- **`plugins/dev-workflow/skills/specialist-roadmap-analyst/SKILL.md`** (Step 1 担当)
  - roadmap の意図・全体目的・スコープ境界・大局的制約を言語化
  - 成果物: `roadmap.md`
- **`plugins/dev-workflow/skills/specialist-roadmap-planner/SKILL.md`** (Step 2 担当)
  - 全体目的をマイルストーンに分割し、各マイルストーンの目的・到達点 (定性) ・依存関係を定義
  - 成果物: `milestones/<milestone-id>.md` (1 ファイル / マイルストーン) + `roadmap.md` 内のマイルストーン一覧/依存グラフ更新
- **`specialist-retrospective-writer` を流用** (新規追加せず): roadmap 全体完了時の振り返り。流用可能性は Step 2 Research で検証する (流用不可なら新規 `specialist-roadmap-retrospective-writer` を追加)

### 新規エージェント定義

- **`plugins/dev-workflow/agents/roadmap-analyst.md`**
- **`plugins/dev-workflow/agents/roadmap-planner.md`**

### 新規成果物テンプレート / 書き方ガイド (1:1 対応)

- `plugins/dev-workflow/skills/shared-artifacts/templates/roadmap.md` ↔ `references/roadmap.md`
- `plugins/dev-workflow/skills/shared-artifacts/templates/milestone.md` ↔ `references/milestone.md`
- `plugins/dev-workflow/skills/shared-artifacts/templates/roadmap-progress.yaml` ↔ `references/roadmap-progress-yaml.md`
  (1:1 対応の例外として `progress.yaml` ↔ `progress-yaml.md` 同様、拡張子の差を許容する)
  **`references/roadmap-progress-yaml.md` の必須セクション**: 「`dev-workflow` 側からの更新プロトコル」セクションを必ず含めること。具体的に何を (どのフィールドを)、いつ (サイクル開始 / 各ステップ完了 / サイクル完了)、どう書くか (値の遷移ルール、コミット粒度、複数 workflow が並行する場合の競合回避) を定義する

### 既存スキルへの最小限変更

- **`plugins/dev-workflow/skills/shared-artifacts/SKILL.md`**: 成果物一覧テーブルに `roadmap.md` / `milestone.md` / `roadmap-progress.yaml` を追加。1:1 対応の例外リストに `roadmap-progress.yaml` ↔ `roadmap-progress-yaml.md` を追記
- **`plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml`**: トップレベルに任意フィールド `roadmap` (default `null`) を追加。roadmap 配下サイクルでは `{id: <roadmap-id>, milestone: {id: <milestone-id>}}` というネストオブジェクトを設定、独立サイクルでは `roadmap: null` のまま。**ネスト構造採用の意図**: (a) roadmap 配下かどうかを `roadmap` キー単独の null 判定で一意に行える、(b) `milestone` は `roadmap` が non-null の場合のみ意味を持つため、`roadmap == null` で `milestone` だけ存在する矛盾状態を構造的に排除できる、(c) 将来 `roadmap` ブロックに `id` / `milestone` 以外のフィールド (例: `joined_at`, `notes`) を追加する余地を残す。**既存サイクル (`docs/workflow/2026-04-26-add-qa-design-step/progress.yaml`、リネーム後パス) の遡及修正は行わない** (任意フィールドのため後方互換)
- **`plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md`**: ネスト構造の説明を追記。具体的には (a) `roadmap` キーが `null` の場合は独立サイクル、(b) `roadmap` が non-null の場合は `roadmap.id` および `roadmap.milestone.id` が必須、(c) `roadmap == null` で `milestone` 相当のフィールドを単独で書く形は不正とする旨を明記
- **`plugins/dev-workflow/skills/dev-workflow/SKILL.md`**: 以下 2 点の追記。後方互換性を維持し、roadmap 配下でないサイクル (`roadmap == null`) では当該プロトコルがスキップされる旨を明記する。追記分量は 1〜2 段落より大きくなる可能性を許容する:
  1. **ワークフロー開始時のセクション**: 「roadmap 配下のマイルストーンから起動された場合は `<identifier>` をマイルストーン ID と紐付け、`progress.yaml` の `roadmap` ブロックを `{id: <roadmap-id>, milestone: {id: <milestone-id>}}` で初期化する」旨の段落
  2. **新規セクション「`roadmap-progress.yaml` 更新プロトコル」**: roadmap 配下サイクル (`roadmap != null`) が、自身の進行に応じて `docs/roadmap/<roadmap-id>/roadmap-progress.yaml` の該当マイルストーン状態を**自律的に更新**する責務を定義する。具体的には (a) サイクル開始時にマイルストーン状態を `in_progress` に遷移、(b) 各ステップ完了時に進捗サマリ (現在ステップ名・ゲート状況) を反映、(c) サイクル完了時 (Step 9 Retrospective 完了時) にマイルストーン状態を `completed` に遷移、(d) 更新時はコミットを伴う、というタイミング・粒度・責務分担を明文化する
- **`plugins/dev-workflow/README.md`**: `dev-roadmap` スキルの存在と位置づけを README の概要セクションに追記

### 保存先ディレクトリ

- ロードマップ作業ディレクトリ: `docs/roadmap/<roadmap-id>/`
  - `roadmap.md` / `milestones/<milestone-id>.md` / `roadmap-progress.yaml`
- ロードマップ retrospective: `docs/retrospective/<roadmap-id>.md` (集約形式)
  - main マージ後の `dev-workflow` が retrospective を `docs/retrospective/<identifier>.md` (集約) に保存する方針 (`docs/adr/` と同パターン) と整合させ、roadmap retrospective も同じ集約ディレクトリへ保存する
  - `dev-workflow` の `<identifier>` と `dev-roadmap` の `<roadmap-id>` の命名衝突回避方針 (例: roadmap 側に prefix を付与するか) は Step 3 architect が `dev-roadmap/SKILL.md` で確定する論点として残す
- 既存の `docs/workflow/<identifier>/` と**並列**配置 (両者は独立ディレクトリで疎結合、参照は ID 文字列で行う)
- **保存先リネームの先行コミット**: 本サイクル実装着手時に、既存 `docs/dev-workflow/` を `git mv` で `docs/workflow/` にリネームし、当該リネームを単独コミットとして先行投入する (Step 6 implementer の最初のタスク)。`git diff --find-renames` がパス変更のみを認識し、内容差分は 0 になる前提

### ステップ構造 (`dev-roadmap` ワークフロー)

| Step | 名称                    | Specialist                                                                                        | Gate | 主要成果物                                                                       |
| ---- | ----------------------- | ------------------------------------------------------------------------------------------------- | ---- | -------------------------------------------------------------------------------- |
| 1    | Roadmap Intent          | `roadmap-analyst` × 1                                                                             | User | `roadmap.md` (Intent セクションのみ初稿)                                         |
| 2    | Milestone Decomposition | `roadmap-planner` × 1                                                                             | User | `milestones/<milestone-id>.md` 群 + 依存グラフ                                   |
| 3    | Execution               | (ユーザーが手動で個別 `dev-workflow` サイクルを起動。各サイクルが `roadmap-progress.yaml` を更新) | Main | `roadmap-progress.yaml` の状態追跡 (dev-workflow 側の自動更新 + Main の補完更新) |
| 4    | Roadmap Retrospective   | `retrospective-writer` × 1 (流用)                                                                 | Main | `docs/retrospective/<roadmap-id>.md` (集約形式)                                  |

Step 3 では `dev-roadmap` 自身は新たな Specialist を起動しない。**`dev-roadmap` が能動的に `dev-workflow` サイクルを起動することはない**: ユーザーがマイルストーン定義を入力源として、必要なタイミングで個別の `dev-workflow` サイクルを手動で起動する。起動された各 `dev-workflow` サイクルは `roadmap != null` (= `progress.yaml` トップの `roadmap` ブロックが non-null) を検知すると、自身の進行 (サイクル開始 / 各ステップ完了 / サイクル完了) に応じて `docs/roadmap/<roadmap-id>/roadmap-progress.yaml` の該当マイルストーン状態を**自律的に更新**する (詳細プロトコルは `dev-workflow/SKILL.md` 内の新規セクションに記載)。Main は対応表 (どのマイルストーンが pending / in_progress / completed か、対応する dev-workflow `<identifier>` は何か) を `roadmap-progress.yaml` で俯瞰し、必要に応じて補完的に更新する。

なお、`dev-workflow` 本体は main マージにより**9 ステップ体系** (Step 1=Intent / 2=Research / 3=Design / 4=QA Design / 5=Task Decomposition / 6=Implementation / 7=External Review / 8=Validation / 9=Retrospective、旧 Step 7 Self-Review は External Review に統合済) に再編されている。`dev-workflow` サイクルが `roadmap-progress.yaml` の `completed` 遷移を行うタイミングは **Step 9 Retrospective 完了時** (= 旧表記 Step 10 完了時に相当) である旨を本サイクルの design.md / dev-workflow SKILL 追記で明記する。

## 非スコープ

- **roadmap 層に観測可能な成功基準を持たせること**: 観測可能性は workflow 側 Intent Spec の責務。roadmap の `roadmap.md` には**定性的な到達点 (例: 「OAuth 認証が本番運用可能な状態になっている」)** のみ記述し、計測手段の特定は workflow に委譲する (ユーザーは論点 A 寄りを表明)
- **roadmap 専用の Design / QA Design / Implementation / Validation ステップ**: roadmap は計画層に純化し、設計・実装・検証は全て個別マイルストーンの `dev-workflow` サイクルに委譲する
- **既存サイクル (`docs/workflow/2026-04-26-add-qa-design-step/`、リネーム後パス) の遡及的 roadmap 紐付け**: 完了済みサイクルは現状のまま保持
- **既存 `progress.yaml` スキーマの破壊的変更**: 追加フィールドはすべて任意 (default null)、既存サイクル動作は完全な後方互換を維持
- **テスト専用 `dev-workflow` サイクル概念の導入**: ユーザー検討案にあった「最終マイルストーン = 統合検証マイルストーン」は roadmap-planner が必要に応じて配置するパターン**例**として `references/milestone.md` に書く程度に留める。「テスト専用 dev-workflow」を別形態として定義しない (通常マイルストーンで表現可能)
- **roadmap を入れ子にすること** (roadmap-of-roadmaps): 1 階層に限定。複数 roadmap を束ねたければプロジェクト全体ドキュメントで対応する
- **CI / 外部システム連携による自動同期**: `roadmap-progress.yaml` の更新は **`dev-workflow` サイクル自身による自律更新 + Main の補完更新**で完結させる。CI パイプライン連携、GitHub Actions、外部 webhook 等による自動化は導入しない。dev-workflow サイクルが yaml を編集してコミットする以上の自動化機構は持たない
- **`dev-roadmap` 自身による `dev-workflow` サイクルの能動起動**: `dev-roadmap` (および Main) は roadmap 定義に基づいて `dev-workflow` サイクルを自動的にキックしない。サイクルの起動はユーザーが手動で行う (Execution ステップは「ユーザーが起動していく期間」を表すマーカー的なステップ)
- **新規プロジェクト横断 ADR の起票**: 本サイクルの設計判断は `design.md` に記録する。`dev-roadmap` の追加は前 ADR (`doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md`) の枠組みの範囲内であり、横断的決定の追加には当たらない (Step 3 Design でこの前提が崩れた場合のみ ADR 起票を再検討)

## 成功基準

以下は全て**機械的または手動目視で合否を一意に判定可能**な観測可能基準。Step 8 Validation (9 ステップ体系における Validation ステップ) で実測する。

1. **新規スキル本体の存在**: `plugins/dev-workflow/skills/dev-roadmap/SKILL.md` が存在し、frontmatter (`name: dev-roadmap` / description / metadata) と本文 (役割定義 / 4 ステップ構造 / ゲート判定 / `dev-workflow` 接続プロトコル / 進捗管理プロトコル) を含む
2. **新規 Specialist スキル 3 個の存在**: `plugins/dev-workflow/skills/specialist-roadmap-analyst/SKILL.md`、`specialist-roadmap-planner/SKILL.md`、`specialist-roadmap-retrospective-writer/SKILL.md` が存在し、それぞれ frontmatter (name / description / metadata) と本文 (役割 / 入力 / 手順 / 失敗モード / スコープ外) を含む (Step 2 Research の retrospective-writer-reusability で案 C 新設が確定したため、当初想定の 2 個から 3 個に増加)
3. **新規エージェント 3 個の存在**: `plugins/dev-workflow/agents/roadmap-analyst.md`、`roadmap-planner.md`、`roadmap-retrospective-writer.md` が存在し、description フィールドと参照スキルセクションを含む
4. **新規成果物テンプレート 4 個の存在**: `plugins/dev-workflow/skills/shared-artifacts/templates/roadmap.md` / `milestone.md` / `roadmap-progress.yaml` / `roadmap-retrospective.md` が存在し、対応する書き方ガイド `references/roadmap.md` / `milestone.md` / `roadmap-progress-yaml.md` / `roadmap-retrospective.md` がそれぞれ存在する
5. **`shared-artifacts/SKILL.md` の目次更新**: 成果物一覧テーブルに `roadmap.md` / `milestone.md` / `roadmap-progress.yaml` / `roadmap-retrospective` (集約) の 4 行が追加され、1:1 対応例外リストに `roadmap-progress.yaml` ↔ `roadmap-progress-yaml.md` が追記されている
6. **既存 `progress.yaml` テンプレートの後方互換拡張**: `templates/progress.yaml` に `roadmap: null` (ネストブロック構造、roadmap 配下サイクルでは `{id, milestone: {id}}` のオブジェクト) のフィールドが追加され、`references/progress-yaml.md` で「`roadmap == null` は独立サイクル / `roadmap` non-null では `roadmap.id` および `roadmap.milestone.id` が必須 / `roadmap == null` で `milestone` 相当を単独で書く形は不正」と明記されている。既存サイクル (リネーム後パス `docs/workflow/2026-04-26-add-qa-design-step/progress.yaml`) の差分は 0 (遡及修正なし)
7. **`dev-workflow/SKILL.md` の追記 (起動時連携)**: 「ワークフロー開始時」セクションに「roadmap 配下のマイルストーンから起動された場合は `<identifier>` をマイルストーン ID と紐付け、`progress.yaml` の `roadmap` ブロックを `{id, milestone: {id}}` で初期化する」旨の段落が 1 つ以上追加されている
8. **`dev-workflow/SKILL.md` の追記 (`roadmap-progress.yaml` 更新プロトコル)**: 「`roadmap-progress.yaml` 更新プロトコル」セクションが新設され、(a) サイクル開始時の `in_progress` 遷移、(b) 各ステップ完了時の進捗サマリ反映、(c) サイクル完了時 (= **Step 9 Retrospective 完了時**) の `completed` 遷移、(d) 更新時のコミット粒度、(e) `roadmap == null` の場合のスキップ規則、の 5 点が明文化されている。観測判定: `grep -nF "roadmap-progress.yaml" plugins/dev-workflow/skills/dev-workflow/SKILL.md` の結果が 3 件以上 (セクション見出し + プロトコル本文の複数言及で複数件出る前提)
9. **README 更新**: `plugins/dev-workflow/README.md` に `dev-roadmap` スキルの存在と「1 サイクル超の大規模開発を束ねる戦略層」としての位置づけが 1 段落以上で記述されている
10. **`references/roadmap-progress-yaml.md` の必須セクション**: 「`dev-workflow` 側からの更新プロトコル」セクションが存在し、何を (フィールド) / いつ (タイミング) / どう書くか (遷移ルール・コミット粒度・並行サイクル時の競合回避) の 3 観点を全て含む
11. **仮想マイルストーン分解の説明性 (手動目視)**: 完成した `dev-roadmap/SKILL.md` および `references/roadmap.md` / `milestone.md` を読んだ Main / ユーザーが、**任意の 1 つの仮想ゴール (例: "OAuth 認証導入") を入力として、3 つ以上のマイルストーン分解と各マイルストーンの定性的到達点・依存関係を抽出する手順**を、追加情報なしに説明できる (Validation で 1 例を作成し、手順が一意に決まることを目視確認)
12. **既存サイクル動作の非破壊性 (mv 後の内容不変)**: 本サイクル開始基準点 (= main マージ直後の `HEAD`、`progress.yaml` の `rollbacks[0].at` 時点に対応) を基準として、本サイクルの全 diff 適用後に**リネーム後パス `docs/workflow/2026-04-26-add-qa-design-step/`** の各成果物 (`intent-spec.md` / `design.md` / `qa-design.md` / `qa-flow.md` / `task-plan.md` / `progress.yaml` / 等) について、`git diff --find-renames <baseline>..HEAD -- docs/workflow/2026-04-26-add-qa-design-step/` の結果に**内容差分 (リネーム以外の変更行) が 0** であること。リネーム自体 (`docs/dev-workflow/` → `docs/workflow/`) は本サイクル Step 6 implementer の最初のタスクで `git mv` により実施されるため、`--find-renames` でパス変更のみが検出される状態を許容する
13. **Specialist 一覧整合性**: main マージ後の `specialist-common/SKILL.md` の Specialist 列挙 (`intent-analyst, researcher, architect, qa-analyst, planner, implementer, reviewer, validator, retrospective-writer` の 9 specialists、Self-Review 統合により `self-reviewer` は削除済) に `roadmap-analyst` および `roadmap-planner` が追加されている、もしくは roadmap 系 Specialist は別系統として明示的に区別されている (どちらかの方針を `specialist-common` で明文化)
14. **ディレクトリ構造の独立性**: `docs/roadmap/<roadmap-id>/` が `dev-roadmap/SKILL.md` と `shared-artifacts/SKILL.md` の保存構造セクションで明記され、`docs/workflow/<identifier>/` と並列配置である旨が図示または説明されている。あわせて roadmap retrospective が `docs/retrospective/<roadmap-id>.md` (集約形式) に保存される旨も明記されている

## 制約

### 技術的制約

- 全成果物は Markdown / YAML 形式とし、追加の build ツールやレンダラを要求しない
- ロードマップ依存グラフは Mermaid コードブロックで表現可 (GitHub 標準レンダラに依存、追加ツール不可)
- スキル frontmatter のスキーマは既存 `dev-workflow` 系スキルと同一 (name / description / metadata: { author })

### 規範的制約

- `dev-workflow` の基本方針 (Main-Centric Orchestration / One-Shot Specialist & Within-Step Persistence / Gate-Based Progression / Artifact-Driven Handoff / Project-Rule Precedence / Commit-Based Resumability / Clean-Transition / Artifact-as-Gate-Review / Report-Based Confirmation for In-Progress Questions) を `dev-roadmap` も全継承する
- 既存 ADR `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md` の Decision (フラット step リスト構造 / 責務分離による specialist 配置) と矛盾しないこと
- 既存 ADR `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md` の枠組み内で、roadmap は「workflow より上位の戦略層」を新設するものであり、workflow 自体のステップ構造変更ではない (workflow は main マージ後の **9 ステップ**体系のまま、Self-Review 廃止/External Review 統合は別サイクルで完了済)。本サイクルが行う `docs/dev-workflow/` → `docs/workflow/` のリネームはディレクトリ命名のみの変更でステップ構造には影響しない
- monorepo 共通の memory rules: `gsed` 使用 (`macos-cli-rules`)、`2>&1` 不使用、`vp run` 経由のコマンド優先、`as` 型アサーション禁止 (TS 該当時)、git commit は sandbox 外実行
- ドキュメント言語: 英語 (skill / template / reference / agent description)、ただし本 Intent Spec / 既存 SKILL.md の本文は日本語を踏襲

### 組織的制約

- レビュー単位: 各ステップ完了時に成果物そのものをユーザーに提示してレビュー依頼 (本サイクルはユーザー単独レビュー)
- 期限なし (ユーザーの判断ペースに合わせる)

## 関連リンク

- 既存 ADR: `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md` (本サイクルの前提となるリネーム + フラット化決定)
- 既存スキル本体: `plugins/dev-workflow/skills/dev-workflow/SKILL.md`
- 既存 Specialist 群: `plugins/dev-workflow/skills/specialist-*` (継承パターンの参照源)
- 既存 shared-artifacts: `plugins/dev-workflow/skills/shared-artifacts/SKILL.md`
- 先行サイクル (構造の参照): `docs/workflow/2026-04-26-add-qa-design-step/intent-spec.md` (リネーム後パス、新ステップ・新成果物追加の先例)
- 関連完了サイクル: `docs/workflow/2026-04-29-integrate-self-review-into-external/` (Self-Review を External Review に統合し dev-workflow を 9 ステップ化、`specialist-self-reviewer/` および `agents/self-reviewer.md` を削除)
- 関連完了サイクル: `docs/workflow/2026-04-29-retro-cleanup/` (retrospective 保存先を `docs/dev-workflow/<id>/retrospective.md` から `docs/retrospective/<id>.md` 集約形式へ移行)
- 過去の議論: 本会話の Plan モード議論 (論点 A vs 論点 B、ユーザーは A 寄りを採用) および intent-analyst 経由の Q1〜Q5 確定 (1:1 推奨 / 1:N 許容、identifier 完全独立、retrospective 流用、`docs/dev-roadmap/` 並列配置、テスト専用 workflow を作らず通常マイルストーンで表現、`dev-workflow` 側からの `roadmap-progress.yaml` 自律更新プロトコル採用)。さらにユーザー承認ゲート時の指示により、`progress.yaml` への追加スキーマをフラット 2 フィールド (`roadmap_id` / `milestone_id`) からネスト構造 (`roadmap.id` / `roadmap.milestone.id`) に変更。**main マージ後の前提崩壊により Step 1 ロールバック実施 (2026-04-29T07:00Z)、保存先 `docs/dev-workflow/` → `docs/workflow/` および `docs/dev-roadmap/` → `docs/roadmap/` に変更 (スキル名は `dev-workflow` / `dev-roadmap` 維持)、9 ステップ体系および retrospective 集約保存形式へ追従**

## 未解決事項

Step 1 で確定した方針を前提に、Step 2 Research / Step 3 Design で確認・決定する技術論点のみを残す (ユーザー判断論点 Q1〜Q5 は確定済み):

1. **既存 `specialist-common` 列挙への追加可否**: roadmap 系 Specialist を `specialist-common` の Specialist 一覧に統合するか別系統として扱うかは、Step 2 Research で `specialist-common/SKILL.md` の現状記述を精査した上で Step 3 Design で確定
2. **roadmap の再開プロトコル**: `dev-workflow` のセッション再開プロトコル (`progress.yaml` を読み込み文脈再構築) を roadmap 用にアダプトする必要があるかどうか、要件定義は Step 3 Design で行う
3. **マイルストーン間依存グラフの記述形式**: Mermaid `flowchart LR` で起草を仮定。サイクル検知や順序検証の Lint ツール導入は不要 (手動目視)
4. **`roadmap-progress.yaml` 更新時の競合回避**: 1:N 許容方針 (Q1) に伴い、複数の `dev-workflow` サイクルが同一マイルストーンに紐付いて並行進行する場合の `roadmap-progress.yaml` 同時更新の競合回避ルールが必要。git ベースのマージ任せにするか、明示的なファイルロック/シリアライズ記法 (例: 1 マイルストーン = 1 セクション/サイクル単位の追記専用構造) にするかを Step 3 Design で決定
5. **`retrospective-writer` 流用可能性の検証**: Q3 で「流用前提」が確定したが、roadmap 単位の retrospective が workflow 単位の `references/retrospective.md` の品質基準にどこまで適合するかを Step 2 Research で精査。流用不可と判定された場合のみ Step 3 Design で `specialist-roadmap-retrospective-writer` の新設可否を再判定
6. **`dev-workflow/SKILL.md` 既存セクションへの統合方針**: 「`roadmap-progress.yaml` 更新プロトコル」セクションを既存のどのセクション群と関連付けて配置するか (例: 「ステップ完了時のコミット規約」と隣接、「ワークフロー開始時」直後、独立トップレベル等) は Step 3 Design で決定
7. **retrospective 集約形式における `<roadmap-id>` と `<identifier>` の命名衝突回避**: `dev-workflow` retrospective が `docs/retrospective/<identifier>.md`、`dev-roadmap` retrospective が `docs/retrospective/<roadmap-id>.md` と同一ディレクトリへ集約されるため、両者の ID 名前空間を構造的に分離する必要がある (例: roadmap 側に `roadmap-` prefix を付与、または別サブディレクトリ `docs/retrospective/roadmap/<roadmap-id>.md` を採用)。具体方針は Step 3 architect が `dev-roadmap/SKILL.md` および `references/retrospective.md` で確定
