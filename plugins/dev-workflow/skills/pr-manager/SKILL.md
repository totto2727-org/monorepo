---
name: pr-manager
description: >
  [Main 専属の write 系 / Specialist read 系] GitHub Pull Request の Draft 作成・概要更新・
  Draft → Ready 化・state 読取を集約するユーティリティスキル。冪等性ガード (`gh pr list --head`
  事前確認、`gh pr view --json isDraft` 事前確認) を必須化し、`--body-file` 経由送信で
  shell quoting 事故を防ぐ。CI 監視は `ci-monitoring`、テンプレート本体は
  `shared-artifacts/{templates,references}/pr-body.md` に委譲する純粋な PR 操作レイヤー。
  起動トリガー: サイクル初期化時の Draft PR 作成、各ステップ完了時の PR 概要更新、
  Step 9 完了後の Ready 化、Specialist が PR 状態を read で参照したい場面。
  "Draft PR 作成", "PR 概要更新", "gh pr ready", "Ready 化", "pr-manager" で参照可能。
  Do NOT use for: ワークフロー手順の規定（dev-workflow）、PR description 本文の中身仕様
  （`shared-artifacts/references/pr-body.md`）、CI 監視・リトライ・Blocker 化（`ci-monitoring`）、
  GitHub Issue / Discussion 管理（本ワークフロー外）。
allowed-tools: Bash, Read, Glob, Grep
---

# PR Manager — GitHub Pull Request 操作の集約スキル

ユースケースカテゴリ: **Workflow Automation**（PR ライフサイクル操作を 1 箇所に集約し、冪等性とパーミッション境界を担保する）
設計パターン: **Domain Intelligence**（gh CLI の PR 関連コマンドのドメイン知識と本ワークフロー固有の冪等性要件を集約）

dev-workflow サイクルでは、サイクルごとに 1 つの GitHub Pull Request を **Draft で作成 → 各ステップ完了時に概要更新 → Step 9 完了後に Ready 化** する。本スキルはこれら **PR 操作 (write 系) の手順** と **PR 状態の読取 (read 系)** を集約し、関連スキル (`dev-workflow` / `specialist-common` / `specialist-validator` / `shared-artifacts`) からの呼び出しに応える。

## 基本方針

- **write 系は Main 専属**: `gh pr create` / `gh pr edit` / `gh pr ready` / `gh pr close` / `gh pr reopen` 等は **Main が単独で実行する**。Specialist は read 系のみ使用してよい (`specialist-common` §7 と整合)
- **冪等性ガード必須**: 「既に作成された PR を二重作成しない」「既に Ready の PR を再 Ready 化しない」など、状態を変える操作は **事前 read で現状確認 → 必要な場合のみ write** の 2 段構えで実装する
- **`--body-file` で送信**: PR description は HEREDOC ではなく `gh pr edit --body-file <path>` 形式で送信する。Markdown 内の引用符・バックティック等が shell quoting で破損する事故を恒久回避する
- **テンプレートは shared-artifacts**: PR description の中身 (各セクションの埋め方) は本スキルでは定義せず、`shared-artifacts/{templates,references}/pr-body.md` に委譲する
- **CI は ci-monitoring**: PR の CI 状態確認・watch・リトライ・Blocker は本スキルでは扱わず、`ci-monitoring` スキルに委譲する。本スキルは「PR メタ情報 (number, isDraft, body, state, mergedAt 等)」の読取のみ
- **Single-Source-of-Progress 整合**: PR description は `progress.yaml` / `TODO.md` から派生する **ビュー** であり、PR description が真のソースになってはいけない

## 前提

- 本ワークフローは GitHub Actions 上で `gh` CLI を使用する前提 (本リポの運用と整合)
- 1 サイクル = 1 PR (本サイクルブランチに対して 1 件の open PR が紐付く)
- ブランチ命名は `feat/<id>` 系 (プロジェクト固有 `git-workflow` スキルに従う)
- `BRANCH` 環境変数または `git rev-parse --abbrev-ref HEAD` で現在のブランチ名を取得済とする

## 1. Draft PR 初期化 (サイクル開始時、冪等)

サイクル初期化コミット `docs(dev-workflow/<identifier>): initialize cycle` と同時に、対応する **Draft PR** を 1 件作成する。Draft PR の作成タイミングはサイクル開始時の 1 回のみで、Step 1 完了直後に Main が冪等に実行する (既存 PR があれば再利用)。

PR description は `$TMPDIR/dev-workflow/<identifier>-pr-body.md` に揮発ファイルとして生成し、`gh pr create --draft --body-file` で送信する (テンプレート: `shared-artifacts/templates/pr-body.md`)。

```bash
# 冪等性ガード: 既存 open PR があれば再利用
existing_pr=$(gh pr list --head "$BRANCH" --state open --json number,isDraft --jq '.[0]')
if [ -z "$existing_pr" ] || [ "$existing_pr" = "null" ]; then
  # 未作成 → Draft PR を新規作成
  gh pr create \
    --draft \
    --base main \
    --head "$BRANCH" \
    --title "feat(dev-workflow/<identifier>): <one-line summary>" \
    --body-file "$TMPDIR/dev-workflow/<identifier>-pr-body.md"
else
  # 既存 PR 再利用 (Step 1 再実行 / 手動作成済み等のケース)
  echo "Reusing existing PR: $existing_pr"
fi
```

**注意:** 既存 PR が `isDraft: false` (= 既に Ready) の場合でも本スキルでは Draft 化に **戻さない** (破壊的操作)。サイクル再開時に Draft 化が必要なケースは Main が `gh pr edit --draft` を明示的に呼び出すか、In-Progress ユーザー問い合わせ形式で確認する。

## 2. PR 概要更新 (各ステップ完了時 + 適宜)

PR 概要 (PR description) は **各ステップ完了コミット直後に必ず更新する** (9 回)。さらに、ステップ途中であっても内容に変化があれば**適宜**更新してよい (例: Research Note の追加、Blocker 発生時のステータス反映など)。

更新手順:

1. Main が `$TMPDIR/dev-workflow/<identifier>-pr-body.md` をテンプレート (`shared-artifacts/templates/pr-body.md`) に従って再生成する (累積状態を反映)
2. `gh pr edit <num> --body-file <path>` で送信する

```bash
# Main がテンプレートから $TMPDIR/dev-workflow/<id>-pr-body.md を再生成した後
PR_NUMBER=$(gh pr list --head "$BRANCH" --state open --json number --jq '.[0].number')
gh pr edit "$PR_NUMBER" --body-file "$TMPDIR/dev-workflow/<identifier>-pr-body.md"
```

**`--body-file` 必須化の理由:** HEREDOC 経由の `--body "..."` は Markdown 内の `` ` `` / `"` / `$` / `\` 等が shell quoting で破損するリスクが恒常的にある (過去の手作業 PR で発生実績あり)。`--body-file` 経由ならファイル内容がそのまま送信される。

**各セクションの埋め方:** `shared-artifacts/references/pr-body.md` の「セクション仕様」を参照。CI status セクションは `ci-monitoring` §5 を参照。

## 3. Draft → Ready 化 (Step 9 完了後、冪等)

Step 9 (Retrospective) 完了コミットの CI が PASS したことを確認した後 (`ci-monitoring` §3 の二重チェック)、Main はサイクル PR を **Draft → Ready 化** する。Ready 化はサイクル完了の最終アクションの一つ。

```bash
PR_NUMBER=$(gh pr list --head "$BRANCH" --state open --json number --jq '.[0].number')
IS_DRAFT=$(gh pr view "$PR_NUMBER" --json isDraft --jq '.isDraft')

if [ "$IS_DRAFT" = "true" ]; then
  gh pr ready "$PR_NUMBER"
  echo "PR #$PR_NUMBER: Draft → Ready"
elif [ "$IS_DRAFT" = "false" ]; then
  echo "PR #$PR_NUMBER: already Ready (no-op)"
else
  echo "Unexpected isDraft value: $IS_DRAFT" >&2
  exit 1
fi
```

**冪等性ガードの理由:** `gh pr ready` の挙動は CLI バージョンや GitHub 側の状態に依存する可能性があり、既に Ready の PR への再実行が破壊的になりうる (公式ドキュメント上は明記なし、`docs/workflow/2026-05-03-pr-ci-integration/research/gh-cli.md` D-2 参照)。設計側で `isDraft` 事前確認を必須化することで CLI 仕様変化に対するリグレッションを防ぐ。

**Ready 化の検証:** `gh pr view --json isDraft` の出力が `false` であることを確認 (テストフレームワーク非依存の機械的判定)。`readyForReviewAt` フィールドが `gh pr view --json` のフィールド一覧にない場合は、`gh api repos/<owner>/<repo>/issues/<num>/timeline` の `event: "ready_for_review"` イベントで Step 9 コミット時刻以降であることを確認する。

## 4. PR state 読取 (Specialist も使用可、read 系)

read 系コマンドは Main / Specialist 共通で使用してよい。代表的なクエリ:

```bash
# 基本メタ情報 (number / isDraft / state / mergedAt)
gh pr view <num> --json number,isDraft,state,mergedAt --jq '.'

# PR body (description) を取得 (validator が SC-2 等の検証で使用)
gh pr view <num> --json body --jq '.body'

# PR に紐付くコミット一覧 (validator が SC-5 で initialize cycle コミット存在確認)
gh pr view <num> --json commits --jq '.commits[].messageHeadline'

# branch / commit 一覧で PR を検索 (サイクルブランチ → PR 番号解決)
gh pr list --head "$BRANCH" --state all --json number,isDraft,createdAt --jq '.[0]'

# PR タイムライン (description 編集イベント・convert_to_draft 等の取得)
gh api repos/<owner>/<repo>/issues/<num>/timeline --paginate \
  --jq '.[] | {event, created_at, actor: .actor.login}'

# created_at vs updated_at (description 編集の実行可否観測。timeline には description 編集が現れない仕様)
gh api repos/<owner>/<repo>/issues/<num> --jq '{created: .created_at, updated: .updated_at}'
```

**Specialist の使用範囲:** `validator` が SC-5/6/8 の動的検証で本スキルの read 系を呼び出す。`reviewer` (holistic 観点) も PR コミット粒度確認等で読取する場合がある。**ただし `--jq` のフィルタや結果の判定は Specialist 側で完結させ、本スキルは observation primitives を提供するに留める。**

## 5. パーミッション境界 (Main vs Specialist)

| 操作種別        | コマンド例                                              | Main | Specialist |
| --------------- | ------------------------------------------------------- | ---- | ---------- |
| Draft 作成      | `gh pr create --draft`                                  | ✅   | ❌         |
| 概要更新        | `gh pr edit <num> --body-file`                          | ✅   | ❌         |
| Ready 化        | `gh pr ready <num>`                                     | ✅   | ❌         |
| Draft 化 (戻し) | `gh pr edit <num> --draft`                              | ✅\* | ❌         |
| close / reopen  | `gh pr close <num>` / `gh pr reopen <num>`              | ✅\* | ❌         |
| state 読取      | `gh pr view <num> --json ...` / `gh pr list --json ...` | ✅   | ✅         |
| timeline 読取   | `gh api .../timeline`                                   | ✅   | ✅         |

\* Draft 化戻し / close / reopen は破壊的・準破壊的操作のため、ユーザー判断 (In-Progress 一時レポート) を経て Main が実行する。

詳細は `specialist-common` §7「PR / CI 操作の権限境界 (全 Specialist 共通)」と整合する。

## 6. テンプレート連携 (shared-artifacts/pr-body.md)

PR description の **構造と各セクションの仕様** は本スキルでは定義しない。以下を参照:

- **テンプレート本体**: `shared-artifacts/templates/pr-body.md` (Main がコピーして `$TMPDIR/dev-workflow/<id>-pr-body.md` に配置)
- **書き方ガイド**: `shared-artifacts/references/pr-body.md` (各セクションの埋め方、品質基準、良例 / 悪例)
- **CI status セクションの埋め方**: `ci-monitoring` スキル §5

更新タイミングだけが本スキルの責務:

- 初回送信: §1 Draft PR 初期化と同時 (`gh pr create --body-file`)
- 以降: §2 各ステップ完了コミット直後 + 適宜 (`gh pr edit --body-file`)

## 7. 関連スキル / 委譲先

| 関心事                                                 | 担当スキル                                             | 本スキルとの関係                      |
| ------------------------------------------------------ | ------------------------------------------------------ | ------------------------------------- |
| PR 操作のいつ (タイミング・トリガー)                   | `dev-workflow` 「## サイクル PR と CI 連携プロトコル」 | dev-workflow が pr-manager を呼び出す |
| PR 操作のどう (コマンド・冪等性)                       | **`pr-manager`** (本スキル)                            | -                                     |
| CI watch / 二重チェック / リトライ / Blocker 化        | `ci-monitoring`                                        | 並列の関心事 (PR 操作には含めない)    |
| PR description テンプレート / 各セクション仕様         | `shared-artifacts/{templates,references}/pr-body.md`   | 本スキル §2 / §6 から参照             |
| Specialist 共通の権限境界                              | `specialist-common` §7                                 | 本スキル §5 と一致                    |
| Specialist 個別の PR 関連責務 (validator が SC で使用) | `specialist-validator` 等                              | 本スキル §4 read 系のみ呼び出す       |
| プロジェクト固有 Git/PR 規約 (Conventional Commits)    | `git-workflow` (totto2727 プロジェクト)                | 本スキル §1 の `--title` 規約に従う   |

## このスキルが扱わないこと

- **PR description の中身 (各セクションの埋め方)** → `shared-artifacts/references/pr-body.md` に委譲
- **CI run の確認・監視・リトライ・Blocker 化** → `ci-monitoring` スキルに委譲
- **PR を「いつ」操作するか (各ステップでのトリガー)** → `dev-workflow` 「## サイクル PR と CI 連携プロトコル」に委譲
- **GitHub Issue / Discussion / Project の操作** → 本ワークフロー外
- **複数リポジトリ間の PR 同期** → 本ワークフロー外
- **PR レビューコメントの書き込み** (`gh pr review` / `gh pr comment`) → 本サイクルでは扱わない (将来の別サイクルで検討、Retrospective 拡張ポイント)
- **マージ操作** (`gh pr merge`) → 人間レビュアーの責務、本ワークフロー外
- **CI ワークフロー定義の改修** (`.github/workflows/*.yaml`) → CI/CD パイプライン設計の領域、本ワークフロー外

## 発火の想定例 (Triggering Test)

- 「Step 1 完了コミットを push したので Draft PR を作りたい」 → §1 (冪等チェック → `gh pr create --draft --body-file`)
- 「Step 5 完了コミット直後に PR description を更新したい」 → §2 (`$TMPDIR/<id>-pr-body.md` 再生成 → `gh pr edit --body-file`)
- 「Step 9 完了コミットの CI が PASS したので PR を Ready にしたい」 → §3 (`isDraft` 事前確認 → `gh pr ready`)
- 「Validator として SC-5 のため PR が Draft で作られたか確認したい」 → §4 read 系 (`gh pr view --json isDraft,createdAt`)
- 「PR description が更新された痕跡を timeline で確認したい」 → §4 read 系 (`gh api .../timeline`)
