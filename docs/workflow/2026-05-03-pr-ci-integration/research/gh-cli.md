# Research Note: gh CLI capabilities

- **Identifier:** 2026-05-03-pr-ci-integration
- **Topic:** gh-cli
- **Researcher:** researcher (gh CLI capabilities)
- **Created at:** 2026-05-03
- **Scope:** GitHub CLI (`gh`) のうち、本サイクルで利用が想定される `gh pr create --draft` / `gh pr ready` / `gh pr edit` / `gh pr view --json` / `gh run list` / `gh run view` / `gh run watch` / `gh run rerun` の挙動・冪等性・運用上の注意点を整理する。CI ジョブ構成の棚卸しは researcher #2 (existing-ci) の担当領域であり、本ノートでは触れない。

## 調査対象

Intent Spec `docs/workflow/2026-05-03-pr-ci-integration/intent-spec.md` の以下の制約・未解決事項に対応する:

- **技術的制約**: 「PR 操作は `gh pr create --draft` / `gh pr edit --body` / `gh pr ready` 等を用いる」「`gh pr ready` の Draft → Ready 化が冪等」「CI 確認は `gh run list` / `gh run view`」(intent-spec.md L83–L85)
- **未解決事項**: 「CI リトライの実装手段 (`gh run rerun` / `gh run rerun --failed` / 新規コミット push のいずれか)」「PR description 更新の自動化レベル」「Step 9 完了 = Ready 化のトリガー条件」「CI 失敗判定の粒度」(intent-spec.md L119–L126)
- **成功基準**: SC-5/SC-6/SC-7/SC-8 の検証で実際に叩く `gh pr list` / `gh pr view --json isDraft` / `gh run list --branch <branch> --json conclusion,headSha,event` 等のクエリ実行可能性 (intent-spec.md L63–L77)

調査は本ホストにインストールされた `gh version 2.83.2 (nixpkgs)` で `--help` を実機実行し、必要に応じて `cli.github.com/manual` および GitHub REST API ドキュメント (Actions / Workflow Runs) を参照した。

## 発見事項

### F-1. `gh pr create --draft`

- `gh pr create` の `-d, --draft` フラグで Draft PR を作成できる。Draft 化は単なる boolean フラグでありオプション値は不要。
- タイトル・本文を非対話で確定するには `-t/--title` と `-b/--body` (または `-F/--body-file`、`--fill` / `--fill-first` / `--fill-verbose`) のいずれかが必須。これらを与えないと TTY 検出時に対話プロンプトに落ちる。
- `--head` 未指定時は現在のブランチを使い、未 push の場合は push 先プロンプトが出る。**非対話実行 (Main / specialist) では事前に `git push -u origin <branch>` を済ませてから `gh pr create --draft --head <branch>` を呼ぶのが安全**。
- `--base` 未指定時は `gh-merge-base` git config → リポジトリ default branch の優先順で決定。
- 成功時は **作成された PR の URL を stdout に 1 行出力**する (これを後段で `gh pr view <url>` などに渡せる)。
- `--dry-run` で「PR を実際には作らないが、push などの副作用は走り得る」モードがあり、テスト用途で利用できる。
- 同一 head ブランチに既存 open PR がある場合、`gh pr create` は冪等ではなく **エラーで終了する** (gh の既知挙動: "a pull request for branch X into branch Y already exists")。サイクル PR を冪等再生成する設計を入れるなら、先に `gh pr list --head <branch> --state open --json number,isDraft` で存在確認するパターンが要る。

### F-2. `gh pr ready`

- 引数なしで実行すると現在のブランチに紐づく PR を Ready 化する (`Mark a pull request as ready for review`)。引数として `<number> | <url> | <branch>` を受ける。
- `--undo` フラグで Draft に戻せる。help 上は **`If supported by your plan, convert to draft with --undo`** と注記されており、private リポジトリの一部 plan では `--undo` が制限される (公式 manual も同じ表現)。本リポは public ではないため事前確認が必要。
- 既に Ready 化された PR に対して `gh pr ready` を再実行した場合の挙動は help / manual いずれにも明記がなく**未保証**。GitHub GraphQL の `markPullRequestReadyForReview` ミューテーションは Ready 状態の PR に対して noop 的に成功する実装が多いが、CLI が前段でチェックして異常終了させる可能性は否定できない。**設計時は「`gh pr view --json isDraft` で `false` を確認 → 既に Ready ならスキップ」という前置確認を入れて冪等性を CLI 側で保証するのが堅実**。
- 成功時の標準出力は短い人間向け文字列 (例: `✓ Pull request <url> is marked as "ready for review"`) で、機械可読性が低い。検証には `gh pr ready` 単体ではなく直後の `gh pr view --json isDraft` を組み合わせる。

### F-3. `gh pr edit --body`

- `-b, --body string` で description を文字列引数として渡す方式と、`-F, --body-file file` でファイルから読み込む方式がある。`-F -` で stdin からも読める。
- shell の HEREDOC (`--body "$(cat <<'EOF' ... EOF)"`) は本リポの過去サイクル運用例 (例えば dev-workflow SKILL.md L?? の git commit 例) でも使われているが、 **PR description は git commit メッセージより数桁長く、Markdown 内のバッククォート・`$`・`!`・コードブロック内の `EOF` 風文字列が頻出する**ため、HEREDOC のクォート崩れリスクが高い。
- `--body-file <path>` を使うと、Markdown 全体を 1 ファイルとして書き出してから渡せるので、本サイクルのように description を毎ステップ更新するワークフローでは shell エスケープ事故を避けられる。
- `gh pr edit` は引数なし呼び出しで「現在ブランチの PR」を対象にする。これは安全ではあるが、Specialist が並列で別ワークツリーに居る場合は誤対象を選ぶ恐れがあるため、**本サイクル運用では PR 番号を明示して `gh pr edit <num> --body-file <path>`** を推奨する。
- `gh pr edit` は description 更新を**冪等的**に上書きする (前の本文と完全一致でも API は 200 を返し PR の `updatedAt` だけ進む)。同じ内容での再呼び出しは安全。

### F-4. `gh pr view --json`

- 出力可能な JSON フィールドは `additions, assignees, author, autoMergeRequest, baseRefName, baseRefOid, body, changedFiles, closed, closedAt, closingIssuesReferences, comments, commits, createdAt, deletions, files, fullDatabaseId, headRefName, headRefOid, headRepository, headRepositoryOwner, id, isCrossRepository, isDraft, labels, latestReviews, maintainerCanModify, mergeCommit, mergeStateStatus, mergeable, mergedAt, mergedBy, milestone, number, potentialMergeCommit, projectCards, projectItems, reactionGroups, reviewDecision, reviewRequests, reviews, state, statusCheckRollup, title, updatedAt, url`。
- 本サイクルで関係するフィールド:
  - **`isDraft`** (Boolean) — SC-8 の検証で直接使う (`gh pr view <num> --json isDraft --jq .isDraft`)。
  - **`statusCheckRollup`** — PR head commit に紐づく全 check の集約。CI 状態を PR 文脈で取りたい場合に最も簡潔。`bucket` / `state` / `name` / `workflowName` などを返す (`gh pr checks --json` も同じ rollup を裏で使う)。
  - **`headRefName` / `headRefOid`** — branch 名と head commit SHA を取得できる。`gh run list --branch` や `--commit` のフィルタ値として使える。
  - **`updatedAt`** — SC-6 (description 編集履歴) の代替検証用。**ただし `updatedAt` は description 以外のあらゆる更新でも進む**ため、編集回数を厳密に追うなら `gh api repos/<owner>/<repo>/pulls/<num>/timeline` で `renamed`/`edited` イベントを別途読む必要がある。
  - **`readyForReviewAt`** — help の JSON FIELDS リストには表示されないが、Intent Spec SC-8 で参照されている。`gh pr view` のフィールド一覧 (本ホストの v2.83.2 で確認) には**載っていない**ため、Ready 化のタイムスタンプを取るには `gh api graphql -f query='... readyForReviewAt ...'` で GraphQL を直接叩くか、PR タイムライン (`gh api .../timeline` の `ready_for_review` イベント) を見る形になる。**SC-8 の検証手順は Step 3 設計時に「`isDraft: false` の確認 + タイムライン上の `ready_for_review` イベントの created_at が Step 9 コミット時刻以降であること」というクエリに具体化する必要がある**。

### F-5. `gh run list`

- 主要フィルタ: `-b, --branch`、`-c, --commit SHA`、`-e, --event`、`-s, --status`、`-w, --workflow`、`-L, --limit (default 20)`。
- `--status` の取りうる値: `queued|completed|in_progress|requested|waiting|pending|action_required|cancelled|failure|neutral|skipped|stale|startup_failure|success|timed_out`。「終了したか否か」は `completed` / `in_progress` 等の **status** で、「成功か失敗か」は `conclusion` で表現される (両者は別概念)。
- `--json` で取れるフィールドは `attempt, conclusion, createdAt, databaseId, displayTitle, event, headBranch, headSha, name, number, startedAt, status, updatedAt, url, workflowDatabaseId, workflowName`。
- `attempt` フィールド (`int`) は同一 `databaseId` (= run id) に紐づく試行回数。`gh run rerun` を 1 回叩くと `attempt` が 1→2 に増える (REST API の `run_attempt` と一致、後述 F-7 参照)。
- **本サイクル SC-7 の検証で重要な含意**: `gh run list --branch <branch> --json conclusion,headSha,event` を叩いた場合、デフォルトでは run record の最新 attempt の conclusion が返る。同じ commit SHA に対して 1 つの run record しか作られないので、**rerun 後は古い `failure` レコードは見えなくなり、最新試行の `success` だけが残る** (history を細かく追いたいなら `gh run view <run-id> --attempt N` で attempt 別に見る必要がある)。

### F-6. `gh run view <id>` / `gh run watch <id>`

- `gh run view` の主要フラグ:
  - `--exit-status` — run が failed なら non-zero で終了する (CI スクリプト連携で便利)。
  - `--json fields` — `attempt, conclusion, createdAt, databaseId, displayTitle, event, headBranch, headSha, jobs, name, number, startedAt, status, updatedAt, url, workflowDatabaseId, workflowName` から選択。`jobs` を含めると各 job 単位の `name` / `databaseId` / `conclusion` も取れる (これは `gh run rerun --job <id>` の引数収集に必要、F-7 参照)。
  - `--log` / `--log-failed` — フルログ / 失敗ステップのみのログを取得できる。`--log-failed` は CI 失敗 → Blocker 化 (intent-spec.md SC-3) 時の症状サマリ収集に有用。
  - `--attempt uint` — 過去の試行を遡って見るときに使う (`gh run rerun` 後の差分検証)。
- `gh run watch <id>` の主要フラグ:
  - `-i, --interval int` — 既定 3 秒。GitHub Actions 側のレート制限に配慮するなら `--interval 10` 程度に伸ばす。
  - `--exit-status` — failed なら non-zero 終了。これがないと `gh run watch` は常に exit 0 で終わるため、後続スクリプトで分岐する場合は **必須**。
  - `--compact` — 関連 / 失敗ステップのみ表示。長時間 watch する場合のログ削減に有効。
  - help 内に「fine grained PAT は `checks:read` が作れないため非対応」と明記。本リポは classic PAT または `gh auth login` の OAuth flow を前提とする。
- 標準出力は ANSI カラーコード混じりのインタラクティブ表示。**バックグラウンド実行する際は `gh run watch <id> --exit-status --interval 10 --compact > "$TMPDIR/dev-workflow/ci-watch-<id>.log" 2>&1 &` の形でリダイレクトするのが妥当** (本サイクルで採用されているパターンと一致)。理由は以下:
  1. `--exit-status` を付けることで CI 失敗が exit code に反映され、後続の `wait $!` で機械的に判定可能になる。
  2. `--interval 10` で API リクエスト数を 1/3 以下に抑えられる (3 秒間隔だと長時間 CI で rate limit に近づく)。
  3. `--compact` でログ容量が肥大化しない (1 サイクル中 multiple runs ある場合に効く)。
  4. リダイレクト先を `$TMPDIR/dev-workflow/` に固定することで、Specialist が並列実行されてもログ衝突しない (PID ではなく run-id で命名されるため、同一 run-id に対して重複 watch が走らない設計である限り安全)。
- **注意**: `gh run watch` は run が `queued` 状態の間も polling し続ける。ステップ完了コミット直後にすぐ `gh run watch` を呼ぶと、対象 run record がまだ作成されていない race がある。**設計時に「commit push → 数秒待機 or `gh run list --commit <sha> --json databaseId` で run id 出現を待つ → 取得した id で `gh run watch`」というシーケンスを明示する**必要がある。

### F-7. `gh run rerun <id>`

- 主要フラグ:
  - 引数なし (`gh run rerun <id>`) — 全 job を再実行 (REST: `POST /actions/runs/{run_id}/rerun`)。
  - `--failed` — 失敗 job + その依存 job のみ再実行 (REST: `POST /actions/runs/{run_id}/rerun-failed-jobs`)。
  - `-j, --job <database-id>` — 特定 job のみ再実行。help に「URL の `/jobs/<number>` の number ではなく `gh run view <run-id> --json jobs --jq '.jobs[] | {name, databaseId}'` で得られる databaseId を渡せ」と明記されている。
  - `-d, --debug` — デバッグログ有効化。本サイクルの自動リトライでは不要。
- **重要な仕様 (REST API ドキュメントで確認)**: `gh run rerun` は **新しい run id を作らず、同じ run record の `run_attempt` をインクリメント**する。そのため:
  - SC-7 の検証 (`gh run list --branch <branch> --json conclusion,headSha,event`) では、commit SHA → run id の対応は 1:1 のまま保たれる。`conclusion: success` を最終結果として読めば良い。
  - 「2 回までリトライ」のカウントは **`attempt` フィールドの増分で観測可能**。`gh run view <id> --json attempt --jq .attempt` で 1 → 2 → 3 と進むので、`attempt > 3` になる前に Blocker 化するロジックが組める。
- `--failed` と無印 `gh run rerun` の違い: 無印は全 job (matrix 全エントリ含む) を再実行するため**実行時間が長い**。本サイクルの想定する flaky test 対策としては `--failed` の方が高速かつ副作用が小さい。ただし「失敗 job + 依存 job」の挙動なので、依存グラフが浅いリポでは結局全 job が走ることもある (本リポの `.github/workflows/ci.yaml` の依存構造は researcher #2 の調査領域)。
- 並列リトライ衝突: 同一 run id に対して `gh run rerun` を多重実行すると、GitHub Actions 側が「a workflow run for this rerun is already in progress」エラーを返す。Specialist が並列で gh コマンドを叩く設計を取る場合、**rerun は Main の単独責務にする**のが安全。
- 公式 API ドキュメント側に **age limit (例: 30 日後は rerun 不可)** の明示記載は現時点で見つからなかった (UI 上は古い run の rerun ボタンが消えるため何らかの制限はある可能性が高いが、本サイクルは作成直後の rerun が前提なので影響小)。

## 引用元

- 実機 help (v2.83.2):
  - `gh pr create --help` (`/tmp/claude-501/dev-workflow/gh-research/pr-create.txt`)
  - `gh pr ready --help` (`/tmp/claude-501/dev-workflow/gh-research/pr-ready.txt`)
  - `gh pr edit --help` (`/tmp/claude-501/dev-workflow/gh-research/pr-edit.txt`)
  - `gh pr view --help` (`/tmp/claude-501/dev-workflow/gh-research/pr-view.txt`)
  - `gh pr checks --help` (本ノート F-4 で言及した `--required` / `bucket` / exit code 8 の出典)
  - `gh run list --help` (`/tmp/claude-501/dev-workflow/gh-research/run-list.txt`)
  - `gh run view --help` (`/tmp/claude-501/dev-workflow/gh-research/run-view.txt`)
  - `gh run watch --help` (`/tmp/claude-501/dev-workflow/gh-research/run-watch.txt`)
  - `gh run rerun --help` (`/tmp/claude-501/dev-workflow/gh-research/run-rerun.txt`)
  - `gh help exit-codes` (exit code 0/1/2/4 の規約 + `gh pr checks` のみ exit code 8 = pending あり)
- GitHub CLI manual:
  - [`gh pr ready`](https://cli.github.com/manual/gh_pr_ready) — `--undo` の plan 制限注記
  - [`gh run rerun`](https://cli.github.com/manual/gh_run_rerun) — フラグ仕様
- GitHub REST API:
  - [Workflow runs API (`rerun` / `rerun-failed-jobs`)](https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28) — `run_id` 不変・`run_attempt` インクリメント仕様、age limit 明記なし
- 本リポ:
  - `docs/workflow/2026-05-03-pr-ci-integration/intent-spec.md` L83–L85 (gh CLI 前提制約) / L119–L126 (未解決事項) / L63–L77 (検証クエリ)
  - 本リポ `.github/workflows/` ディレクトリ (ci.yaml / deploy-bw.yaml / deploy-c-plugin.yaml / deploy-totto2727-fp.yaml の 4 本が存在することのみ確認、ジョブ構造解析は researcher #2 担当)

## 設計への含意

Step 3 (architect) で SKILL.md ルールを書く際の具体的推奨。**括弧書きで対応する Intent Spec の未解決事項 ID を示す**。

- **D-1 (PR description 更新の自動化レベル / 未解決事項「PR description 更新の自動化レベル」)**: PR description は `gh pr edit <num> --body-file <path>` 経由で更新する。`<path>` は `$TMPDIR/dev-workflow/<id>-pr-body.md` に置き、各ステップ完了時に Main がテンプレートから再生成 → `gh pr edit` を 1 回叩く。**HEREDOC (`gh pr edit <num> --body "$(cat <<EOF ... EOF)"`) は採用しない理由**: 本サイクルの description には Markdown コードブロック・バッククォート・`$` 変数表記・関連サイクル URL が頻出し、shell エスケープ事故が起きやすいため。`--body-file` なら shell quoting に依存せず確実。
- **D-2 (Step 9 完了 = Ready 化のトリガー条件 / 未解決事項「Step 9 完了 = Ready 化のトリガー条件」)**: Ready 化は `gh pr view <num> --json isDraft --jq .isDraft` で `true` を確認した上で `gh pr ready <num>` を呼ぶ二段構えにする。これにより、Step 9 が再実行された (例えば retrospective.md の差し戻し) 場合でも冪等に振る舞える。`--undo` 経路は本サイクルでは使用しない (Draft 戻しは想定外)。Ready 化検証 (SC-8) は `gh pr view <num> --json isDraft --jq .isDraft` の値が `false` であることに加え、`gh api repos/<owner>/<repo>/issues/<num>/timeline` で `event: ready_for_review` イベントの `created_at` が Step 9 コミットの時刻以降であることをチェックする (help の JSON フィールドリストには `readyForReviewAt` が露出していないため GraphQL or timeline API が必要)。
- **D-3 (CI リトライの実装手段 / 未解決事項「CI リトライの実装手段」)**: 「最大 2 回リトライ」は **`gh run rerun --failed <run-id>` を最大 2 回**実行する形で実装する (新規コミット push でのリトライは本サイクル非採用、理由: コミット SHA が変わると Intent Spec SC-7 の「各ステップ完了コミット SHA に success が紐づく」検証が複雑化するため)。リトライ判定は `gh run view <run-id> --json attempt,conclusion --jq '.attempt'` で attempt 値を読み、`attempt >= 3` に到達した時点で `gh run rerun` を呼ばず Blocker 化する。`--failed` を使う理由は (a) 失敗 job のみで実行時間短縮、(b) flaky test 起因の偽陰性リトライに最適、(c) REST API 上で `rerun-failed-jobs` エンドポイントが提供する依存解決を活用できる、の 3 点。
- **D-4 (CI 失敗判定の粒度 / 未解決事項「CI 失敗判定の粒度」)**: 「CI が PASS」を判定する際は、ステップ完了コミットの SHA に対して `gh run list --commit <sha> --json conclusion,name,workflowName` を呼び **`conclusion == "success"` がブランチ保護で必須化されている全 workflow について揃っていること**を条件にする (researcher #2 の出力を待って必須 workflow リストを Step 3 で確定する)。**より単純な代替案**として `gh pr checks <num> --required --json bucket --jq 'all(.[]; .bucket == "pass")'` が使える。`--required` フラグでブランチ保護の required check のみに絞れるため、ジョブ名のハードコードを避けられる。`gh pr checks` は exit code 8 で「pending あり」を返すので、watch loop は exit code を見て継続/打ち切り判定可能。
- **D-5 (バックグラウンド `gh run watch` のリダイレクト方針 / 本サイクルで採用済みのパターン妥当性検証)**: 既採用の `gh run watch <id> > "$TMPDIR/dev-workflow/ci-watch-<id>.log" 2>&1 &` パターンは妥当だが、**`--exit-status --interval 10 --compact` の 3 オプションを必ず付ける**ことを SKILL.md に明記すべき。理由は F-6 末尾に記載 (exit code による失敗検知 / API レート制限緩和 / ログ容量抑制)。バックグラウンド実行後の結果取得は `wait $WATCH_PID; rc=$?` で exit code を回収し、`rc != 0` で `gh run rerun --failed <id>` に分岐する。
- **D-6 (Specialist が gh CLI を直接呼ぶか / Main 経由か / 未解決事項)**: F-7 の「rerun は同一 run id に対して直列実行が必要」「並列 rerun 衝突は GitHub Actions 側でエラー化」を踏まえ、`gh run rerun` と `gh pr ready` は **Main 専属操作**にする。`gh pr view --json` / `gh run list --json` / `gh run view --json` (read 系) は Specialist が叩いても副作用がないため許容してよいが、SKILL.md には「PR / CI への書き込み (`pr create` / `pr edit` / `pr ready` / `run rerun`) は Main のみ」と書いておく。これは `specialist-common` の「Git コミットは Main 担当」と整合する。
- **D-7 (PR 生成の冪等性 / SC-5 の堅牢化)**: `gh pr create --draft` を盲目的に呼ぶと「既存 open PR あり」エラーで初期化が失敗する。Step 1 完了コミット直後に Main が **`gh pr list --head <branch> --state open --json number,isDraft` → 0 件なら `gh pr create --draft` / 1 件なら既存 PR を再利用** という分岐を入れる必要がある。これにより、同一サイクル内で Step 1 が再実行されたり、サイクル PR がすでに人手で作られているケースでも冪等に動く。
- **D-8 (description 更新トレース / SC-6 の検証手段)**: `gh pr view --json updatedAt` だけでは「description が更新されたか」と「他フィールドが更新されたか」を区別できない。SC-6 の検証は **`gh api repos/<owner>/<repo>/issues/<num>/timeline --jq '.[] | select(.event == "renamed" or .event == "edited")'`** または **「現在の description text が initial commit 直後の text と差分がある」** で代替する。Step 3 設計時に検証クエリを明示する。

## 残存する不明点

- **`gh pr ready` の冪等性に関する公式保証**: help / manual / source code いずれにも「既に Ready の PR への再実行は noop で成功する」という明文がない。本ノートでは「事前に `isDraft` をチェックして既に Ready ならスキップ」する設計回避策 (D-2) を推奨したが、**実際に gh が Ready PR への `gh pr ready` をエラー化するか否か**は本サイクルのドッグフード (Step 9) で実測するか、cli/cli リポジトリの該当コマンド実装を読んで確定する必要がある。Blocker ではなく Design で仮定を置いて進めて良い (D-2 の回避策で実害が出ない)。
- **`gh run rerun` の age limit**: REST API ドキュメントに明記がない。GitHub Actions UI 上は古い run の rerun ボタンが消えるため何らかの制限がある可能性が高いが、本サイクルは作成直後の rerun が前提のため影響なし。Researcher 追加起動は不要。
- **`readyForReviewAt` フィールドの取得経路**: 本ホストの `gh pr view --json` JSON FIELDS リストには `readyForReviewAt` が露出していない (intent-spec.md SC-8 が参照している項目)。`gh api graphql` 経由 or `gh api .../timeline` 経由で代替できることは F-4 / D-2 で示したが、`gh` バージョンによっては `--json` のフィールドが追加されている可能性がある (v2.83.2 の動作)。Step 3 設計時に確定したクエリで Step 8 (Validation) が走らせて確認するため、Blocker 化は不要。
- **`gh pr checks --required` の動作要件**: `--required` フラグはブランチ保護で「required」設定された check のみフィルタする。本リポの `main` ブランチに required check 設定が入っているか否かは researcher #2 (existing-ci) のスコープに重なるため、本ノートでは「required 設定があれば D-4 の代替案が最小設計」とだけ示し、確定は researcher #2 の出力後に Step 3 で行う。
