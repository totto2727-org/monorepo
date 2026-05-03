# Review Report: documentation-quality (Round 2)

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** documentation-quality
- **Reviewer:** reviewer-documentation-quality (Step 7 specialist instance, Round 2)
- **Reviewed at:** 2026-05-03T11:30:00Z
- **Scope:** Round 2 修正コミット 3 本 (`e01d03c`, `648e233`, `6eae32b`) で変更された全成果物 (`plugins/dev-workflow/` 配下スキル / template / reference / README、および `docs/workflow/2026-04-29-add-dev-roadmap-skill/` 配下のサイクル成果物のうち本ラウンドで修正された `validation-report.md` / `progress.yaml` / `design.md` / `intent-spec.md`)。Round 1 (8 件 = Major 4 / Minor 7、ただし計上ベースは Major 4 + Minor 7 = 11 件、本テーブル「サマリ」では 4 + 7 = 11) の解消確認 + Round 2 修正の波及問題 (新規発生) を主観点とする。サイクル進行中の `qa-design.md` / `manual-tests/` 等は本ラウンドの修正対象外なので Round 1 と同じく対象外、ただし Round 2 修正の影響で新たに整合性を逸脱した箇所があれば Minor として記録する。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 0    |
| Minor   | 3    |

**Gate 判定:** `approved`

Blocker / Major は検出されず。Round 1 で計上した 11 件 (Major 4 / Minor 7) のうち **9 件が解消済**、**2 件が部分解消** (Minor #2 のリスト番号併存問題、Minor #11 の他ファイルとの表記不一致) で残存。新規発生の Minor は **3 件** (うち 2 件は Round 2 修正の取り残し、1 件は新規 inlining セクションの体裁) を検出。Round 1 の Major 4 件は全て解消されており、Step 7 進行可。

## Round 1 指摘の解消状況サマリ

| Round 1 # | 深刻度 | 内容 (要約)                                                                                               | Round 2 状況          | 修正コミット                                                                                                                                                                  |
| --------- | ------ | --------------------------------------------------------------------------------------------------------- | --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| #1        | Major  | 旧 Step 8/9/10 残置 (`specialist-roadmap-retrospective-writer/SKILL.md` L135)                             | **解消済**            | `551e497` (T15 Major fix, Round 1.5)                                                                                                                                          |
| #2        | Major  | `dev-workflow/SKILL.md` ステップ番号 `4'` vs `5` 不整合                                                   | **部分解消**          | `551e497` で参照側 (L778) を `4'` に揃え一貫化したが、リスト番号 `5.` と自己ラベル `4'` の併存は残存                                                                          |
| #3        | Major  | サイクル固有「確定 N」が永続スキル / reference に流出 (planner SKILL L77 / roadmap-progress-yaml.md L149) | **解消済**            | `551e497`                                                                                                                                                                     |
| #4        | Major  | README.md 追記段落の英日不規則混在                                                                        | **解消済**            | `e01d03c`                                                                                                                                                                     |
| #5        | Minor  | `specialist-roadmap-retrospective-writer/SKILL.md` の `metadata.version` 欠落                             | **解消済 (方針転換)** | `648e233` で全 SKILL の `metadata.version` 削除統一                                                                                                                           |
| #6        | Minor  | `dev-roadmap/SKILL.md` L564 の `Intent Spec L41` 誤参照                                                   | **解消済**            | `648e233` (実際の文脈「非スコープ」セクション参照に置換)                                                                                                                      |
| #7        | Minor  | `dev-roadmap/SKILL.md` L88-100 ASCII フローチャートの罫線が論理的に閉じていない                           | **解消済**            | `648e233` (Mermaid `graph LR` 化)                                                                                                                                             |
| #8        | Minor  | `dev-roadmap/SKILL.md` L275-291 双方向参照 ASCII 図のボックス幅・縦線位置のずれ                           | **解消済**            | `648e233` (Mermaid `graph LR` 化)                                                                                                                                             |
| #9        | Minor  | `dev-roadmap/SKILL.md` L383-388 Mermaid 図のラベル `roadmap-id-A` の prefix 重複錯覚                      | **未解消**            | (Round 2 修正対象外、許容)                                                                                                                                                    |
| #10       | Minor  | `shared-artifacts/SKILL.md` 成果物一覧テーブル `#` 列の `-` (ソート不能)                                  | **解消済**            | `648e233` (13-16 連番に置換)                                                                                                                                                  |
| #11       | Minor  | `dev-workflow/SKILL.md` L763 の `unlink milestone` が誤解を招く                                           | **部分解消**          | `6eae32b` (`unlink → complete` 動詞の誤用は解消、ただし design.md L297 / `references/roadmap-progress-yaml.md` L144 の `close cycle with retrospective` 表記との不一致が残る) |

**集計:** 11 件中 9 件解消済 (うち 1 件は方針転換による解消) / 2 件部分解消 / 1 件未解消 (Round 2 修正対象外、Minor 許容範囲)。

## 指摘事項

### #1 `intent-spec.md` L128 / `qa-design.md` L101 の `metadata.version` 表記が SKILL 本体と不整合 (Round 2 取り残し)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `648e233` (T-Round2 M-1 / M-2 修正範囲)
  - File:
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md` L128
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/qa-design.md` L101 (TC-002 の検査文言)
- **問題の要約:** Round 2 修正 (M-1) で全 SKILL の `metadata.version` を削除し統一したにもかかわらず、本サイクル内のサイクル成果物 2 ファイルが旧仕様 (`metadata: { author, version }` / `metadata.version`) を引きずっている:
  - `intent-spec.md` L128: 「スキル frontmatter のスキーマは既存 `dev-workflow` 系スキルと同一 (name / description / metadata: { author, version })」 — `version` を含む規範的制約として記述。
  - `qa-design.md` L101 TC-002: 「`dev-roadmap/SKILL.md` が必要な frontmatter キーを保持する (name / description / metadata.author / metadata.version)」 — `metadata.version` を必須キーとして列挙。
  - 一方、`validation-report.md` SC-1 の観測値 (L26-37) は `name` / `description` / `metadata` の 3 キーで PASS 判定済 (= 実際は `metadata.version` を検査していない)。
- **根拠:** `progress.yaml.rollbacks[2].reason` (M-1) で「drop metadata.version from all SKILL.md (no longer needed, cleanup)」と明記されながら、根拠となる Intent Spec 制約 / QA 設計の検査文言が更新されておらず、**ドキュメント間で frontmatter 仕様の真のソースが二重化**している。Reference 品質基準「成果物間の整合性」を逸脱。Round 1 #5 が「方針転換による解消」となる過程で、Intent Spec / QA 設計の対応更新が漏れた。
- **推奨アクション:**
  - `intent-spec.md` L128 を「(name / description / metadata: { author })」に修正 (`version` を削除)。
  - `qa-design.md` L101 TC-002 の検査内容を「(name / description / metadata.author)」に修正、もしくは TC-002 の検査文言を validation-report.md 実装と揃えて `metadata` キー存在確認のみに簡素化。
  - 修正は機械的かつ Step 7 進行可否に影響しないため、Retrospective 繰越または Round 2.5 での軽微パッチが妥当。
- **設計との関連:** Round 1 #5 の解消アプローチ (方針転換による全削除) は妥当だが、Intent Spec 制約と QA 設計を真のソースとする一貫性が崩れた。Round 2 修正の波及範囲設定で `intent-spec.md` / `qa-design.md` を含めるべきだった。

### #2 `dev-workflow/SKILL.md` ステップ番号付け: リスト番号 `5.` と自己ラベル `4'` の併存が残存 (Round 1 #2 部分解消)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `551e497` (Round 1.5 で参照側を統一) / `648e233` (Round 2 で同範囲に変更なし)
  - File: `plugins/dev-workflow/skills/dev-workflow/SKILL.md` L557 / L777
- **問題の要約:** Round 1 #2 で指摘した「ステップ番号付けが一貫しない (`4'` vs `5`)」について、Round 2 では参照側 (`roadmap-progress.yaml` 更新プロトコル L777 / `references/progress-yaml.md` / `references/roadmap-progress-yaml.md`) を全て **`ステップ 4'`** で統一する方向で修正した。これにより参照表記の一貫性は回復したが、L557 のリスト番号は依然 `5.` で、自己ラベルが「ステップ 4'」のため、**リスト番号 (`5.`) と自己ラベル (`4'`)** が同一段落内で食い違う構造が残る:

  ```
  4. progress.yaml を初期化 ... してコミット
  5. **roadmap 配下サイクルの場合の追加初期化** (ステップ 4'): ...
  6. Step 1 から着手する
  ```

  リストとして読むと「ステップ 5」なのに自己ラベルが「ステップ 4'」となるため、初見の読者は依然として「`4'` と `5` のどちらが正しい識別子か」迷う。

- **根拠:** Round 1 推奨アクション「案 A (L557 のラベル `(ステップ 4')` を削除し、L778 の参照表記 `ステップ 5` に揃える)」または「案 B (L557 を `4a.` のサブステップ表記にして全体を `4 / 4a / 5` に再編)」のいずれも採用されておらず、参照側だけを修正したため自己ラベルとリスト番号の不一致が永続化した。
- **推奨アクション:** Round 1 推奨アクションの案 A または案 B を改めて検討し、Retrospective 繰越または次サイクル軽微パッチで解消する。Round 1 で示した案のうち、**案 B (`4. progress.yaml 初期化 → 4a. roadmap 配下サイクル追加初期化 (新規) → 5. Step 1 着手` のサブステップ表記)** が既に修正された参照側 (`ステップ 4'` / `ステップ 4a` への置換) と整合しやすい。
- **設計との関連:** `design.md` L317 の挿入位置記述は実装 (L558) と整合済。本指摘はリスト体裁のみの問題で、内容・順序・依存性に影響しない。

### #3 `dev-workflow/SKILL.md` L792 のコミットメッセージ例が `design.md` L297 / `references/roadmap-progress-yaml.md` L144 と不一致 (Round 1 #11 部分解消)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `6eae32b` (M-7 修正)
  - File:
    - `plugins/dev-workflow/skills/dev-workflow/SKILL.md` L792
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/design.md` L297
    - `plugins/dev-workflow/skills/shared-artifacts/references/roadmap-progress-yaml.md` L144
- **問題の要約:** Round 1 #11 で指摘した「`unlink milestone` の動詞が誤解を招く」点について、Round 2 では SKILL.md L792 のみ `complete milestone <milestone-id> in roadmap <roadmap-id>` に修正された (動詞の誤用は解消)。しかし、design.md L297 と `references/roadmap-progress-yaml.md` L144 では完了時のコミットメッセージ例として `close cycle with retrospective (roadmap milestone <milestone-id> completed)` と書かれており、**SKILL の例文と design.md / reference の例文が別表記**になっている:
  - SKILL.md L792: `docs(dev-workflow/<identifier>): complete milestone <milestone-id> in roadmap <roadmap-id>`
  - design.md L297 / reference L144: `docs(dev-workflow/<identifier>): close cycle with retrospective (roadmap milestone <milestone-id> completed)`

  両者は意味は同等 (どちらも「completed への遷移」を表す) だが、文字列としては別物で、ユーザー / 別 Specialist が「どちらを正規例とすればよいか」迷う。

- **根拠:** Round 1 推奨アクション「`docs(dev-workflow/<identifier>): close cycle with retrospective (roadmap milestone <milestone-id> completed)` (design.md L297 の表記) に揃える」は採用されず、新規動詞 `complete milestone` を SKILL 側だけに導入したため、設計書 / 書き方ガイドとの 3 ファイル間整合が崩れた。Reference 品質基準「成果物間の表記一貫性」を逸脱。
- **推奨アクション:** 以下 2 案のいずれか:
  - **案 A (推奨、Round 1 で提案された)**: SKILL.md L792 を `docs(dev-workflow/<identifier>): close cycle with retrospective (roadmap milestone <milestone-id> completed)` に揃える。design.md / reference は変更不要。
  - **案 B**: design.md L297 / reference L144 を `docs(dev-workflow/<identifier>): complete milestone <milestone-id> in roadmap <roadmap-id>` に揃える。
- **設計との関連:** Round 1 #11 で「設計書 design.md L297 と SKILL の例文が異なっている点も解消できる」と推奨アクションで明記されていたが、この一致部分が未対応のまま残った。Retrospective 繰越または軽微パッチで解消可。

## 観点固有の評価項目 (documentation-quality)

| 評価軸                               | Round 2 評価                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 誤字脱字 / 文法                      | Round 2 修正による誤字脱字の混入なし。日本語常体は維持。Mermaid 図変換に伴う `&lt;` / `&gt;` / `&#91;` / `&#93;` の HTML エンティティ使用は構文上正当 (`graph LR` 内のラベル `[<milestone-id>.md]` を `&lt;milestone-id&gt;.md` でエスケープ)                                                                                                                                                                                                                                                                                                                                                          |
| タイポ (technical term / identifier) | identifier (`<roadmap-id>` / `<milestone-id>` / `<identifier>`) の表記は Round 2 修正後も全成果物で一貫。新規問題なし                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| 冗長表現                             | Round 2 で `validation-evidence/` 4 ファイル (合計 104 行) を `validation-report.md` の「検証ログ (インライン)」セクションに集約したことで、サイクル進行中ドキュメントの冗長性 (2 場所での同一情報) は解消した。プラグイン側汎用 SKILL の `validation-evidence/` 言及 (specialist-validator/SKILL.md, references/validation-report.md, templates/validation-report.md, dev-workflow/SKILL.md L134/L496/L502/L711, specialist-common/SKILL.md, shared-artifacts/SKILL.md L137) は「大きな証拠が必要な場合のみ」の汎用規定として残存しており、本サイクルでのインライン化方針と矛盾しないため新規指摘なし |
| 論理整合性                           | Round 1 で指摘された 3 大論理整合課題 (旧ステップ番号 / `4'` vs `5` / サイクル固有「確定 N」) のうち 2 件 (#1 / #3) が解消、1 件 (#2) が部分解消。新たに「frontmatter スキーマ規範の二重化」(本ラウンド #1) が発生したため、論理整合の総合評価は Round 1 と比べ若干向上 (Major 0 / Minor 3 件分の整合課題のみ残存)                                                                                                                                                                                                                                                                                     |
| reference 品質基準遵守               | references/roadmap-progress-yaml.md の「サイクル固有連番」流出が解消 (Round 1 #3)。Round 2 で reference 側の修正は最小限に留まったため、本ラウンドの reference 自体への新規指摘なし                                                                                                                                                                                                                                                                                                                                                                                                                    |
| template の placeholder              | `templates/validation-report.md` 内の `validation-evidence/` 言及は汎用規定として残存。本サイクルでインライン化したことで「テンプレート vs 実装」のずれが生じうるが、本サイクルは特殊事例 (小規模、エビデンスがインラインで完結) であり、テンプレート側を変更する必要はなし。新規問題なし                                                                                                                                                                                                                                                                                                              |
| Mermaid 図の正確性                   | dev-roadmap/SKILL.md L88-102 (ワークフロー全体図) と L276-289 (双方向参照図) が `graph LR` の Mermaid に変換され、矢印の論理的接続 (`-->` / `-.->`) も正確。subgraph ラベル / ノード ID は構文準拠 (HTML エンティティで `<>` / `[]` をエスケープ)。Round 1 #7 / #8 / #9 の 3 件のうち #7 / #8 は解消、#9 (`roadmap-id-A` prefix 重複の錯覚) は Round 2 修正対象外で残存だが、Mermaid 図自体の正確性には影響しないため新規指摘なし                                                                                                                                                                      |
| 見出し階層                           | Round 2 修正後も H1 → H2 → H3 → H4 の標準階層を維持。validation-report.md L312 「## 検証ログ (インライン)」が新規 H2 セクションとして適切に追加され、その配下 L316/L335/L356/L365/L383 が H3 で階層化されている                                                                                                                                                                                                                                                                                                                                                                                        |
| 具体例の有無                         | Round 1 で評価した具体例の質は維持。Round 2 で validation-report.md インラインセクションに 4 種類の証拠ログ (SC-12 baseline diff / SC-13 specialist enumeration / SC-7-9 grep counts / TC-015 YAML parse) が直接埋め込まれ、コードブロック内の出力サンプルが具体的になり可読性が向上                                                                                                                                                                                                                                                                                                                   |

## 修正ラウンド履歴

| Round | Blocker | Major | Minor | 主要指摘 (要約)                                                                                                                                    | 修正コミット SHA                                    |
| ----- | ------- | ----- | ----- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| 1     | 0       | 4     | 7     | 旧ステップ番号 (Step 8/9/10) 残置、ステップ番号付け不整合 (`4'` vs `5`)、サイクル固有「確定 N」流出、README 英日混在                               | `551e497`, `e01d03c` (Round 1.5 / Round 2 部分修正) |
| 2     | 0       | 0     | 3     | Round 1 指摘 9 件解消 / 2 件部分解消 / 1 件未解消 (許容)。新規 Minor 3 件 (frontmatter 仕様の二重化、リスト番号併存、コミットメッセージ表記不一致) | `648e233`, `6eae32b`, `e01d03c`                     |

Round 3 以降が発生する場合は本セクションを更新する。本ラウンド時点では Blocker 0 件 / Major 0 件のため Step 7 → Step 8 / 9 (またはサイクル完了) 進行可。Minor 3 件は Retrospective の材料として記録し、機械的修正可能なものは次サイクル軽微パッチで解消することを推奨。

## 他レビューとの整合性

Round 2 では本観点 (documentation-quality) のみ単独再レビューのため、他観点 reviewer との直接整合確認は行わない。Round 1 で同時並列実行された `holistic` / `consistency` / `backward-compatibility` の指摘との重複可能性:

- **本ラウンド #1 (frontmatter スキーマ規範の二重化)**: `consistency` 観点で扱われる可能性高 (Round 1 review/consistency.md L92, L179 で同等の議論がされていた)。Round 2 で SKILL 本体は統一され Round 1 consistency #1 は解消したが、Intent Spec / QA 設計の規範文言は更新漏れで本ラウンドで再浮上。`consistency` 観点の Round 2 再レビューが行われる場合は同件が両観点で重複検出される見込み
- **本ラウンド #2 (リスト番号併存)**: `consistency` 観点で重複検出されうる。本観点では「読者の混乱可能性 = 記述品質」、`consistency` 観点では「番号体系の整合性」として責務分離可能
- **本ラウンド #3 (コミットメッセージ表記不一致)**: `consistency` 観点と重複可能性高。本観点では「読者が正規例として参照する際の混乱」を、`consistency` 観点では「3 ファイル間の表記統一性」を問う形で責務分離可能

重複した場合の優先度判断は Main に委ねる。
