---
name: ci-monitoring
description: >
  [Main / Specialist 共通] GitHub Actions CI run の確認・バックグラウンド監視・
  失敗時のリトライ規律を集約するユーティリティスキル。push 後に CI が PASS した
  ことを **二重チェック** (`gh run watch --exit-status` の log 末尾 EXIT 行 +
  `gh run view --json conclusion`) で確定し、失敗時は最大 2 回のリトライ
  (新規コミット push) を経て 3 回目失敗で Blocker 化する手順を提供する。
  起動トリガー: コミット push 後の CI 確認、Step 完了基準として CI PASS を要求するすべての場面、
  Validator が SC-7 を実測する場面、PR description の CI status セクションを埋める場面。
  "CI 確認", "gh run watch", "CI 失敗時のリトライ", "ci-monitoring" で参照可能。
  Do NOT use for: ワークフロー手順の規定（dev-workflow）、テスト設計（qa-analyst が qa-design.md を作成）、
  CI ワークフロー自体の改修（`.github/workflows/*.yaml` の編集は本ワークフロー外）、
  PR 操作 write 系（Main 専属、`specialist-common §7` 参照）。
allowed-tools: Bash, Read, Glob, Grep
---

# CI Monitoring — GitHub Actions CI run の確認・監視・リトライ手順

ユースケースカテゴリ: **Workflow Automation**（CI 結果を観測値として確定し、後続ステップの完了判定に組み込む）
設計パターン: **Domain Intelligence**（gh CLI / GitHub Actions のドメイン知識と本リポ固有の CI 特性を 1 箇所に集約）

dev-workflow サイクルでは、各ステップ完了コミット (Step 6 はタスク単位コミット) を push した直後に **「対応する CI run が PASS した」ことを確定** してから次ステップへ進む。本スキルはその CI 確認手順 (バックグラウンド watch + EXIT 行確認 + `gh run view --json conclusion` 二重チェック) と、失敗時のリトライ規律 (最大 2 回 → Blocker 化) を集約する。

## 基本方針

- **CI PASS は二重チェックで確定**: `gh run watch --exit-status` の終了 exit code (= log 末尾 `EXIT=N` 行) と、独立した `gh run view <run-id> --json conclusion` の値、**両方が `success`** で初めて PASS と判定する。バックグラウンドタスクの完了通知 (= bash の exit code) だけで判定してはならない
- **EXIT 行は必ず log 末尾に書き出す**: `gh run watch ... > LOG 2>&1; echo "EXIT=$?" >> LOG` のパターンを必須とし、後で grep / tail で `EXIT=` 行を確認できるようにする
- **修正は新規コミット push でリトライ**: 本リポ CI の失敗パターンはほぼ決定的問題 (oxfmt / typecheck / test) であり、`gh run rerun` ではなく **修正コミットの新規 push** を 1 リトライとカウントする
- **3 回目失敗で Blocker 化**: 同一 Step 系列で連続 3 回失敗した時点でリトライを打ち切り、`progress.yaml.blockers[]` に記録 + In-Progress ユーザー問い合わせ形式でユーザー判断を仰ぐ
- **Main 専属の write 系 + Specialist read 系**: `gh run rerun` (write) は Main 専属。read 系 (`gh run list --json` / `gh run view --json` / `gh run watch`) は Specialist (特に `validator`) も使用してよい (`specialist-common §7` 準拠)
- **Single-Source-of-Progress 整合**: CI status の真のソースは GitHub の run 状態。PR description の `## CI status` セクション / `progress.yaml.blockers[]` は派生ビュー

## 前提

- 本リポの CI は単一の必須チェック `check` (`.github/workflows/*.yaml` の workflow name = `CI`)。ジョブ名・workflow 名は `docs/workflow/*/research/ci-structure.md` 等の調査結果で確定済
- 中央値 109s / p90 120s / 最大 140s。flaky ゼロで失敗の 100% が決定的問題 (oxfmt Formatting / typecheck / test)
- `gh run rerun` は本リポでは原則使わない (flaky 性がないため、修正なしの再実行は無意味)

## 1. push 直後の run id 取得 (race 回避)

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
SHA=$(git rev-parse HEAD)

# run id 出現を待つループ (race 回避、最大 30 秒)
RUN_ID=""
for i in 1 2 3 4 5 6; do
  RUN_ID=$(gh run list --branch "$BRANCH" --workflow CI --commit "$SHA" \
    --json databaseId --jq '.[0].databaseId')
  if [ -n "$RUN_ID" ] && [ "$RUN_ID" != "null" ]; then break; fi
  sleep 5
done

if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
  echo "ERROR: run id not found within 30s for $SHA" >&2
  exit 1
fi
```

GitHub Actions 全体障害で 30 秒以内に run id が出現しない場合はエラーで打ち切る (Blocker 候補)。

## 2. バックグラウンド watch + EXIT 行記録

```bash
# 必須 3 オプション:
#   --exit-status : CI conclusion を exit code に反映
#   --interval 10 : 10 秒間隔ポーリング (API レート余裕)
#   --compact     : 出力サイズ抑制
LOG="$TMPDIR/dev-workflow/ci-watch-$RUN_ID.log"
mkdir -p "$(dirname "$LOG")"

gh run watch "$RUN_ID" --exit-status --interval 10 --compact > "$LOG" 2>&1
echo "EXIT=$?" >> "$LOG"
```

バックグラウンド実行する場合は `&` を末尾に付け、`wait $WATCH_PID` で完了を回収する。**いずれの場合も `echo "EXIT=$?" >> "$LOG"` を必ず付ける** (後の確認で末尾行を読むため)。

## 3. 二重チェックで PASS 判定 (必須手順)

`gh run watch` の exit code だけで判定してはならない。以下 **両方** が `success` であることを確認する:

```bash
# (a) log 末尾の EXIT 行を読む
EXIT_LINE=$(tail -1 "$LOG")
case "$EXIT_LINE" in
  "EXIT=0") WATCH_RESULT="success" ;;
  "EXIT="*) WATCH_RESULT="failure" ;;
  *)        WATCH_RESULT="unknown" ;;
esac

# (b) 独立に gh run view で conclusion を取得
CONCLUSION=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')

# 両方が success で初めて PASS
if [ "$WATCH_RESULT" = "success" ] && [ "$CONCLUSION" = "success" ]; then
  echo "CI PASS: run $RUN_ID (commit $SHA)"
  STEP_CI_PASS=1
else
  echo "CI FAIL or inconsistent: watch=$WATCH_RESULT conclusion=$CONCLUSION"
  STEP_CI_PASS=0
fi
```

### なぜ二重チェックが必要か

- バックグラウンドタスクの完了通知 (= bash の `wait` の exit code) は **そのバックグラウンドジョブが exit したこと** だけを示し、`gh run watch` 自体が中断されたケース (ネットワーク切断・GitHub API 503 等) では exit code が 0 でも CI が確定していない可能性がある
- log 末尾の `EXIT=` 行は `gh run watch --exit-status` の終了コードを記録しているが、log がフラッシュされる前に切断された場合は `EXIT=` 行自体が書き込まれない可能性がある
- `gh run view --json conclusion` は GitHub API から **独立に取得** するため、watch とは別経路の確認になる
- 実例: 過去サイクル `2026-05-03-pr-ci-integration` では Main がバックグラウンドタスクの exit code 0 を「CI PASS」と短絡解釈し、log の `EXIT=1` を見落として 9 件の CI failure を見逃した。Validator が `gh run list --json conclusion` で実測して暴露 (Retrospective 参照)

## 4. CI 失敗時のリトライフロー (最大 2 回 → Blocker)

```bash
ATTEMPT=1   # 1, 2 まで許容、3 で Blocker 化
# ATTEMPT は「失敗 → 修正 → 再 push」のサイクル数を Main が手動でカウント
# (1 リトライ = 1 回の修正コミット push、`gh run rerun` は使わない)

while [ $ATTEMPT -le 2 ] && [ $STEP_CI_PASS -eq 0 ]; do
  # 1. 失敗内容を保存
  gh run view "$RUN_ID" --log-failed > "$TMPDIR/dev-workflow/ci-fail-$RUN_ID.log"

  # 2. Main が log を読み、失敗原因に応じてローカル修正
  #    - oxfmt: vp check --fix && vp check
  #    - typecheck: vp check (pass まで)
  #    - test: vp test
  # 3. 修正をパス指定で git add、Conventional Commits 形式でコミット
  # 4. git push origin "$BRANCH"
  # 5. 上記 §1〜§3 を再実行して新規 RUN_ID で PASS / FAIL 判定

  ATTEMPT=$((ATTEMPT + 1))
done

if [ $STEP_CI_PASS -eq 0 ]; then
  # 3 回連続失敗 → Blocker 化
  # progress.yaml.blockers[] に CI failure エントリを追記してコミット
  # In-Progress ユーザー問い合わせ形式で
  # $TMPDIR/dev-workflow/step<N>-ci-blocker.md を作成 (経緯 / 選択肢 / 推奨案)
  # ユーザー判断 (Step 3 ロールバック / 設計再検討 / 別アプローチ) を仰ぐ
  echo "BLOCKER: CI failed 3 consecutive attempts" >&2
fi
```

`progress.yaml.blockers[]` への記録様式は `share-artifacts/references/progress-yaml.md` の CI failure 例参照。

## 5. PR description の `## CI status` セクションの埋め方

各ステップ完了コミット直後に PR description を更新する際 (送信手順は **`share-pr-manager` スキル §2** 参照)、テンプレート (`share-artifacts/templates/pr-body.md`) の CI status セクションには上記手順で取得した値を反映する:

```markdown
## CI status

- 最新コミット SHA: <短縮 7 文字>
- 最新 `check` job: success (run id: <RUN_ID>, attempt: 1)
- リトライ履歴: なし
```

リトライが発生した場合は履歴をブロック化:

```markdown
## CI status

- 最新コミット SHA: def5678
- 最新 `check` job: success (run id: 25271162031, attempt: 2)
- リトライ履歴:
  - Step 6 task-T1 (commit abc1234): attempt 1 failure (oxfmt) → 修正 push def5678 attempt 2 success
```

## 6. Validator (Step 8) からの利用

`specialist-validator` が SC-7 (各ステップ完了コミット CI が最終 PASS) を実測する際は、本スキルの read 系手順を使用する:

```bash
# ブランチ全コミット SHA で最新 attempt の conclusion を集計
git log --pretty=format:"%H" "main..HEAD" | while read SHA; do
  CONCLUSION=$(gh run list --branch "$BRANCH" --commit "$SHA" --workflow CI \
    --json conclusion --jq '.[0].conclusion // "no-run"')
  echo "$SHA $CONCLUSION"
done
```

リトライが発生した場合は **修正コミットが別 SHA を持つ** ため、ステップ完了コミット SHA だけ追えば自動的に「最終 PASS」が反映される (`gh run rerun` 経由ではないため、attempt 番号は基本的に 1)。

## このスキルが扱わないこと

- **CI ワークフロー自体の改修** (`.github/workflows/*.yaml` の編集) → 本ワークフロー外。CI/CD パイプライン設計の領域
- **テスト設計** (qa-design.md / qa-flow.md の作成) → `specialist-qa-analyst`
- **PR write 系操作** (`gh pr create` / `gh pr edit` / `gh pr ready` 等) → **`share-pr-manager`** スキルに委譲。`specialist-common §7` で Main 専属の権限境界が規定されている
- **`gh run rerun` の積極的利用** → 本リポは flaky なし、再実行は基本不要 (Step 7 reviewer が必要に応じて単発で利用するのみ)
- **CI 結果の長期統計** (週次・月次トレンド) → 本ワークフロー外、別スキルや観測ダッシュボードで扱う
- **複数 workflow / matrix CI の統合監視** → 本リポでは単一 `check` job のみ、将来の matrix 化は Retrospective マターとして繰越

## 発火の想定例 (Triggering Test)

- 「コミットを push したので CI が通ったか確認したい」 → §2〜§3 手順を実行
- 「Step 6 のタスク T1 が完了したので CI 確認 + PR description 更新したい」 → §2〜§5 を順次実行
- 「CI が失敗した、どうリトライすべきか」 → §4 のリトライフロー
- 「Validator として SC-7 を測定する」 → §6 の read 系手順
