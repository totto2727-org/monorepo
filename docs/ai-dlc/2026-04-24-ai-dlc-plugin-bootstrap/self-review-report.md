# Self-Review Report: 2026-04-24-ai-dlc-plugin-bootstrap

- **Reviewer:** self-reviewer（逆算実行）
- **Target:** Construction Phase diff（全タスク、コミット `2b34716` および `b386eeb`）
- **Reviewed at:** 2026-04-24T16:30:00Z
- **Last updated:** 2026-04-24T16:30:00Z

## サマリ

| 深刻度      | 件数 |
| ----------- | ---- |
| High        | 0    |
| Medium      | 4    |
| Low         | 4    |

**Gate 判定:** **passed**（High 0 件、Medium は Verification に持ち越し可）

## 指摘事項

### #1 shared-artifacts 内の references 相対パス表記の曖昧性

- **深刻度:** Medium
- **該当箇所:**
  - Commit: `b386eeb`
  - File: `plugins/ai-dlc/skills/shared-artifacts/SKILL.md`
  - Line: 目次テーブルおよび「Reference と Template の使い分け」セクション
- **問題の要約:** shared-artifacts の SKILL.md 内部では `references/<name>.md` / `templates/<name>.md` と記述しているが、他スキル（`specialist-*`, `main-*`）からは `shared-artifacts/references/<name>.md` と full path 指定している。読み手によってパスの解釈起点が異なり、ユーザー／エージェントが混乱する恐れがある。
- **根拠:** `shared-artifacts/SKILL.md` の目次表と、他スキルのエージェント起動仕様で表記が不一致。`Design Document` の「Specialist 起動の入力仕様」では `shared-artifacts/references/<name>.md` と明示しているので、SKILL.md 側の記述が統一されていない。
- **推奨アクション:** shared-artifacts SKILL.md の該当テーブルを `shared-artifacts/references/...` / `shared-artifacts/templates/...` に統一する。または、SKILL.md の冒頭で「本スキル内の相対パス表記は shared-artifacts ディレクトリからの相対」と明示する。
- **design.md との関連:** 「Specialist 起動の入力仕様」セクション
- **Status:** open

### #2 TODO.md スキーマの重複定義

- **深刻度:** Medium
- **該当箇所:**
  - Commit: `b386eeb`
  - File: `plugins/ai-dlc/skills/main-construction/SKILL.md`（「Construction 開始時: タスクリスト反映」セクション）
  - File: `plugins/ai-dlc/skills/shared-artifacts/references/todo.md`
- **問題の要約:** TODO.md のスキーマ（フィールド一覧、ステータス遷移）が 2 箇所に重複している。shared-artifacts 移管時に main-construction 側の記述を十分スリム化しなかった。片方を更新してもう片方を忘れると齟齬が発生する。
- **根拠:** shared-artifacts は成果物仕様の真のソースであるべきで、main-construction は運用フロー（どのステップでいつ TODO.md を更新するか）のみを記述すべき。
- **推奨アクション:** main-construction の「Construction 開始時: タスクリスト反映」セクションから TODO.md フォーマット例を削除し、`shared-artifacts/references/todo.md` へのリンクに置き換える。タスクリスト反映の**手順**（何をいつ書くか）のみ main-construction に残す。
- **design.md との関連:** 「shared-artifacts に集約」の採用理由に矛盾
- **Status:** open

### #3 main-workflow の shared-artifacts 参照セクションに背景説明が不足

- **深刻度:** Medium
- **該当箇所:**
  - Commit: `b386eeb`
  - File: `plugins/ai-dlc/skills/main-workflow/SKILL.md` L253-268 付近（「成果物テンプレート・保存構造・進捗記録フォーマット」）
- **問題の要約:** 「全て `shared-artifacts` スキルに集約」と書かれているが、なぜ集約したのか・分離前の状態がどうだったかの説明がない。新規読者は唐突な委譲に見え、設計意図が伝わらない。
- **根拠:** Design Document の「shared-artifacts に集約」の採用理由（1:1 対応担保、誰でも読める共通基盤）が main-workflow 側からは読み取れない。
- **推奨アクション:** 該当セクション冒頭に 1–2 行で「本プラグインでは成果物仕様を shared-artifacts スキルに集約することで、Main / Specialist / ユーザーが同じ真のソースを参照できるようにしている」の一文を追加。
- **design.md との関連:** 「代替案と採用理由」表の該当行
- **Status:** open

### #4 タスク追加時の task-plan.md 取り扱いが曖昧

- **深刻度:** Medium
- **該当箇所:**
  - Commit: `b386eeb`
  - File: `plugins/ai-dlc/skills/main-construction/SKILL.md`（Step 5 失敗時の挙動）
  - File: `plugins/ai-dlc/skills/shared-artifacts/references/todo.md`
  - File: `plugins/ai-dlc/skills/shared-artifacts/references/task-plan.md`
- **問題の要約:** 「Construction 中にタスク追加が発生した場合、task-plan.md は不変で TODO.md 側に追加タスクを追記」とあるが、`task-plan.md` そのものへの追記を禁じる記述と、「差分の理由を TODO.md 冒頭に記録」という運用が各所に散らばっており、最終的に task-plan.md に手を入れてよいかが不明確（特に main-construction SKILL.md L169 の「`task-plan.md` も対応する変更があれば追記」という表現が曖昧）。
- **根拠:** Design Document の「task-plan.md 不変 + `TODO.md` で状態追跡」採用理由との整合性が取れていない。
- **推奨アクション:** 「task-plan.md は Construction 中 **常に不変** で、追加タスクは TODO.md の 'Appended Tasks' セクションにのみ追記する」とルールを単一化。該当箇所を修正する。
- **design.md との関連:** 「代替案と採用理由」表の `task-plan.md` 不変運用
- **Status:** open

### #5 Specialist 起動時に Main が伝える情報の明示性

- **深刻度:** Low
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/specialist-common/SKILL.md`（「入力契約」セクション）
  - File: `plugins/ai-dlc/agents/*.md`
- **問題の要約:** agents/*.md の「Main への要求」セクションで必要情報を列挙しているが、specialist-common の「入力契約」と多少重複しつつも項目が微妙に違う（具体的成果物パスの有無等）。
- **根拠:** 真のソースが曖昧。どちらを読むべきか不明。
- **推奨アクション:** specialist-common を真のソースとし、agents/*.md 側は specialist-common の入力契約表を参照させる + 役割固有の追加入力のみ列挙、の構造に揃える。
- **design.md との関連:** 「Specialist 起動の入力仕様」
- **Status:** open

### #6 `specialist-common` スキル名が長く、エージェントが起動時に混乱する恐れ

- **深刻度:** Low
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/specialist-common/SKILL.md`
- **問題の要約:** `specialist-*` という命名は具体的な役割と想起させるが、`specialist-common` は「共通」を意味する。この命名はスキル探索の description マッチングで誤発火する可能性がある（例: 「specialist を呼ぶ」と書いた際、common が反応する）。
- **根拠:** Description の最初に `[Specialist 共通基盤]` と prefix を入れて区別を試みているが、description 本文のトリガーワードに「specialist-* スキルを使用開始する際」と含まれており、すべての specialist スキル起動時に反応する設計は意図した動作か検討が必要。
- **推奨アクション:** 現状の意図が「各 specialist 起動時に並行ロードされる」であれば問題なし。Retrospective 段階で実使用検証し、誤発火が起きないか確認する。
- **design.md との関連:** なし（発見的指摘）
- **Status:** open

### #7 Mermaid 図が Claude Code 環境で実際にレンダーされるか未検証

- **深刻度:** Low
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/main-workflow/SKILL.md`（ワークフロー全体図 - ASCII アート）
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/design.md`（mermaid フェンス）
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/task-plan.md`（mermaid フェンス）
- **問題の要約:** テンプレート内の Mermaid 図が、Claude Code の Markdown レンダラーで実際に図として表示されるか検証していない。レンダーされない環境では生の Mermaid ソースが読みづらい。
- **根拠:** CommonMark のみの環境では Mermaid は生テキストのまま
- **推奨アクション:** Verification フェーズでユーザー環境での表示を確認。レンダーされない場合は ASCII 版を併記するか `mermaid` フェンスを除去。
- **design.md との関連:** なし（ユーザビリティ指摘）
- **Status:** open

### #8 Retrospective 事前準備項目の抜け

- **深刻度:** Low
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/specialist-retrospective-writer/SKILL.md`
  - File: `plugins/ai-dlc/skills/shared-artifacts/references/retrospective.md`
- **問題の要約:** Retrospective の「データソース（入力として必要）」に `$TMPDIR/ai-dlc/*.md` の一時レポート一覧が含まれているが、これらは OS 依存のパスで他セッションからアクセスできない場合がある。サイクル完了後に別セッションが Retrospective を実行する場合、元の `$TMPDIR` が存在しない可能性が高い。
- **根拠:** specialist-retrospective-writer は同一セッションで実行される前提だが、仕様として明示されていない。
- **推奨アクション:** Retrospective は Verification の中で実行される前提で「同一セッション内で一時レポートにアクセス可能であること」を specialist-retrospective-writer の前提として明記する。または、Step 9 開始前に一時レポートを `docs/ai-dlc/<identifier>/_tmp-reports/` にコピーしてくる運用を定義する。
- **design.md との関連:** 「成果物保存構造」で `$TMPDIR` を採用した判断の副作用
- **Status:** open

## ADR / Intent Spec との整合性チェック

- **Intent Spec 成功基準:** **満たす見込みあり**
  - すべての成功基準が観測可能な形でチェックリストとして確認済み（Intent Spec L20-27）
  - ファイル存在確認、構造整合性、参照統一、コミット規約文書化すべて実物と一致
- **Design Document との整合:** **準拠**（部分的な不整合は Medium 指摘 #2, #3, #4 で対応予定）
- **詳細:**
  - 2 層 Main/Specialist 構造: ✅ 実装どおり
  - shared-artifacts 抽出: ✅ 実装どおり
  - Artifact-as-Gate-Review + In-Progress Questions: ✅ 実装どおり
  - task-plan 不変 + TODO.md: ⚠️ 記述の曖昧さあり（#4）
  - ステップ完了コミット規約: ✅ 文書化済み（Implementation のみタスク単位の区別も明示）
  - 命名規則 (main-* / specialist-* / shared-artifacts): ✅ 全 15 スキルで統一

## 修正ラウンド履歴

- **Round 1** (2026-04-24T16:25:00Z): 初回レビュー。High 0 件、Medium 4 件、Low 4 件検出
  - High が 0 件のため Gate 通過
  - Medium 4 件は Verification フェーズで Review Report とクロスチェック後、重要度を再判定
  - Low 4 件は Retrospective で改善提案として扱う

## Verification フェーズへの申し送り

Medium 指摘 4 件については、Step 7 (External Review) で複数観点（security / readability / api-design）から再評価する。特に #1（パス表記の曖昧性）と #2（スキーマ重複）は readability / api-design 観点で必ず検出されるべき項目なので、外部 reviewer の指摘と一致するかで self-reviewer の精度も測れる。
