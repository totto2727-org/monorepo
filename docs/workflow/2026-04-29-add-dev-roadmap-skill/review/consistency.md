# Review Report: Consistency

- **Cycle:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** consistency (既存スキル / agent / shared-artifacts との一貫性)
- **First reviewed:** 2026-05-01
- **Last updated:** 2026-05-03
- **Final Gate:** `approved`
- **Round count:** 2

## 指摘一覧

| ID   | 深刻度 | 指摘内容                                                                                                                                                               | 状態             | 検出 Round | 解消 commit     | Notes                                                                                                                                   |
| ---- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | ---------- | --------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| M-1  | Major  | `specialist-roadmap-retrospective-writer/SKILL.md` L135 に旧 10 ステップ番号 (Step 8 / 9 / 10) が残存し新 9 ステップ体系と不整合                                       | `fixed`          | 1          | `aa14c1e` (T14) | grep 検索で旧表記 0 件確認済                                                                                                            |
| M-2  | Major  | path 表記が新規スキル (`docs/workflow/`) と既存 specialist-\* / agents / shared-artifacts/references で `docs/dev-workflow/` のまま分裂、33 箇所残存                   | `fixed`          | 1          | `37eb0d3` (T13) | 29 ファイル一括 sed 置換、`ggrep -rn "docs/dev-workflow/<" plugins/dev-workflow/` 0 件確認済                                            |
| m-3  | Minor  | `specialist-roadmap-retrospective-writer` の frontmatter に `metadata.version` 欠落、同時新設の他 2 specialist は持つ (ファミリー内不一致)                             | `fixed`          | 1          | `7357933`       | ユーザー指示により方針転換 — 全 SKILL.md で `metadata` 自体を完全削除する形で統一 (`metadata.version` の意味自体が消滅)                 |
| m-4  | Minor  | `dev-roadmap/SKILL.md` L90-99 の「ワークフロー全体図」が ASCII art。後の調査で `dev-workflow/SKILL.md` 自身も ASCII art を採用していることが判明し、整合的だったと判定 | `fixed`          | 1          | `648e233`       | Round 2 で `graph LR` Mermaid に変換、表現の一貫性を向上 (双方向参照図 L274-291 も同時 Mermaid 化)                                      |
| m-5  | Minor  | `specialist-roadmap-*` の本文構造で `## 役割` 直前の 1 行説明文が無く、一部既存 specialist と微妙に異なる                                                              | `accepted-as-is` | 1          | -               | Retrospective 繰越合意 (Round 1 ユーザー判定)。既存 specialist 群でも記述粒度が揃っていない事実があり、本サイクル単独の修正対象としない |
| m-6  | Minor  | `agents/roadmap-*` の "Do NOT use for" 記載粒度が `roadmap-analyst/planner` と `roadmap-retrospective-writer` で分裂                                                   | `accepted-as-is` | 1          | -               | Retrospective 繰越合意 (Round 1 ユーザー判定)。既存 agents 全体の粒度差ともリンクしている課題、別サイクルで横断対応推奨                 |
| i-7  | Info   | `agents/roadmap-*` の参照スキルセクションが既存 `agents/qa-analyst.md` と整合                                                                                          | (整合確認のみ)   | 1          | -               | 指摘なし、確認記録                                                                                                                      |
| i-8  | Info   | 1:1 対応の例外 3 件記述が `shared-artifacts/SKILL.md:24-30` と新規 `references/roadmap-progress-yaml.md:13` の双方で正しく整合                                         | (整合確認のみ)   | 1          | -               | 指摘なし、確認記録                                                                                                                      |
| m-9  | Minor  | `manual-tests/TC-025.md` / `TC-032.md` に廃止済 `validation-evidence/TC-XXX.md` への記述残骸                                                                           | `fixed`          | 2          | `6077c3f`       | validation-evidence ディレクトリ廃止後の chain update 漏れ。記録先を `validation-report.md` インラインに修正                            |
| m-10 | Minor  | `qa-design.md` TC-002 / 概要 SC-2 / SC-3 / SC-4 の数値および metadata.version 言及が古い前提のまま (intent-spec L108 旧「2 個」と整合)                                 | `fixed`          | 2          | `7357933`       | 数値を実体 (Specialist 3 / agent 3 / template 4) に更新 + `metadata.version` 言及削除 (frontmatter 全削除統一に追従)                    |

## 詳細セクション

### M-2 詳細: path 残存問題の波及範囲

T13 修正対象ファイル (29 個):

- `agents/{architect,intent-analyst,planner,qa-analyst,researcher,reviewer,validator}.md`
- `skills/specialist-{architect,implementer,intent-analyst,planner,qa-analyst,researcher,reviewer,validator}/SKILL.md`
- `skills/shared-artifacts/references/{intent-spec,research-note,task-plan,todo,review-report,validation-report,qa-design,design,implementation-log,qa-flow,retrospective,progress-yaml}.md` (12 ファイル)
- `skills/shared-artifacts/templates/{qa-design,validation-report}.md` (2 ファイル)

`ggrep -rl "docs/dev-workflow/<" plugins/dev-workflow/ | xargs gsed -i 's#docs/dev-workflow/<#docs/workflow/<#g'` の機械置換で全件解消。

### m-3 詳細: metadata 削除の根拠

ユーザー指示「`metadata` 自体全て削除で良い (dev-workflow プラグインに関しては)」により、frontmatter 規範を `name` + `description` のみに簡素化。これにより「version 欠落 vs 揃え」議論が消滅 (= ファミリー内不一致の概念自体が解消)。

## Round 履歴メタ

| Round | 実行日     | reviewer instance (簡易)               | 単独 Gate                                  |
| ----- | ---------- | -------------------------------------- | ------------------------------------------ |
| 1     | 2026-05-01 | reviewer (consistency, initial)        | `needs_fix` (Major 2 件)                   |
| 2     | 2026-05-03 | reviewer (consistency, post-Minor-fix) | `approved` (Major 0、Minor 2 件は `fixed`) |

最終 Gate: `approved`。Major / Blocker 0 件、未解消 Minor 2 件 (m-5, m-6) はいずれも `accepted-as-is` (Retrospective 繰越合意)。
