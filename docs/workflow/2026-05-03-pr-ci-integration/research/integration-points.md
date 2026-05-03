# Research Note: integration-points

- **Identifier:** 2026-05-03-pr-ci-integration
- **Topic:** integration-points (dev-workflow 内部スキル文書への新ルール統合ポイント特定)
- **Researcher:** researcher / integration-points
- **Created at:** 2026-05-03
- **Scope:** `plugins/dev-workflow/skills/dev-workflow/SKILL.md` を中心に、`specialist-common/SKILL.md` および周辺成果物仕様 (`shared-artifacts/`, `progress-yaml.md`) のどこに 5 つの新ルール (Draft PR / PR 概要更新 / CI 確認 + 2 回リトライ → Blocker / Step 9 完了後 Ready 化) を差し込むのが最も整合的かを、行番号レベルで特定する。設計判断 (Step 3 architect) や文書改修 (Step 6 implementer) は行わない。

## 調査対象

Intent Spec (`docs/workflow/2026-05-03-pr-ci-integration/intent-spec.md`) のスコープ §2 で列挙された 5 種の新ルールは、`dev-workflow/SKILL.md` への追記を主、`specialist-common` 等への参照リンク追加を従とする方針。本 Research Note では:

1. `dev-workflow/SKILL.md` (888 行) の主要セクション境界を行番号付き表で固定し、5 ルールそれぞれの「挿入候補位置 (1〜2 案)」と「採用推奨案」を Step 3 architect が即座に意思決定できる粒度で提示する。
2. 既存「ステップ完了時のコミット規約」(L701-L767) との関係を整理する (新規セクション独立 vs 同セクション内拡張)。
3. `specialist-common/SKILL.md` の「7. Git コミットに関する注意」(L177-L194) と「Specialist が gh CLI を直接呼ぶか / Main 経由か」の責任所在をマッピングする。
4. 既存「ゲート通過時」(L589-L602) / 「Blocker 発生時」(L604-L611) / 「セッション再開時」(L613-L627) プロトコルと CI 失敗 → 2 回リトライ → Blocker フローの統合点を提示する。
5. 「並列起動のガイドライン」(L822-L835) の Step 6 / Step 7 並列 Specialist が PR 概要更新の責務をどう負うかを整理する。
6. 本サイクルブランチ `feat/dev-workflow-pr-ci-integration` の既存コミット履歴 (3 件) をサンプルに、新ルールが既存ステップ記述と矛盾しないかを確認する。

Intent Spec §未解決事項のうち本観点で扱う 3 件 (Specialist 直 gh CLI / Step 9 Ready 化トリガー / CI 失敗復旧の進捗記録パス) について、Step 3 architect が判断材料に使える形で「文書上の挿入位置と表現の制約」を提示する。

## 発見事項

### F1. `dev-workflow/SKILL.md` (888 行) の主要セクション境界マップ

`grep -nE "^#{1,4} "` で機械抽出した結果、主要セクションの行番号と目的は以下のとおり。

| セクション (見出しレベル)                               | 開始行 | 終了行 (推定) | 目的                                                                                                                                                                                                                    |
| ------------------------------------------------------- | -----: | ------------: | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `# dev-workflow` (タイトル + 概要)                      |    L15 |           L21 | スキル概要                                                                                                                                                                                                              |
| `## 基本方針`                                           |    L22 |           L51 | 9 つのコア原則 (Main-Centric / Single-Source-of-Progress / Gate-Based / Artifact-Driven / Project-Rule Precedence / Commit-Based Resumability / Clean-Transition / Artifact-as-Gate-Review / Report-Based Confirmation) |
| `## 役割定義`                                           |    L54 |           L92 | Main / Specialist の責務                                                                                                                                                                                                |
| `### Main`                                              |    L56 |           L75 | Main の責務と原則                                                                                                                                                                                                       |
| `### Specialist`                                        |    L77 |           L92 | Specialist の責務と原則                                                                                                                                                                                                 |
| `## ワークフロー全体図`                                 |    L95 |          L117 | 9 ステップの ASCII 図                                                                                                                                                                                                   |
| `## ステップ一覧`                                       |   L121 |          L135 | 9 ステップの一覧表                                                                                                                                                                                                      |
| `## ステップ詳細`                                       |   L139 |          L557 | 各ステップの目的 / Main の作業 / Exit Criteria / Gate / 失敗時                                                                                                                                                          |
| `### Step 1: Intent Clarification`                      |   L143 |          L170 |                                                                                                                                                                                                                         |
| `### Step 2: Research`                                  |   L172 |          L200 |                                                                                                                                                                                                                         |
| `### Step 3: Design`                                    |   L202 |          L232 |                                                                                                                                                                                                                         |
| `#### ADR の起票条件` (Step 3 配下)                     |   L234 |          L244 |                                                                                                                                                                                                                         |
| `### Step 4: QA Design`                                 |   L246 |          L288 |                                                                                                                                                                                                                         |
| `### Step 5: Task Decomposition`                        |   L290 |          L317 |                                                                                                                                                                                                                         |
| `### Step 6 着手前: タスクリスト反映`                   |   L319 |          L342 | TODO.md / TaskCreate 同期手順                                                                                                                                                                                           |
| `### Step 6: Implementation`                            |   L344 |          L391 |                                                                                                                                                                                                                         |
| `### Step 7: External Review`                           |   L393 |          L445 |                                                                                                                                                                                                                         |
| `#### Step 6 ↔ Step 7 ループ (Round 反復)`              |   L447 |          L495 | Round 反復構造                                                                                                                                                                                                          |
| `### Step 8: Validation`                                |   L497 |          L529 |                                                                                                                                                                                                                         |
| `### Step 9: Retrospective`                             |   L531 |          L557 |                                                                                                                                                                                                                         |
| `## 調整プロトコル (Main ↔ Specialist)`                 |   L561 |          L627 |                                                                                                                                                                                                                         |
| `### 1. ワークフロー開始時`                             |   L563 |          L572 | サイクル初期化手順 6 ステップ                                                                                                                                                                                           |
| `### 2. ステップ実行ループ`                             |   L574 |          L587 | 全ステップ共通の実行ループ                                                                                                                                                                                              |
| `### 3. ゲート通過時`                                   |   L589 |          L602 | ユーザー承認ゲート / In-Progress 問い合わせ / Main 判定                                                                                                                                                                 |
| `### 4. Blocker 発生時`                                 |   L604 |          L611 | Blocker フロー 3 ステップ                                                                                                                                                                                               |
| `### 5. セッション再開時`                               |   L613 |          L627 | 再開プロトコル 8 ステップ                                                                                                                                                                                               |
| `## 成果物テンプレート・保存構造・進捗記録フォーマット` |   L631 |          L646 | shared-artifacts への委譲                                                                                                                                                                                               |
| `## プロジェクト固有ルールとの関係`                     |   L650 |          L697 | 適用手順 / 矛盾判定例                                                                                                                                                                                                   |
| `## ステップ完了時のコミット規約`                       |   L701 |          L767 | **本研究の主要対象**                                                                                                                                                                                                    |
| `### 原則` (コミット規約)                               |   L705 |          L711 | 1 ステップ = 1 コミット原則                                                                                                                                                                                             |
| `### ステップ別コミット内訳`                            |   L713 |          L731 | 9 ステップごとのコミット表                                                                                                                                                                                              |
| `### ユーザー承認ゲート通過時`                          |   L733 |          L738 |                                                                                                                                                                                                                         |
| `### コミットメッセージ規約`                            |   L740 |          L750 | プロジェクト規約優先                                                                                                                                                                                                    |
| `### コミット前チェック`                                |   L752 |          L761 | 6 ステップのチェック手順                                                                                                                                                                                                |
| `### 一時ファイルの扱い`                                |   L763 |          L767 |                                                                                                                                                                                                                         |
| `## roadmap-progress.yaml 更新プロトコル`               |   L771 |          L818 | dev-roadmap 連携                                                                                                                                                                                                        |
| `## 並列起動のガイドライン`                             |   L822 |          L835 | Step ごとの並列起動推奨度表                                                                                                                                                                                             |
| `## 逸脱時のリカバリ`                                   |   L838 |          L876 | スコープ変更 / 期待外成果物 / 整合性崩れ / ロールバック早見表                                                                                                                                                           |
| `## このスキルが扱わないこと`                           |   L880 |          L888 | 委譲事項。**L888 に「デプロイ・観測・SLA 監視 → 本ワークフロー外 (CI/CD パイプライン等)」あり (重要、F8 で扱う)**                                                                                                       |

### F2. 既存 SKILL.md 内の PR / CI 言及はほぼゼロ

`grep -nE "(PR|pull request|gh pr|gh run|CI|Draft|Ready)" plugins/dev-workflow/skills/dev-workflow/SKILL.md` の結果は 2 件のみ:

- L692 — 「本ワークフローの task 粒度『1 日以内』、プロジェクト規約が『1 PR = 複数週』」 (矛盾判定例の 1 行、PR は単に粒度比喩として登場)
- L888 — 「デプロイ・観測・SLA 監視 → 本ワークフロー外 (CI/CD パイプライン等)」 (`このスキルが扱わないこと` セクション内の現行宣言)

→ **設計上の含意:** L888 の現行宣言は「CI/CD パイプライン**自体**は扱わない」のスコープアウトであり、「CI **結果を読んで判断する**ルール」は別レイヤとして加えられる余地がある。Intent Spec §非スコープ「CI ワークフロー (`.github/workflows/*.yaml`) 自体の改修は扱わない」と整合する。L888 の文言は **改修対象** (新ルール追加と不整合を起こさないよう微修正、または隣に「結果参照は扱う」旨を 1 文補足する) になり得る。

### F3. `specialist-common/SKILL.md` の「7. Git コミットに関する注意」(L177-L194) — 現行は Specialist 直 Git 操作の責任所在を `implementer` のみ許可

L179-L184 引用 (実線の制約):

- `implementer`: コード変更を担当タスクごとにコミットする (通常の Git 運用)
- その他: 成果物ファイルを作成・更新するのみ。**Git コミットは Main が実行する**

L186-L194 の Git ガードレール (`implementer` 向け必須ルール):

- `git add -A` / `git add .` 禁止 (パス指定必須)
- 秘匿ファイル検出時の中断
- `--no-verify` / `--no-gpg-sign` 禁止
- force push 禁止 (main/master へは絶対不可、他ブランチでもユーザー明示許可なしで不可)
- コミット前チェック (`git diff --staged`)

→ **PR / CI 操作の責任所在に関する設計上の含意:** 現行ルールは「Git コミット = Main 実行 (implementer のみ例外)」だが、`gh pr` 系コマンドはこの規約に**まだ含まれていない**。Step 3 で「PR 操作 = Main 限定 / Specialist にも委譲可」を確定する際の文書上のレバーは以下 2 案:

- **案 A (Main 限定):** `specialist-common §7` を「Git コミットおよび GitHub PR 操作は Main が実行する」と更新。`implementer` の例外はコミットのみで PR 操作は含めない。Intent Spec §制約「作業者は AI エージェント (Main + Specialist) のみ — 人間レビュアーは Gate でのみ介入。Specialist が GitHub 操作を直接行ってよいかは Step 3 Design で再整理 (現状 `specialist-common` では『Git コミットは Main が実行する』)」 (L91) と整合。
- **案 B (Specialist 委譲可):** `specialist-common §7` に「PR 操作 (gh pr create/edit/ready) は Main が原則担当、ただし implementer がタスクコミット直後に PR 概要更新を行うことを許容する」を追記。並列 implementer 環境では概要更新の競合リスクあり (F6 で言及)。

→ **本観点の推奨は案 A (Main 限定)**。理由は (1) 並列 implementer 同士の PR 概要更新競合を回避 (Single-Source-of-Progress 原則と整合)、(2) `specialist-common §7` の既存構造 (Main = 真の Git 書き手、implementer = 例外) を最小限の追記で拡張可能 (新セクション追加不要、既存テーブルに 1 行追加するだけ)、(3) Intent Spec §SC-1〜SC-8 の検証はすべて Main 起点で完結可能。

### F4. 既存「ゲート通過時」(L589-L602) と CI 確認の統合点

L589-L602 は 3 種のゲート (ユーザー承認ゲート / In-Progress 問い合わせ / Main 判定ゲート) を定義する。CI PASS 確認はどのゲートに属するかを明示する必要がある。

- **ユーザー承認ゲート** (L591-L596): 成果物そのものを提示してユーザー承認を得る。CI PASS 状態は成果物の品質ではなく**ステップ完了の事実そのもの**なので、ゲート前提条件として位置づけるのが自然。
- **In-Progress ユーザー問い合わせ** (L597-L601): Blocker 発生時の判断要請。CI 2 回リトライ失敗 → Blocker 化 → ユーザー判断はここに分類される。
- **Main 判定ゲート** (L602): Main が Exit Criteria 各項目を照合。CI PASS は Exit Criteria の 1 項目として全ステップに追加するのが整合的 (= 各ステップ Exit Criteria に「該当コミットの CI が PASS」を追加)。

→ **設計上の含意:** CI PASS 確認は **「Main 判定ゲート」と「ユーザー承認ゲート」の前提条件** (= 各ステップ Exit Criteria の必須項目) として組み込み、CI 失敗 → 2 回リトライ → 失敗継続は **「In-Progress ユーザー問い合わせ」を経由した Blocker 化** として L604-L611 の既存 Blocker フローに統合する。これにより既存プロトコルを破壊せずに統合できる。

### F5. 既存「Blocker 発生時」(L604-L611) と CI 失敗 → Blocker のフロー統合点

L604-L611 の現行フロー:

1. Specialist が Blocker を検知 → 作業中断して Main に報告
2. Main は前ステップに戻る / 並列 Specialist 追加起動 / ユーザー判断 (In-Progress) のいずれかを選択
3. `progress.yaml.blockers` に追記してコミット

→ **CI 失敗 → 2 回リトライ → Blocker のフロー統合 (推奨案):** L604-L611 を破壊せず、**「4. Blocker 発生時」セクション内に副節 `### 4-a. CI 失敗時の Blocker 化フロー` (または `### 4 補足`)** を追加する形で 5-7 行追記:

1. ステップ完了コミット後、Main は対応する CI 実行 (`gh run list --branch <branch> --commit <sha>`) を確認
2. CI PASS → 当該ステップ完了。CI FAIL → 最大 2 回までリトライ (具体手段は Step 3 で確定: `gh run rerun --failed` / 修正コミット push のいずれか)
3. 2 回リトライ後も FAIL → Blocker 化 (`progress.yaml.blockers` に CI run URL + 原因を追記してコミット) → In-Progress ユーザー問い合わせ形式でユーザー判断を仰ぐ
4. 復旧後の進捗再開は「5. セッション再開時」のフローに準じる

「セッション再開時」(L613-L627) との整合: CI Blocker 状態で中断した場合、再開時は `progress.yaml.blockers` を読んで CI run 状態を再確認するステップが必要 → 既存「5. セッション再開時」L626 の `blockers があればユーザーに再提示し、対応方針を確認 (In-Progress ユーザー問い合わせ形式)` の枠組みでカバー可能 (CI 専用追記不要)。

### F6. 「並列起動のガイドライン」(L822-L835) と PR 概要更新責任

L822-L835 の表は Step 6 (Implementation) と Step 7 (External Review) を並列起動「高」推奨としている (タスクごと / 観点ごと)。並列 Specialist が並行で commit を作る Step 6 では、PR 概要更新の責任所在が論点となる:

- **タスクごとの並列 implementer × N** (L831): 各 implementer がコミットを作り、対応する CI が並列に走る
- **観点ごとの並列 reviewer × 6** (L832): review レポートを作る (コミットは Main が集約)

→ **設計上の含意 (PR 概要更新の責任):** 並列 Specialist が個別に PR 概要を更新すると競合・上書きリスクが大きい (例: implementer A が Task T1 完了 → 概要に T1 [x] を書き、ほぼ同時に implementer B が Task T2 [x] を書こうとして A の更新を上書き)。**Main が PR 概要更新の単独責任者**とすることで Single-Source-of-Progress 原則 (L25) と整合。Step 6 では Main が「各タスク完了コミット + TODO.md 更新コミット + CI PASS 確認」の 3 点セット完了後にまとめて PR 概要を更新する流れが自然。

→ **挿入位置案:** 「並列起動のガイドライン」(L822-L835) の表の直後に補足段落を追加し、「並列 Specialist が並行で commit / 成果物を作る場合でも、PR 概要 (`gh pr edit --body`) の更新は Main が単独で実行する」と 1〜2 行記述する。または `## 役割定義 / Main` (L56-L75) の責務リストに「PR 概要更新の単独責任者」を 1 行追加する案もあるが、後者は責務追加の意味合いが強くスキル全体への影響が大きいため、F3 推奨の `specialist-common §7` 拡張と合わせて整合させる方が局所変更で済む。

### F7. 本サイクルの実証コミット履歴 (3 件) と新ルールの矛盾チェック

`feat/dev-workflow-pr-ci-integration` ブランチには現在 3 コミット存在する:

```
1ac3b5f docs(dev-workflow/2026-05-03-pr-ci-integration): initialize cycle
9a6a537 chore(dev-workflow/2026-05-03-pr-ci-integration): align cycle dir with docs/workflow/ rename from main
1cb5743 docs(dev-workflow/2026-05-03-pr-ci-integration): complete Step 1 (Intent Clarification)
```

→ **新ルールとの整合性確認:**

- **ルール 1 (initialize cycle と同時に Draft PR 作成):** `1ac3b5f` が `initialize cycle` コミット。本観点では「このコミット直後に Draft PR が作成されているか」を `gh pr list --state all --search "2026-05-03-pr-ci-integration"` で別途検証する必要がある (Step 8 Validator の責務、本 Note では未検証)。本サイクル開始時点では Draft PR はまだ作成されていない可能性があり、新ルール導入の文書整備とドッグフード実証はインクリメンタルに進める前提。
- **ルール 2 (各ステップ完了時に PR 概要更新):** `1cb5743` が Step 1 完了コミット。新ルール上は同時または直後に PR 概要更新が必要。これも未検証。
- **ルール 3 (CI 確認 + 2 回リトライ + Blocker):** 既存 3 コミットの CI 状態は `gh run list` で確認可能。SKILL.md 文書改修コミットに対する CI は既存 `.github/workflows/ci.yaml` (詳細は researcher #2 の所掌) で動作するはず。新ルール導入後は本サイクル PR 自身が初の実証対象となる。
- **ルール 4 (Step 9 完了後 Ready 化):** 本サイクルが Step 9 まで到達した時点で適用される (Step 8 Validator が SC-8 を実測)。
- **ルール 5 (PR description GitHub 限定 / リポジトリ内に成果物として永続化しない):** `docs/workflow/2026-05-03-pr-ci-integration/` 配下に `pr-overview.md` 等のファイルが作られていないことを `ls` で確認 → 現状作られていない (確認済、F7 補足)。

→ **既存コミットメッセージは新ルールと矛盾しない**。Conventional Commits (`docs(dev-workflow/<id>): ...`) は L740-L750 の規約と整合し、新ルール追加で破壊される箇所はない。新ルールは既存コミット規約への**追加**であり、既存メッセージ規約は維持される。

### F8. L888 「このスキルが扱わないこと」の現行宣言と新ルールの両立

L888 「デプロイ・観測・SLA 監視 → 本ワークフロー外 (CI/CD パイプライン等)」は CI/CD パイプライン**自体**のスコープアウトを宣言する。新ルールは「CI ワークフロー自体の改修」(Intent Spec §非スコープ) は扱わず、「CI **結果**を読んで判断する」のみを扱う。

→ **設計上の含意 (L888 の改修要否):** 厳密に読めば L888 は CI/CD パイプライン**設計** (デプロイ手順・観測・SLA) を指しており、CI **結果参照**は別物として共存可能。だが読者の誤解を防ぐため、Step 3 architect は以下のいずれかを選択する余地がある:

- **案 1 (L888 を最小改変):** 「デプロイ・観測・SLA 監視」「CI/CD パイプライン**そのもの**の設計」のように修飾語を 1 つ加え、新ルールが「CI 結果参照」を扱うことと矛盾しないことを明示する (1 行修正)
- **案 2 (L888 はそのまま、新セクションで明示的に住み分け):** 新規追加するセクション (例: `## サイクル PR と CI 連携プロトコル`) の冒頭に「本セクションは CI ワークフロー定義を扱わず、CI 結果を読んで完了基準に組み込むことのみを規定する」と明記し、L888 と棲み分ける

→ **本観点の推奨は案 2** (L888 改変なし、新セクションで住み分け宣言)。理由は L888 はスキル全体の境界宣言であり改変は影響波及が大きいため。

### F9. `progress.yaml` の `blockers` / `artifacts` フィールドと CI Blocker 記録の整合

`shared-artifacts/references/progress-yaml.md` (143 行) を確認した結果:

- `blockers` フィールド (L57-L60) は「未解決の Blocker。文言は『事象 + 影響 + 対応方針』を含める」と規定済み → CI 失敗 Blocker もこの形式で記録可能、新フィールド追加不要
- `artifacts` フィールド (L62-L77) には PR / CI 関連エントリは存在しない (`intent_spec` / `research` / `design` / `qa_design` / `qa_flow` / `external_adrs` / `task_plan` / `todo` / `review` / `validation` / `retrospective`)
- Intent Spec §非スコープ「PR 概要を成果物として永続化する仕組み (`pr-overview.md` 等) は作らない」と整合 → `artifacts.pr_overview` のような新フィールドは**追加しない**
- ただし PR URL や CI run URL は再開時に必要になり得るため、追加フィールドとして `artifacts.pr_url` (1 件) や `blockers[].ci_run_url` (CI Blocker 時のみ) を最小限追加する案は検討余地あり (Intent Spec §スコープ「影響を受けるドキュメント整合性の維持 — `progress-yaml.md` などで PR / CI への参照追加が必要かは Step 2 (Research) / Step 3 (Design) で判断 (本 Intent では SKILL.md 改修と本サイクル PR を中心にするが、整合性を崩さない最小限の追記は許容)」)

→ **設計上の含意:** `progress-yaml.md` への追記は **最小限** (PR URL を `artifacts` に 1 行 / CI Blocker 用の `blockers[].ci_run_url` 任意フィールド) に留め、Step 3 architect が判断する。本観点では「追加するなら」の挿入位置として `references/progress-yaml.md` の `### artifacts` セクション (L62-L77) 末尾、および `### blockers` セクション (L57-L60) 末尾を提示する。

### F10. `git-workflow` スキルとの重複・矛盾チェック

`plugins/totto2727/skills/git-workflow/` の確認:

- `git-workflow/SKILL.md` (77 行) は Decision Flow と Universal Rules のみ。PR / CI ルールは **branch-split-workflow.md** にのみ存在
- `references/branch-split-workflow.md` の Phase 3 (L63-L70) で `gh pr create --base <base-branch> --title "..." --body "..." --assignee @me` を規定。**Draft PR (`--draft` flag) や CI 連携の規定はなし**
- `references/commit-rules.md` L60: Conventional Commits の `ci` type 定義のみ (CI 連携自体は未規定)

→ **設計上の含意:** `git-workflow` スキルは Branch-Split (複数 PR 並走) の文脈での `gh pr create` を扱うのみで、Draft PR や CI リトライ規律は未規定。Intent Spec §非スコープ「`git-workflow` スキル等への大規模変更は行わない」と整合させ、本サイクルでは `git-workflow` を**変更しない**方針が妥当。`dev-workflow/SKILL.md` 内に新ルールを完結させ、`git-workflow` を参照リンクのみで言及する形が最小変更。

## 引用元

### dev-workflow/SKILL.md (改修対象本体)

- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L15-L51` — タイトル + 基本方針 9 原則
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L54-L92` — 役割定義 (Main / Specialist)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L121-L135` — ステップ一覧表
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L143-L557` — ステップ詳細 (Step 1〜Step 9)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L158-L165` — Step 1 Exit Criteria + Gate
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L187-L194` — Step 2 Exit Criteria + Gate
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L221-L227` — Step 3 Exit Criteria + Gate
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L265-L275` — Step 4 Exit Criteria + Gate
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L305-L312` — Step 5 Exit Criteria + Gate
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L369-L378` — Step 6 Exit Criteria + Gate
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L424-L432` — Step 7 Exit Criteria + Gate
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L512-L518` — Step 8 Exit Criteria + Gate
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L547-L552` — Step 9 Exit Criteria + Gate
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L563-L572` — 「1. ワークフロー開始時」(Draft PR 作成タイミング候補)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L589-L602` — 「3. ゲート通過時」(CI PASS 確認の前提条件位置)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L604-L611` — 「4. Blocker 発生時」(CI 2 回リトライ → Blocker 統合点)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L613-L627` — 「5. セッション再開時」(CI Blocker 復旧フロー統合点)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L692` — 既存 PR 言及 1 (粒度比喩)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L701-L767` — 「ステップ完了時のコミット規約」(主要対象)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L713-L726` — ステップ別コミット内訳表
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L740-L750` — コミットメッセージ規約
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L752-L761` — コミット前チェック (CI 確認を組み込む候補)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L822-L835` — 並列起動のガイドライン
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L880-L888` — このスキルが扱わないこと
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L888` — 既存 PR/CI 言及 2 (CI/CD スコープアウト宣言)

### specialist-common/SKILL.md

- `plugins/dev-workflow/skills/specialist-common/SKILL.md:L177-L194` — 「7. Git コミットに関する注意」 + Git ガードレール (PR 操作の責任所在を拡張する候補位置)

### specialist-implementer/SKILL.md

- `plugins/dev-workflow/skills/specialist-implementer/SKILL.md:L29-L77` — implementer の作業手順 (タスク単位コミット規約) — PR 操作の Main 限定方針との整合確認

### shared-artifacts/SKILL.md / progress-yaml.md

- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md:L42-L59` — 成果物一覧表 (PR 概要は明示的に成果物に含まれない、Intent Spec §非スコープと整合)
- `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md:L57-L60` — `blockers` フィールド (CI Blocker 記録形式)
- `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md:L62-L77` — `artifacts` フィールド (PR URL 追加候補位置)

### git-workflow (既存 Git/PR 規約)

- `plugins/totto2727/skills/git-workflow/SKILL.md:L1-L77` — Decision Flow / Universal Rules
- `plugins/totto2727/skills/git-workflow/references/branch-split-workflow.md:L63-L70` — Phase 3 で `gh pr create` を規定 (Draft 規定なし)
- `plugins/totto2727/skills/git-workflow/references/commit-rules.md:L60` — Conventional Commits の `ci` type

### Intent Spec / 本サイクルブランチ

- `docs/workflow/2026-05-03-pr-ci-integration/intent-spec.md:L23-L31` — スコープ (新ルール 5 種 + ドッグフード)
- `docs/workflow/2026-05-03-pr-ci-integration/intent-spec.md:L46-L77` — 成功基準 SC-1〜SC-8 (Step 8 Validator が実測する観測形式)
- `docs/workflow/2026-05-03-pr-ci-integration/intent-spec.md:L91` — 「Specialist が GitHub 操作を直接行ってよいかは Step 3 Design で再整理」(F3 と整合)
- `docs/workflow/2026-05-03-pr-ci-integration/intent-spec.md:L115-L127` — 未解決事項 8 件 (Step 2 Research 引き継ぎ論点)
- `git log feat/dev-workflow-pr-ci-integration ^main` — 本サイクルの実証コミット 3 件 (`1ac3b5f`, `9a6a537`, `1cb5743`)

## 設計への含意

以下、5 ルールそれぞれの「挿入候補位置 (1〜2 案)」と「採用推奨案」、Step 1〜9 Exit Criteria への CI PASS 追加方針、既存「コミット規約」セクションとの関係、specialist-common 伝達方法、Intent Spec §未解決事項のうち本観点で扱う 3 件への答えを Step 3 architect が直接利用できる粒度で示す。

### I1. 5 ルールの挿入候補位置と推奨案

#### ルール 1: Draft PR 作成タイミング (サイクル初期化時)

| 案  | 挿入位置                                                                                                                                                  | 想定文量   | 利点                                                                                                   | 欠点                                                                                                                   |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| A   | `## 調整プロトコル / 1. ワークフロー開始時` (L563-L572) のステップ 4 と 5 の間に新ステップ 4.5「`gh pr create --draft` で Draft PR を作成」               | 2-3 行追記 | 既存 6 ステップの初期化フローに自然に組み込める / `progress.yaml` 初期化コミットと同じタイミングで完結 | ステップ番号の振り直しが必要 (4', 5', 6' → 5, 6, 7 等)。L571 の roadmap 配下サイクル特例 (現ステップ 5) との整合に注意 |
| B   | `## ステップ完了時のコミット規約 / ステップ別コミット内訳` (L713-L731) の「サイクル開始時」行 (L717) に「+ Draft PR 作成 (`gh pr create --draft`)」を追記 | 1 行追記   | 既存表に最小変更 / コミットと PR 作成の同期を表で表現                                                  | 「コミット規約」セクションは Git コミット中心なので PR 操作との混在で読み手に違和感                                    |

→ **推奨案: A** (`### 1. ワークフロー開始時` への新ステップ追加)。新ステップを「5. roadmap 配下サイクルの追加初期化」(現 L571) と並列の「6. Draft PR 作成」(新規) として 1 ステップ独立させ、ステップ 6 → 7 (現 L572 の Step 1 着手) に再番号する形が文書上の整合性が高い。**併用案 A+B も推奨**: 案 A で初期化フローに組み込み、案 B でコミット内訳表にも反映 (二重宣言で見落とし防止)。

#### ルール 2: PR 概要更新 (各 Step 完了時 + 適宜)

| 案  | 挿入位置                                                                                                                                                                                              | 想定文量                  | 利点                                                                                                                                                                            | 欠点                                                                                                      |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| A   | `## ステップ完了時のコミット規約` (L701-L767) を `## ステップ完了時のコミット・PR 概要・CI 確認規約` に拡張し、新サブセクション `### PR 概要更新` を `### ユーザー承認ゲート通過時` (L733) の前に挿入 | 5-10 行                   | 既存セクションを「ステップ完了時の三位一体 (コミット + PR 概要 + CI)」として再編成、関連事項を 1 セクションに集約 / 読み手は「ステップ完了したら何をするか」を 1 箇所で把握可能 | セクション名変更でリンク参照の更新が必要 (他スキルからの参照箇所要確認)                                   |
| B   | 新セクション `## サイクル PR と CI 連携プロトコル` を `## ステップ完了時のコミット規約` の直後 (L767 の後) に追加し、その中で PR 概要更新 / CI 確認 / Draft → Ready 化を全て規定                      | 30-50 行 (新規セクション) | 既存セクションを破壊せず追加のみ / PR / CI 関連を 1 箇所に集約 / 将来の拡張余地大                                                                                               | セクション数が増え目次が長くなる / 「コミット規約」と「PR / CI 連携」の境界が読み手に伝わりにくい場合あり |

→ **推奨案: B** (新セクション独立)。Intent Spec §スコープが「5 種の新ルール」を独立した変更単位として扱っているため、新セクションで一括規定することで `grep "Draft PR"` / `grep "PR 概要"` / `grep "CI"` の検索性が高まり、Step 8 Validator の SC-1〜SC-4 検証が容易になる。既存「ステップ完了時のコミット規約」セクション (L701-L767) は Git コミットに集中させ、PR / CI は新セクションに分離する。

#### ルール 3: CI 確認 + 2 回リトライ + Blocker 化 (各 Step Exit Criteria に追加)

| 案  | 挿入位置                                                                                                                                                                                                | 想定文量                                                              | 利点                                                                                                              | 欠点                                                                                                       |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| A   | `## ステップ詳細` 配下の各ステップ (Step 1〜9) の Exit Criteria 末尾に「該当コミットの CI が PASS している」を 1 行ずつ追加 + 新セクション (案 B) で詳細フロー (リトライ手段・Blocker 化) を規定        | 各ステップ Exit Criteria に 1 行 × 9 ステップ + 新セクション 15-20 行 | Exit Criteria に明示的に組み込まれることで Main 判定 / ユーザー承認ゲートの前提条件として強制力を持つ / 検索性高  | 9 箇所への分散追記で漏れリスクあり (review で各ステップを精査する必要)                                     |
| B   | `## ステップ完了時のコミット規約 / コミット前チェック` (L752-L761) の現行 6 ステップに「7. 該当コミットの CI が PASS することを確認 (FAIL なら最大 2 回リトライ、それでも FAIL なら Blocker 化)」を追加 | 5-10 行追記                                                           | 既存「コミット前チェック」フローに 1 ステップ追加するだけで全ステップ共通化 / 各ステップ Exit Criteria は変更不要 | 「コミット前チェック」は本来コミット**前**のチェックであり、CI は コミット**後**に走るので名前と実態の乖離 |

→ **推奨案: A** (Exit Criteria 各個追加 + 新セクションで詳細)。理由は (1) Intent Spec §SC-3 の検証 `grep -E "(CI|continuous integration|gh run)" plugins/dev-workflow/skills/dev-workflow/SKILL.md が 3 件以上ヒット` を満たすには各ステップ Exit Criteria への組み込みで自動的に CI 言及件数が増える、(2) 各ステップで「CI PASS = 完了」を明示することで Gate-Based Progression 原則 (L30) との整合が強く、(3) 案 B の「コミット前チェック」改名問題を回避できる。**書き方は全 9 ステップ統一のテンプレ表現**にし、例えば:

```
- 該当ステップ完了コミットに紐付く CI (.github/workflows/*) が PASS している (FAIL 時の対応は「`## サイクル PR と CI 連携プロトコル` / CI 失敗時の Blocker 化フロー」参照)
```

の 1 行を 9 箇所に追加。詳細フロー (2 回リトライ手段、Blocker 化、In-Progress ユーザー問い合わせ起動) は新セクション (案 B 推奨セクション) と「`### 4. Blocker 発生時`」(L604-L611) の補足で規定。

#### ルール 4: Step 9 完了後の Ready 化

| 案  | 挿入位置                                                                                                                                                                                                         | 想定文量                                                | 利点                                                                                                                  | 欠点                                                                                                                          |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| A   | `### Step 9: Retrospective` (L531-L557) の Exit Criteria (L547-L550) に「サイクル PR が Draft → Ready 化されている (`gh pr ready <PR>`)」を追加 + Main の作業 (L537-L541) に Ready 化アクションを 1 ステップ追加 | 2-3 行追記                                              | Step 9 完了 = Ready 化を Exit Criteria に組み込むことで成功基準と整合 / Specialist が変わらずに Main の責務として完結 | Ready 化のトリガー条件 (Retrospective コミット直後 / 最終ユーザー承認後) は Intent Spec §未解決事項のため Step 3 で確定が必要 |
| B   | 新セクション (ルール 2 推奨案 B の中) に「Step 9 完了後 Ready 化」サブ節を設け、Step 9 セクションからは新セクションを参照リンク                                                                                  | 新セクション内 5-10 行 + Step 9 セクションへの 1 行参照 | 全 PR / CI 関連を新セクションに集約 / 一貫性                                                                          | Step 9 セクションを読む読み手は新セクションへ飛ぶ必要 (1 ホップ増)                                                            |

→ **推奨案: A + B 併用** (Step 9 Exit Criteria に明示記述 + 新セクションで詳細フロー)。理由は SC-4 の検証 `grep -nE "(Ready (for review|化)|ready_for_review|undraft)"` が「Step 9 セクション内」をターゲットにしているため、案 A で Step 9 セクションに明示文言を置くことが必須。同時に案 B の新セクションでも詳細を規定して責任所在を明確化する。

#### ルール 5: PR description リポジトリ内永続化禁止

Intent Spec §スコープ §3 「PR 概要は GitHub 側にのみ保持し、リポジトリ内に永続化された成果物 (`pr-overview.md` 等) は作らない」。これは禁止規定であり、SKILL.md への追記は新セクションの一文で完結。

→ **推奨案:** 新セクション (ルール 2 推奨案 B のセクション) 冒頭で「PR description は GitHub 側にのみ保持し、`docs/workflow/<identifier>/` 配下に `pr-overview.md` 等として永続化しない (Single-Source-of-Progress 原則 / Artifact-as-Gate-Review 原則と整合し、PR description は派生表現の位置づけ)」を 1 段落で規定。`shared-artifacts/SKILL.md` の成果物一覧表 (L42-L59) には PR 関連エントリを**追加しない**ことで二重管理を防ぐ。

### I2. 各 Step Exit Criteria への CI PASS 項目追加方針

ルール 3 推奨案 A で 9 ステップ Exit Criteria に追加する文言を統一:

```markdown
- 該当ステップ完了コミット (Step 6 の場合は各タスク単位コミット) に紐付く CI (.github/workflows/\*) が PASS している。FAIL 時の対応は「## サイクル PR と CI 連携プロトコル」セクションを参照
```

挿入箇所 (Exit Criteria 末尾、現行最終項目の直後):

| Step | 現行 Exit Criteria 行範囲 | 挿入推奨位置                                                                                                                                                                     |
| ---: | ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|    1 | L158-L163                 | L163 の `intent-spec.md がコミット済み、progress.yaml.completed_steps に追記済み` の直後                                                                                         |
|    2 | L187-L192                 | L192 の `全 Research Note がコミット済み、progress.yaml に反映` の直後                                                                                                           |
|    3 | L221-L226                 | L223 の `design.md + progress.yaml がコミット済み (横断 ADR を起票した場合は ADR 本体も同コミット)` の直後                                                                       |
|    4 | L265-L273                 | L273 の `qa-design.md + qa-flow.md + progress.yaml がコミット済み` の直後                                                                                                        |
|    5 | L305-L310                 | L310 の `task-plan.md + progress.yaml がコミット済み` の直後                                                                                                                     |
|    6 | L369-L376                 | L375-L376 の `タスクごとに分割された全コミット` および `TODO.md + progress.yaml が最終状態で反映・コミット済み` の直後 (Step 6 はタスク単位コミットの CI を全て PASS と読み替え) |
|    7 | L424-L430                 | L430 の `review/*.md (全観点、Round 1〜N の追記履歴を含む) + progress.yaml がコミット済み` の直後                                                                                |
|    8 | L512-L516                 | L516 の `validation-report.md + validation-evidence/* (該当あれば) + progress.yaml がコミット済み` の直後                                                                        |
|    9 | L547-L550                 | L549 の `docs/retrospective/<identifier>.md + progress.yaml (status: completed に更新) がコミット済み (サイクル最終コミット)` の直後。**+ ルール 4 の Ready 化項目もここに追加** |

→ Step 6 のみ「タスク単位コミット = タスクごとに CI PASS 必要」という補足が必要なため、Step 6 Exit Criteria の追加文言だけは「全タスクコミットそれぞれに対応する CI が PASS している」と微修正する。

### I3. 既存「コミット規約」セクションとの関係

- **既存規約 (L701-L767):** 1 ステップ = 1 コミット (Step 6 のみタスク単位)、`docs(dev-workflow/<id>): ...` メッセージ規約、`git add` 明示パス指定、一時ファイル除外
- **新規ルール (本サイクル追加):** + 各コミット後に CI 確認、+ 各ステップ完了時に PR 概要更新 (`gh pr edit --body`)、+ サイクル開始時に Draft PR 作成、+ Step 9 完了後 Ready 化
- **整合方針:** 既存「コミット規約」は Git コミット中心の規約として**維持**。PR / CI ルールは新セクション `## サイクル PR と CI 連携プロトコル` (推奨セクション名) に分離し、既存セクションの末尾 (L767) に「PR 概要更新および CI 確認は『## サイクル PR と CI 連携プロトコル』を参照」と 1 行参照リンクを追加する。
- **補足:** 既存「ステップ別コミット内訳」表 (L713-L726) には変更なし。コミット内容自体は変わらない。新ルールはコミット**後**のアクション (PR 概要更新、CI 確認) であり、コミット**内容**ではない。

### I4. specialist-common での新ルール伝達方法

| 案  | 内容                                                                                                                                                              | 想定文量                          | 採否                                                                              |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- | --------------------------------------------------------------------------------- |
| A   | `specialist-common/SKILL.md` に新セクション「11. PR / CI 操作の責任所在」を追加 (現行は §0〜§10)                                                                  | 10-15 行新セクション              | 不採用 (specialist-common は横断ルールに集中、PR / CI は dev-workflow 本体の話題) |
| B   | `specialist-common/SKILL.md §7 (Git コミットに関する注意)` の冒頭リスト (L179-L184) に 1 行追加: 「PR 操作 (`gh pr create/edit/ready`) は Main が単独で実行する」 | 1 行追加                          | 推奨                                                                              |
| C   | `specialist-common/SKILL.md §7` には変更を加えず、`dev-workflow/SKILL.md` の新セクションのみで規定し、specialist-common から本ファイルへ参照リンクのみ            | 0 行 (specialist-common 変更なし) | 補完案                                                                            |

→ **推奨案: B + C 併用**。理由は (1) `specialist-common` は Specialist が読む横断ルール集なので「PR 操作は Main が単独」という責任所在ルールは §7 への追記が自然、(2) 詳細フロー (Draft PR 作成手順、CI リトライ手段等) は dev-workflow/SKILL.md 新セクションに集約し specialist-common には書かない、(3) Intent Spec §非スコープ「specialist-\* スキルへの大規模変更は行わない」と整合 (§7 への 1 行追加は「軽微な参照リンク追加」の範疇)。

具体追記文例 (`specialist-common/SKILL.md:L184` の直後):

```markdown
- **PR 操作 (`gh pr create/edit/ready`) は Main が単独で実行する**: Specialist (`implementer` 含む) は GitHub PR を直接操作しない。詳細は `dev-workflow/SKILL.md` の「サイクル PR と CI 連携プロトコル」セクション参照
```

### I5. Intent Spec §未解決事項 (本観点で扱う 3 件) への答え

#### Q1. Specialist が gh CLI を直接呼ぶか / Main 経由か (Intent Spec L123)

→ **A1: Main 単独。** 理由 (詳細は F3 / F6):

1. 並列 implementer 環境での PR 概要更新競合を回避 (Single-Source-of-Progress 原則 L25 と整合)
2. `specialist-common §7` の既存責任所在 (Git コミット = Main 実行、implementer のみ例外) との一貫性
3. 文書改修コストの最小化 (`specialist-common §7` への 1 行追加で完結、新セクション不要)

例外なし: `implementer` であっても PR 操作はしない (タスク単位コミットは行うが、その後の PR 概要更新は Main が並列タスク完了後にまとめて実施)。

#### Q2. Step 9 完了 = Ready 化のトリガー条件 (Intent Spec L124)

→ **A2: Retrospective コミット直後の Main 自動実行を推奨。** 理由 (詳細は F4):

1. SC-8 検証 `gh pr view <PR> --json isDraft` が `false` を要求するのみで「最終ユーザー承認後」は要求していない (実測上は Step 9 Main 判定ゲート L552 通過後の任意タイミングで OK)
2. Step 9 の Gate は「Main 判定 (ユーザーには情報共有のみ)」(L552) なので、ユーザー承認待ちのブロッキングは発生しない設計
3. Retrospective コミット (L549 の最終コミット) と Ready 化を同期させることで、外部観測者は「最終コミット = Ready 化」と機械的に判定可能

文書化: Step 9 Exit Criteria (L547-L550) の最終項目として `gh pr ready` 実行を組み込み、Main の作業 (L537-L541) のステップ 3 (現「次サイクルで参照可能な形式でリポジトリに保存」) の後に新ステップ 4「サイクル PR を `gh pr ready <PR>` で Draft → Ready 化」を追加する。

#### Q3. CI 失敗 → Blocker → ユーザー判断 → 復旧の進捗記録パス (Intent Spec L125)

→ **A3:** `progress.yaml.blockers[]` への記録形式を以下のとおり提案する。詳細は F5 / F9。

```yaml
blockers:
  - id: ci-fail-step-<N>-<sha-prefix>
    occurred_at: 2026-05-04T10:00:00Z
    event: 'CI failed for Step <N> commit <full-sha>'
    impact: 'Step <N> cannot be marked complete until CI PASS'
    ci_run_url: 'https://github.com/<org>/<repo>/actions/runs/<id>'
    retry_count: 2 # 0..2、2 で User Blocker 化
    response: 'In-Progress ユーザー問い合わせ起動中、ユーザー判断待ち'
```

- **TODO.md との整合:** Step 6 で CI Blocker が発生した場合、該当タスクを `TODO.md` の `[x]` から `[ ]` に戻し `re_activations` カウンタをインクリメント (既存の Step 7 Blocker 戻しと同パターン、L382-L384 の手順を準用)
- **再開時の手順:** L613-L627 の「5. セッション再開時」フローで `progress.yaml.blockers` に CI Blocker が残っていれば、Main は再開時にまず `gh run view <run-id>` で CI 現状を確認し、PASS 済みなら `blockers` から削除して当該ステップを完了化、FAIL のままなら In-Progress ユーザー問い合わせを再起動。「セッション再開時」ステップ 7 (L626) の Blocker 再提示フローで包括される。
- **`progress-yaml.md` への追記要否:** F9 の通り、`blockers` フィールドの汎用記述形式 (`事象 + 影響 + 対応方針`) でカバー可能なため、新フィールド `ci_run_url` / `retry_count` は**任意拡張**として `references/progress-yaml.md` `### blockers` セクションに 2-3 行のサブ節として追記を推奨 (Step 3 architect が判断)。`artifacts.pr_url` (PR 1 件) も同様に任意拡張として 1 行追記を推奨。

### I6. PR 概要更新責任 (Step 6 / Step 7 並列環境)

F6 の通り、**Main が PR 概要更新の単独責任者**。並列 Specialist (implementer × N、reviewer × 6) が個別に更新しない。書き方詳細:

- **Step 6 (並列 implementer × N):** Main は各タスクコミット完了 + TODO.md 更新コミット + CI PASS 確認の 3 点セット完了後にまとめて PR 概要を更新 (タスクごとに毎回更新するのではなく、Wave 単位 (`task-plan.md` の依存グラフで識別される並列実行単位) で集約更新を推奨)
- **Step 7 (並列 reviewer × 6):** Main は全 6 観点の Review Report 集約後にまとめて PR 概要を更新 (Round 単位で更新、Round N+1 が発生した場合は再更新)

これは Step 3 architect が PR description テンプレート設計時に「Wave 単位 / Round 単位の更新」を前提にすることで自然に実現される。

## 残存する不明点

以下は本観点 (integration-points) のスコープ外、または Step 3 architect での判断材料として残しておく論点:

1. **新セクション `## サイクル PR と CI 連携プロトコル` の正式名称:** 本 Note では仮称 `サイクル PR と CI 連携プロトコル` を使用したが、英語タイトル併記 (現行 SKILL.md の `## ワークフロー全体図` は日本語のみ、`## ステップ完了時のコミット規約` も日本語のみ) のスタイル整合性は Step 3 で確定。

2. **Draft PR 作成コマンドの正確な仕様:** `gh pr create --draft --title "..." --body "..." --base main --head <branch>` の正確な引数構成 / `--assignee @me` 要否 / `--label` 付与有無は researcher #1 (gh CLI 仕様調査) の所掌。本 Note では「文書上のどこに書くか」のみを扱った。

3. **CI 確認コマンドの正確な仕様:** `gh run list --branch <branch> --commit <sha>` / `gh run view <run-id> --json conclusion` / `gh run rerun --failed` 等の具体引数と挙動確認は researcher #2 (CI 構造調査) の所掌。本 Note では「文書上のどこに書くか」のみを扱った。

4. **PR description フォーマットのテンプレート構造:** Intent Spec §未解決事項「PR description のフォーマット」(L122) は Step 3 architect の所掌。本 Note では「リポジトリ内に永続化しない」原則の文書配置のみを扱った。

5. **L888「このスキルが扱わないこと」の改修要否最終判断:** F8 で案 1 (修飾語追加) / 案 2 (新セクションで住み分け宣言) を提示したが、最終判断は Step 3 architect。

6. **過去サイクル (`2026-04-29-retro-cleanup` 等) の PR 暗黙運用パターン:** researcher #4 (過去サイクル分析) の所掌。本 Note では本サイクル `feat/dev-workflow-pr-ci-integration` の 3 コミットの整合性確認のみを行った。

7. **本サイクル PR が Step 1 完了時点で既に作成されているか否か:** Step 1 完了コミット `1cb5743` の直後に Draft PR が作成されているかは未検証 (本 Note 作成時点でブランチ自体は存在するが PR 作成状況は `gh pr list` で別途確認が必要)。本サイクル自身が「ドッグフード実証」の最初の対象 (Intent Spec §93) なので、Main がインクリメンタルにルール適用を進めている段階と推測する。Step 8 Validator が SC-5 検証時に PR 作成タイムスタンプを実測する責務。

以上、Step 3 architect が改修案を構築する際は、本 Note の I1〜I6 を直接参照して挿入位置・文言案・責任所在を確定できる。
