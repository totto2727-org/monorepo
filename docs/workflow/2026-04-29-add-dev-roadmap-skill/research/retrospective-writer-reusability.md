# Research Note: retrospective-writer-reusability

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Topic:** retrospective-writer-reusability
- **Researcher:** researcher (Step 2 Research, single-aspect instance)
- **Created at:** 2026-04-29T03:00:00Z
- **Scope:** `specialist-retrospective-writer` を `dev-roadmap` Step 4 (Roadmap Retrospective) に流用できるか、新規 `specialist-roadmap-retrospective-writer` の追加が必要かの判定材料を Step 3 architect に提供する。Intent Spec 「未解決事項 #5」に対応。

## 調査対象

Intent Spec (`docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:41`, `:79`, `:152`) で「`retrospective-writer` を流用前提、流用不可なら新設を再判定」と明記された方針について、以下の観点から検証する:

- 既存 `specialist-retrospective-writer/SKILL.md` の役割定義が roadmap 単位の振り返りを内包できるか
- 既存 `references/retrospective.md` の書き方ガイドが roadmap 振り返り対象 (複数 workflow を集約) でも整合するか
- 既存 `templates/retrospective.md` のプレースホルダ構造が roadmap 文脈で意味を保つか
- 案 A (完全流用) / 案 B (部分流用 + モードフラグ) / 案 C (新設) の比較

スコープ外: 既存スキル群の包括的精査 (別 researcher 担当)、再開プロトコル (別 researcher 担当)、設計判断そのもの (Step 3 architect)、新規スキル/テンプレ実装 (Step 6 implementer)。

## 発見事項

### F1. `specialist-retrospective-writer` の役割定義は workflow 単位を前提

`plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md:6-7,29-30,36-43` で成果物保存先が `docs/dev-workflow/<identifier>/retrospective.md` (workflow 単位の `<identifier>`) に固定されており、サイクル全体の振り返りとして定義されている。「役割」セクション (`:34-44`) でも「サイクル全体を振り返り、次サイクル以降に活かせる知見を抽出」と記述。「サイクル」=「1 つの dev-workflow 10 ステップ完了」を前提にしており、roadmap 単位 (= 複数 workflow を束ねる戦略層) を直接想定していない。

### F2. 入力契約は workflow 内部の運用データに密着

`specialist-retrospective-writer/SKILL.md:46-54` の「固有の入力」は以下:

- サイクル全成果物 (`Intent Spec / Research Notes / Design Document / Task Plan / diff / Self-Review / Review Reports / Validation Report`)
- `progress.yaml` (全フェーズのタイムスタンプ、完了ステップ、ユーザー承認履歴、ロールバック履歴)
- `TODO.md` (re_activations カウンタ、タスク完了時間、Self-Review ループ履歴)
- Blocker 履歴 (progress.yaml の blockers フィールド)
- In-Progress ユーザー問い合わせ用一時レポート (`$TMPDIR/dev-workflow/*.md`) の件数と概要

これらは全て **1 workflow サイクル内のメタデータ**。roadmap 振り返り対象である「全マイルストーン状態 / マイルストーン依存の妥当性 / `roadmap-progress.yaml` の状態遷移履歴 / 個別 workflow `retrospective.md` 群」は入力リストに含まれていない。

### F3. 作業手順は workflow 内部のループ分析に最適化

`specialist-retrospective-writer/SKILL.md:56-79` の作業手順 (Step 2 「データ分析」, `:60-65`) は以下を分析対象とする:

- ループ回数 (Step 6 ↔ Step 7 の往復、ロールバック発生ステップと回数)
- Blocker 発生と解消の経緯
- ユーザー承認ゲートの承認 / 却下履歴
- In-Progress ユーザー問い合わせの件数 (多ければ Intent Spec 段階の明確化不足を示唆)
- Specialist 起動回数と並列度の実効

→ 全て **workflow 内部の 10 ステップ間の挙動**が対象。roadmap 視点での分析項目 (マイルストーン分解の妥当性、依存グラフの正確性、roadmap-progress.yaml の更新タイミング遅延など) は手順上明示されていない。

### F4. `references/retrospective.md` の品質基準は workflow 単位の観測データに依拠

`shared-artifacts/references/retrospective.md:34-43` (ループ回数の分析) は `Step 6 ↔ Step 7` `Step 6/7 → Step 3` という workflow 内部のステップ間遷移を品質指標としている。`:55-65` (スキル改善 / Specialist プロンプト改善) も `main-*` / `specialist-*` という個別 Specialist への改善提案を例示しており、roadmap 構造の改善 (例: マイルストーン分解粒度、`roadmap-planner` 入力契約) は項目として用意されていない。

### F5. `templates/retrospective.md` のプレースホルダは workflow Specialist 名にハードコード

`shared-artifacts/templates/retrospective.md:67-74` の「Specialist プロンプト改善」セクションには 8 つの Specialist (`intent-analyst, researcher, architect, planner, implementer, self-reviewer, reviewer, validator`) のプレースホルダが固定で並んでいる。roadmap 系 Specialist (`roadmap-analyst`, `roadmap-planner`) のスロットは存在しない。

`templates/retrospective.md:33-38` の「ループ回数の分析」テーブルも `Step 6 ↔ Step 7 / Step 6/7 → Step 3 / Step 8 → Step 6` という workflow 内部ループのみが行として定義済みで、roadmap で起こりうる「マイルストーン → 別マイルストーン依存巻き戻し」「複数 workflow が同一マイルストーンに紐付いた際の競合」等の roadmap 固有の analysis 軸は存在しない。

`templates/retrospective.md:91-95` (ユーザー承認ゲートの振り返り) も `Step 1 / Step 3 / Step 5 / Step 8 / Step 9` という workflow 単位のゲートに固定。roadmap 4 ステップ (Roadmap Intent / Milestone Decomposition / Execution / Roadmap Retrospective) のゲートとは異なる。

### F6. roadmap 4 ステップ構造には Self-Review / External Review / Validation が存在しない

Intent Spec `:74-79` の roadmap ステップ表を見ると、roadmap は 4 ステップ (Intent / Decomposition / Execution / Retrospective) のみで、workflow が持つ Step 6/7/8/9 (Implementation / Self-Review / External Review / Validation) を持たない。これにより以下のデータソースが roadmap 文脈では存在しない:

- `self-review-report.md` の修正ラウンド履歴 (`references/retrospective.md:98`)
- `review/*.md` 観点別レビュー結果 (`references/retrospective.md:99`)
- `validation-report.md` (`references/retrospective.md:100`)
- `Step 6 ↔ Step 7` 等のループ (`templates/retrospective.md:36-38`)

→ 既存テンプレを埋めると **大量に "N/A" が並ぶ**ことになり、roadmap 振り返りの本質 (マイルストーン達成度、依存グラフの妥当性、配下 workflow の集約結果) が逆に薄まる。

### F7. roadmap 振り返り対象として固有のデータソースが存在する

Intent Spec の roadmap 構造から推察される roadmap 振り返り固有の入力:

- `docs/dev-roadmap/<roadmap-id>/roadmap.md` (戦略意図、定性的到達点)
- `docs/dev-roadmap/<roadmap-id>/milestones/<milestone-id>.md` 群 (マイルストーン定義、依存グラフ)
- `docs/dev-roadmap/<roadmap-id>/roadmap-progress.yaml` (各マイルストーンの状態遷移履歴、紐付けられた `<identifier>` 群)
- 配下 workflow の `retrospective.md` 群 (Intent Spec `:79` で「`retrospective.md` (roadmap 単位)」と記載: roadmap retrospective が個別 workflow の retrospective を集約する読み方を含意)
- `docs/dev-roadmap/<roadmap-id>/` 内のコミット履歴 (マイルストーン定義の変更履歴、意図の追加調整履歴)

これらは既存 `specialist-retrospective-writer/SKILL.md:46-54` の入力契約に **1 件も含まれていない**。

### F8. 抽象構造としての「振り返り」は両者で共通

役割の本質 (「観測データに基づく因果分析」「アクション可能な改善案抽出」「再利用可能な知見の蒸留」) は workflow 振り返りと roadmap 振り返りで共通。`references/retrospective.md:5` (目的) と `:84-91` (品質基準) はどちらの単位にも適用可能なメタ規範を提供している。具体的には:

- 「観測データから因果を分析」 → workflow ではループ回数、roadmap ではマイルストーン状態遷移
- 「アクション粒度の改善案」 → workflow では Specialist プロンプト、roadmap ではマイルストーン分解粒度ガイド
- 「再利用可能な知見」 → 両者ともプロジェクト横断の学び抽出が目的

この抽象層は流用可能だが、**具体セクションの構成と入力契約は分岐が必要**。

### F9. 1:N 許容方針による集約観点の追加要件

Intent Spec `:151` (未解決事項 #4) で 1:N 許容 (1 マイルストーン ↔ N 個 workflow) が明示されている。roadmap retrospective は「1 マイルストーンに対して複数 workflow が紐付いた場合、その分解の妥当性 (なぜ 1 サイクルで完結しなかったか / 追加サイクルでどう補完したか)」を分析する必要がある。これは workflow 単位の retrospective には存在しない観点で、既存テンプレ・既存手順では捕捉できない。

### F10. 前サイクルでの retrospective 運用実績

`docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md:1-7` を見ると、当時は「Step 9 Retrospective」(旧 9 ステップ構造) として実施されており、Specialist プロンプト改善セクション (`:67-77`) には **`qa-analyst` のプレースホルダが既存テンプレに存在しない**まま `qa-analyst` 改善案が追記されている。これは「テンプレに固定された Specialist リストは新 Specialist 追加時に必ず追従更新が必要」という運用実態を示している。roadmap 系 Specialist 追加時にも同種の更新は不可避。

## 引用元

### スキル定義

- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md:1-100` (役割定義全体)
- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md:26-32` (担当ステップ・成果物・テンプレートの対応表)
- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md:46-54` (固有の入力)
- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md:56-79` (作業手順)
- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md:81-85` (出力品質基準)
- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md:94-99` (スコープ外)

### 書き方ガイド (Reference)

- `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md:1-108` (全体)
- `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md:5` (目的)
- `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md:34-43` (ループ回数分析セクション)
- `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md:55-65` (スキル改善 / Specialist プロンプト改善)
- `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md:84-91` (品質基準テーブル)
- `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md:93-101` (データソース)

### テンプレート

- `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md:1-113` (全体)
- `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md:33-38` (ループ回数分析テーブル: workflow ステップ固有)
- `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md:67-74` (Specialist プロンプト改善: 8 specialist 名がハードコード)
- `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md:91-95` (ユーザー承認ゲート: workflow ゲートに固定)

### 共通基盤

- `plugins/dev-workflow/skills/specialist-common/SKILL.md:50-60` (1 Specialist = 1 ステップ、ステップ跨ぎ禁止)
- `plugins/dev-workflow/skills/specialist-common/SKILL.md:67-78` (入力契約)
- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md:55` (retrospective.md は Step 10 の workflow 成果物として登録)

### Intent Spec (本サイクル)

- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:41` (流用前提の宣言)
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:74-81` (roadmap 4 ステップ表)
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:152` (流用可能性検証論点)
- `docs/dev-workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md:151` (1:N 許容方針による競合回避論点)

### 前サイクルの実績

- `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md:1-7` (旧構造での運用実績)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md:67-77` (qa-analyst 追加時のテンプレ追従実態)

## 設計への含意

### 案ごとの長所短所評価

#### 案 A: 完全流用 (既存 `specialist-retrospective-writer` を入力切替のみで起動)

**長所:**

- Intent Spec の「最小限変更」原則 (Intent Spec `:56`) と直接整合。新規スキル追加なし。
- メンテ対象スキル数が増えない。

**短所 (致命的):**

- 既存 `specialist-retrospective-writer/SKILL.md:29` (成果物保存先) が `docs/dev-workflow/<identifier>/retrospective.md` に固定されており、roadmap 用 (`docs/dev-roadmap/<roadmap-id>/retrospective.md`) には**素のままでは出力できない**。最低でも保存先パスのプレースホルダ化が必要。
- 既存入力契約 (F2) に roadmap 固有データソース (F7) が含まれない。Specialist が独断で入力を追加することは `specialist-common/SKILL.md:65` の「不足があれば Main に補足を求める」原則に反する。
- 作業手順 (F3) が workflow 10 ステップ前提で書かれており、roadmap 4 ステップに適用すると Step 6/7/8/9 関連のループ分析が空回りする (F6)。
- 既存テンプレ (F5) を埋めると大量の N/A が並び、roadmap 振り返りの本質を逆に薄める (F6)。

→ **採用不可**。「入力切替のみで流用」は実体として成立しない。

#### 案 B: 部分流用 (同 Specialist + モードフラグ)

具体構造: `specialist-retrospective-writer/SKILL.md` に「モード」概念を追加し、Main 起動時に `mode: workflow | roadmap` を入力に含めて切り替える。テンプレも `templates/retrospective.md` 1 本のまま、各セクションを「workflow モードのみ / roadmap モードのみ / 両者共通」に分類する条件付き記述にする。

**長所:**

- 「振り返り」という抽象役割の単一性を保てる (F8)。
- スキルファイル数が増えない。
- Intent Spec の「retrospective-writer 流用」と Specialist 数増加抑制の方針両方を満たす。

**短所:**

- `specialist-retrospective-writer/SKILL.md` の入力契約・作業手順・出力品質基準・固有失敗モードを**全て条件分岐で記述する**ことになり、SKILL.md が肥大化・可読性低下。
- テンプレも条件分岐記述になり、`shared-artifacts/SKILL.md:24` の「templates と references は同名 1:1 対応」原則が「単一テンプレが複数文脈をカバー」する形に揺らぐ。
- `specialist-common/SKILL.md:50-60` (1 Specialist = 1 ステップ) の原則と「同一 Specialist が workflow Step 10 と roadmap Step 4 の両方を担当」状態の整合性確認が必要 (どちらも「振り返り」だが異なる workflow / roadmap の異なるステップという意味では原則違反の余地がある)。
- F5 のプレースホルダ追加 (roadmap-analyst / roadmap-planner) は案 B でも案 C でも同じく必要。
- `specialist-retrospective-writer` の description (frontmatter) が `dev-workflow Step 10` に明示固定されているため (`SKILL.md:5`)、description 改訂が必要 → 既存スキルの description 大幅変更は description-based ルーティングへの影響リスクがある。

→ **採用は可能だが、肥大化と原則の揺らぎという代償がある**。

#### 案 C: 新設 `specialist-roadmap-retrospective-writer/SKILL.md` (+ 別テンプレ・別 reference)

具体構造: `plugins/dev-workflow/skills/specialist-roadmap-retrospective-writer/SKILL.md` を新規追加し、roadmap Step 4 専用の役割定義 / 入力契約 / 作業手順を持つ。テンプレも `shared-artifacts/templates/roadmap-retrospective.md` ↔ `shared-artifacts/references/roadmap-retrospective.md` を新設 (1:1 対応原則を維持)。`specialist-retrospective-writer` (workflow 用) は変更なし。

**長所:**

- 既存 `specialist-retrospective-writer` を一切変更しない (`shared-artifacts/SKILL.md` の目次行追加のみ)。Intent Spec の「最小限変更」原則は新規追加に向けられているため、既存改変ゼロは別軸の最小性として評価可。
- 1 SKILL = 1 役割の単純性を保てる (`specialist-common` の 1 Specialist = 1 ステップ原則と整合)。
- 入力契約・作業手順を roadmap 固有に最適化可能 (F7 の固有データソースを直接列挙、F9 の 1:N 集約観点を手順に組み込む等)。
- テンプレを workflow 用 / roadmap 用で別ファイル化することで `shared-artifacts/SKILL.md:24` の 1:1 対応原則を維持。
- ループ分析テーブル (F5) のセクション構成を roadmap 文脈で再設計可能。具体例として「Execution Step 中の workflow 起動間隔」「マイルストーン依存巻き戻し回数」「`roadmap-progress.yaml` の自律更新失敗回数」等の roadmap 特有メトリクスを行として定義できる。

**短所:**

- 新規スキル 1 件 + 新規テンプレ 1 件 + 新規 reference 1 件の追加。Intent Spec `:33-54` のスコープ表記には現時点で `specialist-roadmap-retrospective-writer` が**含まれていない**ため、Intent Spec 改訂が必要。
- スキル数が増えるためメンテ負荷がやや増加 (ただし両者は概念的に別単位なので、独立メンテ可能性が高い)。
- 共通の振り返り抽象 (F8) が 2 ファイルに重複する余地があり、抽象パターンを共通 reference に括り出す等の二次的整理が望ましい。

→ **概念的明快さが最も高く、既存スキル改変リスクが最小**。

### 推奨: 案 C

以下の根拠から **案 C (新設) を強く推奨**する:

1. **入力契約の根本的差異** (F2 vs F7): roadmap 振り返りの入力 (`roadmap.md`, `milestones/*.md`, `roadmap-progress.yaml`, 配下 workflow の `retrospective.md` 群, roadmap ディレクトリのコミット履歴) は workflow 振り返りの入力と**重なる成果物が 0 件**。データソースが完全に異なるものを 1 つの SKILL で扱うのは抽象漏れ (leaky abstraction) になる。
2. **作業手順の根本的差異** (F3 vs F6): workflow 振り返りは 10 ステップ間ループ分析が中核、roadmap 振り返りは 4 ステップ + 配下 workflow 集約が中核。同一手順では表現できず、案 B にすると分岐記述で SKILL が肥大化する。
3. **テンプレ構造の差異** (F5, F6): プレースホルダ構成 (Specialist 名 / ステップ名 / ゲート位置) が異なるため、1 テンプレで両者を満たすには大量の条件付きセクションが必要になり、`shared-artifacts/SKILL.md:24` の 1:1 対応原則の精神に反する。
4. **Intent Spec 改訂の許容性**: Intent Spec `:152` (未解決事項 #5) で「流用不可と判定された場合のみ Step 3 Design で `specialist-roadmap-retrospective-writer` の新設可否を再判定」と既に記述されており、新設はワークフロー上想定された分岐パス。Step 3 architect が Intent Spec 改訂提案を Main 経由でユーザー承認ゲートに乗せる流れは正規の手順。
5. **既存スキルの安定性確保**: 案 B は既存 `specialist-retrospective-writer` の description / 役割定義 / 入力契約 / 作業手順全てに条件分岐を導入し、現在 workflow Step 10 で正しく動作している既存スキルを破壊するリスクがある。前サイクル (`2026-04-26-add-qa-design-step`) は案 C 的アプローチ (qa-analyst を新設) を採用しており、運用上の前例とも整合。
6. **抽象パターンの共通化は別軸で可能**: F8 の共通抽象 (観測データ + 因果分析 + アクション粒度) は両 SKILL の本文に類似記述で書けば足りる。重複を許容するか、共通 reference (例: `shared-artifacts/references/retrospective-base.md`) を切り出すかは Step 3 architect の判断 (本研究では既存 `references/retrospective.md` の品質基準セクションを workflow 用 reference の中で「両者共通」と注記し、roadmap 用 reference から参照する軽量パターンを推奨)。

### Step 3 architect への引き継ぎ事項

- **Intent Spec 改訂の必要性**: スコープセクション (`intent-spec.md:25-93`) の以下を改訂する必要がある:
  - 「`specialist-retrospective-writer` を流用」(`:41`) → 「新規 `specialist-roadmap-retrospective-writer` を追加」に修正
  - 「新規 Specialist スキル」セクション (`:34-41`) に `specialist-roadmap-retrospective-writer` を追加 (3 件目)
  - ステップ表 (`:79`) の Step 4 担当を `roadmap-retrospective-writer × 1 (新設)` に変更
  - 成功基準 #2 (`:100`) の Specialist スキル数を「2 個」→「3 個」に変更
  - エージェント定義 (`:45-46`) に `roadmap-retrospective-writer.md` 追加要否を判定 (Intent Spec の現方針: workflow 用と同名の retrospective-writer エージェントを流用するならエージェント追加不要、別エージェント化するなら追加要)
  - 新規成果物テンプレート/書き方ガイド (`:48-54`) に `templates/roadmap-retrospective.md` ↔ `references/roadmap-retrospective.md` を追加

- **テンプレート設計の論点**: 新規テンプレ `templates/roadmap-retrospective.md` には少なくとも以下のセクションを含める想定:
  - サイクル概要 → roadmap 概要 (戦略意図、達成したマイルストーン群)
  - マイルストーン達成度サマリ (各マイルストーン: pending / in_progress / completed の最終状態と達成所要 workflow 数)
  - マイルストーン分解の妥当性振り返り (1:N 紐付けが発生した場合の分解粒度妥当性、依存グラフの正確性)
  - 配下 workflow `retrospective.md` の集約サマリ (横断的に発生したパターン、横断的改善案)
  - roadmap 構造への改善提案 (`roadmap-analyst`, `roadmap-planner` プロンプト改善 + roadmap-progress.yaml 更新プロトコルへの改善)
  - 再利用可能な知見 (workflow 用 retrospective と同様、ただし戦略層視点)

- **エージェント追加の判定**: Intent Spec `:45-46` のエージェント定義は現在 `roadmap-analyst.md`, `roadmap-planner.md` の 2 件のみ。`roadmap-retrospective-writer.md` を別エージェントとして追加するか、workflow 用の `retrospective-writer.md` (現存するか未確認) を流用するかは Step 3 で判断。新規 SKILL を追加する以上、エージェント定義の参照スキル変更は必要なため、別エージェント追加が一貫性高い。

- **抽象共通化の選択肢**: F8 の共通抽象を両 reference に重複記述するか、`references/retrospective-base.md` を共通基盤として切り出すかは Step 3 架構判断。重複を許容する場合でも、両 reference の「品質基準」「観測データ重視」記述の同期メンテ責務を Step 3 design.md で明示する必要がある。

## 残存する不明点

1. **`agents/retrospective-writer.md` の既存有無**: 本調査では `plugins/dev-workflow/agents/` ディレクトリの内容を実地確認していない。Intent Spec `:45-46` で `roadmap-analyst.md` / `roadmap-planner.md` を新規追加する既述から、既存に `retrospective-writer.md` が存在するかどうかは Step 3 architect が確認すべき (もし存在すれば、その流用 vs 新設 `roadmap-retrospective-writer.md` の判断が追加で必要になる)。

2. **配下 workflow の `retrospective.md` 群を roadmap retrospective が「集約」する際の具体的読み方**: 全件読み込んで横断パターンを抽出するのか、それぞれの「再利用可能な知見」セクションのみ抽出するのかは Step 3 で具体化が必要。本研究では F7 で「集約する読み方を含意」とまでしか踏み込んでいない。

3. **`templates/roadmap-retrospective.md` のループ分析セクション設計**: roadmap 文脈で workflow の「Step 6 ↔ Step 7」相当のループ分析がそもそも有効かは未確定。roadmap には Self-Review / External Review 相当の構造がない (F6) ため、別の analysis 軸 (例: マイルストーン依存巻き戻し回数、`roadmap-progress.yaml` 更新の遅延回数) を採用するか、ループ分析セクション自体を省略するかは Step 3 design 判断。

4. **抽象パターン共通化の最終形**: 案 C 採用時、共通 reference (`references/retrospective-base.md`) を切り出すか、両 reference に重複記述で許容するかは設計上の選択肢。本研究では「軽量パターン (重複許容 + 注記)」を Step 3 への提案として記述したが、重複量が予想以上に多い場合は共通基盤化が望ましい。Step 3 architect が両 reference の draft 草稿で重複量を見て判断する。

5. **Intent Spec 改訂のユーザー承認ゲート扱い**: 案 C 採用は Intent Spec の方針 (流用前提) を逆転させるため、Step 3 design.md 提示時に Intent Spec の改訂版を併せて提示し、ユーザー承認を得るべきか、それとも Step 3 design レビューの一部として処理可能かは Main の判断 (本研究のスコープ外)。
