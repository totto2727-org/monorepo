# Review Report: Security

- **Cycle:** 2026-05-03-pr-ci-integration
- **Aspect:** security — 認証認可・入力検証・秘匿情報露出・新攻撃面・gh CLI 権限境界・一時ファイル取り扱い
- **First reviewed:** 2026-05-03
- **Last updated:** 2026-05-03
- **Final Gate:** approved
- **Round count:** 1

## 指摘一覧

| ID  | 深刻度 | 指摘内容                                                                                                                                                                                                                           | 状態           | 検出 Round | 解消 commit | Notes                                                                                                                                                                                       |
| --- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ---------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| m-1 | Minor  | Specialist の PR write 系コマンド禁止が specialist-common §7 L195 のテキストルールのみで担保されており、settings.json の deny やフックによる技術的強制が無いため、実装ミスや誤操作で `gh pr create/edit/ready` が実行され得る      | accepted-as-is | 1          | -           | Intent Spec L34 が「specialist-\* スキルへの大規模変更は行わない」を非スコープ宣言しており、本サイクル時点では運用ルールでカバー。[詳細](#m-1-詳細-specialist-の権限境界の技術的強制力欠如) |
| m-2 | Minor  | `$TMPDIR/dev-workflow/ci-watch-<run-id>.log` および `ci-fail-<run-id>.log` のクリーンアップ手順が SKILL.md 改修箇所 (L883-L943) に明示されておらず、失敗ログが長期残存する可能性がある                                             | accepted-as-is | 1          | -           | 既存 L776 で「サイクル完了時に残す / 削除するかはプロジェクト方針」と概括的に書かれているが、CI ログ専用の retention 規律は未定義。[詳細](#m-2-詳細-ci-ログの-retention-規律未定義)         |
| m-3 | Minor  | PR description テンプレの「Notable incidents」(L874) に「ロールバック・前提崩壊履歴」を残すと指示されているが、public リポでは GitHub PR body にこれらが永続露出するため、組織内インシデントの公開度合いに対するガイドラインが無い | accepted-as-is | 1          | -           | 当リポは public かつ既に `docs/workflow/<id>/retrospective.md` 等で類似情報が公開されており新規露出はほぼない。[詳細](#m-3-詳細-notable-incidents-の公開範囲ガイドライン欠如)               |
| i-1 | Info   | gh CLI の write 系コマンド (`gh pr create/edit/ready` / `gh run rerun`) が Main 専属化されており、認証コンテキスト (`gh auth login` の current repo) によって他リポへの誤操作は実質的に防がれている                                | (整合確認のみ) | 1          | -           | SKILL.md L788, specialist-common §7 L195 の併記で責任所在が一意。`gh pr list --head "$BRANCH"` も current repo に閉じる動作                                                                 |
| i-2 | Info   | 「2 回リトライ → Blocker 化」を悪用した DoS 攻撃面 (CI を意図的に失敗させ続けて作業停止) は本リポの脅威モデル (Main = AI agent、外部介入経路なし) では現実的でなく、追加対策不要                                                   | (整合確認のみ) | 1          | -           | CI 失敗主因は本リポでは決定的問題 (oxfmt Formatting / typecheck) であり flaky ゼロ (`research/ci-structure.md` F-6)                                                                         |
| i-3 | Info   | private リポ運用時の `gh api` timeline アクセス制約 (fine-grained PAT は `checks:read` 不可) が SKILL.md 改修箇所には記述されておらず design.md L488 にのみ記載                                                                    | (整合確認のみ) | 1          | -           | 当リポは public で運用、private リポへの展開時に再評価する事項。本サイクル スコープ外                                                                                                       |

## 詳細セクション

### m-1 詳細: Specialist の権限境界の技術的強制力欠如

**該当箇所:** `plugins/dev-workflow/skills/specialist-common/SKILL.md` L195、`plugins/dev-workflow/skills/dev-workflow/SKILL.md` L788

**事実:**

- specialist-common §7 (Git ガードレール) 末尾に「PR 操作 (`gh pr create` / `gh pr edit` / `gh pr ready` / `gh run rerun`) は Main が単独で実行する。Specialist は read 系 (`gh pr view --json` / `gh run list --json` / `gh run view --json`) のみ使用してよい。」が 1 行追加されている
- これは**運用ルールとして文書化されているのみ**で、settings.json の `permissions.deny` 等による技術的強制 (例: PreToolUse hook で gh write 系コマンドをブロック) は導入されていない

**security 観点での懸念:**

- Specialist が誤って (または将来の Specialist 設計変更時の意図せぬ regression で) `gh pr edit` を実行した場合、Single-Source-of-Progress 原則違反 (PR description が複数主体で書き換えられる) と整合性問題が起きる
- **権限の昇格や他リポ操作のリスクは低い** (gh CLI は認証コンテキスト内でしか動作せず、current repo 制約があるため)、よって即時の Blocker / Major には該当しない
- セキュリティの "defense in depth" 観点では、ルールのみではなく hook 等の二重防御が望ましい

**推奨アクション (Retrospective 繰越):**

- 将来サイクルで `.claude/settings.json` に PreToolUse hook を追加し、Specialist subagent コンテキストで `gh pr (create|edit|ready)` および `gh run rerun` を block する強制機構を検討
- ただし本サイクルの非スコープ (`specialist-*` への大規模変更禁止) と整合させるため、別サイクルで扱うのが妥当

### m-2 詳細: CI ログの retention 規律未定義

**該当箇所:** `plugins/dev-workflow/skills/dev-workflow/SKILL.md` L901, L913 (新セクション内)

**事実:**

- バックグラウンド `gh run watch` のログ出力先は `$TMPDIR/dev-workflow/ci-watch-<run-id>.log` (L901)
- 失敗時には `gh run view <id> --log-failed > $TMPDIR/dev-workflow/ci-fail-<run-id>.log` (L913)
- `--log-failed` の出力には CI ジョブのログがそのまま含まれる (本リポの ci.yaml には `secrets.*` 参照は無いため秘匿変数の生値混入リスクは低い)
- 既存セクション L776 では「サイクル完了時に `$TMPDIR/dev-workflow/<cycle>-*.md` を残す / 削除するかはプロジェクト方針」と概括的に書かれているが、**`<run-id>` をキーとする新規ログ群はこの命名パターン (`<cycle>-*.md`) に完全には一致しない** ため、cleanup 対象から漏れる可能性

**security 観点での懸念:**

- `$TMPDIR` は OS 再起動時にクリアされるが、長時間稼働するセッションや CI 用 runner では数日〜数週間残存する可能性
- ログサイズ累積 (run id ごとに新ファイル) によるディスク占有
- 万が一 CI ログに環境変数値の漏洩 (例: 失敗 stack trace 内の sensitive 文字列) があった場合、cleanup 漏れが追跡困難

**推奨アクション (Retrospective 繰越):**

- SKILL.md L776 の一時ファイル取扱セクションに「`ci-watch-<run-id>.log` / `ci-fail-<run-id>.log` もサイクル完了時 (Step 9 後) に削除対象とする」旨を 1 行追記
- 本サイクルでは Blocker / Major には該当しないため、次サイクルで補強する形で十分

### m-3 詳細: Notable incidents の公開範囲ガイドライン欠如

**該当箇所:** `plugins/dev-workflow/skills/dev-workflow/SKILL.md` L874-L876 (PR description テンプレ内)

**事実:**

- PR description テンプレに `## Notable incidents (該当があった場合のみ)` セクションがあり「ロールバック・前提崩壊履歴」を残すと指示
- public リポの場合、PR body は誰でも閲覧可能 (匿名アクセス可)
- 当リポは public で、既に `docs/retrospective/<id>.md` (Retrospective Note) や `progress.yaml.blockers[]` で類似情報がリポジトリに永続化されている

**security 観点での懸念:**

- private リポ → public 化や、組織内 OSS 運用への横展開時、Notable incidents に記載すべきでない情報 (顧客名、内部障害の詳細、外部依存サービスの一時的脆弱性情報など) を含めてしまうリスク
- 既存 `specialist-common §9` (秘匿情報の取り扱い) は API キー・トークン・PII 等を対象にしているが、「組織内インシデント情報の公開度合い」までは扱っていない

**推奨アクション (Retrospective 繰越):**

- 将来 private リポで dev-workflow を運用する際に、PR description テンプレの Notable incidents 記載基準 (どの粒度まで書くか) を別途定義する。本サイクルでは public リポ前提のため Minor 据え置き
- 既存 `specialist-common §9` への参照リンクを SKILL.md L874 近辺に貼って読者の注意を喚起する案もあり (1 行追加で実装可能)

## Round 履歴メタ

| Round | 実行日     | reviewer instance            | 単独 Gate |
| ----- | ---------- | ---------------------------- | --------- |
| 1     | 2026-05-03 | reviewer (security, Round 1) | approved  |

最終 Gate: `approved`。Major / Blocker 0 件、`accepted-as-is` 3 件 (m-1 / m-2 / m-3、いずれも Retrospective 繰越候補)。

<!--
書き方ガイド: shared-artifacts/references/review-report.md
状態ラベル詳細・観点別の重点項目は specialist-reviewer/SKILL.md に委譲。
-->
