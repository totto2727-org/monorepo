# Intent Spec: dev-workflow に Draft PR / PR 概要更新 / バックグラウンド CI 連携を統合する

- **Identifier:** 2026-05-03-pr-ci-integration
- **Author:** totto2727
- **Created at:** 2026-05-03
- **Last updated:** 2026-05-03

## 背景

現行の `dev-workflow` (v2.0.0) は 9 ステップの成果物 (Intent Spec / Design Document / Task Plan / Review Report / Validation Report / Retrospective 等) と `progress.yaml` / `TODO.md` の永続化、ステップ完了時の Conventional Commits を規定しているが、以下の領域はサイクル運用の一部として明文化されていない:

- **GitHub Pull Request の運用** — Draft PR の作成タイミング、PR 概要 (description) の更新タイミング、Ready 化の条件
- **CI との連携** — 各ステップ完了コミット (および Step 6 のタスク単位コミット) で実行される CI の扱い、CI 失敗時のステップ完了判定への影響、リトライ規律

過去のサイクル (`2026-04-29-retro-cleanup` など) を見ても、PR は人間が暗黙運用で立てており、CI 失敗時の対応も場当たり的だった。`dev-workflow` の Single-Source-of-Progress 原則 (Main が唯一の真実として進捗を保持) と Gate-Based Progression (各ステップに明確な完了基準) を GitHub PR / CI まで拡張することで、外部観測可能性を高めつつ「ステップ完了したと言ったが CI が赤」のような認識ずれを防ぐ。

## 目的

`dev-workflow` SKILL.md にサイクル PR と CI 連携のルールを追記し、(1) サイクル初期化時の Draft PR 作成、(2) ステップ完了時の PR 概要更新、(3) バックグラウンド CI の確認と完了基準への組み込み、(4) Step 9 完了後の Ready 化、を明文化する。本サイクル自身でこれらのルールを実証し、自身が Draft → Ready 化される最初のサイクルとなる。

## スコープ

- **dev-workflow/SKILL.md への新ルール追加** (本サイクルで追加するルールは以下 5 種):
  1. サイクル初期化コミット (`docs(dev-workflow/<id>): initialize cycle`) と同時に Draft PR を作成する
  2. PR 概要 (GitHub の description) を各ステップ完了時に必ず更新し、内容変化があれば随時更新する
  3. PR 概要は GitHub 側にのみ保持し、リポジトリ内に永続化された成果物 (`pr-overview.md` 等) は作らない
  4. ステップ完了コミット後、当該コミットに紐づく CI の結果を確認し、PASS していなければ当該ステップを完了と認めない。CI 失敗時は最大 2 回までリトライし、解決しない場合は Blocker としてユーザー判断を仰ぐ (作業中断)
  5. Step 9 (Retrospective) 完了後にサイクル PR を Draft → Ready 化する (PR Ready 化はサイクル完了の最終アクションの一つ)
- **本サイクル自身でのドッグフード実証** (本サイクルが上記 5 ルールに沿って Draft PR 作成 → 適宜概要更新 → CI PASS 確認 → Ready 化される一連を実体験する)
- **影響を受けるドキュメント整合性の維持** — `shared-artifacts/references/progress-yaml.md` などで PR / CI への参照追加が必要かは Step 2 (Research) / Step 3 (Design) で判断 (本 Intent では SKILL.md 改修と本サイクル PR を中心にするが、整合性を崩さない最小限の追記は許容)

## 非スコープ

- **`git-workflow` スキル / `shared-artifacts/*` / 個別 `specialist-*` スキルへの大規模変更** — `dev-workflow/SKILL.md` 以外の主要スキルへの新セクション追加・既存セクションの大幅書き換えは行わない (PR / CI 関連の既存記述があれば軽微な参照リンク追加に留める)
- **CI ワークフロー (`.github/workflows/*.yaml`) 自体の改修** — 本サイクルでは既存 CI を所与として「結果を読んで判断する」ルールのみ追加。ジョブ追加・改名・並列化・matrix 変更などは扱わない
- **PR 概要を成果物として永続化する仕組み** — `docs/workflow/<id>/pr-overview.md` のようなファイルは作らない (PR description は GitHub 側に置くのみ)
- **PR をスキップするサイクルの定義** — 全サイクルで PR 必須とし、PR スキップ条件は議論しない
- **CI 失敗時の自動リカバリ実装** — 自動再実行・自動 revert などの自動化は本サイクル外
- **複数サイクル PR の並走戦略・コンフリクト解決手順** — 単一サイクル = 単一 PR を前提とする
- **Squash / Merge / Rebase のマージ戦略の規定** — マージ方針はプロジェクト既存運用に従い、本サイクルでは触れない

## 成功基準

すべて観測可能 (grep / gh CLI / `git log` で機械的に検証可能) な形式で記述する。Step 8 (Validation) ではこれらをそのまま実測する。

- **SC-1 (SKILL.md ルール追加 — Draft PR セクション):** `plugins/dev-workflow/skills/dev-workflow/SKILL.md` に「サイクル初期化時に Draft PR を作成する」旨を明示するセクションまたは項目が追加されている
  - 検証: `grep -E "(Draft PR|draft pull request|Draft Pull Request)" plugins/dev-workflow/skills/dev-workflow/SKILL.md` が 1 件以上ヒット
  - 該当箇所に「`initialize cycle` コミットと同時に作成」相当の文言を含む

- **SC-2 (SKILL.md ルール追加 — PR 概要更新セクション):** SKILL.md に「PR 概要を各ステップ完了時に必ず更新する」旨と「内容変化時の任意更新」旨が記述されている
  - 検証: `grep -E "(PR (概要|description|overview)|プルリクエスト概要|pull request description)" plugins/dev-workflow/skills/dev-workflow/SKILL.md` が 2 件以上ヒット (定義箇所 + 運用箇所など)
  - 「各ステップ完了時に必ず」「適宜」相当の更新タイミング表現を含む

- **SC-3 (SKILL.md ルール追加 — CI 確認 / 2 回リトライ / Blocker 化):** SKILL.md に「ステップ完了コミットに紐づく CI が PASS するまで当該ステップを完了と認めない」「失敗時は最大 2 回リトライ」「2 回失敗で Blocker 化しユーザー判断」が明文化されている
  - 検証: `grep -E "(CI|continuous integration|gh run)" plugins/dev-workflow/skills/dev-workflow/SKILL.md` が 3 件以上ヒット
  - `grep -E "(2 回|二回|retry|リトライ)" plugins/dev-workflow/skills/dev-workflow/SKILL.md` が 1 件以上ヒット
  - Blocker / In-Progress ユーザー問い合わせとの接続が文中で示されている

- **SC-4 (SKILL.md ルール追加 — Step 9 完了後 Ready 化):** SKILL.md の Step 9 セクションまたは関連セクションで「Retrospective 完了後に PR を Draft → Ready 化する」旨が記述されている
  - 検証: `grep -nE "(Ready (for review|化)|ready_for_review|undraft)" plugins/dev-workflow/skills/dev-workflow/SKILL.md` が 1 件以上ヒット
  - Step 9 の Exit Criteria または直近セクションに位置する

- **SC-5 (本サイクル PR の Draft 作成):** 本サイクル PR が GitHub 上で Draft として作成され、`docs(dev-workflow/2026-05-03-pr-ci-integration): initialize cycle` 相当のコミットを含む
  - 検証: `gh pr list --state all --search "2026-05-03-pr-ci-integration"` で 1 件以上ヒットし、作成時点で `isDraft: true`
  - PR 本文にサイクル概要 / Step 進捗 / 関連 issue (あれば) が記載されている

- **SC-6 (本サイクル PR の概要更新トレース):** 本サイクル中、各ステップ完了時に PR 概要が更新されたことが PR の編集履歴 (またはコミット連動の更新) から読み取れる
  - 検証: PR の description が初期作成時から複数回更新されている (gh api で更新タイムスタンプ確認、または現在の description が initial と差分がある)
  - 各 Step 完了タイミングと description 更新タイミングが整合する (ユーザー承認ゲート前の状態で description が反映済み)

- **SC-7 (本サイクル中の各ステップ完了コミット CI が PASS):** Step 1〜Step 9 の各ステップ完了コミット (Step 6 はタスク単位コミット) について、対応する CI 実行が最終的に PASS している
  - 検証: `gh run list --branch <本サイクルブランチ> --json conclusion,headSha,event` で各完了コミット SHA に対し `conclusion: success` が紐づく (リトライ後の最終結果が success であれば良い)
  - 失敗から 2 回リトライ以内で success になったケース、または Blocker → ユーザー判断 → 修正後 success のケースを許容 (「最初の 1 回で必ず success」は要求しない)

- **SC-8 (Step 9 完了後の Ready 化):** Step 9 完了後、本サイクル PR が Draft から Ready 化されている
  - 検証: `gh pr view <PR番号> --json isDraft` で `isDraft: false`
  - Ready 化のタイミングが Step 9 (Retrospective) コミット以降である (`gh pr view` の `readyForReviewAt` または PR タイムラインで確認)

## 制約

### 技術的制約

- **GitHub CLI (`gh`) 前提** — 既存リポジトリの運用に倣い、PR 操作は `gh pr create --draft` / `gh pr edit --body` / `gh pr ready` 等を用いる。GitHub Web UI 操作には依存しない
- **CI バックエンドは GitHub Actions** — `.github/workflows/*.yaml` で動作している既存 CI を所与とする。確認手段は `gh run list` / `gh run view`
- **`gh pr ready` の Draft → Ready 化が冪等** — 既に Ready の PR に再度実行しても破壊的にならないこと (CLI 仕様確認は Step 2 Research で行う)
- **Conventional Commits 維持** — 既存リポジトリのコミット規約 (`docs(dev-workflow/<id>): ...` 等) と整合する
- **Skill ローダ互換性** — `dev-workflow/SKILL.md` の構造変更 (frontmatter / 見出し構成) は既存ローダで読み取れる範囲に留める

### 組織的制約

- **作業者は AI エージェント (Main + Specialist) のみ** — 人間レビュアーは Gate でのみ介入。Specialist が GitHub 操作を直接行ってよいかは Step 3 Design で再整理 (現状 `specialist-common` では「Git コミットは Main が実行する」)
- **本サイクル中に他のサイクルを並走させない** — PR / CI 連携の初期実証なので、リソース・認知負荷を抑える
- **本サイクル自身が新ルールに準拠する** (ドッグフード) — Step 1 で Intent Spec をコミット → 直後に Draft PR を作成 → 各ステップで概要更新 → CI 確認 → Step 9 完了で Ready 化、を実体験する

### 規範的制約

- **Single-Source-of-Progress 原則** — 進捗の真のソースは引き続き `progress.yaml` / `TODO.md`。PR description は外部公開ビュー (派生表現) の位置づけで、PR description が真ではない
- **Artifact-as-Gate-Review 原則** — ユーザー承認ゲートでは引き続き成果物そのもの (Intent Spec / Design Document 等) をレビュー対象とする。PR description はゲートレビューの一次資料ではない
- **`specialist-common` の Git ガードレール** — `--no-verify` / `--no-gpg-sign` / force push 禁止、`git add -A` 禁止 (パス指定必須)。本サイクルの新ルールがこれらに違反しないこと
- **既存スキルへの影響最小化** — `git-workflow` / `shared-artifacts/*` / `specialist-*` への大規模変更は本サイクル非スコープ (上記参照)
- **秘匿情報の取り扱い** — PR description / コミットメッセージ / Research Note 等に API キー・トークン・本番データを含めない

## 関連リンク

- `plugins/dev-workflow/skills/dev-workflow/SKILL.md` (改修対象本体、v2.0.0)
- `plugins/dev-workflow/skills/specialist-common/SKILL.md` (Specialist 共通ルール、Git ガードレール)
- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md` (成果物仕様)
- `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md` (`progress.yaml` 仕様、PR / CI への参照追加要否を Step 2 で判断)
- `plugins/totto2727/skills/git-workflow/` (Conventional Commits / GPG / 安全な git 操作の既存規範)
- 直近完了サイクル `docs/workflow/2026-04-29-retro-cleanup/` (現行運用パターンの参考)
- 直近完了サイクル `docs/workflow/2026-04-29-integrate-self-review-into-external/` (SKILL.md 改修サイクルの参考)
- 直近完了サイクル `docs/workflow/2026-04-29-add-dev-roadmap-skill/` (origin/main マージで取り込まれた最新サイクル — `docs/dev-workflow/` → `docs/workflow/` リネーム + roadmap 概念追加を実施)
- GitHub CLI ドキュメント `gh pr create --draft` / `gh pr ready` / `gh pr edit --body` (Step 2 Research で公式仕様を裏取り)

## 未解決事項

Step 2 (Research) への引き継ぎ論点:

- **CI 失敗判定の粒度** — 「CI が PASS」をどう定義するか (必須チェック群のみ vs 全ジョブ vs branch protection 設定参照)。本リポジトリの CI ジョブ構成を Research で棚卸しし、Design で確定させる
- **CI リトライの実装手段** — 「2 回までリトライ」の具体操作 (`gh run rerun` / `gh run rerun --failed` / 新規コミット push のいずれか / 組み合わせ)。CLI 挙動と GitHub Actions の rerun 仕様を裏取りする必要あり
- **PR description 更新の自動化レベル** — 各 Step 完了時に Main が手動で `gh pr edit --body` するのか、テンプレートを `$TMPDIR/dev-workflow/<id>-pr-body.md` 等で管理するのか、Step 3 Design で決定
- **PR description のフォーマット** — サイクル進捗・成果物リンク・関連 issue・CI 状況などをどう構造化するか (テンプレート化要否)。Step 3 Design で `docs/workflow/<id>/` のディレクトリ命名規則と整合させる
- **Specialist が gh CLI を直接呼ぶか / Main 経由か** — 現状 `specialist-common` では Git コミットは Main 担当。PR 操作も同じく Main 担当か、特定 Specialist (例: implementer) に委譲してよいかを Step 3 Design で整理
- **Step 9 完了 = Ready 化のトリガー条件** — Retrospective コミット後に Main が即時実行か、最終ユーザー承認の後にするか。Step 3 Design で確定
- **CI 失敗 → Blocker → ユーザー判断 → 復旧の進捗記録パス** — `progress.yaml.blockers` への記録形式、TODO.md との整合、再開時の手順 (`dev-workflow` の「セッション再開時」プロトコルとの統合)
- **既存 CI ジョブの実行時間目安** — 「ステップ完了後に CI を待ってから次ステップ」が許容できるかを Research で実測情報として確認 (待機時間が長すぎる場合は別途方針相談)
