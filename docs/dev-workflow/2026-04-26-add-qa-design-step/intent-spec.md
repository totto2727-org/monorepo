# Intent Spec: Add Step 4 "QA Design" to dev-workflow

- **Identifier:** 2026-04-26-add-qa-design-step
- **Author:** totto2727 (intent-analyst role assumed by Main)
- **Created at:** 2026-04-26T13:00:00Z
- **Last updated:** 2026-04-26T13:00:00Z

## 背景

現状の `dev-workflow` プラグイン (Step 1〜9) では、テスト設計が `planner` (Step 4 Task Decomposition) の責任の一部として扱われており、`task-plan.md` の各タスクに「テスト追加方針」フィールドが付くだけの薄い扱いになっている。これにより以下の問題が生じている:

1. **責務の混在:** 「成功基準を観測可能なテストケースに展開する」(品質視点) と「実装単位に切り出す」(計画視点) という独立した関心が planner に詰め込まれている。
2. **テスト設計の浅さ:** 各タスク 1 行の方針記述では、自動 vs 手動の判断、本質ロジックの分岐網羅、成功基準とのトレーサビリティを表現できない。
3. **判断軸の欠如:** 「誰が実行するか」(自動 / AI エージェント / 人間) と「何をどう確認するか」(関数アサーション / シナリオ / 観測 / 目視) を独立して扱える形が無く、選定根拠を残す場がない。
4. **可視化手段の欠如:** テストの分岐構造をレビュアーが俯瞰できる成果物がなく、抜け漏れを発見しづらい。
5. **言語/プロジェクト依存の漏出:** 既存運用では `Vitest` / `Playwright` のような具体ツール名が暗黙の前提になりがちで、別言語 / 別スタックのプロジェクトで再利用しづらい。

これは原典 AWS AI-DLC でも未解決の構造的弱点で、`dev-workflow` を独立した手法として位置づけ直した今、専用ステップとして整備するのが妥当なタイミングである。

## 目的

`Step 4 QA Design` を新設して `qa-analyst` Specialist が成功基準を観測可能なテストケース集合 (`qa-design.md`) と本質ロジックの分岐図 (`qa-flow.md`) として確定させ、`planner` を分解のみの役割に純化する。後続の `implementer` / `validator` が同じテスト設計を共通参照することで、設計→実装→検証のトレーサビリティを成果物単位で担保する。

## スコープ

- 新ステップ `Step 4 QA Design` の追加 (旧 Step 4 以降を 1 つずつ後ろにシフト、全 10 ステップに)
- 新 Specialist `qa-analyst` (skill + agent) の定義
- 新成果物 2 種:
  - `qa-design.md` (テストケース表 + 検証手段の 2 軸分類 + 配置ポリシー + 実装段階追記セクション)
  - `qa-flow.md` (本質ロジックの分岐を表現する Markdown。**1 つ以上の Mermaid コードブロック**を含み、複雑な場合は関心ごと/サブシステムごとに**複数ブロックに分割可**。各葉に TC-ID / `skip` を付与)
- **検証手段の抽象化軸 (2 軸)** を qa-design.md の列構造に組み込む:
  - 軸 A 「実行主体」: `automated` (テストランナー / スクリプト) / `ai-driven` (AI エージェント操作) / `manual` (人間)
  - 軸 B 「検証スタイル」: `assertion` (期待値検証) / `scenario` (操作フロー検証) / `observation` (メトリクス・ログ観測) / `inspection` (主観・目視)
  - 各テストケースは 2 軸の組み合わせで表現 (例: `automated × assertion`, `ai-driven × scenario`)
- `specialist-planner` から「テスト追加方針」記述を削除し、代わりに「カバーするテストケース ID」を扱う形に変更
- `specialist-implementer` の入力に `qa-design.md` と `qa-flow.md` を追加し、(a) ライブラリ制約由来の防御的テストを `qa-design.md` の専用セクションに追記、(b) 実装段階で発見された本質的な分岐 (Step 4 で予見されなかった条件分岐) を `qa-flow.md` の Mermaid コードブロックに追記する責任を付与
- `specialist-validator` の入力に `qa-design.md` / `qa-flow.md` を追加し、全 TC + qa-flow 葉カバレッジの検証責任を付与
- `dev-workflow/SKILL.md` のステップ一覧 / 図 / コミット規約 / 並列起動ガイド / ロールバック早見表 / 番号シフトの全更新
- `shared-artifacts/SKILL.md` の成果物一覧と `templates/progress.yaml` `references/progress-yaml.md` の `artifacts` セクションに `qa_design` / `qa_flow` 追加
- `templates/task-plan.md` / `references/task-plan.md` の「テスト追加方針」削除と「カバーする TC-ID」追加
- 旧 Step 5〜9 を参照しているすべての specialist-_ / agents/_ 内の番号 (本文中) を 6〜10 にシフト
- `plugins/dev-workflow/README.md` の 9-step 表記を 10-step に更新

## 非スコープ

- 単体 / 統合 / E2E のようなテスト分類体系の導入 (ユーザー指示で明示的に除外。分類が困難なため)
- **具体的なテストフレームワーク名 (Vitest / Playwright / Jest / pytest 等) を qa-design.md に書くこと** — フレームワーク選定はプロジェクト固有スキル (`vite-plus`, `effect-*` 等) と task-plan / implementer の領域。qa-design.md は抽象化された 2 軸カテゴリのみを扱う
- テストファイル配置の具体的なパス決定 (`qa-design.md` には**配置ポリシー**のみ書き、具体ファイル名は task-plan / implementer の領域)
- Step 4 で実装都合のテスト (ライブラリ制約由来の防御的分岐) を予見的に設計すること (Step 6 Implementation で `implementer` が `qa-design.md` 追記セクションに追加する運用)
- `qa-design.md` / `qa-flow.md` の自動生成・自動カバレッジ計測 (手動カバレッジ確認のみ)
- 既存サイクル `docs/ai-dlc/2026-04-24-ai-dlc-plugin-bootstrap/` の遡及修正 (完了済み)
- プロジェクト固有のテストフレームワーク選定スキル (`vitest-strategy` 等) の新規作成 (プロジェクト側の別作業)
- task-plan の「カバーする TC-ID」フィールドを必須化する厳格化 (推奨にとどめ、planner ドキュメントの圧迫を避ける)
- **新 ADR の起票**: 本サイクルの設計は **本サイクルの `design.md`** に記録する。前 ADR `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md` の主要決定 (フラット step リスト構造 / 責務分離による specialist 配置) を覆さない範囲の追加であり、Step 4 の挿入は前 ADR の枠組み内の sub-decision。横断的意思決定の追加は本サイクルでは発生しない

## 成功基準

1. `plugins/dev-workflow/skills/specialist-qa-analyst/SKILL.md` が存在し、frontmatter (name / description / metadata) と本文 (役割 / 入力 / 手順 / 失敗モード / スコープ外) を含む
2. `plugins/dev-workflow/agents/qa-analyst.md` が存在し、description フィールドと参照スキルセクションを含む
3. `plugins/dev-workflow/skills/shared-artifacts/templates/qa-design.md` および `references/qa-design.md` が存在し、成功基準対応列・実行主体列 (軸 A)・検証スタイル列 (軸 B)・実装段階追記セクションのプレースホルダ/説明を含む。具体ツール名 (Vitest / Playwright 等) は含まない
4. `plugins/dev-workflow/skills/shared-artifacts/templates/qa-flow.md` および `references/qa-flow.md` が存在し、(a) **1 つ以上の Mermaid コードブロック**を含む Markdown 形式、(b) 複数ブロック分割の指針、(c) Mermaid flowchart の if/switch/葉 (TC-ID or `skip`) の書き方を含む
5. `plugins/dev-workflow/skills/dev-workflow/SKILL.md` のステップ一覧テーブルが 10 行で、Step 4 が `QA Design` / `qa-analyst` × 1 / Gate=User / 主要成果物に `qa-design.md` と `qa-flow.md` を持つ
6. `plugins/dev-workflow/skills/specialist-planner/SKILL.md` で `grep -nF "テスト追加方針"` が 0 件、かつ「カバーするテストケース ID」または同義の記述が存在
7. `plugins/dev-workflow/skills/specialist-implementer/SKILL.md` の固有入力欄に `qa-design.md` と `qa-flow.md` が両方含まれ、`qa-design.md` の「実装段階で追加されたテスト」追記責任、および `qa-flow.md` の Mermaid コードブロック追記責任が明文化されている
8. `plugins/dev-workflow/skills/specialist-validator/SKILL.md` の固有入力欄に `qa-design.md` と `qa-flow.md` が含まれ、qa-flow 葉カバレッジ検証責任が明文化されている
9. `plugins/dev-workflow/skills/dev-workflow/SKILL.md` のロールバック早見表に少なくとも 2 つの Step 4 関連エントリ (例: 「Step 4 で観測不能 → Step 1」「Step 4 で振る舞い未定 → Step 3」) が含まれる
10. `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml` の `artifacts` セクションに `qa_design: null` と `qa_flow: null` が新規追加される
11. `plugins/dev-workflow/skills/shared-artifacts/templates/task-plan.md` から「テスト追加方針」相当の列が削除される
12. `plugins/dev-workflow/README.md` が 10 ステップ構成を反映 (1〜10 の名前列挙が含まれる)
13. `grep -nF "Step 5 (Implementation)" plugins/dev-workflow/` の結果が 0 件 (旧番号での参照が残らない)
14. `qa-flow.md` テンプレート内の各 Mermaid コードブロックを GitHub の Markdown プレビュー (Mermaid 自動レンダリング) で表示した際、構文エラーなく図として描画される (手動目視確認)

## 制約

### 技術的制約

- 新成果物 2 種は Markdown 形式とし、追加の build ツールやレンダラを要求しない (Mermaid は Markdown コードブロック内で記述、GitHub のネイティブレンダラに依存)
- ステップ番号シフトに伴う旧番号置換は順序依存 (Step 9 → 10 から先に処理しないと連鎖二重置換が発生)。`gsed` で逆順実行する

### 規範的制約

- `dev-workflow` の基本方針 (Main-Centric Orchestration / One-Shot Specialist / Gate-Based Progression / Artifact-Driven Handoff / Project-Rule Precedence) を全継承
- 既存 ADR `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md` の Decision (フラット構造、フェーズ概念非導入、9 specialist 維持) と矛盾しないこと。本サイクルで specialist が 1 名増えるが、これは「責務分離による specialist 追加」であり「フェーズ概念の再導入」ではない
- monorepo 共通の memory rules: `gsed` 使用 (macos-cli-rules)、`2>&1` 不使用、`vp run` 経由のコマンド優先、`as` 型アサーション禁止 (TS の場合)、git commit は sandbox 外実行
- ドキュメント言語: 英語 (skill / template / reference / agent description)、ただし本 Intent Spec / 既存 SKILL.md の本文は日本語を踏襲

### 組織的制約

- レビュー単位: 各ステップ完了時に成果物そのものをユーザーに提示してレビュー依頼 (本サイクルはユーザー単独レビュー)
- 期限なし (ユーザーの判断ペースに合わせる)

## 関連リンク

- 既存 ADR: `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md` (本サイクルの前提となるリネーム + フラット化決定)
- 既存スキル本体: `plugins/dev-workflow/skills/dev-workflow/SKILL.md`
- 既存プランナー: `plugins/dev-workflow/skills/specialist-planner/SKILL.md`
- 既存 implementer / validator: `plugins/dev-workflow/skills/specialist-implementer/SKILL.md`, `plugins/dev-workflow/skills/specialist-validator/SKILL.md`
- 既存 shared-artifacts: `plugins/dev-workflow/skills/shared-artifacts/SKILL.md`
- 過去の議論: 本会話の Plan モード議論 (Step 4 の名称 `qa-design` / `qa-analyst` 確定、実装都合テストは Step 6 で `qa-design.md` 追記方針確定)

## 未解決事項

(主要な意思決定は AskUserQuestion で確定済み。以下は Step 2 Research / Step 3 Design で確認・決定する細部)

- `qa-design.md` のテストケース表に持たせる必須列 vs 任意列の境界
- `qa-flow.md` の Mermaid 構文選択 (`flowchart TD` vs `stateDiagram-v2` vs その他)。GitHub レンダラ互換性が判断基準
- `qa-flow.md` を分割する際の単位の指針 (関心領域別 / サブシステム別 / 成功基準グループ別 のいずれを推奨するか)。Step 3 Design で検討
- task-plan.md の「カバーするテストケース ID」を**必須**にするか**推奨**にとどめるか
- 旧 Step 5〜9 を参照する箇所の網羅的な棚卸し (Research で grep して全件リスト化)
- `qa-analyst` 起動時に渡すプロジェクト固有スキルのデフォルトリスト (`vite-plus`, `effect-*` 等のうち、テスト基盤関連の最小セット)
