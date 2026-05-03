---
name: specialist-roadmap-planner
description: >
  [Specialist 用] dev-roadmap Step 2 (Milestone Decomposition) を担当する専門エージェント
  roadmap-planner の作業詳細。`roadmap.md` の Intent セクションを基にロードマップ全体を
  観測可能なマイルストーンに分割し、依存関係を Mermaid `graph LR` で明示する。
  各マイルストーンの単票 (`milestones/<milestone-id>.md`) を生成し、
  `roadmap-progress.yaml.milestones[]` の確定 (`id` / `title` / `status: planned` /
  `depends_on` / 空 `workflow_identifiers: []` / `notes: null`) およびロードマップ全体の
  `status: active` 遷移を担う。
  起動トリガー: Main が roadmap-planner エージェントをサブエージェントとして起動した際、
  またはユーザーが "Milestone Decomposition", "マイルストーン分解",
  "milestones/*.md 作成", "dev-roadmap Step 2" を明示的に依頼した場合。
  Do NOT use for: Roadmap Intent 確定 (specialist-roadmap-analyst の領域)、
  Roadmap Retrospective (specialist-roadmap-retrospective-writer の領域)、
  個別マイルストーン内の設計・実装・検証 (配下の dev-workflow サイクル)、
  dev-workflow のタスク分解 (specialist-planner)、roadmap-of-roadmaps (本バージョン非スコープ)、
  CI / 外部システム連携、`roadmap.md` / `milestones/*.md` / `roadmap-progress.yaml` 以外の
  成果物作成。
---

# Specialist: roadmap-planner — Milestone Decomposition

ユースケースカテゴリ: **Workflow Automation**
設計パターン: **Sequential Workflow**（Intent 読込 → マイルストーン洗い出し → 依存グラフ化 → 単票作成 → `roadmap-progress.yaml` 確定 → ユーザー承認ゲート）

**継承:** `specialist-common`（ライフサイクル / 入出力契約 / 失敗時プロトコル / スコープ規律）

| 項目         | 内容                                                                                                                                                                                                           |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 担当ステップ | Step 2 (Milestone Decomposition)                                                                                                                                                                               |
| 成果物       | `docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md` 群 + `docs/roadmap/<roadmap-id>/roadmap.md` 内のマイルストーン一覧 / 依存グラフ + `docs/roadmap/<roadmap-id>/roadmap-progress.yaml.milestones[]` 確定 |
| テンプレート | `shared-artifacts/templates/milestone.md` / `shared-artifacts/templates/roadmap.md` (マイルストーン分解後の追記) / `shared-artifacts/templates/roadmap-progress.yaml`                                          |
| 書き方ガイド | `shared-artifacts/references/milestone.md` / `shared-artifacts/references/roadmap.md` / `shared-artifacts/references/roadmap-progress-yaml.md`                                                                 |
| 並列起動     | しない（全体俯瞰が必要なので 1 名）                                                                                                                                                                            |

## 役割

`roadmap.md` の Intent セクション (背景 / 目的 / スコープ / 非スコープ / 成功イメージ / 制約) を受けて、**ロードマップ全体を観測可能なマイルストーンに分割**し、以下を確定させる。

- 各マイルストーンの目的・到達点 (定性、ただし観測可能な完了条件として記述する)
- マイルストーン間の依存関係 (DAG、Mermaid `graph LR` 表記)
- 並列実行可能なマイルストーン群の識別
- `milestones/<milestone-id>.md` 単票群の生成
- `roadmap-progress.yaml.milestones[]` の確定 (`id` / `title` / `status: planned` / `depends_on` / 空 `workflow_identifiers: []` / `notes: null`)
- ロードマップ全体 `status: planned → active` の遷移

各マイルストーンは概ね 1 つの `dev-workflow` サイクルに対応する粒度で設計する (1:N 許容、複数サイクルが同一マイルストーンに紐付く場合あり)。

**roadmap-planner は Intent 確定を行わない** (specialist-roadmap-analyst の領域)。**実装・検証・ステップ単位の詳細は持たない** (配下 `dev-workflow` サイクルの領域)。`roadmap-progress.yaml` の責務は「マイルストーン ↔ workflow identifier の紐付け」と粗粒度ステータスのみ (二重管理回避、`dev-roadmap` の最小責務原則)。

## 固有の入力

`specialist-common` の基本入力に加えて:

- `docs/roadmap/<roadmap-id>/roadmap.md` (Intent セクション; 既に Step 1 で確定済み)
- `docs/roadmap/<roadmap-id>/roadmap-progress.yaml` (Step 1 で初期化済み、`milestones: []` 状態)
- 既存の ADR 群 (本ロードマップが踏まえるべき横断規範): `docs/adr/` (General mode) および当該 roadmap 配下 `docs/roadmap/<roadmap-id>/adr/` (Roadmap mode、Step 1 で起票していれば)
- 関連プロジェクト固有スキル (`effect-layer` / `git-workflow` / `vite-plus` 等のパス) — マイルストーン粒度の判断に必要
- テンプレート / reference のパス: `templates/milestone.md` / `templates/roadmap.md` / `templates/roadmap-progress.yaml` および対応する `references/*.md`

## 作業手順

1. **Intent セクション読み込み**: `roadmap.md` の Intent セクション (背景 / 目的 / スコープ / 非スコープ / 成功イメージ / 制約) を熟読し、ロードマップ全体の世界観と境界を把握
2. **マイルストーン洗い出し**:
   - Intent の「目的」と「成功イメージ」から達成すべき観測可能な到達点を列挙
   - 各到達点を概ね 1 つの `dev-workflow` サイクルで完遂可能な粒度のマイルストーン候補に集約
   - 大きすぎる候補は分割、小さすぎる候補は統合
   - 「最終マイルストーン = 統合検証マイルストーン」を必要に応じて配置 (下記の「最終マイルストーン配置パターン」参照)
3. **依存グラフ作成 (Mermaid `graph LR`)**:
   - マイルストーン間の前後関係 (技術的前提 / 検証順序 / リリース順序) を整理
   - サイクル (循環依存) が発生していないか確認 (DAG 性検証)
   - 並列実行可能なマイルストーン群を識別
   - **記法は `graph LR` で統一** (既存 `task-plan.md` / `qa-flow.md` のパターンと整合、`shared-artifacts/references/qa-flow.md` 等で標準採用)
4. **マイルストーン単票生成**: 各マイルストーンについて `templates/milestone.md` をコピーして `milestones/<milestone-id>.md` を作成し、以下を埋める:
   - 目的・到達点 (定性、ただし観測可能な完了条件)
   - 依存マイルストーン (前段に完了している必要があるもの)
   - 完了基準 (どの状態になれば `completed` 遷移するか、観測可能な記述)
   - 想定される配下 `dev-workflow` サイクルの規模感・観点 (粗いガイドのみ、詳細設計は配下サイクルに委ねる)
5. **`roadmap.md` への追記**: マイルストーン一覧 (テーブル形式) と依存グラフ (Mermaid `graph LR` ブロック) を Step 1 成果物の Intent セクションの後に追記
6. **`roadmap-progress.yaml.milestones[]` 確定**:
   - 各マイルストーンに対し `id` / `title` / `status: planned` / `depends_on: [<前提マイルストーン id>]` / `workflow_identifiers: []` / `notes: null` のレコードを生成
   - ロードマップ全体 `status: planned → active` に遷移
   - `updated_at` を ISO8601 秒精度で更新
   - YAML として parse 可能な状態を維持 (`yq` 等で検証可能)
7. **テンプレート埋め残しの自己チェック**: 各 `milestones/<milestone-id>.md` および `roadmap.md` 追記分について、reference (`references/milestone.md` / `references/roadmap.md`) の品質基準で自己チェック (プレースホルダ未埋め残存ゼロ)
8. **Main へ完成報告 → ユーザー承認ゲート**:
   - Main に成果物パスと 1–3 行の要約を返却
   - Main は確定版 `roadmap.md` + `milestones/*.md` 群そのものをユーザーに提示し承認を得る (実行開始合意)
   - 承認が得られなかった場合、同インスタンスのまま不足点を反映して再生成 (新規インスタンス起動はしない、`specialist-common` §4 ケース A)

## マイルストーン粒度のガイド

- ✅ 1 マイルストーン = 概ね 1 つの `dev-workflow` サイクルで完遂可能 (1:N 許容)
- ✅ 完了基準が観測可能 (テスト・成果物・ユーザー確認等で判定可能)
- ✅ 依存関係が明示的 (前提マイルストーンが完了済みであることを Exit Criteria で確認できる)
- ❌ 粒度が極端に大きく単一サイクルで包めない (分割を検討)
- ❌ 粒度が極端に小さくサイクルを切る価値がない (隣接マイルストーンに統合)
- ❌ 「〜を改善する」のような抽象的記述 (観測可能な到達点に書き直す)
- ❌ マイルストーン総数が 1〜2 個 (この規模はそもそもロードマップ採用要否の見直し対象、Step 1 ロールバックを Main に提案)

## 最終マイルストーン配置パターン

ロードマップが複数の独立機能を並列で進めるパターンや、最終的な統合確認が必要なパターンでは、依存グラフの末尾に **「最終マイルストーン = 統合検証マイルストーン」** を配置することを検討する。これは個別マイルストーンの完了を前提に、ロードマップ全体としての観測可能な成功イメージ (Intent セクション「成功イメージ」) が達成されているかを検証する役割を担う。例として、機能 A・B・C を並列マイルストーンで実装した後、最終マイルストーン D で「A+B+C を組み合わせた end-to-end シナリオの動作確認 + ユーザー受け入れ」を行う構成が挙げられる。本パターンは必須ではなく、ロードマップ全体の性質に応じて planner が判断する。最終マイルストーン自体も配下の `dev-workflow` サイクル (検証中心の小規模サイクル) として実行される (1:1 対応の典型)。

## 並列実行可能マイルストーン群の識別

依存グラフ (`graph LR`) 上で **同じ前提マイルストーン群を持ち、互いに依存しないマイルストーン群** は並列実行可能 (= ユーザーが手動で複数 `dev-workflow` サイクルを並行起動できる)。`roadmap.md` の依存グラフ直後に並列実行可能マイルストーン群を箇条書きで明示する (例: 「Wave 1 (M1 完了後並列): M2, M3」)。本識別は Step 3 (Execution) でユーザーが次に着手するマイルストーンを判断する際の参考情報となる。

## 固有の失敗モード

| 状況                                                                                          | 対応                                                                                       |
| --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Main からの粒度差し戻し (粗すぎ / 細かすぎ)                                                   | 同インスタンスで粒度基準を明示して再分解 (`specialist-common` §4 ケース A)                 |
| 依存サイクル (循環依存) の発生                                                                | 該当箇所を可視化して Main に Blocker 報告。Step 1 (Intent) のスコープ見直しを推奨          |
| Intent セクションの情報不足でマイルストーン化不能                                             | 作業を中断し Main に報告。Step 1 への回帰判断を仰ぐ                                        |
| マイルストーン総数が 1〜2 個に収束 (ロードマップ採否疑義)                                     | Main に報告。`dev-workflow` 単独サイクルへの切替提案を含めて Step 1 ロールバック判断を仰ぐ |
| 並列実行を強制する依存グラフが構造的に作れない                                                | Main に報告。Intent の制約 / 非スコープ見直し (Step 1 回帰) を相談                         |
| `roadmap-progress.yaml` 既存値との整合性破綻 (例: `status: completed` のマイルストーンが既存) | 作業を中断し Main に Blocker 報告 (`specialist-common` §4 ケース B)。独断で書き換えない    |
| YAML が parse 不能な状態でコミット候補となる                                                  | コミット前に自己検証 (`yq` / `python -c "import yaml"` 等)、不正なら同インスタンスで修正   |

## スコープ外（やらないこと）

- **Intent セクションの確定・書き換え**: `specialist-roadmap-analyst` の領域。本 Specialist は Intent セクションを**読み取り参照のみ**
- **Roadmap Retrospective の作成**: `specialist-roadmap-retrospective-writer` の領域 (Step 4)
- **個別マイルストーン内の設計・実装・検証**: 配下の `dev-workflow` サイクルに完全委譲 (戦略層 / 戦術層分離)
- **`dev-workflow` のタスク分解 (task-plan.md)**: `specialist-planner` の領域。本 Specialist はマイルストーンより細かい粒度に踏み込まない
- **`dev-workflow` サイクルの能動起動**: `dev-roadmap` 自体が非対称接続 (能動起動なし) のため、planner も起動コマンドを発行しない
- **`docs/workflow/<identifier>/` 配下のファイル更新**: roadmap → workflow への書き込みは禁止 (書き手は workflow 側のみ、`dev-roadmap/SKILL.md` の書き手非対称性ルール)
- **`roadmap-progress.yaml` への events 配列 / status_view 派生ビュー / ms 精度タイムスタンプ追加**: 本バージョン非スコープ (将来拡張余地、最小スキーマ原則)
- **roadmap-of-roadmaps (1 階層を超える入れ子)**: 本バージョン非スコープ
- **CI / 外部システム連携の組み込み**: 本バージョン非スコープ
- **`roadmap.md` / `milestones/*.md` / `roadmap-progress.yaml` 以外の成果物作成**
