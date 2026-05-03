# Validation Report: 2026-05-03-pr-ci-integration

- **Validator:** specialist-validator (single instance, dev-workflow Step 8)
- **Validated at:** 2026-05-03T06:19:11Z (UTC) / 2026-05-03 15:19 JST
- **Target:** 実装済み diff (`feat/dev-workflow-pr-ci-integration` HEAD = `53ccf5a`、PR #95) と GitHub 上の実 PR / CI 状態
- **Reference:** `docs/workflow/2026-05-03-pr-ci-integration/intent-spec.md` の成功基準 SC-1〜SC-8、`docs/workflow/2026-05-03-pr-ci-integration/qa-design.md` の TC-001〜TC-022

## サマリ

| 判定         | 件数 |
| ------------ | ---- |
| PASS         | 5    |
| FAIL         | 1    |
| 保留（明示） | 1    |
| PENDING      | 1    |

**全体判定:** `partially_passed`

判定の内訳:

- **PASS (5):** SC-1, SC-2, SC-3, SC-4, SC-5
- **FAIL (1):** SC-7 (一部の中間コミットで CI 失敗が発生し、リトライ規律違反 9 連続 failure を観測。新プロトコル成立 (Step 6 task-T1) 以降の Step 6 / Step 7 完了コミットは success)
- **保留 (1):** SC-6 (PR description の編集履歴は GitHub REST API では timeline に現れず、各 Step 完了時刻と更新時刻の対応は観測不能。`updated_at > created_at` のみ判定可)
- **PENDING (1):** SC-8 (Step 9 完了後の Ready 化を要求するため、Step 9 未完了の現時点では判定不可)

カバレッジ: SC-1〜SC-8 すべてに 1 件以上の TC-NNN が紐づいており未カバーなし (qa-design.md カバレッジ表で確認済み)。

## 成功基準ごとの判定

### 成功基準 #1 (SC-1): SKILL.md ルール追加 — Draft PR セクション

> `plugins/dev-workflow/skills/dev-workflow/SKILL.md` に「サイクル初期化時に Draft PR を作成する」旨を明示するセクションまたは項目が追加されている

- **観測値:**
  - `grep -cE "(Draft PR|draft pull request|Draft Pull Request)" plugins/dev-workflow/skills/dev-workflow/SKILL.md` → **3** (期待 ≥1)
  - `grep -nE "initialize cycle" SKILL.md` → 3 ヒット (L756, L796, L1017)。L796 は Draft PR セクション本文 (`### Draft PR 初期化 (サイクル開始時)`) で「`docs(dev-workflow/<identifier>): initialize cycle` と同時に対応する **Draft PR** を 1 件作成する」と明記
- **判定:** **PASS**
- **証拠:** `validation-evidence/static/sc3-pr-ci-section.txt` (PR/CI プロトコル節抽出)、SKILL.md L794〜L815 の `### Draft PR 初期化 (サイクル開始時)` サブセクション本文 + bash 擬似コードブロック
- **計測手段:** 静的検証 (`grep -cE` / `grep -nE` / `grep -B5 -A5`)
- **計測条件:** ローカルチェックアウト `feat/dev-workflow-pr-ci-integration` HEAD = 53ccf5a、macOS gnu-grep (ggrep) 使用
- **備考:** TC-001 / TC-002 ともに PASS。「initialize cycle と Draft PR の同時作成」が文中で明示的に接続されている

### 成功基準 #2 (SC-2): SKILL.md ルール追加 — PR 概要更新セクション

> SKILL.md に「PR 概要を各ステップ完了時に必ず更新する」旨と「内容変化時の任意更新」旨が記述されている

- **観測値:**
  - `grep -cE "(PR (概要|description|overview)|プルリクエスト概要|pull request description)" SKILL.md` → **10** (期待 ≥2)
  - `grep -cE "(各ステップ完了時|各 Step 完了時|ステップ完了時に必ず)" SKILL.md` → **7**
  - `grep -cE "(適宜|随時|内容変化)" SKILL.md` → **1**
- **判定:** **PASS**
- **証拠:** SKILL.md L817〜L836 の `### PR 概要更新 (各ステップ完了時)` サブセクション。L819 で「**各ステップ完了時に必ず更新する**。さらに、ステップ途中であっても内容に変化があれば**適宜**更新してよい」と両タイミングを明記
- **計測手段:** 静的検証 (`grep -cE`)
- **計測条件:** 上記と同じ
- **備考:** TC-003 / TC-004 ともに PASS。両タイミング表現 (必須 + 適宜) が共存

### 成功基準 #3 (SC-3): SKILL.md ルール追加 — CI 確認 / 2 回リトライ / Blocker 化

> SKILL.md に「ステップ完了コミットに紐づく CI が PASS するまで当該ステップを完了と認めない」「失敗時は最大 2 回リトライ」「2 回失敗で Blocker 化しユーザー判断」が明文化されている

- **観測値:**
  - `grep -cE "(CI|continuous integration|gh run)" SKILL.md` → **31** (期待 ≥3)
  - `grep -cE "(2 回|二回|retry|リトライ)" SKILL.md` → **15** (期待 ≥1)
  - PR/CI プロトコル節 (`## サイクル PR と CI 連携プロトコル` 配下、コードフェンス除外、184 行) 内で:
    - `grep -cE "(Blocker|In-Progress)"` → **7** (期待 ≥1)
    - `grep -cE "(リトライ|2 回|二回|retry)"` → **5** (期待 ≥1)
- **判定:** **PASS**
- **証拠:** `validation-evidence/static/sc3-pr-ci-section.txt`。SKILL.md L863〜L944 (`### バックグラウンド CI 確認とリトライ規律`) で「最大 2 回までリトライ」「3 回目失敗時に Blocker 化 → In-Progress ユーザー問い合わせ」の連鎖が明記
- **計測手段:** 静的検証 + `gawk` でコードフェンス除外したセクション抽出 (`/tmp/claude/extract-sc3.sh`)
- **計測条件:** 上記と同じ
- **備考:** TC-005 / TC-006 / TC-007 すべて PASS。同 H2 内で Blocker 経路とリトライ経路が両方明示

### 成功基準 #4 (SC-4): SKILL.md ルール追加 — Step 9 完了後 Ready 化

> SKILL.md の Step 9 セクションまたは関連セクションで「Retrospective 完了後に PR を Draft → Ready 化する」旨が記述されている

- **観測値:**
  - `### Step 9 完了後の Ready 化` H3 サブセクション (21 行) を抽出 → `grep -cE "(Ready (for review|化)|ready_for_review|undraft)"` → **2** (期待 ≥1)
  - 抽出本文には「Retrospective コミット直後」「`gh pr ready` を冪等に実行」「`isDraft: true` 時のみ実行、`isDraft: false` ならスキップ」の冪等ガード bash 擬似コードを含む
- **判定:** **PASS**
- **証拠:** `validation-evidence/static/sc4-step9-ready-section.txt`、SKILL.md L945〜L965
- **計測手段:** 静的検証 + `gawk` で H3 サブセクション抽出 (`/tmp/claude/extract-sc4.sh`)
- **計測条件:** 上記と同じ
- **備考:** TC-008 PASS (代替案 b: 「サイクル PR と CI 連携プロトコル」配下の H3 で記述充足)

### 成功基準 #5 (SC-5): 本サイクル PR の Draft 作成

> 本サイクル PR が GitHub 上で Draft として作成され、`docs(dev-workflow/2026-05-03-pr-ci-integration): initialize cycle` 相当のコミットを含む

- **観測値:**
  - `gh pr list --state all --search "2026-05-03-pr-ci-integration" --json number,isDraft,createdAt,title,headRefName` → 1 件ヒット (PR #95、`isDraft: true`、`createdAt: 2026-05-03T01:50:41Z`)
  - PR #95 の現在状態: `isDraft: true`、`baseRefName: main`、`headRefName: feat/dev-workflow-pr-ci-integration`
  - `gh pr view 95 --json commits --jq '.commits[].messageHeadline'` で `docs(dev-workflow/2026-05-03-pr-ci-integration): initialize cycle` を含むコミットを確認 (1 件)
  - PR 本文 (`gh pr view 95 --json body --jq .body`) の H2 見出し: `## Summary` / `## Cycle` / `## Scope` / `## Implementation summary (Step 6 done)` / `## Progress` / `## CI status` / `## Notable events` / `## Test plan` / `## Artifacts` (9 個の H2)
  - PR タイムラインに `convert_to_draft` イベントが 0 件、Draft 作成のまま現在まで継続 → 「作成時点で Draft」の証拠
- **判定:** **PASS**
- **証拠:** `validation-evidence/dynamic/pr95-body.md`、`validation-evidence/dynamic/pr95-commits.txt`、`validation-evidence/dynamic/pr95-timeline.jsonl`
- **計測手段:** 動的検証 (`gh pr view --json` / `gh pr list --json` / `gh api repos/.../timeline`)
- **計測条件:** 2026-05-03T06:19:11Z (UTC) 時点の GitHub 状態、リポジトリ `totto2727-org/monorepo`、PR #95
- **備考:**
  - **TC-012 PASS:** `convert_to_draft` イベント不在で「作成時点で Draft」証明
  - **TC-013 PASS:** `initialize cycle` コミット含有 (1 件)
  - **TC-014 注記:** qa-design.md TC-014 の厳格基準 (`^## (Summary|Cycle artefacts|Progress checklist)` ≥3) で評価すると 1 ヒット (Summary のみ完全一致)。実 PR body の見出しは `## Cycle` / `## Progress` と短縮されており、design.md L102-L153 のテンプレート (`## Cycle artefacts` / `## Progress checklist`) と差異がある。**ただし SC-5 の本質要件「最低限サイクル概要 / Step 進捗 / 関連 issue (あれば) 相当が含まれる」は 9 個の H2 で実体的に満たされている**ため SC-5 全体は PASS と判定。テンプレート見出し名の正規化は次サイクルへの引き継ぎ事項とする (Notable observation 1)

### 成功基準 #6 (SC-6): 本サイクル PR の概要更新トレース

> 本サイクル中、各ステップ完了時に PR 概要が更新されたことが PR の編集履歴から読み取れる

- **観測値:**
  - `gh api repos/totto2727-org/monorepo/issues/95 --jq '{created:.created_at, updated:.updated_at}'` → `created: 2026-05-03T01:50:41Z`、`updated: 2026-05-03T06:10:29Z`
  - `updated_at > created_at` (差: 約 4 時間 20 分) → 初回作成後に少なくとも 1 回 description が編集された証拠
  - PR タイムラインの取得結果 (26 イベント) は `committed` (25 件) + `head_ref_force_pushed` (1 件) のみ。**`renamed` / description 編集を示す event は GitHub REST API の timeline では現れない仕様** (qa-design.md TC-015 注記と一致)
  - Step 7 完了コミット (`1989e19`、`2026-05-03T06:09:23Z` UTC) と PR `updated_at` (`06:10:29Z`) が 1 分差 → 直近 Step 完了直後に PR body 更新を実施した間接証拠
- **判定:** **保留 (deferred)**
  - 理由: TC-015 の単純判定 (`updated_at > created_at`) は **PASS** だが、TC-016 が要求する「**各 Step 完了時刻と description 更新時刻の対応**」は GitHub API の制約で観測不能。`updated_at` は最新 1 回分しか取得できず、各 Step 完了に対応する複数回更新の履歴は API レベルで観測手段が存在しない
- **証拠:** `validation-evidence/dynamic/pr95-timeline.jsonl`、`gh api repos/.../issues/95` JSON 抜粋
- **計測手段:** 動的検証 (`gh api`)
- **計測条件:** 上記と同じ
- **備考:**
  - **TC-015 単独では PASS** (`updated > created` 成立)
  - **TC-016 は計測不能** (GitHub REST API 仕様上、PR description 編集タイムスタンプの履歴取得手段なし)
  - 厳密な要件達成証拠は不足するが、Step 7 完了直後の `updated_at` 更新から **複数回更新が行われた強い間接証拠**は存在する。完全 PASS でも完全 FAIL でもないため **保留** とする。次サイクル以降の改善案: PR body 更新ごとに progress.yaml に「pr_body_update_at: <timestamp>」を記録するなど、観測可能性をリポジトリ側で担保する設計検討 (Notable observation 2)

### 成功基準 #7 (SC-7): 本サイクル中の各ステップ完了コミット CI が PASS

> Step 1〜Step 9 の各ステップ完了コミット (Step 6 はタスク単位コミット) について、対応する CI 実行が最終的に PASS している

- **観測値:**
  - `gh run list --branch feat/dev-workflow-pr-ci-integration --limit 100 --json ...` → 計 14 run (workflowName: CI、event: pull_request)
  - **conclusion 内訳: failure 9 件 / success 5 件**
  - 時系列: `b05b5f29 success` → `9a6a537b success` → `1cb57436 success (Step 1 完了)` → **`a0a50077 failure (Step 2 完了)` → `ab0d18e9 failure (Step 3 完了)` → `cdbc8863 failure (Step 4 完了)` → `7d4ca953 failure (Step 5 完了)` → `c75818a7 failure (Wave 1 開始)` → `bfb9c92d failure (T4 完了)` → `03473b66 failure (T5 完了)` → `62239371 failure (T1 完了)` → `7c06bfd8 failure (T2 完了)`** → `fd519c6b success (Step 6 完了)` → `53ccf5a5 success (Step 7 progress 更新)`
  - **9 連続 failure** が観測された (`a0a50077` 04:38:13Z 〜 `7c06bfd8` 05:32:32Z)
  - Step 単位の完了コミットでの最終 CI conclusion (push の最新 run のみ実装される GitHub Actions 仕様に従う):
    - Step 1 (1cb5743): success
    - Step 2 (a0a5007): **failure** (リトライなし、次の push にまとめて success)
    - Step 3 (ab0d18e): **failure**
    - Step 4 (cdbc886): **failure**
    - Step 5 (7d4ca95): **failure**
    - Step 6 (fd519c6): success
    - Step 7 (1989e19 / 53ccf5a): success
  - 中間コミット (Wave 1〜3 の各 task コミット間など) は `pull_request.synchronize` イベントの仕様で push の最新コミットにのみ run が紐づき、間のコミットには run なし
- **判定:** **FAIL**
  - 理由 1: Step 2〜Step 5 完了コミット (a0a5007 / ab0d18e / cdbc886 / 7d4ca95) はいずれも CI = failure のまま、リトライせず次の Step に進行している (新プロトコル「CI が PASS するまでステップ完了と認めない」「最大 2 回リトライ」違反)
  - 理由 2: 9 連続 failure が観測されており、TC-018 の判定基準「3 回目の失敗が出ていれば違反」を超過
  - 理由 3 (TC-019): `progress.yaml.blockers` フィールドは `[]` (空) であり、9 連続 failure の Blocker 記録なし。新プロトコルが要求する「2 回 failure → Blocker 化 → ユーザー判断」のフロー実施跡なし
- **証拠:** `validation-evidence/dynamic/pr95-runs.json` (14 run の詳細)、`validation-evidence/dynamic/branch-commits.txt`、`docs/workflow/2026-05-03-pr-ci-integration/progress.yaml` (`blockers: []`)
- **計測手段:** 動的検証 (`gh run list --branch ... --json conclusion,headSha,createdAt,attempt,databaseId` + `jq` 集計)
- **計測条件:** 上記と同じ
- **備考:**
  - **重要な解釈ポイント:** SKILL.md L792 で「**本プロトコルは新規サイクル(本プロトコル成立後に開始されるサイクル)に対して適用する。既に進行中・完了済みのサイクルへの遡及適用は行わない**」と明記されている。本サイクル `2026-05-03-pr-ci-integration` 自身は本プロトコル成立前 (Step 6 task-T1 commit `45dff2b` 2026-05-03T05:21:52Z で初めて SKILL.md に追加) から進行中であったため、Step 1〜Step 5 完了時点では新ルールがリポジトリに存在しない状態
  - **新プロトコル成立後 (T1 commit 以降) の評価:** Step 6 完了 (fd519c6) と Step 7 完了 (1989e19/53ccf5a) はいずれも CI = success
  - **遡及不適用ルールを採用した場合の評価:** SC-7 PASS (新ルール適用範囲のすべてが success)
  - **遡及適用 / 厳密評価の場合:** SC-7 FAIL (上記 3 理由)
  - 本 Validation Report では **厳密評価で FAIL を採用** し、ドッグフード性 (本サイクル自身が新ルール準拠) の観点で課題があったことを観測値として記録する。総合判定への影響は「新ルールの遡及不適用ルールが SKILL.md に明記済み」という事実から軽減される (詳細は「未達基準への対応方針」参照)
  - TC-017 / TC-018 / TC-019 すべて FAIL (厳密評価) または vacuously PASS (遡及不適用評価)

### 成功基準 #8 (SC-8): Step 9 完了後の Ready 化

> Step 9 完了後、本サイクル PR が Draft から Ready 化されている

- **観測値:**
  - `gh pr view 95 --json isDraft --jq '.isDraft'` → **`true`** (Draft のまま)
  - PR タイムラインに `ready_for_review` イベント不在
  - Step 9 (Retrospective) は本 Validation 実施時点で未着手 (`progress.yaml` に Step 9 完了記録なし、TODO.md にも未完了)
- **判定:** **PENDING**
  - 理由: SC-8 は「Step 9 完了後に PR が Ready 化されている」を要求するが、Step 9 完了は Step 8 (本 Validation) 後の Step。Step 8 実行時点では原理的に判定不能。`isDraft: true` のままであることは新ルール (Step 9 完了後 Ready 化) と整合
- **証拠:** `validation-evidence/dynamic/pr95-timeline.jsonl` (`ready_for_review` イベント 0 件)、`gh pr view 95 --json isDraft` 出力
- **計測手段:** 動的検証 (`gh pr view --json isDraft`、`gh api .../timeline`)
- **計測条件:** 上記と同じ
- **備考:** TC-020 / TC-021 は Step 9 完了後に Main または Validator が再実行する。TC-022 (Ready 化冪等ガードの SKILL.md 内静的確認) は **PASS** (`/tmp/claude/check-bash-blocks.sh` で `IS_DRAFT` と `gh pr ready` の同一 bash コードブロック共存を確認、blocks_with_both: 1)

## テスト実行結果

本サイクルはドキュメント改修と GitHub PR / CI 状態観測が中心のため、Vitest / Playwright 等の自動テストランナーは実行していない。すべてのテストケースは bash + grep / awk + gh CLI + jq で実装されている。

```text
=== 静的検証 (TC-001〜TC-011, TC-022) — 12 ケース ===
TC-001 (SC-1): grep Draft PR              → 3 ヒット (期待 ≥1)        PASS
TC-002 (SC-1): initialize cycle + Draft PR近接 → L796 で同行ヒット  PASS
TC-003 (SC-2): PR description 等          → 10 ヒット (期待 ≥2)       PASS
TC-004 (SC-2): 各ステップ完了時 + 適宜    → 7 / 1 (両 ≥1)             PASS
TC-005 (SC-3): CI / gh run                → 31 ヒット (期待 ≥3)       PASS
TC-006 (SC-3): リトライ                    → 15 ヒット (期待 ≥1)       PASS
TC-007 (SC-3): Blocker + リトライ 同一節 → 7 / 5 (両 ≥1)             PASS
TC-008 (SC-4): Ready 化 (代替案 b)        → 2 ヒット (期待 ≥1)        PASS
TC-009 (-)   : 主要見出し保全              → 3 ヒット (期待 ≥3)        PASS
TC-010 (-)   : Specialist common §7       → 1 ヒット (期待 ≥1)        PASS
TC-011 (-)   : progress-yaml blockers 例 → 1 ヒット (期待 ≥1)        PASS
TC-022 (-)   : IS_DRAFT + gh pr ready 共存 → blocks_with_both=1     PASS

=== 動的検証 (TC-012〜TC-021) — 10 ケース ===
TC-012 (SC-5): PR #95 Draft 作成証拠       → convert_to_draft 不在    PASS
TC-013 (SC-5): initialize cycle commit    → 1 ヒット (期待 ≥1)        PASS
TC-014 (SC-5): PR body 構造 (厳格)         → 1 / 3                     FAIL (見出し名差異、SC-5 全体は PASS)
TC-015 (SC-6): updated_at > created_at    → 04:19 差                  PASS
TC-016 (SC-6): 各 Step 完了 ↔ description 更新 → API 制約で取得不能 SKIP (保留)
TC-017 (SC-7): 各 Step 完了 commit が success → Step 2-5 が failure FAIL
TC-018 (SC-7): リトライ ≤2 回              → 9 連続 failure 観測       FAIL
TC-019 (SC-7): blockers 記録               → blockers: [] (空)         FAIL
TC-020 (SC-8): isDraft: false              → isDraft: true            PENDING (Step 9 未完)
TC-021 (SC-8): ready_for_review 時刻       → イベント不在             PENDING

合計: 22 TC 中 PASS 14 件、FAIL 4 件 (TC-014/017/018/019)、SKIP 1 件 (TC-016)、PENDING 2 件 (TC-020/021)
```

- 自動テスト: 上記 22 件 (本サイクル独自 = bash + gh CLI による静的・動的検証スクリプト)
- 統合テスト: 該当なし (ドキュメント改修サイクル)
- E2E テスト: 該当なし

## メトリクス

| メトリクス                               | 目標値 | 観測値                             | 判定          |
| ---------------------------------------- | ------ | ---------------------------------- | ------------- |
| SKILL.md `Draft PR` 言及数               | ≥1     | 3                                  | PASS          |
| SKILL.md `PR description` 系言及数       | ≥2     | 10                                 | PASS          |
| SKILL.md `CI` / `gh run` 言及数          | ≥3     | 31                                 | PASS          |
| SKILL.md `リトライ` 系言及数             | ≥1     | 15                                 | PASS          |
| SKILL.md `Ready` 化記述 (Step 9 関連節)  | ≥1     | 2                                  | PASS          |
| PR #95 `isDraft` (現時点)                | true   | true                               | PASS (SC-5)   |
| PR #95 `initialize cycle` コミット含有数 | ≥1     | 1                                  | PASS          |
| PR #95 H2 見出し数 (テンプレート厳格)    | ≥3     | 1                                  | FAIL          |
| PR #95 H2 見出し数 (実体観点 / 緩和正規) | ≥3     | 3 (Summary/Cycle/Progress)         | PASS          |
| PR #95 `updated_at > created_at`         | true   | true (差 04:19)                    | PASS          |
| CI run 件数 (branch)                     | -      | 14 run                             | (情報)        |
| CI conclusion success 比率               | (高)   | 5/14 = 35.7%                       | -             |
| 連続 failure 最大数                      | ≤2     | 9 (a0a5007 → 7c06bfd)              | FAIL (TC-018) |
| `progress.yaml.blockers[]` 件数          | -      | 0 (期待: 9 連続 failure に伴い ≥1) | FAIL (TC-019) |

## 計測不能 / 前提崩壊の記録

### 1. PR description 編集タイムスタンプ履歴 (TC-016)

- **対象成功基準:** SC-6 (各 Step 完了タイミングと description 更新タイミングが整合する)
- **前提崩壊の内容:** GitHub REST API の `/issues/{n}/timeline` エンドポイントは PR title 変更 (`renamed`) は出力するが、PR body (description) 編集は専用イベントとして出力しない。`/issues/{n}` の `updated_at` は最終更新時刻 1 件のみで、過去の更新履歴は取得不能 (`gh-cli.md` 研究ノートでも同仕様確認済み)
- **代替観測の可否:** 完全な代替不可。間接証拠として「`updated_at = 06:10:29Z` が Step 7 完了 (`06:09:23Z`) の 1 分後 = 直近 Step 完了直後に description 更新が行われた」までは観測可能。ただし Step 1〜6 完了直後にも更新が行われたかは観測手段なし
- **対応推奨:** SC-6 の検証手段を「リポジトリ内の付帯ファイル (例: progress.yaml に `pr_body_updated_at` 列を持たせる、または PR コメントで body 更新を機械的に記録) で観測可能性を担保する」設計に修正することを次サイクル以降の改善 (Intent Spec 修正候補) として提案

## 未達基準への対応方針

### SC-7 (FAIL): CI failure 9 連続 + Blocker 化未実施

- **原因分類:** 運用プロセス未順守 (新ルール = task-T1 で SKILL.md に追加、task-T1 完了は Step 6 の Wave 1)。Step 1〜Step 5 進行中は新ルールがリポジトリに存在しなかったため、CI failure を観測しても遡及対応が物理的に困難 (新ルール成立後の Step 6 / Step 7 完了は CI = success)
- **重要な軽減要因:** SKILL.md L792 で「**本プロトコルは新規サイクル(本プロトコル成立後に開始されるサイクル)に対して適用する。既に進行中・完了済みのサイクルへの遡及適用は行わない**」と明記されており、**本サイクル自身は遡及不適用の対象**となる。この条文に基づけば SC-7 の評価対象は新ルール成立後 (Step 6 以降) のみに限定され、その範囲では完全 success
- **推奨ロールバック先:** ロールバック不要 (新プロトコルの遡及不適用条文と整合する観測結果)。ただしドッグフード性 (本サイクル自身が新ルールを実証する) は **部分達成** に留まる (Step 6/7 では実証できたが Step 1-5 では未実証)
- **ユーザー判断への引き継ぎ要否:**
  - **必要 (推奨):** 「SC-7 は厳密評価で FAIL だが、SKILL.md の遡及不適用条文に従えば許容範囲」という解釈を採用するか、Intent Spec 自体を「新ルール成立後の Step のみを SC-7 評価対象とする」に明示修正するかをユーザー判断 (Step 9 Retrospective までに決定推奨)
  - 採用案として `Validation Report 記録の上で Step 9 へ進行 (FAIL を Notable として残す)` を Validator から提案
- **次サイクル改善案:**
  1. 新ルール成立前から進行中のサイクルでも CI failure を Blocker として記録する遡及運用ガイドを SKILL.md に追記 (今回サイクル自身でできなかったメタ知見)
  2. CI failure 連続検知をプロアクティブに通知する仕組み (例: progress.yaml に `last_ci_status` フィールド追加、または PR description の `## CI status` セクションを Step 完了時に必ず更新する規約強化)
  3. Step 6 task-T1 (新セクション追加) を Wave 0 として最優先で完了させ、それ以降の Step ですぐ新ルール適用できる順序に Task Plan を再設計する選択肢

### TC-014 (SC-5 構成要素): PR body 見出し名がテンプレートと差異

- **原因分類:** テンプレート遵守の軽微な逸脱 (design.md L102-L153 の `## Cycle artefacts` / `## Progress checklist` が PR body では `## Cycle` / `## Progress` に短縮)
- **影響:** SC-5 の本質要件 (サイクル概要・Step 進捗・関連 issue 相当の含有) は満たされており、SC-5 全体としては PASS
- **次サイクル改善案:** Step 6 implementer が PR body を生成する際に design.md テンプレートのリテラル見出し名を採用する規約を SKILL.md または PR body 生成スクリプトに追記。あるいは TC-014 の判定基準を緩和 (`Cycle|Cycle artefacts` の OR マッチ)

### TC-016 (SC-6 構成要素): GitHub API 制約による観測不能

- **原因分類:** 設計時に観測手段を確定していなかった (qa-design.md TC-015 注記には API 制約言及あるが TC-016 に踏み込んでいない)
- **対応:** 上記「計測不能 / 前提崩壊の記録」参照
- **次サイクル改善案:** 計測不能な検証要件は Intent Spec / qa-design 段階で「観測手段確定済み」を Gate 条件とする (Step 4 QA Design 終了時の自己チェック追加)

## 証拠アーカイブ

### `validation-evidence/static/`

- `validation-evidence/static/sc3-pr-ci-section.txt`: SKILL.md `## サイクル PR と CI 連携プロトコル` 配下を `gawk` でコードフェンス除外抽出した本文 (184 行)。SC-3 / TC-007 の証拠
- `validation-evidence/static/sc4-step9-ready-section.txt`: SKILL.md `### Step 9 完了後の Ready 化` H3 サブセクション本文 (21 行)。SC-4 / TC-008 の証拠
- `validation-evidence/static/sc-blockers-progress-yaml.txt`: `progress-yaml.md` の `### blockers` セクション抽出 (5 行)。TC-011 の証拠

### `validation-evidence/dynamic/`

- `validation-evidence/dynamic/pr95-runs.json`: `gh run list --branch feat/dev-workflow-pr-ci-integration --limit 100 --json ...` 出力 (14 run、CI workflow、pull_request イベント)。SC-7 / TC-017 / TC-018 の証拠
- `validation-evidence/dynamic/pr95-timeline.jsonl`: `gh api repos/totto2727-org/monorepo/issues/95/timeline --paginate` 出力 (26 イベント = committed 25 + head_ref_force_pushed 1)。SC-5 (Draft 維持証明) / SC-6 (description 更新は出力されない仕様確認) / SC-8 (ready_for_review 不在) の証拠
- `validation-evidence/dynamic/pr95-commits.txt`: `gh pr view 95 --json commits --jq '.commits[].messageHeadline'` 出力 (25 件)。TC-013 / TC-017 の証拠
- `validation-evidence/dynamic/pr95-body.md`: PR #95 description 全文 (71 行)。TC-014 / SC-5 / SC-6 の証拠
- `validation-evidence/dynamic/branch-commits.txt`: `git log --pretty=format:"%h %ci %s" feat/dev-workflow-pr-ci-integration --not main` 出力 (24 commit)。TC-016 / TC-017 で各 Step 完了タイムスタンプ参照に使用

## Step 9 への引き継ぎ事項

1. **SC-7 解釈の最終確定:** 厳密評価 (FAIL) / 遡及不適用評価 (PASS) のいずれを採用するかをユーザー判断で確定。Retrospective でドッグフード性の自己評価として記録推奨
2. **PENDING SC-8 の再評価:** Step 9 Retrospective コミット後、Main が `gh pr ready 95` を冪等実行 (SKILL.md L945-L965 の bash 擬似コードに従う)。実行後 Validator または Main が `gh pr view 95 --json isDraft` で `false` を確認、`gh api repos/.../issues/95/timeline` で `ready_for_review` イベントの created_at が Step 9 commit 以降であることを確認 → SC-8 PASS 確定
3. **Notable observations (次サイクル改善候補):**
   - PR body 見出し名のテンプレート遵守 (TC-014)
   - PR description 更新履歴の観測可能性確保 (TC-016 / SC-6)
   - 進行中サイクルでの新ルール導入時の遡及運用ガイド (SC-7 のドッグフード性ギャップ)
   - CI failure を Blocker として `progress.yaml.blockers[]` に記録する運用フロー実例追加 (新ルール成立後の最初の CI failure 発生時に必須)

## 参考: コマンド再現手順

`validation-evidence/` 配下のファイルを再生成するコマンド (本 Validator が実際に実行したもの):

```bash
# 静的検証
ggrep -cE "(Draft PR|draft pull request|Draft Pull Request)" plugins/dev-workflow/skills/dev-workflow/SKILL.md
ggrep -cE "(PR (概要|description|overview)|プルリクエスト概要|pull request description)" plugins/dev-workflow/skills/dev-workflow/SKILL.md
ggrep -cE "(CI|continuous integration|gh run)" plugins/dev-workflow/skills/dev-workflow/SKILL.md
ggrep -cE "(2 回|二回|retry|リトライ)" plugins/dev-workflow/skills/dev-workflow/SKILL.md
bash /tmp/claude/extract-sc3.sh > validation-evidence/static/sc3-pr-ci-section.txt
bash /tmp/claude/extract-sc4.sh > validation-evidence/static/sc4-step9-ready-section.txt
bash /tmp/claude/extract-blockers.sh > validation-evidence/static/sc-blockers-progress-yaml.txt
bash /tmp/claude/check-bash-blocks.sh   # TC-022

# 動的検証
gh pr view 95 --json number,isDraft,createdAt,updatedAt,baseRefName,headRefName,title,state,url,author
gh pr view 95 --json commits --jq '.commits[].messageHeadline' > validation-evidence/dynamic/pr95-commits.txt
gh pr view 95 --json body --jq '.body' > validation-evidence/dynamic/pr95-body.md
gh api repos/totto2727-org/monorepo/issues/95 --jq '{created:.created_at, updated:.updated_at}'
gh api repos/totto2727-org/monorepo/issues/95/timeline --paginate \
  --jq '.[] | {event: .event, created_at: .created_at, actor: .actor.login}' \
  > validation-evidence/dynamic/pr95-timeline.jsonl
gh run list --branch feat/dev-workflow-pr-ci-integration --limit 100 \
  --json databaseId,headSha,headBranch,conclusion,status,workflowName,event,createdAt,attempt \
  > validation-evidence/dynamic/pr95-runs.json
git log --pretty=format:"%h %ci %s" feat/dev-workflow-pr-ci-integration --not main \
  > validation-evidence/dynamic/branch-commits.txt
```

`/tmp/claude/extract-*.sh` および `/tmp/claude/check-bash-blocks.sh` は本 Validator がローカル一時環境で `gawk` の zsh history-expansion 回避のため作成した補助スクリプト。再現にはこれらを再作成する必要があるが、内容は本レポート末尾の証拠アーカイブ説明と上記 `gawk` ワンライナーから復元可能。
