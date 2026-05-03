# Research Note: ci-structure

- **Identifier:** 2026-05-03-pr-ci-integration
- **Topic:** ci-structure (本リポの既存 CI 構造とランタイム特性)
- **Researcher:** researcher#ci-structure
- **Created at:** 2026-05-03
- **Scope:** 本リポ (`totto2727-org/monorepo`) の GitHub Actions ワークフロー構成、必須チェック (required status checks)、ジョブ実行時間、再実行/失敗パターンの棚卸し。Step 3 Design で「CI PASS の定義」「リトライ規律」「ステップ完了後の CI 待機方針」を確定するための事実を提供する。

## 調査対象

Intent Spec「未解決事項」のうち以下 2 点に対し、本リポ固有の事実で回答する:

- **CI 失敗判定の粒度** — 「CI PASS」を必須チェックのみとするか / 全ジョブとするか
- **既存 CI ジョブの実行時間目安** — ステップ完了ごとに CI を待つ運用が現実的かの判断材料

加えて、Step 3 Design が必要とする以下の事実も併記する:

- ワークフロー / ジョブ / トリガー / 依存関係の一覧
- `pull_request` 再実行挙動 (`concurrency` / `cancel-in-progress`)
- 直近 failed run の失敗箇所分布と flaky 性
- 「失敗 = Blocker」「失敗 = リトライで治る」の境界

スコープ外: gh CLI 一般仕様 (researcher#1 担当)、過去サイクルの PR/CI 運用パターン (researcher#4 担当)、CI ワークフロー自体の改修提案 (Intent 非スコープ)。

## 発見事項

### F-1: ワークフローは 4 本のみ。CI 本体は単一ジョブ `check` のみ

リポジトリ内 `.github/workflows/` には 4 ファイルのみ。CodeQL / Dependency Graph は GitHub の "default setup" によるリポ内ファイル無しの dynamic workflow。

| Workflow                      | File                                                  | Trigger                                                                                                                   | Job                                                      | Concurrency                                                                                              |
| ----------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `CI`                          | `.github/workflows/ci.yaml`                           | `push` (main のみ) / `pull_request` (全ブランチ)                                                                          | `check` (`runs-on: ubuntu-latest`, `timeout-minutes: 5`) | `group: ${{ github.workflow }}-${{ github.ref }}` のみ。`cancel-in-progress` 未指定 (= デフォルト false) |
| `Publish @totto2727/bw`       | `deploy-bw.yaml`                                      | `push` to main + paths filter (`js/app/bw/**`, `.github/workflows/deploy-bw.yaml`, `.github/actions/setup-typescript/**`) | `publish`                                                | なし                                                                                                     |
| `Publish @totto2727/c-plugin` | `deploy-c-plugin.yaml`                                | `push` to main + paths filter (`js/app/c-plugin/**`, 同 yaml, setup-typescript)                                           | `publish`                                                | なし                                                                                                     |
| `Publish @totto2727/fp`       | `deploy-totto2727-fp.yaml`                            | `push` to main (paths filter なし)                                                                                        | `publish`                                                | なし                                                                                                     |
| (CodeQL)                      | `dynamic/github-code-scanning/codeql` (default setup) | `push` / scheduled / dynamic                                                                                              | `Code Quality: ...` / `Push on main` 等                  | デフォルト                                                                                               |
| (Dependency Graph)            | `dynamic/dependabot/update-graph` (default setup)     | dependabot push                                                                                                           | (内部)                                                   | デフォルト                                                                                               |

`needs:` を用いたジョブ依存は全ワークフローで未使用 (各 workflow が単一ジョブ)。

### F-2: 必須チェック (Required status checks) は **`check` ただ 1 つ**

リポジトリは旧来の "Branch protection rules" を持たない (`gh api .../branches/main/protection` は 404 "Branch not protected") が、`Repository rulesets` を 2 件持つ:

| Ruleset (id)         | Target / scope           | Required status checks                          | その他主要 rule                                                                                                                       |
| -------------------- | ------------------------ | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `All` (9367580)      | `~ALL` (全ブランチ)      | `[{ context: "check", integration_id: 15368 }]` | `pull_request` (approving review 0)、`required_status_checks` (strict=true)                                                           |
| `Default` (14454858) | `~DEFAULT_BRANCH` (main) | `[{ context: "check", integration_id: 15368 }]` | `pull_request` (approving review 1, dismiss_stale=true)、`merge_queue` (ALLGREEN)、`non_fast_forward`、`creation`/`update`/`deletion` |

両 ruleset とも required は `check` 1 個のみ。`integration_id: 15368` は GitHub Actions 自身の id。CodeQL / Dependency Graph / Publish 系は **必須ではない**。

`All` ruleset の `strict_required_status_checks_policy: true` により、PR は base ブランチ最新を取り込んだ上で `check` が PASS していなければマージできない (= "Require branches to be up to date before merging" 相当)。

### F-3: `check` ジョブの所要時間 — PR では中央値 109 秒、p90 120 秒、最大 140 秒

`gh run list` 直近 30 件の `pull_request` トリガー CI run (CI workflow のみ) を集計:

- **PR の `check` ジョブ単体 (startedAt → completedAt)**: 中央値 107s / 平均 107s / 最小 96s / 最大 132s / p90 115s (n=30)
- **PR の "createdAt → 完了" (ユーザーから見た合計時間。queue 含む)**: 1 件の outlier (24h スタックした手動再実行: id `25241951988`) を除いて、中央値 109s / 平均 111s / 最小 98s / 最大 140s / p90 120s (n=29)
- **queue 待ち時間 (createdAt → job startedAt)**: 中央値 2s / 最大 8s (outlier 除く)
- **main の `check` ジョブ**: 中央値 141s / 最大 170s (n=5、push event)。PR より僅かに長い傾向 (merge コミットで影響範囲が広いため)

ジョブ内訳の体感値: `actions/checkout` + `setup-moonbit` + `setup-typescript` (devbox + setup-vp + `vp install`) + `devbox run -- 'vp run -r prebuild && vp run -r check && vp run -r test && vp run -r build'`。`timeout-minutes: 5` 設定だが実測は最長でも 2m20s 程度で十分余裕。

### F-4: `pull_request` トリガーは push ごとに新規 run を生成、旧 run は cancel されず完走

`concurrency.group: ${{ github.workflow }}-${{ github.ref }}` のみで `cancel-in-progress` は未指定 = `false`。実測でも同一 PR ブランチで連続コミットすると、各 run は別 `databaseId` を持ち、いずれも完走している。例: branch `worktree-elegant-doodling-stearns` で 10 件の独立した CI run が完了。

- **含意**: PR への新コミット push は「新規 run を生成」する。Step 完了コミットを push したら、その SHA で新規 run が作られる。
- 既存 run を cancel して新規だけ走らせたい場合は `cancel-in-progress: true` の追加が必要だが、Intent 非スコープ。

### F-5: 直近 failed run 4 件はすべて oxfmt の "Formatting issues found" / 失敗時間も短い

直近 30 件中 failure は PR 3 件 + main 1 件 = 計 4 件。全件 `check` ジョブ内の `Run check, build, and test` ステップで失敗:

| run id        | branch                                 | 失敗箇所                                 | 所要時間 (createdAt→completedAt) |
| ------------- | -------------------------------------- | ---------------------------------------- | -------------------------------- |
| `24951883867` | main (push, merge of #90)              | `error: Formatting issues found` (oxfmt) | 81s                              |
| `25212480243` | `worktree-elegant-doodling-stearns`    | `error: Formatting issues found` (oxfmt) | 132s                             |
| `25241951988` | `worktree-dazzling-meandering-pudding` | `error: Formatting issues found` (oxfmt) | 110s (run_attempt=2 の rerun)    |
| `25267108217` | `worktree-clever-moseying-fiddle`      | `error: Formatting issues found` (oxfmt) | 128s                             |

すべて `vp run -r check` 内の oxfmt が "Formatting issues found" を出して exit 1 → `devbox run` exit status 1 → step failure。型エラー / テスト失敗 / build 失敗による失敗例は直近 30 件には**観測されなかった** (調査範囲内)。

### F-6: 再実行 (`run_attempt > 1`) はほぼゼロ — flaky 性は実用上ない

直近 100 run 中、`run_attempt` の分布は `attempt=1: 99 件`、`attempt=2: 1 件`。唯一の attempt=2 は `25241951988` (上記 F-5) で、initial 失敗 → 約 24h 後に手動 rerun → 再度 same な Formatting failure。**flaky 起因の rerun は 0 件**。本リポでは「失敗 = 実装/設定の決定的な問題」と仮定して良い。

### F-7: `setup-moonbit` / `setup-typescript` は composite action として `.github/actions/` に切り出し済み

`ci.yaml` は `./.github/actions/setup-moonbit` (moon toolchain + `moon update`) と `./.github/actions/setup-typescript` (devbox install + `voidzero-dev/setup-vp@v1.6.0` with cache + `vp install`) を順に呼ぶ。デプロイ系 workflow は setup-typescript のみ使用。共通アクションのキャッシュが効いているため queue 後のセットアップは高速 (合計 1m40s 前後)。

## 引用元

- ワークフロー定義
  - `/.github/workflows/ci.yaml` L1-L25 (`name: CI`, triggers `push: branches: [main]` / `pull_request:`, `concurrency.group`, `timeout-minutes: 5`, `run: devbox run -- 'vp run -r prebuild && vp run -r check && vp run -r test && vp run -r build'`)
  - `/.github/workflows/deploy-bw.yaml` L1-L39 (paths filter, npm publish guard via registry HTTP 200 check)
  - `/.github/workflows/deploy-c-plugin.yaml` L1-L39 (同上、対象は c-plugin)
  - `/.github/workflows/deploy-totto2727-fp.yaml` L1-L37 (jsr publish + npm publish guard、paths filter なし)
  - `/.github/actions/setup-moonbit/action.yaml` L1-L14 (`hustcer/setup-moonbit@v1.19` + `moon update`)
  - `/.github/actions/setup-typescript/action.yaml` L1-L31 (`jetify-com/devbox-install-action@v0.14.0` + `voidzero-dev/setup-vp@v1.6.0` + `vp install`)
- Repository rulesets (gh api 実行結果)
  - `gh api repos/totto2727-org/monorepo/rulesets` → 2 件 (id 9367580 "All" / 14454858 "Default")
  - `gh api repos/totto2727-org/monorepo/rulesets/9367580` → `required_status_checks: [{context: "check", integration_id: 15368}]`、`strict_required_status_checks_policy: true`
  - `gh api repos/totto2727-org/monorepo/rulesets/14454858` → 同 required check 1 つ、`merge_queue.grouping_strategy: ALLGREEN`、`pull_request.required_approving_review_count: 1`
  - `gh api repos/totto2727-org/monorepo/branches/main/protection` → 404 "Branch not protected" (旧 branch protection は未使用)
- Run history
  - `gh run list --branch main --limit 30 --json conclusion,createdAt,updatedAt,databaseId,name,event,workflowName,...` → CI 6 件 / Publish 系 / CodeQL 多数
  - `gh run list --limit 30 --event pull_request --json ...` → CI 30 件 (うち failure 3 件、すべて Formatting)
  - `gh run view <id> --json jobs` で各 job の `startedAt` / `completedAt` を取得し集計
  - `gh run view <id> --log-failed` で 4 件の failed run を確認、全件 `error: Formatting issues found` → `Process completed with exit code 1`
  - `gh api repos/totto2727-org/monorepo/actions/runs?per_page=100` → `run_attempt` 分布 99:1 (attempt=1:attempt=2)
- Registered workflows (動的含む)
  - `gh api repos/totto2727-org/monorepo/actions/workflows` → 6 件 (CI / Publish bw / Publish c-plugin / Publish fp / Dependency Graph (`dynamic/dependabot/update-graph`) / CodeQL (`dynamic/github-code-scanning/codeql`))
- Intent Spec
  - `docs/workflow/2026-05-03-pr-ci-integration/intent-spec.md` L115-L127 (未解決事項リスト、本 Note の対応対象)

## 設計への含意

### I-1: 「CI PASS」の定義は **必須チェック `check` の最終結果のみ**で確定して良い (Intent Spec 未解決事項「CI 失敗判定の粒度」への回答)

- ruleset で必須化されているのは `check` 1 つだけ。CodeQL / Dependency Graph / Publish 系は必須ではないため、これらが未完了/失敗でもマージは ruleset 上ブロックされない。
- Step 3 Design では「ステップ完了コミットの SHA に対して `check` ジョブの最終 conclusion が `success` であること」を「CI PASS」の定義として採用するのが本リポの実態に整合する。
- 検証コマンド例: `gh run list --branch <branch> --workflow CI --json headSha,conclusion,databaseId --jq '.[] | select(.headSha=="<SHA>")'`、または `gh pr checks <pr-number>` で `check` 行を抽出。
- 注意: `strict_required_status_checks_policy: true` (All ruleset) のため、main 更新後に PR は最新化が必要。SC-7 の「最終 PASS」判定では「base 最新化後に走った run が success」を要件とすべき。

### I-2: ステップ完了ごとに CI 完走を待つ運用は **十分実用的** (Intent Spec 未解決事項「既存 CI ジョブの実行時間目安」への回答)

- 通常 PR の `check` 完走は中央値 1m49s、p90 2 分、最大 2 分 20 秒。queue 待ちは 2〜8 秒。
- 9 ステップ分すべてで待っても理論上 9 × 2 分 = **18 分程度**で済む。Step 6 (Implementation) のタスク単位コミットでも数分追加に過ぎない。
- Step 3 Design は「ステップ完了コミット push → CI 完走確認 → 次ステップ着手」を直列で組んで問題ない。バックグラウンドで監視する場合でも、ポーリング間隔は 30 秒〜1 分で十分 (run 完了の検出に大きな遅延は出ない)。
- バックグラウンド監視タイムアウトの目安として、**5 分** (workflow 側 `timeout-minutes: 5` と一致) を Blocker 判定閾値にすれば現実的な余裕を持って取れる。

### I-3: リトライ規律は「**新規コミット push 中心**、`gh run rerun` は補助」が安全 (Intent Spec 未解決事項「CI リトライの実装手段」への部分回答)

- 直近 failed run はすべて Formatting (oxfmt) で再実行しても結果は変わらない (run_attempt=2 の `25241951988` も同じ理由で再失敗)。コードを修正せずに `gh run rerun` するだけでは無意味。
- 一方で flaky は実質ゼロ (F-6) のため、「リトライで治る一過性失敗」は本リポでは想定する必要がほぼない。
- Step 3 Design 推奨: 「CI 失敗 → 失敗内容を `gh run view --log-failed` で読む → 直す → 新コミット (`fix: ...` または `style: apply oxfmt` 等) を push (= 新規 run 自動生成)」を 1 リトライとカウント。`gh run rerun` の純粋呼び出しは原則使わず、本リポでは「コード/設定を直して push」がリトライの実体。
- 2 回失敗で Blocker 化する Intent Spec ルールは、本リポの flaky 性ゼロ前提と整合する。

### I-4: failed の典型は oxfmt 違反 — Step 6 (Implementation) で `vp check --fix` の事前実行を planner/implementer に伝える価値あり

- 直近 failed 4/4 が Formatting issue。原因の典型は「ローカル開発で `vp check --fix` を忘れた」または「自動生成ファイル (`worker-configuration.d.ts` 等) が devbox 環境で再生成されたが手元に commit されていなかった」。
- Step 3 Design / Step 5 Task Plan で「タスク完了 → push 前に `vp check --fix && vp check && vp test` をローカルで通す」という運用ガイダンスを書いておくと、CI Blocker 発生数を実質的に低減できる。
- Intent Spec 非スコープ (CI ワークフロー自体の改修) には踏み込まないが、運用ガイダンスとして SKILL.md / `git-workflow` 軽微参照は許容範囲 (Intent Spec L34 にもある通り)。

### I-5: PR ベースのバックグラウンド CI 監視は `gh pr checks --watch` または `gh run list --branch <branch> --workflow CI --limit 1` の比較で実装可能

- ワークフローは 1 本 (`CI`) かつジョブも 1 本 (`check`) なので、`gh pr checks <pr> --json name,status,conclusion` 出力をフィルタするロジックが極めて単純。複雑な並列ジョブ集約は不要。
- `cancel-in-progress` 未設定のため、Step 完了コミット直後に push を重ねた場合、古い run も完走してしまう。Step 3 Design では「最新 SHA = `git rev-parse HEAD` で実行された run の conclusion を見る」ロジックにする (古い run は無視)。
- `merge_queue` (Default ruleset, ALLGREEN) は本サイクルでは原則使わない (PR は単純 merge → main push)。merge_queue 経路の挙動検証は Intent 非スコープ。

### I-6: Step 9 完了後の Ready 化は CI 待ちと独立に実行可能だが、Ready 化 = "main にマージ可能宣言" のため CI 完走後が望ましい

- `gh pr ready` 自体は CI 状態に関係なく成功する。ただし Ready 化直後に main 更新があれば `strict_required_status_checks_policy: true` により再 CI が必要になる。
- Step 3 Design 推奨: `Step 9 retrospective コミット push → CI PASS 確認 → gh pr ready` の順 (Intent Spec SC-7 と SC-8 の要件を両立)。

## 残存する不明点

| #   | 不明点                                                                                                               | 推奨対応                                                                                                                                                    |
| --- | -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `gh run rerun` / `gh run rerun --failed` の挙動詳細 (新規 run id を作るか、`run_attempt` のみ増やすか、ログに残るか) | researcher#1 (gh CLI 一般仕様) の担当範囲。本観点では「flaky 想定が不要なので rerun 自体ほぼ使わない」結論で十分                                            |
| 2   | `merge_queue` (Default ruleset の ALLGREEN) を使った場合の CI 走り方                                                 | Intent 非スコープ (本サイクルは通常 PR merge を想定)。Step 3 Design で「merge_queue は使わない」と明示するだけで足りる                                      |
| 3   | CodeQL / Dependency Graph の失敗が将来必須化された場合の影響                                                         | 現状非必須なので Intent スコープ外。Design で「CI PASS = 必須チェック (`check`) のみ」と固定すれば将来変更時も Design 修正で対応可                          |
| 4   | `concurrency.cancel-in-progress` を有効化すべきかの議論                                                              | Intent 非スコープ (CI ワークフロー自体の改修)。本 Note では「未設定なので最新 SHA で run を判定する」運用前提を提示                                         |
| 5   | Publish 系 workflow が main push で失敗した場合の扱い                                                                | 本サイクルは PR 中心の運用ルール定義。main push 後の Publish 失敗対応は本サイクル非スコープ。Design で「対象は `check` のみ」と限定                         |
| 6   | 全 30 件サンプルでの failure 比率の母集団代表性                                                                      | サンプル数 30 で OS / 月の偏りはあるが、傾向 (Formatting 100%) は十分有意。Design で「失敗パターンの第一候補は Formatting」とガイダンスする程度に留めて良い |
