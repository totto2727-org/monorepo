# Review Report: Holistic

- **Cycle:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** holistic (Intent / Design / QA / Task / Implementation / Review / Validation / Retrospective の連鎖整合性)
- **First reviewed:** 2026-05-01
- **Last updated:** 2026-05-03
- **Final Gate:** `approved`
- **Round count:** 2

## 指摘一覧

| ID  | 深刻度 | 指摘内容                                                                                                                                                                                                                 | 状態             | 検出 Round                     | 解消 commit     | Notes                                                                                                                                                                    |
| --- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------- | ------------------------------ | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| M-1 | Major  | path 置換のスコープ過小: design.md L313-330 と T8/T9/T10 が 3 ファイル限定で、実装後に 29 ファイル / 33 箇所の `docs/dev-workflow/` 表記が残存 (Intent Spec L23 「path 表記は全てリネーム後の新パスを前提とする」に違反) | `fixed`          | 1                              | `37eb0d3` (T13) | T13 後発追加で全 29 ファイル一括 sed 置換、Validation で 0 件確認済                                                                                                      |
| M-2 | Major  | TC-029 / TC-030 の `ggrep` 行内マッチ判定が specialist-common/SKILL.md の YAML 多行 description で fail する観測手段不整合                                                                                               | `accepted-as-is` | 1                              | -               | qa-design.md は immutable 原則で修正せず、Step 8 Validator が代替コマンド (`gawk \| gtr ',' '\n' \| ggrep -oE \| gsort -u \| gwc -l = 12`) で実測、SC-13 を実体的に PASS |
| M-3 | Major  | TC-017 / TC-026 / TC-028 の `git diff --find-renames` 単一パス指定では rename detection が機能せず誤陽性                                                                                                                 | `accepted-as-is` | 1                              | -               | Step 8 Validator が代替コマンド (`--find-renames -M50% docs/workflow/<cycle>/ docs/dev-workflow/<cycle>/` で双方 pathspec 指定) で実測、SC-12 を実体的に PASS            |
| m-4 | Minor  | `design.md` L317「ステップ 4 と 5 の間」と実装 `dev-workflow/SKILL.md` L558「ステップ 5 として上書き」のラベル方式が枝番 (`4'`) vs 連番 (`5`) で乖離                                                                     | `fixed`          | 1 (Round 2 残課題として再検出) | `6077c3f`       | リスト番号 5 のみで参照に統一、自己ラベル `4'` を撤去                                                                                                                    |
| m-5 | Minor  | `design.md` L518-520 で旧 Step 番号への参照表現が混在 (履歴的説明として意図的)                                                                                                                                           | `accepted-as-is` | 1                              | -               | 履歴的説明として意図的、Round 1 で許容判定                                                                                                                               |
| m-6 | Minor  | `qa-design.md` TC-005 と SC-2 の文言乖離が補注で補強されているが、Intent Spec L108 の本文 (「2 個」) は未改訂                                                                                                            | `fixed`          | 1 (Round 2 で再検出)           | `6077c3f`       | intent-spec.md SC-2/3/4/5 を実体に整合 (Specialist 3 / agent 3 / template 4)                                                                                             |
| m-7 | Minor  | `progress.yaml` が `current_step: 'Step 7: External Review'` のままで Step 7 完了反映が pending                                                                                                                          | `obsolete`       | 1                              | -               | Step 8 進行で `current_step` 更新済 (Step 7 完了処理時に自然解消)                                                                                                        |
| i-1 | Info   | SC ↔ TC の偏り (一部 SC に対して TC が 1 件のみで脆弱)                                                                                                                                                                   | `accepted-as-is` | 1                              | -               | 本サイクルではドキュメント生成のため十分、Retrospective 繰越                                                                                                             |
| i-2 | Info   | companion ブランチ並行進行リスク (本サイクル中に 4 サイクルが merge されたことで前提崩壊が発生)                                                                                                                          | `accepted-as-is` | 1                              | -               | Retrospective に教訓として反映済                                                                                                                                         |
| m-8 | Minor  | Round 2 取り残し: `retrospective.md` L60/L107 で廃止済 `validation-evidence/` 参照が陳腐化                                                                                                                               | `fixed`          | 2                              | `6077c3f`       | retrospective.md の該当箇所を「validation-report.md インライン記録」記述に更新                                                                                           |
| m-9 | Minor  | Round 2 取り残し: `intent-spec.md` / `design.md` / `qa-design.md` の `metadata: {author, version}` 旧仕様記述残存 (実装は metadata 全削除済)                                                                             | `fixed`          | 2                              | `7357933`       | サイクル成果物側を `metadata: {author}` に更新 → ユーザー指示で `metadata` 全削除統一に追従                                                                              |

## SC ↔ TC ↔ 実装の整合性 (最終状態)

| SC    | TC (代表)             | 実装ファイル                                                                 | 整合性                                                        |
| ----- | --------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------- |
| SC-1  | TC-001 〜 003         | `dev-roadmap/SKILL.md`                                                       | ✅                                                            |
| SC-2  | TC-004, 005, 006      | `specialist-roadmap-{analyst,planner,retrospective-writer}/SKILL.md` (3 個)  | ✅ (Round 2 で intent-spec 文言 2→3 に整合)                   |
| SC-3  | TC-007, 008           | `agents/roadmap-{analyst,planner,retrospective-writer}.md` (3 個)            | ✅ (Round 2 で intent-spec 文言 2→3 に整合)                   |
| SC-4  | TC-009, 010, 011      | templates/references 4 セット                                                | ✅ (Round 2 で intent-spec 文言 3→4 に整合)                   |
| SC-5  | TC-012, 013           | `shared-artifacts/SKILL.md` テーブル + 例外 3 件                             | ✅                                                            |
| SC-6  | TC-014, 015, 016, 017 | `templates/progress.yaml` + `references/progress-yaml.md`                    | ✅                                                            |
| SC-7  | TC-018, 021           | `dev-workflow/SKILL.md` 「ワークフロー開始時」追記                           | ✅                                                            |
| SC-8  | TC-019, 020, 021      | `dev-workflow/SKILL.md` 「`roadmap-progress.yaml` 更新プロトコル」セクション | ✅                                                            |
| SC-9  | TC-022                | `README.md` 英語段落                                                         | ✅ (Round 2 で完全英語化、TC-022 grep キーワードも英語に切替) |
| SC-10 | TC-023, 024           | `references/roadmap-progress-yaml.md` 必須セクション                         | ✅                                                            |
| SC-11 | TC-025                | `references/roadmap.md` 説明性セクション                                     | ✅ (Round 2 で SC-11 言及削除し汎用化、内容は維持)            |
| SC-12 | TC-017, 026, 027, 028 | git diff baseline `8444fb4`                                                  | ✅ (Validator 代替コマンドで PASS)                            |
| SC-13 | TC-029, 030           | `specialist-common/SKILL.md` Specialist 列挙                                 | ✅ (Validator 代替コマンドで 12 specialists 確認)             |
| SC-14 | TC-031, 032, 033      | `dev-roadmap/SKILL.md` + `shared-artifacts/SKILL.md` 保存構造                | ✅                                                            |

## Round 履歴メタ

| Round | 実行日     | reviewer instance (簡易)            | 単独 Gate                                                   |
| ----- | ---------- | ----------------------------------- | ----------------------------------------------------------- |
| 1     | 2026-05-01 | reviewer (holistic, initial)        | `needs_fix` (Major 3 件)                                    |
| 2     | 2026-05-03 | reviewer (holistic, post-Minor-fix) | `approved` (Major 0、Minor 2 件は `fixed` (Round 3 で対応)) |

最終 Gate: `approved`。Major / Blocker 0 件、`accepted-as-is` 4 件 (M-2, M-3, m-5, i-1, i-2 のうち 4 件はいずれも実体 PASS / 履歴的記述 / Retrospective 繰越合意)。
