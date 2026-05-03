# Review Report: {{aspect_title}}

- **Cycle:** {{identifier}}
- **Aspect:** {{aspect}} <!-- security | performance | readability | test-quality | api-design | holistic | etc. -->
- **First reviewed:** {{first_reviewed_date}} <!-- YYYY-MM-DD (Round 1) -->
- **Last updated:** {{last_updated_date}} <!-- YYYY-MM-DD (最終 Round) -->
- **Final Gate:** {{final_gate}} <!-- approved | needs_fix | blocked -->
- **Round count:** {{round_count}}
<!-- backward-compatibility 観点では追加: - **SC-12 baseline:** {{baseline_commit}} -->

## 指摘一覧

| ID  | 深刻度 | 指摘内容            | 状態           | 検出 Round        | 解消 commit  | Notes       |
| --- | ------ | ------------------- | -------------- | ----------------- | ------------ | ----------- |
| M-1 | Major  | {{finding_1_brief}} | {{state_1}}    | {{first_round_1}} | {{commit_1}} | {{notes_1}} |
| m-2 | Minor  | {{finding_2_brief}} | {{state_2}}    | {{first_round_2}} | {{commit_2}} | {{notes_2}} |
| i-3 | Info   | {{finding_3_brief}} | (整合確認のみ) | {{first_round_3}} | -            | {{notes_3}} |

<!--
状態ラベル (1 つを選ぶ):
  fixed         : 修正済 (commit SHA を必ず併記)
  partial       : 一部解消、残課題あり (Notes に詳細)
  pending       : 未解消で次 Round で対応予定 (担当タスクを Notes に)
  accepted-as-is: ユーザー承認による Retrospective 繰越合意 / 対応不要 (合意日付を Notes に)
  obsolete      : 設計変更 / 前提変更で無効化 (理由を Notes に)

ID 接頭辞: B-N (Blocker) / M-N (Major) / m-N (Minor) / i-N (Info)
重複指摘 (複数 Round で再検出) は 1 行に統合し、検出 Round は最初の Round のみ記録する。
-->

## 詳細セクション

<!--
テーブル要約 (1〜2 文) では伝わらない指摘のみ、ここに個別記述する。
詳細不要な指摘 (テーブル行の Notes 列で済むもの) はここに書かない。
リンク方式: テーブルの Notes 列から `[詳細](#m-1-詳細-...)` を貼っても良い。
-->

### M-1 詳細: {{detail_1_heading}}

{{detail_1_body}}

## Round 履歴メタ

<!--
監査用の付帯情報。本ファイルの本筋ではないため末尾に置く。
読み手が「いつ誰が何を判定したか」を確認したいときのみ参照する。
-->

| Round | 実行日           | reviewer instance    | 単独 Gate        |
| ----- | ---------------- | -------------------- | ---------------- |
| 1     | {{round_1_date}} | {{round_1_reviewer}} | {{round_1_gate}} |
| 2     | {{round_2_date}} | {{round_2_reviewer}} | {{round_2_gate}} |

最終 Gate: `{{final_gate}}`。Major / Blocker {{open_critical_count}} 件、`accepted-as-is` {{accepted_count}} 件。

<!--
書き方ガイド: share-artifacts/references/review-report.md
状態ラベル詳細・観点別の重点項目は specialist-reviewer/SKILL.md に委譲。
-->
