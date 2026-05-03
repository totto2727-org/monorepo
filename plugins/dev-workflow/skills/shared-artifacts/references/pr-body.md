# Reference: pr-body.md

GitHub の Draft / Ready PR の **description (body)** を生成するための雛形。テンプレート: `shared-artifacts/templates/pr-body.md`。

## 目的

サイクル PR の description を **GitHub 上にのみ永続化** する設計 (`dev-workflow/SKILL.md` 「## サイクル PR と CI 連携プロトコル」参照) のもと、Main が各ステップ完了時に揮発ファイル経由で再生成して PR に送信するための共通テンプレートを提供する。

- リポジトリ内に `pr-overview.md` のような永続成果物は作らない (Single-Source-of-Progress 原則: 真のソースは `progress.yaml` / `TODO.md`)
- テンプレートは **「いつ何を埋めるか」を明示するための共通契約** として shared-artifacts に置く
- 個別サイクルの description (= テンプレート展開後の中身) は **commit しない**。`$TMPDIR/dev-workflow/<identifier>-pr-body.md` に揮発生成し、`gh pr edit --body-file` で送信する

## 作成タイミングと作成者

- **作成者:** Main (write 系 `gh pr edit` は Main 専属、`specialist-common §7` 参照)
- **再生成タイミング:**
  - サイクル初期化コミット直後 (Step 1 着手時の Draft PR 作成と同時、初回送信)
  - 各ステップ完了コミット直後 (必須、9 回)
  - その他、内容が大きく変化したと Main が判断した時 (任意、適宜)
- **配置先:** `$TMPDIR/dev-workflow/<identifier>-pr-body.md` (揮発、サイクル間で再利用しない)

## セクション仕様

テンプレートの各セクションは **段階的に埋まる** 構造。Step 1 完了時には Summary + Cycle artefacts (intent-spec のみ) + Progress checklist (Step 1 のみ `[x]`) + CI status (初回コミットの結果) で初期化し、以降のステップ完了ごとに該当セクションを更新する。

### `## Summary`

- 1〜3 bullet で **目的・主要変更**を要約する
- ソース: Intent Spec (`docs/workflow/<id>/intent-spec.md`) の「目的」セクションから派生
- ステップ進行で内容が変化することは少ない (Intent Spec が変わらない限り維持)

### `## Cycle artefacts`

- 既に作成された成果物のパスを `<種別>: docs/workflow/<id>/<file>` 形式で列挙
- ステップ完了ごとに該当行を追記。**未着手のステップは行を出さない** (空のブレットを残さない)
- 例外: Retrospective は `docs/retrospective/<id>.md` (集約ディレクトリ)

### `## Progress checklist`

- Step 1〜9 のチェックリスト
- 完了したステップは `[x]`、未完了は `[ ]`
- ロールバックで「再活性化中」のステップがある場合は `[ ]` に戻し、Notable incidents セクションに理由を記録

### `## CI status`

- **最新コミット SHA**: 短縮 SHA (7 文字)
- **最新 `check` job 結果**: `success` / `failure` / `in_progress`、run id、attempt 番号
- **リトライ履歴**: 失敗 → 修正 push のサイクルが発生した Step だけブロック化して列挙
  - 例: `Step 6 task-T1 (commit abc1234): attempt 1 failure → fix push def5678 attempt 2 success`
- **判定根拠**: `gh run view <run-id> --json conclusion` の出力 (詳細は `ci-monitoring` スキル参照)

### `## Test plan (Step 8 で完成)`

- Step 1〜7 の間は **チェックボックス未確定の暫定リスト** (Intent Spec の SC-N をベースに）
- Step 8 Validation 完了時点で各 SC の判定 (`PASS` / `FAIL` / `SKIP` / `PENDING`) と観測値を記入
- 観測値は `validation-report.md` から要約抜粋して引用

### `## Notable incidents (該当があった場合のみ)`

- ロールバック発生履歴 (`progress.yaml.rollbacks[]` から派生)
- Blocker → ユーザー判断での回復履歴 (`progress.yaml.blockers[]` から派生)
- origin/main の大規模変更を rebase で取り込んだ等の前提崩壊イベント
- **該当がない場合はセクションごと省略** (空セクションを残さない)

### フッター区切り (`---` + Generated with Claude Code)

- 区切り線 `---` とフッターは PR body の末尾に必ず置く
- フッター文言は固定: `🤖 Generated with [Claude Code](https://claude.com/claude-code)`

## 品質基準

- **Single-Source-of-Progress 整合**: PR description の内容は `progress.yaml` / `TODO.md` から派生する **ビュー** であり、PR description が真のソースになってはいけない
- **段階的更新の整合**: ステップが進むごとにテンプレートの該当セクションだけが伸びる。**未着手ステップの行を残さない** (= "[Step 5]: TBD" のような placeholder を残さない)
- **CI status の最新性**: PR description 更新コミット時点の最新 SHA / run id が反映されていること (古い run の状態を残さない)
- **Test plan は Validator 出力の引用**: Step 8 完了後の Test plan セクションは `validation-report.md` の SC 判定行をそのまま引用する (要約は OK だが矛盾は不可)
- **Notable incidents は事実記載のみ**: 主観的な所感は Retrospective に書き、PR description には事実 (発生日時 / コミット SHA / 影響範囲) のみ記載

## 関連成果物との関係

- **入力**: `progress.yaml` (Step 状態 / artifacts 一覧)、`TODO.md` (Step 6/7 進捗)、`validation-report.md` (Step 8 完了後の Test plan セクション)
- **出力**: GitHub PR body (永続) + `$TMPDIR/dev-workflow/<identifier>-pr-body.md` (揮発)
- **関連スキル**: `dev-workflow/SKILL.md` 「## サイクル PR と CI 連携プロトコル」、`ci-monitoring/SKILL.md` (CI status セクションの埋め方)、`specialist-common §7` (`gh pr edit` は Main 専属)

## 良例 / 悪例

### 良例

- Step 5 完了時点で Cycle artefacts に intent-spec / research/ / design / qa-design / qa-flow / task-plan / TODO の 7 種が列挙され、Progress checklist の Step 1〜5 が `[x]`、CI status に最新コミット SHA + `check: success`、Test plan は SC-N の暫定リスト、Notable incidents セクションが省略 (該当なし)
- フッター直前に空行 1 行 + `---` 区切り

### 悪例

- 未着手の Step 6〜9 まで全部 `Cycle artefacts` に書いてしまう (パスが空のまま列挙される)
- CI status の SHA が古いまま (= 最新の更新コミットを反映していない、別ファイルの編集だけで PR body 更新を忘れた)
- Notable incidents セクションを「該当なし」と空欄で残す (省略すべき)
- Test plan を Step 8 完了後も暫定リストのまま放置 (Validator 出力を引用していない)
