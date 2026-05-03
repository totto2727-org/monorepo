# Research Note: existing-skill-structure

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Topic:** existing-skill-structure
- **Researcher:** researcher (existing-skill-structure)
- **Created at:** 2026-04-29T00:00:00Z
- **Scope:** 既存 dev-workflow プラグインのスキル構造・記述パターン・スキーマを精査し、`dev-roadmap` 系スキル / 新規 Specialist / 新規成果物テンプレート / `dev-workflow` SKILL の追記が既存構造とどう整合するかを明らかにする。Intent Spec 未解決事項 #1 (specialist-common 列挙への追加可否) / #3 (Mermaid 記述形式) / #6 (`dev-workflow/SKILL.md` 既存セクションへの統合方針) を主要対象とし、付随して shared-artifacts 構造と agents 配下の最小要件も整理する。

## 調査対象

本 Research Note が扱うのは、Intent Spec の以下の論点に対応する**構造的整合性**の事実調査である。

- 論点 1: `specialist-common/SKILL.md` における Specialist 列挙の現状記述精査 (Intent Spec 未解決事項 #1, 成功基準 #13)
- 論点 2: `dev-workflow/SKILL.md` のセクション構造と「`roadmap-progress.yaml` 更新プロトコル」セクション挿入位置の選択肢 (Intent Spec 未解決事項 #6, 成功基準 #7・#8)
- 論点 3: マイルストーン依存グラフの Mermaid 記述形式 (Intent Spec 未解決事項 #3, 制約「Mermaid コードブロックで表現可」)
- 論点 4: `shared-artifacts/SKILL.md` の構造と新規テンプレート/リファレンス追加パターン (Intent Spec 成果物追加項目 / 成功基準 #4・#5)
- 論点 5: `agents/` 配下のエージェント定義パターン (Intent Spec 新規エージェント定義 / 成功基準 #3)

スコープ外 (他の researcher が担当): retrospective-writer 流用可否 (論点 5 の扱う agent 形式以外の中身検証は別)、再開プロトコル設計、`roadmap-progress.yaml` 並行更新の競合回避、設計判断そのもの。

## 発見事項

### 論点 1: `specialist-common/SKILL.md` の Specialist 列挙

- F1-1. **Specialist 列挙は frontmatter `description` フィールド内 (`specialist-common/SKILL.md:5-6`) と「Do NOT use for:」記述 (`specialist-common/SKILL.md:13-15`) に文章として記述される**。テーブルではなくカンマ区切りリストかつスラッシュ区切りリスト。
  - L5: `エージェント (intent-analyst, researcher, architect, planner, implementer, self-reviewer,`
  - L6: `reviewer, validator, retrospective-writer) が継承する共通ルールを定義する。`
  - L13-15: `個別 Specialist の役割手順（specialist-intent-analyst / specialist-researcher / specialist-architect / specialist-planner / specialist-implementer / specialist-self-reviewer / specialist-reviewer / specialist-validator / specialist-retrospective-writer）`
- F1-2. **本文の Specialist 列挙は限定的**で、`specialist-common/SKILL.md:24` に「個別役割（`specialist-intent-analyst` 等）」とパターン省略表記がある (`等` で列挙打ち切り)。本文で具体名が出るのは以下のみ:
  - L159 `（例: researcher が設計判断をする、implementer が Intent Spec を書き換える）` (スコープ侵食の例示)
  - L169 `同一ステップで並列起動される Specialist（researcher / implementer / reviewer 等）` (並列例示)
  - L182, L187, L189 `implementer` (Git ガードレールの対象として実名指定)
- F1-3. **Intent Spec 内の現状認識** (`docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:111`) では、列挙対象として `qa-analyst` も含めた 10 名 (`intent-analyst, researcher, architect, planner, qa-analyst, implementer, self-reviewer, reviewer, validator, retrospective-writer`) を「具体的に追加されるべき場」として捉えている。一方、`specialist-common/SKILL.md` 自体には **`qa-analyst` の具体名が現状一度も登場しない** (`ggrep` でゼロ件)。`specialist-qa-analyst/SKILL.md` というスキル本体は存在する (`plugins/dev-workflow/skills/specialist-qa-analyst/`) ものの、`specialist-common` 側のリストは Step 4 追加サイクル (`docs/dev-workflow/2026-04-26-add-qa-design-step/`) 時点で更新されていない。
- F1-4. **Specialist 列挙の意味合い**は `specialist-common/SKILL.md:22-24` の宣言「このスキルは全 Specialist が継承すべき横断ルールをまとめる。個別役割（`specialist-intent-analyst` 等）はこれを前提に、**固有の入力・手順・失敗モード・スコープ外事項のみ記述**する」から、**「このルール集が継承される対象 Specialist 一覧」**であって、「10 ステップに対応する Specialist」ではない。すなわち**ステップ数とは独立したリスト**。
- F1-5. `specialist-common` の本文構造はステップ番号 0〜10 のフラットなセクション群 (`specialist-common/SKILL.md` headings: `## 0.` `## 1.` … `## 10.`) であり、Specialist の系統 (workflow / roadmap) を分けるための `### サブグループ` 構造は現状存在しない。

### 論点 2: `dev-workflow/SKILL.md` のセクション構造

- F2-1. `dev-workflow/SKILL.md` のトップレベル `##` セクション一覧 (`dev-workflow/SKILL.md` headings):
  - L25: `## 基本方針`
  - L56: `## 役割定義`
  - L97: `## ワークフロー全体図`
  - L125: `## ステップ一覧`
  - L144: `## ステップ詳細` (L148-565 の Step 1〜10 + 中間補助 = 11 サブセクション)
  - L569: `## 調整プロトコル (Main ↔ Specialist)` (5 サブセクション: ワークフロー開始時 / ステップ実行ループ / ゲート通過時 / Blocker / セッション再開時)
  - L638: `## 成果物テンプレート・保存構造・進捗記録フォーマット`
  - L657: `## プロジェクト固有ルールとの関係`
  - L708: `## ステップ完了時のコミット規約`
  - L779: `## 並列起動のガイドライン`
  - L796: `## 逸脱時のリカバリ`
  - L839: `## このスキルが扱わないこと`
- F2-2. **「ワークフロー開始時」の所在**: `## 調整プロトコル (Main ↔ Specialist)` 配下の `### 1. ワークフロー開始時` (L571-579)。番号付き 5 段落 (1. ユーザーが Main に開始指示 / 2. 再開可能サイクル確認 / 3. `<identifier>` 命名合意 / 4. `progress.yaml` 初期化 / 5. Step 1 着手) で構成。Intent Spec 成功基準 #7 で要求される「`progress.yaml` の `roadmap` ブロック初期化」の段落は、**この 5 段落の流れ (特にステップ 4「`progress.yaml` 初期化」の中、または直後)** に挿入するのが論理的に最も自然 (= roadmap ブロック初期化は progress.yaml 初期化の 1 部分として位置付けられる)。
- F2-3. **「ステップ完了時のコミット規約」の構造** (L708-776):
  - L712 `### 原則` (1 ステップ = 1 コミットなど)
  - L720 `### ステップ別コミット内訳` (テーブルで Step 1-10 のコミット内容を列挙)
  - L741 `### ユーザー承認ゲート通過時`
  - L748 `### コミットメッセージ規約`
  - L760 `### コミット前チェック`
  - L771 `### 一時ファイルの扱い`
  - **既存テーブル (L722-734) は `progress.yaml` を全 Step に登場させる構造**であり、`roadmap-progress.yaml` を「各 Step で更新される」と書くなら同テーブルへの追記が一貫的。ただし「`roadmap == null` ではスキップ」という条件が混じるため、テーブル内に注釈を入れるか、別テーブル/別セクションに切り出すかの設計選択が発生する。
- F2-4. **新規セクション「`roadmap-progress.yaml` 更新プロトコル」の挿入候補位置の比較**:

  | 候補                                                                              | 既存セクションとの論理的連続性                                                                     | 読み手の探しやすさ                                                             | リスク                                                                                                       |
  | --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
  | (A) 「ステップ完了時のコミット規約」と隣接 (L708 直前 / 直後)                     | 高: コミット粒度・タイミングの規約と本質的に同じ系統 (「いつ / 何を更新してコミットするか」)       | 中: コミット規約の章を読む人なら自然に発見                                     | コミット規約セクションが肥大化する。`roadmap == null` 条件分岐が cohesive な「コミット規約」を散らかす可能性 |
  | (B) 「ワークフロー開始時」直後 (新規 `### 6.` として「調整プロトコル」配下に追加) | 中: 「開始時に roadmap ブロック初期化 → ステップ進行中に更新」という時系列としては自然             | 中: 調整プロトコルは Main ↔ Specialist 通信の章なので、yaml 更新規約はやや異質 | 「調整プロトコル」が yaml ファイル仕様まで巻き込む形になり、章の意味が拡散                                   |
  | (C) 独立トップレベル `## roadmap-progress.yaml 更新プロトコル`                    | 高: 新規責務 (workflow → roadmap への自律的書き込み) であり、独立した第一級概念として扱える        | 高: 目次から一発で発見可能                                                     | トップレベル章が増える (現状 11 章 → 12 章) ことによる目次の縦長化                                           |
  | (D) 「ステップ完了時のコミット規約」セクション**内**にサブセクションとして        | 高: コミット規約の `### コミットメッセージ規約` `### コミット前チェック` 等と同水準の `###` で並ぶ | 中: コミット規約の章を読まないと到達しない                                     | 「コミット規約」=「サイクル内コミット」のスコープを越えて roadmap ファイルに踏み込むため章のスコープが拡大   |

- F2-5. **既存テーブル (`## ステップ一覧` L127-138) とのインパクト**: roadmap 配下サイクルでは Step 1-10 の各完了時に `roadmap-progress.yaml` を**並行更新**する責務が増えるが、既存「主要成果物」列に常に追加すると `roadmap == null` 時にも適用される誤解を招く。「ステップ別コミット内訳」テーブル (L722-734) も同様。**「条件付き追加更新は別セクションで明文化、既存テーブルは未改変」**が後方互換性を保ちやすい。
- F2-6. Intent Spec 成功基準 #8 は `grep -nF "roadmap-progress.yaml" plugins/dev-workflow/skills/dev-workflow/SKILL.md` の結果が **3 件以上**を要求している (`docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:106`)。これは「セクション見出し + 本文での複数言及」を想定するもので、**候補 A〜D いずれを採用しても達成可能**だが、独立トップレベル化 (C) が最も自然に件数を稼げる。

### 論点 3: マイルストーン依存グラフの Mermaid 記述形式

- F3-1. dev-workflow プラグイン内の Mermaid コードブロック実利用箇所 (`grep -rni 'mermaid|flowchart|graph T|graph L'` 結果より):
  - `templates/task-plan.md:50` `graph LR` (タスク依存グラフ)
  - `references/task-plan.md:43` `graph LR` (説明)
  - `templates/qa-flow.md:31, 44, 60, 72` `flowchart TD`
  - `references/qa-flow.md:59, 102, 113, 126, 156, 196` `flowchart TD`
  - `templates/design.md:31` `mermaid` (種別未指定の `{{component_diagram}}` プレースホルダ、コンポーネント図用)
- F3-2. **`graph LR` と `flowchart TD` の使い分けが既に確立**している:
  - **`graph LR` (左→右)**: タスク依存グラフ (`task-plan.md`)。前→後の処理順序、DAG の流れを左から右に追える視覚レイアウト。
  - **`flowchart TD` (上→下)**: ロジック分岐 (`qa-flow.md`)。判断ノード `{Cond?}` と分岐ラベル `-->|true|` でテストケース葉を上から下にぶら下げる構造。
- F3-3. **マイルストーン依存グラフの最適な記法**: `task-plan.md` のタスク依存グラフ (`graph LR`) と**性質が同型** (DAG / 順序 / 並列許容) のため、**`graph LR` (もしくは `flowchart LR`) を採用するのが既存パターンと整合的**。Intent Spec 未解決事項 #3 (`docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:150`) も「Mermaid `flowchart LR` で起草を仮定」と仮置きしている。
- F3-4. **`graph` と `flowchart` の差分**: Mermaid 公式ではどちらも flowchart を生成するが、`flowchart` が新しい構文・サブグラフ等の新機能対応版。既存 `task-plan.md` は古い `graph LR` 系を採用しているため、**新規追加で `flowchart LR` を採用すると同じ DAG 用途で表記が分裂する**問題が起こりうる。Intent Spec の仮置き (`flowchart LR`) と既存パターン (`graph LR`) の差を Step 3 で明示的に意思決定する必要あり。
- F3-5. **cycle 検知**: `qa-flow.md` の `references/qa-flow.md:5-6` は「テストの分岐構造をレビュアーが俯瞰できる形で図示することで、テスト網羅性確認の認知負荷を下げる」と明記しており、**Mermaid 自体には cycle 検知機能はない (手動目視が前提)**。`task-plan.md` の `references/task-plan.md:67` 「依存関係が非循環」も品質基準として手動目視で担保。Intent Spec 未解決事項 #3 「サイクル検知や順序検証の Lint ツール導入は不要 (手動目視)」と整合する。
- F3-6. **ノード数上限の知見**: `references/qa-flow.md:167` 「1 つの flowchart で **15〜20 ノードを超える**と視覚的に追いにくい」「30 ノード超で読みにくい」(L208) と明記済み。マイルストーン依存グラフでも同基準を適用するのが既存パターンと整合的。

### 論点 4: shared-artifacts の構造と新規テンプレート/リファレンス追加パターン

- F4-1. **References の見出し構造は完全に統一されている** (`grep "^#|^##"` 結果より、6 ファイル横並び比較):
  - `# Reference: <name> の書き方`
  - `## 目的`
  - `## 作成者 / 作成タイミング` (or `## 作成者 / 更新タイミング` for 永続記録系)
  - `## ファイル位置`
  - `## 各セクションの書き方` (or `## 各フィールドの書き方` for YAML 系)
  - `## 品質基準`
  - `## 関連成果物`
  - 任意の補助章 (例: `design.md` の `## ADR 起票の判定基準` L87 / `todo.md` の `## TaskCreate との同期ルール` L70 / `retrospective.md` の `## データソース（入力として必要）` L93)
- F4-2. **Templates にはフロントマターがない**。1 行目はそのまま `# <ArtifactType>: {{title or identifier or topic}}` 形式の Markdown 見出しから始まる (`templates/*.md` の 1 行目を一覧確認: 全 12 ファイル共通)。`templates/progress.yaml` のみ YAML 直書き。
- F4-3. **テンプレートのプレースホルダ規約**: `{{name}}` 形式 (`shared-artifacts/SKILL.md:78` 「プレースホルダは `{{name}}` 形式（将来 EJS 等に移行可能）」)。`progress.yaml` のみ YAML 互換のため空白入りの `{ { identifier } }` 形式 (`templates/progress.yaml:1-3`) が採用されている。
- F4-4. **1:1 対応の例外リストは目次直下** (`shared-artifacts/SKILL.md:24-29`) に記述:
  - L26 `references/progress-yaml.md` ↔ `templates/progress.yaml`
  - L27 `references/todo.md` ↔ `templates/TODO.md`
  - L29 「これら 2 件以外で同名対応が崩れる成果物を追加してはならない」と例外追加を明示的に禁止
- F4-5. Intent Spec (`docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:53-54`) では `roadmap-progress.yaml` ↔ `roadmap-progress-yaml.md` を**3 件目の例外として追加する**方針が確定済み。これは F4-4 の禁止記述自体を更新する必要があることを意味する (現状: 「これら 2 件以外で同名対応が崩れる成果物を追加してはならない」→ 「これら 3 件以外で…」へ)。
- F4-6. **成果物一覧テーブルの拡張箇所** (`shared-artifacts/SKILL.md:39-55`): 現在 13 行 (`progress.yaml`〜`retrospective.md`)。新規 `roadmap.md` / `milestone.md` / `roadmap-progress.yaml` の 3 行を追加する場合、ステップ列の値が `dev-roadmap` ステップ (1-4) になるため、**既存の `Phase / Step` 列の意味が拡張**される (現状は `dev-workflow` の Step のみを想定)。
- F4-7. **保存構造セクション (`shared-artifacts/SKILL.md:105-164`)**: 「サイクル作業ディレクトリ」を `docs/dev-workflow/<identifier>/` 配下と定義 (L107)。`docs/dev-roadmap/<roadmap-id>/` を併記する場合、L109 の `### ディレクトリ構造` ツリー図に**第二のツリー (roadmap 用) を追加**する形式が最も既存パターンと整合する。L148-163 の `### サイクル外の成果物` 内に「プロジェクト横断 ADR」「In-Progress 一時レポート」を列挙する構造があるが、`roadmap` は**サイクル**ではなく**サイクルの上位**であるため、サイクル外成果物として扱うのは概念上不正確。**新規見出し `### roadmap 作業ディレクトリ` を追加する**のが妥当。
- F4-8. Intent Spec 成功基準 #14 (`docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:112`) は「`docs/dev-roadmap/<roadmap-id>/` が `dev-roadmap/SKILL.md` と `shared-artifacts/SKILL.md` の保存構造セクションで明記」を要求。両者で重複的に書く必要がある (DRY 違反だが構造上やむを得ない)。

### 論点 5: agents/ 配下のエージェント定義パターン

- F5-1. **agents/\*.md の frontmatter は `description` 単一フィールドのみ** (`agents/architect.md:1-6`, `agents/intent-analyst.md:1-6`, `agents/planner.md:1-6`, `agents/researcher.md:1-6`, `agents/retrospective-writer.md:1-9` 等で確認)。`name` / `metadata` / `tools` 等は記述されない。これは `plugins/dev-workflow/skills/*/SKILL.md` の frontmatter (`name` + `description` + `metadata: {author, version}`) とは異なる。
- F5-2. **本文構造は完全に統一**:
  - L8 (例: `architect.md:8`): `# <agent-name>`
  - 直後 1 行: `dev-workflow Step <N> (<StepName>) 専門エージェント。**1 サイクル = 1 インスタンス**(...)` 形式の概要
  - L12-15: `## 参照スキル` セクション (リスト形式: `- specialist-common — ...` / `- specialist-<role> — ...` の 2 行)
  - L17: `このエージェントが起動されたら、上記スキルを読み込んで作業を進めること。` の必須インストラクション (全 agents 共通の文言)
  - L19-25: `## 概要` テーブルまたはリスト形式 (担当ステップ / 成果物 / 書き方ガイド / テンプレート / 並列起動)
  - L27-: `## Main への要求` セクション (番号付き要求項目リスト)
- F5-3. **`description` の語彙パターン**: 「dev-workflow Step <N> (<StepName>) 担当の専門エージェント。<役割の 1〜2 文要約>。Main がサブエージェントとして起動する。並列起動は<する/しない>(...)。」の構造で全 10 ファイル統一。`retrospective-writer.md:7-9` は `Do NOT use for:` 節も含む例外的拡張版 (内容が他と紛らわしい場合のみ追加)。
- F5-4. **`qa-analyst.md` の追加された主要な責任範囲セクション** (`agents/qa-analyst.md:47-56`) は他 agents には存在しない例外。Step 4 サイクルで導入されたパターンで、agent が複数成果物 (qa-design.md + qa-flow.md) を扱う場合に責任範囲を明示するための追加章。Step 4 が複数成果物を扱う唯一のステップであるため、**`roadmap-planner` (milestone.md 群 + roadmap.md 内依存グラフ更新の両方を担う)** にも同様のパターンが適用可能。
- F5-5. **新設エージェントの最小要件** (Intent Spec 成功基準 #3 の「description フィールドと参照スキルセクション」と F5-2 の構造から):
  - frontmatter: `description: >` 単一フィールド (`name` 等は不要、ファイル名がそのまま agent 名扱い)
  - 本文: `# <agent-name>` / 概要 1 文 / `## 参照スキル` (specialist-common + specialist-<role>) / 必須インストラクション文 / `## 概要` / `## Main への要求`
  - 任意: `## 主要な責任範囲` (qa-analyst パターン、複数成果物扱い時)
- F5-6. agents/ 配下に**新規 agent を追加するための「目次」「インデックスファイル」は存在しない**。`gls plugins/dev-workflow/agents/` の出力が事実上のリスト。`plugin.json` 等での明示的な enumeration はない (構造的に `agents/*.md` 全件が自動検知される前提)。

## 引用元

- Intent Spec: `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md`
  - L53-54: 1:1 例外追加方針
  - L62-63: 既存セクションへの追記方針
  - L106: 成功基準 #8 (grep 件数判定)
  - L111: 成功基準 #13 (Specialist 列挙整合性)
  - L112: 成功基準 #14 (ディレクトリ構造の独立性)
  - L150: 未解決事項 #3 (Mermaid 形式)
  - L153: 未解決事項 #6 (`dev-workflow/SKILL.md` 統合方針)
- `plugins/dev-workflow/skills/specialist-common/SKILL.md`
  - L5-6: frontmatter description 内 Specialist 列挙
  - L13-15: Do NOT use for 内 specialist-\* スキル名列挙
  - L22-24: 「全 Specialist が継承すべき横断ルール」宣言
  - L159, L169: 本文での個別 Specialist 名言及
  - L182, L187, L189: implementer 専用 Git ガードレール
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md`
  - L25, L56, L97, L125, L144, L569, L638, L657, L708, L779, L796, L839: トップレベル `##` 見出し位置
  - L127-138: ステップ一覧テーブル
  - L571-579: ワークフロー開始時 5 段落
  - L722-734: ステップ別コミット内訳テーブル
- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md`
  - L24-29: 1:1 対応の例外リストと例外追加禁止記述
  - L39-55: 成果物一覧テーブル (13 行)
  - L78: プレースホルダ規約 `{{name}}`
  - L105-164: 成果物保存構造セクション
  - L148-163: サイクル外の成果物
- `plugins/dev-workflow/skills/shared-artifacts/references/`
  - `intent-spec.md:1, 3, 7, 13, 17, 61, 70`: 標準見出し構造
  - `design.md:1, 3, 7, 13, 17, 78, 87, 100`: 標準 + ADR 起票判定基準 (L87) の任意章
  - `research-note.md:1, 3, 7, 13, 19, 53, 62`: 標準見出し構造
  - `task-plan.md:42-47`: `graph LR` Mermaid 例
  - `task-plan.md:67`: 「依存関係が非循環」品質基準
  - `qa-flow.md:5, 19, 28, 49, 58-65, 167, 208`: `flowchart TD` 採用と分割指針
  - `progress-yaml.md:1, 3, 7, 13, 17, 88, 97`: 標準見出し構造 (「各セクション」が「各フィールド」に置換)
  - `todo.md:1, 3, 7, 13, 17, 70, 78, 87`: 標準 + TaskCreate 同期ルール (L70) の任意章
  - `retrospective.md:1, 3, 7, 13, 17, 84, 93, 103`: 標準 + データソース (L93) の任意章
- `plugins/dev-workflow/skills/shared-artifacts/templates/`
  - `progress.yaml:1-3`: YAML 内プレースホルダ `{ { identifier } }` 形式
  - `task-plan.md:50`: `graph LR` 採用
  - `qa-flow.md:31, 44, 60, 72`: `flowchart TD` 採用 (4 ブロック)
  - `design.md:25-33`: コンポーネント図 (`{{component_diagram}}` プレースホルダ、種別未指定 mermaid)
- `plugins/dev-workflow/agents/`
  - `architect.md:1-35`: 標準構造例 (frontmatter description のみ + `## 参照スキル` + 必須文 + `## 概要` + `## Main への要求`)
  - `intent-analyst.md:1-36`: 同上 (description に「並列起動はしない」を明記)
  - `planner.md:1-10`: 同上
  - `researcher.md:1-37`: 並列起動「高推奨」明記の例
  - `retrospective-writer.md:1-40`: `Do NOT use for:` 節を含む拡張版
  - `qa-analyst.md:1-57`: 複数成果物 (qa-design.md + qa-flow.md) を扱う agent の例 (`## 主要な責任範囲` セクション L47-56 の例外章)

## 設計への含意

Step 3 architect が以下の判断に直接利用可能。

### A. 論点 1 (Specialist 列挙) への含意

- **A-1. F1-2 / F1-3 から、`specialist-common/SKILL.md` の Specialist 列挙は frontmatter `description` の 1 箇所と「Do NOT use for」内の `specialist-*` スキル名列挙の 1 箇所に集中している (本文には限定的言及のみ)**。よって roadmap 系 Specialist の追加は、これら 2 箇所を更新するだけで構造的整合性を確保できる。本文の影響範囲は最小。
- **A-2. F1-3 から、現状リスト自体が `qa-analyst` (Step 4 で導入済) を反映し損ねている技術的負債がある**。本サイクルで Specialist 列挙を更新する際、**(I) `qa-analyst` を含めて 10 名 + roadmap 系 2 名 = 12 名に揃える** か **(II) qa-analyst の追加漏れを別 ADR 扱いにし本サイクルでは roadmap 系のみ追加** かの選択肢が発生。Intent Spec 成功基準 #13 の言い回し (「`intent-analyst, researcher, architect, planner, qa-analyst, implementer, ...` に追加されている」) は **qa-analyst が既に含まれた前提**で書かれており、(I) を採用するのが Spec との整合性が高い。
- **A-3. F1-4 から、Specialist 列挙は「ステップ数とは独立した、継承される対象 Specialist のリスト」**。よって「dev-workflow 用 Specialist (10 名) + dev-roadmap 用 Specialist (2 名) は同列の継承対象」として 1 つのリストに統合可能。Intent Spec 未解決事項 #1 の (A) 案 (同列挙に統合) を採用するのが既存構造と最小摩擦。
- **A-4. F1-5 から、roadmap 系を別系統として明示的に区別する場合は、新規 `### roadmap 系 Specialist` のような H3 サブセクションを `## 1. ライフサイクル規則` か新設 `## 11. roadmap 系 Specialist の固有事項` などで設ける必要があり、構造改変が大きい**。一方で「2 層 Specialist (workflow / roadmap) の責務差を強調したい」場合は (B) 案 (別系統明示) も論理的選択肢。
- **A-5. 推奨**: A-3 を採用し、`description` 内列挙と「Do NOT use for」内列挙の 2 箇所のみ更新 (qa-analyst も同時に追加して負債解消)。本文には特例的差異がない限り「全 Specialist」のままとし、roadmap 固有事項は `specialist-roadmap-analyst/SKILL.md` 個別に書く。

### B. 論点 2 (`dev-workflow/SKILL.md` 統合方針) への含意

- **B-1. F2-2 から、Intent Spec 成功基準 #7 の「`progress.yaml` の `roadmap` ブロック初期化」は `### 1. ワークフロー開始時` の 5 段落フロー内 (特にステップ 4「`progress.yaml` 初期化」直後) に挿入するのが最も自然**。新規セクションは不要、既存番号付き手順に新ステップを追加 (例: 4. → 4'. ← 既存 / 4''. roadmap 配下なら roadmap ブロック初期化) する形式。
- **B-2. F2-4 のセクション挿入位置候補のうち、(C) 独立トップレベル化が以下の理由で最も推奨**:
  - 新規責務 (workflow → roadmap への自律的書き込み) は既存「コミット規約」「ワークフロー開始時」のいずれとも本質的に異なる第一級概念
  - F2-6 の grep 件数要件 (3 件以上) を最も自然に達成できる
  - 「`roadmap == null` ではスキップ」という条件分岐をセクション冒頭で 1 箇所に閉じ込められる
  - 既存セクションを汚染しない (後方互換性が最大)
- **B-3. F2-3 から、(A) や (D) (コミット規約セクション内化) を採用すると「ステップ別コミット内訳」テーブルが `roadmap == null` 条件付きで肥大化し可読性が落ちる**。コミット規約は「サイクル内コミット」の責務であり、サイクル外の `docs/dev-roadmap/<roadmap-id>/roadmap-progress.yaml` への書き込みは概念的に異質。
- **B-4. F2-5 から、既存テーブル (`## ステップ一覧` / `## ステップ別コミット内訳`) は roadmap 関連で改変しないのが安全**。新規セクション側で「Step 1〜10 完了時に追加で発生する責務」をテーブルとして自前持つ形 (条件付き追加責務テーブル) を提案する。
- **B-5. 配置位置の具体案**: 現状 `## ステップ完了時のコミット規約` (L708) の**直後**に新規 `## roadmap-progress.yaml 更新プロトコル` を挿入。読み手は「コミット規約」を読んだ流れで「サイクル外の関連ファイルへの追加責務」を続けて読める。
- **B-6. Intent Spec 成功基準 #8 で要求される 5 点 (in_progress 遷移 / ステップ完了サマリ反映 / completed 遷移 / コミット粒度 / null スキップ) の章立て構造案**:
  - `### 適用条件 (roadmap == null のスキップ規則)` (5 点目)
  - `### 更新タイミングと値の遷移` (1, 3 点目: in_progress / completed)
  - `### 各ステップ完了時の進捗サマリ反映` (2 点目)
  - `### 更新時のコミット粒度` (4 点目)
  - `### 並行サイクル時の競合回避` (Intent Spec 未解決事項 #4 の領域、別 researcher 担当だが章は予約)

### C. 論点 3 (Mermaid 記述形式) への含意

- **C-1. F3-2 / F3-3 から、マイルストーン依存グラフは DAG であり `task-plan.md` のタスク依存グラフと同型のため、既存パターンの `graph LR` を採用するのが最小摩擦**。Intent Spec の仮置き (`flowchart LR`) は同等の機能を持つが、既存 `task-plan.md` との表記分裂を避けるなら `graph LR` を選ぶべき。
- **C-2. F3-4 から、もし `flowchart LR` を採用するなら、同時に `task-plan.md` も `flowchart LR` に揃える更新を別途検討する必要がある (本サイクル外でよい)**。本サイクル単独では `graph LR` が最小変更で済む。
- **C-3. F3-5 から、cycle 検知は手動目視 (Intent Spec 既決事項) であり、これは既存パターンと一致**。マイルストーン用に新たな Lint 不要。
- **C-4. F3-6 から、ノード数の目安 (15〜20 ノード以下、30 超で分割) は既存 `qa-flow.md` パターンを引用する形で `references/roadmap.md` の品質基準に書ける**。マイルストーン数の上限は明記すべき。
- **C-5. 推奨**: `references/roadmap.md` の依存グラフ章で `graph LR` を採用、`task-plan.md` の同章を引用パターンとして参照。`flowchart LR` でなく `graph LR` を選ぶ理由を 1 行で添える (「`task-plan.md` のタスク依存グラフと同表記で統一」)。

### D. 論点 4 (shared-artifacts 構造) への含意

- **D-1. F4-1 から、新規 `references/roadmap.md` / `references/milestone.md` / `references/roadmap-progress-yaml.md` は標準 7 章構造 (目的 / 作成者 / ファイル位置 / 各セクションの書き方 / 品質基準 / 関連成果物) に厳密に従うべき**。`roadmap-progress-yaml.md` のみ「各フィールドの書き方」(YAML 系標準)、Intent Spec 必須セクション「`dev-workflow` 側からの更新プロトコル」を任意章として `## 関連成果物` の前に配置。
- **D-2. F4-2 / F4-3 から、新規テンプレート 3 件は frontmatter なし、1 行目 Markdown 見出し形式を厳守**。`templates/roadmap.md` は `# Roadmap: {{title}}` または `# Roadmap: {{roadmap_id}}`、`templates/milestone.md` は `# Milestone: {{milestone_id}}`、`templates/roadmap-progress.yaml` は YAML 直書き ( `{ { roadmap_id } }` プレースホルダ形式)。
- **D-3. F4-5 から、`shared-artifacts/SKILL.md:29` の禁止記述「これら 2 件以外で同名対応が崩れる成果物を追加してはならない」は本サイクルで「これら 3 件以外で...」または「以下の例外以外で...」へ更新が必要**。Intent Spec 成功基準 #5 と整合。
- **D-4. F4-7 から、保存構造セクションには `### roadmap 作業ディレクトリ` を新設し、`docs/dev-roadmap/<roadmap-id>/` ツリー (roadmap.md / milestones/<milestone-id>.md / roadmap-progress.yaml / retrospective.md) を `### サイクル作業ディレクトリ` と並列配置する形が既存パターンと整合**。`### サイクル外の成果物` (L148) には `roadmap` を含めない (概念的に上位)。
- **D-5. F4-6 から、成果物一覧テーブルの `Phase / Step` 列は「dev-workflow Step N」と「dev-roadmap Step N」が共存する**。既存 13 行の Step 列の意味を「workflow Step」と暗黙に仮定する記述があれば、列名を「Workflow / Roadmap | Step」または注釈を追加して明確化する必要がある。最小変更案: 列名はそのままで、roadmap 系 3 行のみ Step 列を「dev-roadmap Step 1」等と prefix 付きで書く。
- **D-6. F4-8 から、`docs/dev-roadmap/<roadmap-id>/` の説明は `dev-roadmap/SKILL.md` と `shared-artifacts/SKILL.md` の両方に書く必要があり、片方からもう片方へのリンクで重複説明を避ける運用を推奨**。Single Source of Truth 候補は `shared-artifacts/SKILL.md` (成果物の保存構造はここが本籍)。

### E. 論点 5 (agents 定義) への含意

- **E-1. F5-1 / F5-2 から、新規 `agents/roadmap-analyst.md` と `agents/roadmap-planner.md` は frontmatter `description` 単一フィールド + 本文 5 章 (見出し / 参照スキル / 必須インストラクション文 / 概要 / Main への要求) を厳守**。Intent Spec 成功基準 #3 「description フィールドと参照スキルセクション」は最小要件であり、F5-2 の本文構造を全て満たすのが既存パターンとの完全整合。
- **E-2. F5-3 から、`description` の語彙テンプレート**: 「dev-roadmap Step <N> (<StepName>) 担当の専門エージェント。<役割の 1〜2 文要約>。Main がサブエージェントとして起動する。並列起動はしない (...)。」。`dev-workflow` を `dev-roadmap` に置換。
- **E-3. F5-4 から、`roadmap-planner` は milestones/\*.md 群と roadmap.md 内依存グラフの両方を更新する複数成果物 agent のため、`qa-analyst.md` パターン (`## 主要な責任範囲` 章追加) を採用すべき**。`roadmap-analyst` は単一成果物 (roadmap.md の Intent セクション) のため標準 5 章構造で十分。
- **E-4. F5-6 から、agent ファイルの追加だけで自動検知される (インデックスファイル不要)**。本サイクルでは `agents/roadmap-analyst.md` と `agents/roadmap-planner.md` の 2 ファイル追加のみで成功基準 #3 を満たす。

### F. 横断的含意

- **F-1. Intent Spec の文書言語ポリシー** (`docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:128`) は「ドキュメント言語: 英語 (skill / template / reference / agent description)、ただし本 Intent Spec / 既存 SKILL.md の本文は日本語を踏襲」だが、**既存 `references/*.md` / `templates/*.md` は全て日本語本文 + 英語見出しキーワード混在**。新規 roadmap 系成果物の言語選択で**英語主導と日本語踏襲のいずれを取るかを Step 3 で確定が必要**。既存パターンとの整合 = 日本語踏襲が最小摩擦。
- **F-2. Intent Spec が要求する progress.yaml の `roadmap` ネストブロック追加** (`intent-spec.md:59`) は `templates/progress.yaml` (現状フラット構造) と `references/progress-yaml.md` (現状 13 フィールド列挙) の両方に追記が必要。F4-1 の標準 7 章構造を維持しつつ、`### 各フィールドの書き方` 内の `### artifacts` 後に `### roadmap` ネストブロック説明を追加する位置取りが既存パターンと整合的。

## 残存する不明点

調査で解けなかった、または別 researcher 担当の論点を明記する。

- **U-1. retrospective-writer の流用可否の構造的検証**: 本観点では agent 構造 (F5-1〜F5-6) のみ調査。流用時に必要な `retrospective.md` references の roadmap 単位適用可能性は **別 researcher (流用検証担当) の領域**。本観点では retrospective-writer.md の構造が roadmap 用途にも適合可能か、formal 整合性 (frontmatter / 見出し構造) は問題ないことのみ確認 (F5-1〜F5-3 で全 agents が同構造のため)。
- **U-2. `roadmap-progress.yaml` の YAML スキーマ詳細**: Intent Spec で大枠 (マイルストーン状態 pending/in_progress/completed) は決まっているが、F2-4 の B-6 で予約した「並行サイクル時の競合回避」章の具体的書式 (例: 1 マイルストーン 1 セクション追記専用 vs git マージ任せ) は **別 researcher (並行更新競合回避担当) の領域**。本観点は yaml ファイルが追加される事実と shared-artifacts の例外リスト更新規約のみ確定。
- **U-3. dev-roadmap セッション再開プロトコルの構造**: Intent Spec 未解決事項 #2 で「`progress.yaml` を読み込み文脈再構築する dev-workflow プロトコルを roadmap 用にアダプトするかどうか」は **別 researcher (再開プロトコル担当) の領域**。本観点は `dev-workflow/SKILL.md:620-635` の `### 5. セッション再開時` セクションの位置と構造のみ事実として記録 (再開プロトコルが既に dev-workflow に存在する事実 = roadmap でも類似章を `dev-roadmap/SKILL.md` に置くかどうかの判断材料となる)。
- **U-4. Mermaid 記法選択 (`graph LR` vs `flowchart LR`) の最終判断**: F3-3 / C-1〜C-2 で既存パターン整合 (`graph LR` 推奨) と Intent Spec 仮置き (`flowchart LR`) の差を提示済み。**Step 3 architect の意思決定領域**であり、本 Research Note では事実と判断材料のみ提供。
- **U-5. Intent Spec 成功基準 #13 の `qa-analyst` 含有問題 (A-2)**: 既存 `specialist-common/SKILL.md` に `qa-analyst` が登場しない事実は本観点で確定したが、これを「本サイクルで同時修正する」か「別 ADR で扱う」かの判断は **Step 3 architect の意思決定領域**。本 Research Note では事実と選択肢のみ提示。
