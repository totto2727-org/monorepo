# Review Report: holistic (Round 2)

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** holistic
- **Reviewer:** reviewer-holistic-round2
- **Reviewed at:** 2026-05-03T12:30:00Z
- **Scope:** Round 2 修正コミット 2 件 (`648e233` Step 7 Minor findings 解消、`6eae32b` validation-evidence インライン化 + commit example 修正 + Round 2 rollback 記録) によりサイクル全体 (Intent ↔ Design ↔ QA ↔ Implementation ↔ Review ↔ Validation ↔ Retrospective) の整合性が維持されているか、および Round 1 の Minor / Info 級指摘 (主に design-implementation 番号付け乖離、Intent Spec L108 数値、metadata.version、ASCII 図) が解消されたかの再検証。観点別 (security / performance / readability / test-quality / api-design / consistency / documentation-quality / backward-compatibility) の深掘りは別 reviewer の Round 1 レポートで既出のため対象外、ただし retrospective との連鎖陳腐化のみ holistic の責務として確認。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 0    |
| Minor   | 3    |
| Info    | 2    |

**Gate 判定:** `approved` (Blocker 0 件で Step 7 Round 2 進行可。Minor 3 件はいずれも retrospective 繰越または将来サイクルでの一括クリーンアップ候補で本サイクル進行を阻害しない)

## Round 1 指摘の解消状況サマリ

Round 1 holistic で挙げた Major 3 件 / Minor 4 件 / Info 2 件、および他観点 reviewer (consistency / documentation-quality / backward-compatibility) との連鎖を含めて再評価。

| Round 1 指摘 (出典)                                                                  | Round 2 状況             | 根拠                                                                                                                                                                                                 |
| ------------------------------------------------------------------------------------ | ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Major-1**: path 置換スコープ過小 (29 ファイル / 33 箇所残存)                       | 解消済                   | T13 (commit `37eb0d3`) で 32 箇所 / 29 ファイル一括置換。実測 `ggrep -rn "docs/dev-workflow" plugins/dev-workflow/` で本サイクル成果物外を含めて 0 件 (Round 1 backward-compatibility Major-1 同根)  |
| **Major-2**: TC-029 / TC-030 が `ggrep` 行内マッチで fail                            | 解消済                   | Step 8 Validator が代替判定 (gawk + tr + ggrep -oE + gsort -u + gwc -l = 12) で PASS (validation-report.md L213-226 / L335-354)                                                                      |
| **Major-3**: TC-017 / TC-026-028 が rename detection を機能させられない              | 解消済                   | Step 8 Validator が `--find-renames -M50% docs/workflow/<cycle>/ docs/dev-workflow/<cycle>/` の双方 pathspec 指定で `0 insertions / 0 deletions` 観測 (validation-report.md L194-211 / L316-333)     |
| **Minor-4 (≒ Round 1 holistic Minor-4)**: design L317 ↔ 実装 L558 の挿入位置記述ズレ | 部分解消                 | design.md L245 が「ステップ 4 直後 (= 新ステップ 4'として挿入)、既存ステップ 5 の前」「実装は L558 で確定済」と詳細化。後述 #1 (Minor) で残り齟齬を指摘                                              |
| **Minor-5**: design.md L518-522 履歴的説明                                           | 未対応 (許容)            | retrospective 繰越方針のまま。Round 2 では触らず                                                                                                                                                     |
| **Minor-6**: Intent Spec L108 SC-2 「2 個」                                          | 解消済                   | commit `648e233` で SC-2/3/4/5 文言更新 (intent-spec.md L108-111 が 3 個 / 3 個 / 4 個 / 4 行に直接更新済、qa-design.md 補注に頼らず Intent Spec 本文で整合)                                         |
| **Minor-7**: progress.yaml.review が空配列                                           | 部分解消                 | progress.yaml L87-91 で Round 1 の review 4 ファイル列挙済、ただし Round 2 holistic を含めた追加更新は本レビュー後に Main 側で反映する想定 (specialist は commit しない原則)                         |
| **Info-1**: SC ↔ TC 件数偏り                                                         | 未対応 (許容)            | retrospective 繰越方針のまま                                                                                                                                                                         |
| **Info-2**: 複数 companion 並行進行のリスク                                          | 未対応 (許容)            | retrospective 繰越方針のまま                                                                                                                                                                         |
| **(他観点) consistency Major-1 / documentation-quality Major-1**: 旧 10 ステップ番号 | 解消済                   | T14 (commit `aa14c1e`) で `specialist-roadmap-retrospective-writer/SKILL.md` を Step 7/8/9 に置換、本サイクル外参照は historical 表記として残置                                                      |
| **(他観点) consistency Minor**: dev-roadmap/SKILL.md の `metadata.version` 欠落      | Round 2 の方針転換で消化 | commit `648e233` で全 SKILL.md から `version:` を削除し統一。frontmatter スキーマ齟齬は無くなったが、Intent Spec L128 / design.md L18 / qa-design.md TC-002 の規範記述は更新されず → 後述 #2 (Minor) |
| **(他観点) documentation-quality Minor**: dev-roadmap/SKILL.md の ASCII art          | 解消済                   | commit `648e233` で L86-100 (ワークフロー全体図) と L274-291 (双方向参照図) を Mermaid `graph LR` に変換                                                                                             |
| **(他観点) documentation-quality Minor**: shared-artifacts テーブル `#` 列が `-`     | 解消済                   | commit `648e233` で 13-16 連番に更新 (shared-artifacts/SKILL.md L56-59)                                                                                                                              |

**Round 2 修正によって解消された Round 1 指摘**: Major 3 件 / Minor 2 件 (Intent Spec 数値・ASCII art・テーブル番号・metadata.version の方針確定)
**残存指摘 (新規含む)**: Minor 3 件 (後述 #1〜#3) + Info 2 件 (後述 Info)

## チェックリスト 6 項目の判定サマリ

Main 側依頼の Round 2 確認観点に対する判定。

| #   | チェック項目                                                                                                           | 判定        | 関連 Finding |
| --- | ---------------------------------------------------------------------------------------------------------------------- | ----------- | ------------ |
| 1   | Intent Spec ↔ 実装 (SC-2/3/4/5 文言更新で整合)                                                                         | PASS        | —            |
| 2   | Design ↔ 実装 (design.md L317 修正で実装と整合)                                                                        | 部分的 PASS | Minor #1     |
| 3   | 9 ステップ体系の維持 (Round 2 修正で前提崩れていない)                                                                  | PASS        | —            |
| 4   | append-only スキーマ整合 (`complete milestone` 文言と `roadmap-progress.yaml.workflow_identifiers[]` append-only 性質) | PASS        | —            |
| 5   | Validation 結果の妥当性 (validation-evidence インライン化後も各 SC 判定が観測可能・再現可能)                           | 部分的 PASS | Minor #3     |
| 6   | Retrospective との整合 (retrospective.md が Round 2 修正で陳腐化していない)                                            | 部分的 PASS | Minor #2     |

## 指摘事項

### #1 (Minor) design.md L245 ↔ 実装 L555-558 のステップ番号付け方針が依然として完全一致しない

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `648e233` (design.md 改訂) / `6b6206b` 起点の T9 実装
  - File:
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/design.md` L245
    - `plugins/dev-workflow/skills/dev-workflow/SKILL.md` L555-558
  - Line: design.md L245「実装後の構造は『ステップ 4 → ステップ 4' (新規) → ステップ 5』となる (実装は dev-workflow/SKILL.md L558 で確定済)」 / 実装 L555-558 では新規ブロックを「5.」と番号付けし「Step 1 から着手」が「6.」に押し下げられている
- **問題の要約:** Round 2 の commit `648e233` で design.md L245 の挿入位置記述を「ステップ 4 直後 (= 新ステップ 4'として挿入)、既存ステップ 5 (Step 1 着手) の前。実装後の構造は『ステップ 4 → ステップ 4' (新規) → ステップ 5』となる」と明確化したが、実装側は新規ブロックを「**5.** roadmap 配下サイクルの場合の追加初期化 (ステップ 4')」とし「Step 1 から着手」を「**6.**」に押し下げている。design 側の「ステップ 4' → ステップ 5 (Step 1 着手)」という枝番方式と、実装側の「ステップ 5 (新規=4') → ステップ 6 (Step 1 着手)」という連番繰り上げ方式が依然として乖離。design 側で「実装は L558 で確定済」と書かれており設計を実装に追従させた形跡があるが、ラベル方式は揃っていない。Round 1 holistic Minor-4 で同根の指摘あり。
- **根拠:**
  - 実測 `ggrep -nE "^[0-9]+\." plugins/dev-workflow/skills/dev-workflow/SKILL.md | gsed -n '/ワークフロー開始時/,/^### 2/p'` 相当の構造観察: 実装は連番 (1〜6) で「Step 1 から着手」が 6 番目
  - design.md L245 「実装後の構造は『ステップ 4 → ステップ 4' (新規、roadmap 配下サイクルでのみ実行) → ステップ 5』となる」 ← 実装と異なる
  - 機能的には等価で TC-018 (`ggrep -nE "ワークフロー開始時"` 配下に roadmap ブロック初期化記述) は引き続き PASS
- **推奨アクション:** Retrospective 繰越。本サイクルでの修正は不要。次回類似の挿入時に「枝番 (4') 維持か連番繰り上げか」を design 段階で明示する運用ルールを retrospective の改善案に追記するのが望ましい。実装側を 4' 表記に揃える代替案 (= 「5.」を「4'.」へ単純改名し 6→5 へ繰り戻す) は Mermaid フローや TC への影響皆無で安全だが、機械的整合のみのため Round 2 での緊急性はない。
- **設計との関連:** design.md L245 (Round 2 修正後) / 実装 L555-558 / Round 1 holistic Minor-4

### #2 (Minor) retrospective.md の 2 箇所で廃止済み `validation-evidence/` を補助スクリプトとして言及している (陳腐化)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `2cf1037` (retrospective 完成時点) / Round 2 で `6eae32b` により廃止済だが retrospective は未追従
  - File: `docs/retrospective/2026-04-29-add-dev-roadmap-skill.md`
  - Line:
    - L60 「validation-evidence/ の補助スクリプトで観測手段を補正」
    - L107 「(TC-029 / TC-028 の観測手段補正を validation-evidence/ で適切にカバー)」
- **問題の要約:** Round 2 で `validation-evidence/` ディレクトリを廃止しログを `validation-report.md` 内にインライン化した (commit `6eae32b`、progress.yaml.rollbacks[2].reason の M-8) が、retrospective.md の「課題 2: TC 観測手段の不整合」L60 と「次回への提案 → validator」L107 で `validation-evidence/` が依然として「補助スクリプトでカバー」「補助スクリプトで補正」と記述されており、実体とのズレが生じている。読者は retrospective 経由で「validation-evidence/ ディレクトリが存在する」と誤認しうる。
- **根拠:**
  - 実測: `find docs/workflow/2026-04-29-add-dev-roadmap-skill -name "validation-evidence" -type d` → 0 件 (廃止確認)
  - retrospective.md L60 / L107 の文字列 (上記引用)
  - validation-report.md L312-385 で全証拠ログがインライン化済み
- **推奨アクション:** Retrospective 繰越（または retrospective.md を文字列置換で補正）。具体には L60 を「validation-report.md 内のインライン検証ログで観測手段を補正」、L107 を「TC-029 / TC-028 の観測手段補正を validation-report.md インライン化で適切にカバー」に置換する小修正で解消可能。Specialist は commit しない原則のため、Main が retrospective-writer を再起動するか直接修正するかを判断。修正コストは S 規模 (2 行)。
- **設計との関連:** Round 2 progress.yaml.rollbacks[2] M-8 (validation-evidence 廃止 + インライン化) / retrospective.md の Round 2 修正未追従

### #3 (Minor) Intent Spec L128 / design.md L18 / qa-design.md TC-002 が `metadata: { author, version }` をスキーマ規範として残しているが実装は `version` を削除済 (規範文書と実装の乖離)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `648e233` (実装側で全 SKILL.md から `version:` 削除、本サイクル新規 3 specialist + dev-roadmap + 既存 dev-workflow ほか合計 13 ファイル)
  - File:
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md` L128
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/design.md` L18
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/qa-design.md` TC-002 (L101)
  - Line:
    - intent-spec.md L128 「スキル frontmatter のスキーマは既存 `dev-workflow` 系スキルと同一 (name / description / metadata: { author, version })」
    - design.md L18 「スキル frontmatter スキーマは既存 `dev-workflow` 系と同一 (`name` / `description` / `metadata: {author, version}`)」
    - qa-design.md TC-002 「必要な frontmatter キーを保持する (name / description / metadata.author / metadata.version)」
- **問題の要約:** Round 2 で `metadata.version` を全削除する方針 (progress.yaml.rollbacks[2] M-1) は実装に反映されたが、Intent Spec / design / qa-design の規範文書側はいずれも「`metadata: { author, version }`」のままで、規範と実装の乖離が生じた。Step 8 Validation の TC-002 (qa-design 上の判定基準) は本来「`metadata.version` を含む 4 キー」を要求するが、実装にそのキーが存在しないため厳密適用すると FAIL になる。validation-report.md L27 では「`metadata:` (L18) の 3 キーを保持 (TC-002)」と判定文言を緩めて PASS としている (= qa-design 文言に対する観測条件の独自緩和)。SC-1 / SC-2 の本文は「frontmatter (`name: dev-roadmap` / description / metadata)」と曖昧表記のため SC レベルでは fail に至らないが、TC レベルでは観測条件が文書化された規範から外れている。
- **根拠:**
  - 実測 `ggrep -n "version: " plugins/dev-workflow/skills/*/SKILL.md` → 0 件 (実装で全削除確認)
  - intent-spec.md L128 / design.md L18 / qa-design.md TC-002 の文字列 (上記引用)
  - validation-report.md L27 「frontmatter: `name: dev-roadmap` (L2)、`description: >` (L3)、`metadata:` (L18) の 3 キーを保持 (TC-002)」 ← `metadata.version` を観測条件から外している
  - progress.yaml.rollbacks[2].reason の M-1 「(M-1) drop metadata.version from all SKILL.md (no longer needed, cleanup)」
- **推奨アクション:** Retrospective 繰越または小規模追従修正のいずれか。
  - (A) **Retrospective 繰越** — 「Round 2 の方針転換 (metadata.version 削除) を Intent Spec / design / qa-design の規範文書に伝播するタイミングを失った。次回 metadata 拡張時に同様の伝播ミスが起きないよう、規範文書 ↔ 実装の整合チェックを task-plan に明示する」と retrospective に追記。本サイクル進行を阻害しない。
  - (B) **規範文書側を Round 2 後方追従修正** — Intent Spec L128 / design.md L18 / qa-design.md TC-002 の `metadata: { author, version }` を `metadata: { author }` に置換。Specialist は commit しない原則のため Main 経由。修正コストは XS 規模 (3 行)。
- **設計との関連:** Round 2 progress.yaml.rollbacks[2] M-1 / 実装 frontmatter スキーマ / SC-1 / SC-2 / TC-002 / Round 1 consistency Minor (dev-roadmap version 欠落指摘)

## 観点固有の評価項目

### Round 2 修正 ↔ サイクル全体整合性チェック (本レビューの中核)

- **Intent Spec ↔ 実装整合性 (チェック 1):** PASS。Round 2 commit `648e233` で SC-2 (3 個) / SC-3 (3 個) / SC-4 (4 個) / SC-5 (4 行) が実体と完全整合 (intent-spec.md L108-111)。Round 1 で qa-design 補注に頼っていた数値乖離が Intent Spec 本文で直接解決された (Round 1 holistic Minor-6 解消)。SC-1 / SC-7 / SC-8 / SC-9 / SC-10 / SC-13 / SC-14 については Round 2 修正の影響が及ばず Round 1 から PASS のまま。
- **Design ↔ 実装整合性 (チェック 2):** 部分的 PASS。Round 2 で design.md L245 が「実装は L558 で確定済」と詳細化され、設計記述は実装に追従済 (Round 1 holistic Minor-4 が緩和)。ただし「ステップ 4 → ステップ 4' → ステップ 5」と「実装の連番 5 → 6」のラベル方式の差異は依然として残存 (#1 で指摘)。機能的等価性は維持されているため Major には届かない。
- **9 ステップ体系の維持 (チェック 3):** PASS。Round 2 修正の対象は (a) 文言数値 (b) 図形変換 (c) テーブル番号付け (d) コミットメッセージ例 (e) validation-evidence 廃止 (f) metadata.version 削除のいずれもステップ構造には触れない。実測 `ggrep -rn "self-reviewer\|Self-Review\|Step 8 Self-Review\|Step 10" plugins/dev-workflow/` で本サイクル新規ファイル + 既存 SKILL/dev-workflow にサイクル外参照を除き残存ゼロを Round 1 で確認済、Round 2 修正後も差分なし。
- **append-only スキーマ整合 (チェック 4):** PASS。Round 2 commit `6eae32b` で dev-workflow/SKILL.md L792 のコミットメッセージ例を `unlink milestone <id>` から `complete milestone <id>` に変更し、同行末尾に「`workflow_identifiers[]` は append-only で削除しない (= unlink 操作は存在しない、`complete` は `status: active → completed` 遷移を表す)」と理由を併記。これにより以下が同時整合する:
  - design.md L302 (並行サイクル時の競合回避) 「書き込みは原則 `milestones[].status` のスカラ書き換えと `milestones[].workflow_identifiers[]` への append のみ」
  - design.md L305 (マージ衝突手順) 「③ `workflow_identifiers[]` は両ブランチの追加分を両方残す (set union)」
  - dev-workflow/SKILL.md L797 (並行サイクル時の競合回避) 「append のみとする」
  - templates/roadmap-progress.yaml の `milestones[].workflow_identifiers` 配列フィールド
- **Validation 結果の妥当性 (チェック 5):** 部分的 PASS。Round 2 commit `6eae32b` で `validation-evidence/` 4 ファイル (合計 104 行) を validation-report.md L312-385 にインライン化。各 SC 判定の観測値・証跡が単一ファイルで自己完結し、再現可能性 (検証コマンドの記載) が維持されている (例: TC-015 は L370-381 で `uvx --from pyyaml python3 -c ...` まで明示)。シンプル化として妥当。ただし retrospective.md は廃止追従していない (#2 で指摘)。
- **Retrospective との整合 (チェック 6):** 部分的 PASS。retrospective.md は Round 1 完了時点 (2026-05-01T11:00:00Z) で凍結されており、Round 2 修正 (M-1〜M-8) は反映されていない。陳腐化の主たる箇所は L60 と L107 (validation-evidence/ への参照、#2 で詳述)。良かった点・課題セクションの構造は Round 2 修正でも本質的に陳腐化しない (Round 2 修正は「Round 1 残課題の整理」であり、retrospective が記録する「サイクル全体の振り返り」観点は Round 2 後も妥当)。

### 観測コマンド (再現性)

```bash
# 本レビューで実行した主要観測コマンド (Specialist は commit しないため記録のみ)
git -C <repo> log --oneline 5fda5a5..HEAD
git -C <repo> show --stat 648e233 6eae32b
git -C <repo> show 648e233 -- plugins/dev-workflow/skills/dev-roadmap/SKILL.md
git -C <repo> show 6eae32b -- plugins/dev-workflow/skills/dev-workflow/SKILL.md
ggrep -rn "docs/dev-workflow" plugins/dev-workflow/
ggrep -n "version: " plugins/dev-workflow/skills/*/SKILL.md
ggrep -n "validation-evidence\|metadata.*version" docs/retrospective/2026-04-29-add-dev-roadmap-skill.md docs/workflow/2026-04-29-add-dev-roadmap-skill/{intent-spec,design,qa-design}.md
find docs/workflow/2026-04-29-add-dev-roadmap-skill -name "validation-evidence" -type d
```

## 修正ラウンド履歴

| Round | Blocker | Major | Minor | 主要指摘 (要約)                                                                                                                                                                                   | 修正コミット SHA                                                   |
| ----- | ------- | ----- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 1     | 0       | 3     | 4     | path 置換スコープ過小 (Major-1) / TC-029-030 観測手段不整合 (Major-2) / SC-12 観測手段不整合 (Major-3) / 番号付け乖離 (Minor-4) / SC-2 数値 (Minor-6) ほか                                        | `37eb0d3` `aa14c1e` `551e497` (Round 1 ↔ Round 2 間の Major fixes) |
| 2     | 0       | 0     | 3     | design L245 ↔ 実装 L558 番号方式の枝番 vs 連番乖離 (Minor #1) / retrospective.md の validation-evidence 参照陳腐化 (Minor #2) / Intent/design/qa-design 規範の `metadata.version` 残存 (Minor #3) | (Round 2 検出のみ、修正未着手)                                     |

Round 2 で Major 0 件 / Blocker 0 件のため Round 3 不要。Minor 3 件はすべて retrospective 繰越または小規模文言修正で消化可能で、本サイクル進行を阻害しない。

## 他レビューとの整合性

- **Round 1 holistic との整合**: 本レポートは Round 1 holistic (`docs/workflow/2026-04-29-add-dev-roadmap-skill/review/holistic.md`) を起点に、Round 2 修正での変化分のみを評価する形で書いている。Round 1 で観点別 reviewer (consistency / documentation-quality / backward-compatibility) が単独で挙げた指摘も、Round 2 修正で解消されたものは「解消済」、未対応のものは「retrospective 繰越済」として個別に追跡し、Round 1 サマリ表で網羅した。
- **Round 2 では他観点 reviewer は再起動されていない**: ユーザー指示により Round 2 は holistic 単独再レビューのため、他観点との直接的なクロスチェックは行われていない。Round 2 修正対象の Minor 級は本来観点別 reviewer (consistency / documentation-quality) の領域だが、holistic で全体整合の文脈で取り上げて差し支えない (specialist-reviewer SKILL.md L52-53 のループ運用に従い、Round 2 で全観点並列再起動するか単独 holistic で済ますかは Main が判断)。本レビューでは Round 1 で観点別 reviewer が記録した Minor (metadata.version、ASCII art、テーブル番号) のうち Round 2 で解消済の項目を holistic サマリ表で再確認した。
- **Round 1 で他観点が見逃した可能性のある新規指摘**: 本 Round 2 レビューで初めて検出した指摘は #2 (retrospective 陳腐化) と #3 (規範文書 `metadata.version` 残存) の 2 件。両者とも Round 2 修正の副作用として発生した整合不一致であり、Round 1 時点では存在しなかった (= Round 1 reviewer の漏れではない)。

## 補足: Info 級の観察事項 (将来 retrospective 材料)

- **Info-1:** Round 2 修正は「Round 1 後の post-cycle Minor cleanup round」として progress.yaml.rollbacks[2] に新規 rollback (Step 9 → Step 6) として記録されている。これにより本サイクルは「Step 4→1 (Plan D)」「Step 7→6 (Major fixes)」「Step 9→6 (Round 2 Minor cleanup)」の 3 度のロールバックを経験した。9 ステップ体系における「サイクル完了後 (Step 9 完了後) の post-cycle round」運用パターンが本サイクルで確立した形だが、これを通常運用に組み込むか緊急救済に留めるかは将来 retrospective での議題候補。
- **Info-2:** Round 2 で `validation-evidence/` 廃止インライン化 (M-8) が採用されたが、shared-artifacts/references/validation-report.md は「大きな証跡 (必要な場合のみ) 補助ファイルへ」と規定する。本サイクルは小規模 (104 行) なのでインライン化が妥当だが、将来「大規模証跡時はインライン化を避ける」という閾値判断が必要になる。retrospective でガイドラインを足すと再利用性が高まる。
