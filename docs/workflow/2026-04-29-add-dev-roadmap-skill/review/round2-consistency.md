# Review Report: consistency (Round 2)

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** consistency
- **Reviewer:** reviewer-consistency-instance-002 (Round 2)
- **Reviewed at:** 2026-05-03T11:30:00Z
- **Scope:** Round 2 修正コミット 2 本 (`648e233` + `6eae32b`) と直前の Round 1 リワーク (`37eb0d3` / `aa14c1e` / `551e497`) を含む、`progress.yaml.rollbacks[1].at` 以降のサイクル全成果物。**観点は consistency に限定** — Round 1 既指摘 8 件 (Major 2 / Minor 4 / Info 2) の解消確認 + Round 2 修正で新規発生した整合性論点。security / performance / readability / test-quality / api-design / documentation-quality / backward-compatibility / holistic は別 reviewer の領域につきスコープ外。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 0    |
| Minor   | 1    |
| Info    | 4    |

**Gate 判定:** approved

Round 1 で指摘した Major 2 件は両方とも解消済 (Round 1.5 = T13/T14/T15 リワーク + Round 2 = `648e233`/`6eae32b` の合計で完全解消)。Round 1 Minor 4 件は 3 件解消、1 件は **存在意義そのものが Round 2 で変質** (Minor #3: `metadata.version` 不揃い → Round 2 で `version` 全削除統一により別の意味で揃った)。Round 2 単独で新規発生した consistency 問題は本サイクルローカル成果物 (qa-design / manual-tests) に限定された残骸が 1 件 (Minor、Round 2 修正の chain effect 漏れ)。Blocker は 0 件であり Step 7 通過可。

## 指摘事項

### #1 (新規) `manual-tests/TC-025.md` / `TC-032.md` の結果記録テンプレートが廃止済 `validation-evidence/` 配下のパスを残骸として参照

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `7e91e6e` (T12 manual-test 追加、Round 1 直前) で導入。Round 2 (`6eae32b`) の `validation-evidence/` 廃止 (M-8) で chain update が漏れた箇所
  - File:
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/manual-tests/TC-025.md:118`
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/manual-tests/TC-032.md:107`
  - Line: 各ファイルの「## 結果記録テンプレート」直下、1 行のみ
- **問題の要約:** 両ファイルの「結果記録テンプレート」見出し直下に「Validator は以下の項目を `validation-report.md` または `validation-evidence/TC-025.md` に記録する」「同 `validation-evidence/TC-032.md`」という記述が残っており、本サイクル Round 2 (M-8、`6eae32b`) で `docs/workflow/2026-04-29-add-dev-roadmap-skill/validation-evidence/` ディレクトリを廃止し全証跡を `validation-report.md` にインライン化した方針と矛盾する。実際の `validation-report.md:312-385` 「## 検証ログ (インライン)」では TC-025 / TC-032 の手動目視結果は本文内に書き出し済 (`validation-report.md:383-385` 「手動目視 (TC-025 / TC-032)」セクション)、補助ファイルは不使用と明記されている。
- **根拠:** 本サイクル内の同一概念 (TC-025/TC-032 結果記録の保管場所) について 2 つの矛盾する記述が併存している。`progress.yaml.rollbacks[1].reason` (M-8) で「`validation-evidence/` ディレクトリ廃止」を確定済、`validation-report.md:312-314` で「補助ディレクトリ … は廃止」と宣言済。一方 `manual-tests/TC-025.md:118` / `TC-032.md:107` は廃止前の前提で `validation-evidence/TC-025.md` / `validation-evidence/TC-032.md` を提示し続けている。本サイクル**外**の汎用仕様 (`shared-artifacts/SKILL.md:137` / `shared-artifacts/references/validation-report.md:17,44,68,75` / `shared-artifacts/templates/validation-report.md:54,86-89` / `dev-workflow/SKILL.md:134,496,502,711` / `specialist-validator/SKILL.md:70,78`) は「大きな証跡 (必要な場合のみ)」として `validation-evidence/` を引き続き規定しているため、これらは矛盾の対象外 (`shared-artifacts` 側は「必要な場合のみ」許容、本サイクルは「不要だった」という整合的な解釈)。問題は本サイクルローカル成果物内の整合性のみ。
- **推奨アクション:** Retrospective 繰越案件として記録、または極小フォローアップコミットで以下に置換:
  - TC-025.md L118: 「Validator は以下の項目を `validation-report.md` または `validation-evidence/TC-025.md` に記録する」 → 「Validator は以下の項目を `validation-report.md` 内の §「検証ログ (インライン)」または同 §「成功基準ごとの判定」セクションに記録する (本サイクルでは `validation-evidence/` ディレクトリを使用しない)」
  - TC-032.md L107: 同様の置換
    1 ファイル 1 行差分 × 2 ファイルで完結する機械的修正。Step 7 進行 (Blocker 0) を阻害しないため、ユーザー判断で「フォローアップ修正」「Retrospective 繰越」「現状維持 (汎用仕様との整合解釈で吸収)」のいずれかを選択。
- **設計との関連:** `progress.yaml.rollbacks[1].reason` M-8、`validation-report.md:312-314` (検証ログ (インライン) セクションの導入宣言)、`shared-artifacts/SKILL.md:137` (汎用仕様の `validation-evidence/` は維持)。

---

### #2 (Info / 解消確認) Round 1 Major #1 (旧 10 ステップ番号残存) 完全解消

- **深刻度:** Info
- **該当箇所:**
  - Commit: `aa14c1e` (Round 1.5 T14、Round 2 入りの直前で先行解消)
  - File: `plugins/dev-workflow/skills/specialist-roadmap-retrospective-writer/SKILL.md:135` (Round 1 指摘当時)
- **問題の要約:** Round 1 #1 で指摘した「旧 Step 8 / 9 / 10」の表記は `aa14c1e` で「新 Step 7 / 8 / 9」に修正済。`grep -nE 'Step (8 External Review|9 Validation|10 Retrospective)' plugins/dev-workflow/` の実測結果は **0 件**で残存ゼロを確認。Round 2 で同種の混入は新規発生していない。
- **根拠:** `intent-spec.md:134` 規範的制約「workflow は main マージ後の 9 ステップ体系」と完全整合。
- **推奨アクション:** 修正不要。Round 1 Major #1 は **完全解消** として記録。
- **設計との関連:** `design.md` §「main マージによる前提崩壊への追従」#1 (L25-28)。

---

### #3 (Info / 解消確認) Round 1 Major #2 (`docs/dev-workflow/` 旧パス 33 箇所残存) 完全解消

- **深刻度:** Info
- **該当箇所:**
  - Commit: `37eb0d3` (Round 1.5 T13、Round 2 入りの直前で先行解消)
  - File: 旧 33 箇所
- **問題の要約:** Round 1 #2 で指摘した 33 箇所の旧 `docs/dev-workflow/<identifier>/` 表記は `37eb0d3` で全件機械置換済 (新 `docs/workflow/<identifier>/`)。`grep -rn 'docs/dev-workflow/' plugins/dev-workflow/` の実測結果は **0 件**。Round 2 で同種の混入は新規発生していない。`docs(dev-workflow/<identifier>): ...` のコミットスコープ表記は path とは別概念として `dev-workflow/SKILL.md:792` 等で明示的に維持される方針 (Round 1 で確認済) と整合。
- **根拠:** `intent-spec.md:23,75` の path 統一方針と完全整合。
- **推奨アクション:** 修正不要。Round 1 Major #2 は **完全解消** として記録。
- **設計との関連:** `design.md` §「保存先ディレクトリのリネーム」(L28)、`intent-spec.md` §「スコープ → 保存先ディレクトリ」(L68-76)。

---

### #4 (Info / 状態変化記録) Round 1 Minor #3 (`specialist-roadmap-retrospective-writer` の `metadata.version` 欠落) は **Round 2 の `version` 全削除統一** により解消方向が転換

- **深刻度:** Info
- **該当箇所:**
  - Commit: `648e233` (Round 2、M-1 fix)
  - File: 全 SKILL.md (`dev-workflow` / `dev-roadmap` / `specialist-architect` / `specialist-common` / `specialist-intent-analyst` / `specialist-planner` / `specialist-qa-analyst` / `specialist-researcher` / `specialist-reviewer` / `specialist-roadmap-analyst` / `specialist-roadmap-planner` の 11 ファイル)
- **問題の要約:** Round 1 #3 で指摘した「`specialist-roadmap-retrospective-writer` のみ `metadata.version` 欠落、他 2 specialist は持つ」というファミリー内分裂は、Round 2 で**逆方向の統一** (`metadata.version` を全 SKILL.md から削除) により解消された。実測: `grep -rn 'version: ' plugins/dev-workflow/skills/*/SKILL.md` の結果 0 件、`grep -rn 'metadata:' plugins/dev-workflow/skills/*/SKILL.md` で 15 ファイル全てが `metadata: { author: totto2727 }` の単一フィールド構成で揃う。`intent-spec.md:128` の「frontmatter スキーマは既存 dev-workflow 系スキルと同一」という制約は、`metadata.version` を含めるか含めないかという揺れの両端のうち**含めない**側で全 SKILL.md が揃う方向に統一されたため整合的。
- **根拠:** Round 1 時点では「3 specialist のうち retrospective-writer だけ `version` 欠落」で揃っていなかったが、Round 2 で「全 SKILL.md から `version` 削除」で統一されたため、新しい統一基準では揃っている。`progress.yaml.rollbacks[1].reason` M-1「drop metadata.version from all SKILL.md (no longer needed, cleanup)」と整合。
- **推奨アクション:** 修正不要。Round 1 Minor #3 は **方向転換による解消** として記録。
- **設計との関連:** `intent-spec.md:128` 規範的制約 (frontmatter スキーマ既存と同一)。

---

### #5 (Info / 解消確認) Round 1 Minor #4 (dev-roadmap/SKILL.md L89-100 ASCII art) 完全解消

- **深刻度:** Info
- **該当箇所:**
  - Commit: `648e233` (Round 2、M-6 fix)
  - File:
    - `plugins/dev-workflow/skills/dev-roadmap/SKILL.md:88-102` (ワークフロー全体図、Round 1 指摘箇所)
    - `plugins/dev-workflow/skills/dev-roadmap/SKILL.md:276-289` (双方向参照図、Round 2 で同時に Mermaid 化)
- **問題の要約:** Round 1 #4 で指摘した ASCII art (`────┐` / `─────┤◄───`) ワークフロー全体図は `648e233` で Mermaid `graph LR` に変換済。同時に L274-291 の双方向参照図 (Round 1 では指摘外) も同コミットで Mermaid 化されており、`design.md` 確定 4「Mermaid `graph LR` で統一」と完全整合。実測: roadmap 関連ファイル全体に罫線文字 (`─` `┌` `│` `└` `►` `◄`) は **0 件**残存、`flowchart LR` は本サイクル全体で **0 件** (`graph LR` のみ使用)。HTML エンティティのエスケープ (`&lt;` `&gt;` `&#91;` `&#93;`) は L276-289 と L355-394 の双方向参照図 / ディレクトリレイアウト図でプレースホルダ含有時のみ整合的に使用。
- **根拠:** `design.md` 確定 4 (L357-358)。
- **推奨アクション:** 修正不要。Round 1 Minor #4 は **完全解消** として記録。
- **設計との関連:** `design.md` 確定 4 (Mermaid 記法統一)。

---

### #6 (Info / 状態継続記録) Round 1 Minor #5 / #6 (specialist-roadmap-\* 概要表のライフサイクル行有無 / agents の Do NOT use for 有無のファミリー内分裂) は Round 2 で未対応 (= 当初判断通り Retrospective 繰越案件)

- **深刻度:** Info
- **該当箇所:**
  - File: `plugins/dev-workflow/skills/specialist-roadmap-{analyst,planner,retrospective-writer}/SKILL.md` ヘッダ部、および `plugins/dev-workflow/agents/roadmap-{analyst,planner,retrospective-writer}.md` frontmatter
- **問題の要約:** Round 1 で「Retrospective 繰越案件」と判定した Minor #5 (specialist-roadmap-\* の概要表「ライフサイクル」行の有無、3 specialist 横並びの一覧性微差) および Minor #6 (agents の Do NOT use for 有無のファミリー内分裂) は Round 2 修正対象に含まれず、Round 1 判定通り**現状維持**となった。これは Round 1 時点で「既存パターン側の揺れを踏襲した結果」「ルール化は本サイクル外」と判断済の内容と整合しており、新規問題ではない。
- **根拠:** `progress.yaml.rollbacks[1].reason` (Round 2 の修正対象 M-1〜M-8) に Minor #5 / #6 は含まれていない。Round 1 推奨アクションが「Retrospective 繰越」だったため、当該判断が維持されている形。
- **推奨アクション:** 修正不要 (Round 1 判定継続)。Retrospective 繰越案件として `docs/retrospective/2026-04-29-add-dev-roadmap-skill.md` 等に既に転記されているか確認 (Step 9 retrospective.md の更新は Round 2 での再生成は行わない方針と思われる、Main 判断)。
- **設計との関連:** `design.md` §「コンポーネント構成」(L72-94) は agents 構造の詳細仕様を定めていないため明示ルールなし。

---

### #7 (Minor、新規) qa-design.md の SC-2 / SC-3 / SC-4 補足記述が「intent-spec.md L108 の『2 個』」を引用しているが Round 2 修正で intent-spec から「2 個」表記が削除済

- **深刻度:** Minor (Info に近いが、文書間参照の整合性が崩れているため Minor 扱い)
- **該当箇所:**
  - Commit: Round 2 `648e233` の M-2 (intent-spec SC-2/3/4/5 を「2 個」→「3 個」/「3 個」→「4 個」に更新) で chain effect 漏れ
  - File:
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/qa-design.md:21` (SC-2 補足)
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/qa-design.md:22` (SC-3 補足)
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/qa-design.md:23` (SC-4 補足)
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/qa-design.md:108` (TC-009 備考: 「intent-spec.md SC-4 の『3 個』は暫定」)
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/qa-design.md:157,158` (SC↔TC マッピング表の備考列)
- **問題の要約:** qa-design.md L21 は「intent-spec.md L108 の『2 個』は流用前提の暫定値で、design.md 確定 1 (L75) により案 C を採用」と記述しているが、Round 2 (`648e233` M-2) で intent-spec.md L108 は「**新規 Specialist スキル 3 個の存在**」に既に書き換え済であり、「2 個」表記は intent-spec から消えている。同様に L22 / L23 / L108 / L157 / L158 も「intent-spec の『2 個』は…3 個に拡張」「intent-spec.md SC-4 の『3 個』は暫定」など、現時点の intent-spec.md の文言と一致しない過去形の引用が残存している。読み手が qa-design.md の補足コメントを頼りに intent-spec.md L108 を引いても、当該箇所には既に「3 個」と書かれており、補足コメントが指す「暫定値」は実物では存在しない。
- **根拠:** Round 2 修正の M-2 chain effect として qa-design.md の更新も伴うべきだったが、`progress.yaml.rollbacks[1].reason` の M-2 では「intent-spec SC-2/3/4/5 文言更新 (Specialist/agent 数 2→3、template 数 3→4)」のみ言及されており、qa-design.md 側の参照記述更新は対象に含まれていなかった。Step 4 成果物 (qa-design) は本来「Step 4 確定時点での intent-spec を引用する歴史的記録」としての性格もあるが、ここでの引用は「intent-spec L108 の現状を解説する」trailing コメント (= 現在形の文書間参照) として書かれているため、整合性違反とみなせる。Major には届かないのは、qa-design.md L21〜L23 の本文 (= 「本サイクル実装は **3 個**」「**4 対**」) は新パターンと整合しており、運用上の数値判断は破綻していないため。
- **推奨アクション:** ユーザー判断ポイントとして以下 3 案を提示:
  - **案 A (推奨、極小フォローアップ):** qa-design.md L21 / L22 / L23 / L108 / L157 / L158 の補足コメントを以下のように書き換える:
    - L21: 「design.md 確定 1 (L75) により case C を採用、retrospective-writer は流用しない」(intent-spec.md L108 への言及を削除、design.md だけを参照)
    - L22 / L23 / L108: 同様に「intent-spec の『2 個』は…」「intent-spec.md SC-4 の『3 個』は暫定」を削除し「design.md 確定 1 により」のみに統一
    - L157 / L158: 「(intent-spec の『2 個』は design 確定 1 で 3 個に拡張)」を「(design 確定 1 で 3 個に拡張)」に短縮 1 ファイル 5 〜 6 行差分の機械的修正。
  - **案 B (Retrospective 繰越):** Round 1 の Minor #5 / #6 と同様に、本サイクル外で別途修正、または Retrospective に「Round 2 修正で chain effect 漏れが発生した」事実を記録。
  - **案 C (現状維持 + 注記):** qa-design.md は Step 4 時点の歴史的記録として「intent-spec.md L108 (Step 4 当時) の…」のように時点を明示する形で読み替える運用を許容。本ファイル自体は変更しない。
- **設計との関連:** `intent-spec.md:108-110` (Round 2 で更新済)、`progress.yaml.rollbacks[1].reason` M-2、`qa-design.md` L21-L23 (chain update 漏れ箇所)。

---

## 観点固有の評価項目

consistency (新規スキル / template / reference / agent と既存 dev-workflow / shared-artifacts / specialist-\* との一貫性、および Round 1 → Round 2 修正後の状態) について、Round 1 の 8 項目チェックリストを Round 2 状態で再評価する。

### 1. frontmatter スキーマの一貫性

- **Round 1 状態:** 新規 3 specialist のうち `roadmap-retrospective-writer` のみ `metadata.version` 欠落 (Minor #3)。
- **Round 2 状態:** Round 2 (`648e233` M-1) で `metadata.version` を全 SKILL.md から削除する逆方向統一を採用。実測: 全 15 SKILL.md が `metadata: { author: totto2727 }` 単一フィールドで揃う。Round 1 Minor #3 は新しい統一基準で**解消** (#4 として記録)。

### 2. 命名規則

- **Round 1 状態:** `specialist-<name>` / `agents/<name>.md` / `<roadmap-id>` / `roadmap-` prefix の各規則は完全整合。
- **Round 2 状態:** Round 2 で命名規則変更なし。維持されており整合継続。

### 3. 本文セクション構造

- **Round 1 状態:** 新規 3 specialist のセクション構造は整合、`dev-roadmap/SKILL.md` も既存パターン整合。`specialist-roadmap-retrospective-writer` の概要表に「ライフサイクル」行あり / 他 2 specialist にはない微差 (Minor #5、Retrospective 繰越判定)。
- **Round 2 状態:** 本文セクション構造は変更なし。Minor #5 は当初判定通り Retrospective 繰越維持 (#6 として記録)。

### 4. テンプレート / リファレンス対応

- **Round 1 状態:** 1:1 対応の例外 3 件、新規テンプレ 4 件と reference 4 件の対応は全件整合 (Info #8)。
- **Round 2 状態:** Round 2 で `shared-artifacts/SKILL.md:53-59` の成果物一覧テーブル `#` 列を `-` から連番 13-16 に修正 (M-4)。`#` 列の連番が既存 1-12 行と整合し、表全体が均質化。テンプレート / reference の 1:1 対応自体は維持されており整合継続。

### 5. agent 構造

- **Round 1 状態:** 新規 3 agent の `## 参照スキル` 構造は既存 `qa-analyst.md` と整合 (Info #7)。Do NOT use for の有無で 3 specialist 内に分裂あり (Minor #6、Retrospective 繰越判定)。
- **Round 2 状態:** 変更なし。Minor #6 は Retrospective 繰越維持 (#6 として記録)。

### 6. path 表記の統一

- **Round 1 状態:** 33 箇所の旧 `docs/dev-workflow/<identifier>/` 残存 (Major #2)。
- **Round 1.5 状態:** `37eb0d3` で 33 箇所全件置換済。実測 0 件残存。
- **Round 2 状態:** 維持されており、`grep -rn 'docs/dev-workflow/' plugins/dev-workflow/` 結果 0 件で完全整合継続 (#3 として記録)。

### 7. Mermaid 記法

- **Round 1 状態:** `graph LR` 統一、ただし `dev-roadmap/SKILL.md:89-100` ワークフロー全体図のみ ASCII art 残存 (Minor #4)。
- **Round 2 状態:** Round 2 (`648e233` M-6) で L88-102 (ワークフロー全体図) と L276-289 (双方向参照図) の両方を Mermaid `graph LR` に変換済。実測: 罫線文字 0 件、`flowchart LR` 0 件。HTML エンティティエスケープ (`&lt;` `&gt;` `&#91;` `&#93;`) はプレースホルダを含む図 (L276-289 双方向参照図、L355-394 ディレクトリレイアウト図) のみで使用、プレースホルダ非含有図 (L88-102 ワークフロー全体図) では非使用と用途別に整合。Round 1 Minor #4 は完全解消 (#5 として記録)。

### 8. 既存 dev-workflow との接続記述

- **Round 1 状態:** 「ワークフロー開始時」段落追加 (SC-7) と「`roadmap-progress.yaml` 更新プロトコル」セクション (SC-8) は確認済。`progress.yaml.roadmap` ネストブロック構造記述も整合。
- **Round 2 状態:** Round 2 (`6eae32b` M-7) で `dev-workflow/SKILL.md:792` のコミットメッセージ例を「unlink milestone」→「complete milestone」に変更し、`workflow_identifiers[]` の append-only スキーマ (`references/roadmap-progress-yaml.md` で確定済) と整合。`grep -nF 'unlink' plugins/dev-workflow/` 実測: 1 件のみ (= L792 の「`workflow_identifiers[]` は append-only で削除しない (= unlink 操作は存在しない、`complete` は `status: active → completed` 遷移を表す)」という説明的記述、これは整合的な内容)。Round 2 (`648e233` M-5) で `design.md:245` のステップ番号挿入位置記述を実装 (L558) と整合する詳細表現に更新済 (「ステップ 4 → ステップ 4' (新規) → ステップ 5」)。Round 2 (`648e233` M-3) で `dev-roadmap/SKILL.md:561` の旧 Intent Spec L41 誤参照 (「Intent Spec L41 / 制約」) を「Intent Spec の非スコープ『`roadmap` を入れ子にすること』」に置換済 (現 intent-spec.md には L41 制約なし、本記述は古い L41 番号を指していたため誤参照だった、Round 2 で適切な文脈参照に修正)。8 項目すべて整合継続。

## 修正ラウンド履歴

| Round | Blocker | Major | Minor | 主要指摘 (要約)                                                                                                                           | 修正コミット SHA                                                                               |
| ----- | ------- | ----- | ----- | ----------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| 1     | 0       | 2     | 4     | 旧 10 ステップ番号残存 (Major #1、`specialist-roadmap-retrospective-writer/SKILL.md:135`) と path 表記分裂 33 箇所 (Major #2)             | Round 1.5 で `37eb0d3` (path 33 箇所一括置換) / `aa14c1e` (旧 step 番号) / `551e497` (Misc)    |
| 2     | 0       | 0     | 1     | Round 1 Major 2 件は完全解消、Minor 4 件のうち 3 件解消 + 1 件は方向転換解消、Round 2 chain update 漏れ 1 件 (qa-design.md ↔ intent-spec) | Round 2 修正コミット `648e233` (M-1〜M-7) + `6eae32b` (M-8 + L792 fix + Round 2 rollback 記録) |

Round 3 は不要 (Blocker 0、唯一の Minor #1 (manual-tests) と Minor #7 (qa-design.md chain update 漏れ) はいずれもユーザー判断で「フォローアップ」「Retrospective 繰越」「現状維持 + 注記」のいずれか選択可能、Step 7 進行を阻害しない)。

## 他レビューとの整合性

- Round 1 では `consistency` / `documentation-quality` / `backward-compatibility` / `holistic` の 4 観点が並列実行された。Round 2 では他観点の reviewer の Round 2 出力は本レポート作成時点で参照していない (本 Specialist は consistency 観点に限定された並列インスタンスのため、`specialist-reviewer/SKILL.md` のクロスリファレンスルールに従い独立並列で動作)。
- 本 Round 2 で新規発見した Minor #1 (manual-tests の `validation-evidence/` 残骸) と Minor #7 (qa-design.md の intent-spec.md L108 古参照) は、`holistic` 観点 (全体整合性 / 設計文書↔実装整合) でも同種の指摘が出る可能性が高い。Main は両 reviewer の指摘を比較してマージ判断を行うことを推奨する。
- `documentation-quality` 観点は M-3 (旧 Intent Spec L41 誤参照修正)、M-4 (`#` 列連番化)、M-7 (`unlink` → `complete`) の修正品質 (置換後の文章可読性 / コミットメッセージ例の自然さ) を別軸で見るため、本レポートとは指摘軸が異なるはず。
- `backward-compatibility` 観点は Round 2 で `metadata.version` を全削除した影響 (= 既存スキル利用者から見て frontmatter スキーマが変わったか、SemVer 的な互換性影響) を別軸で見るはず。本 Round 2 consistency レポートでは新統一基準での揃い具合のみを評価しており、互換性影響は scope out。
