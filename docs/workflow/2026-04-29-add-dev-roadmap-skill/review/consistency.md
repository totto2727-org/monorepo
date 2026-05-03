# Review Report: consistency

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** consistency
- **Reviewer:** reviewer-consistency-instance-001
- **Reviewed at:** 2026-04-29T00:00:00Z
- **Scope:** 本サイクル Step 6 で追加・変更された全成果物 (新規 14 ファイル + 既存追記 6 ファイル + T0 リネーム + manual-tests 2 件)。**観点は consistency に限定** — frontmatter スキーマ / 命名規則 / 本文セクション構造 / テンプレート ↔ リファレンス 1:1 対応 / agent 構造 / path 表記統一 / Mermaid 記法統一 / 既存 dev-workflow との接続記述。security / performance / readability / test-quality / api-design / holistic は別 reviewer 担当のためスコープ外。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 2    |
| Minor   | 4    |
| Info    | 2    |

**Gate 判定:** needs_fix

Major 2 件はいずれもユーザー判断 (Step 6 戻し / Retrospective 繰越) を要する論点。Blocker (= Step 6 への必須差し戻し) は検出していない。Major #1 (旧ステップ番号残存) は局所的な機械置換で解消可能、Major #2 (path 表記の分裂) は設計スコープに関わる判断が必要。

## 指摘事項

### #1 specialist-roadmap-retrospective-writer に旧 10 ステップ番号 (Step 8 / 9 / 10) が残存

- **深刻度:** Major
- **該当箇所:**
  - Commit: `011daa3` (T4 実装) または `5fda5a5` (Step 6 完了)
  - File: `plugins/dev-workflow/skills/specialist-roadmap-retrospective-writer/SKILL.md`
  - Line: 135
- **問題の要約:** スコープ外セクションに「各 workflow の **Step 8 External Review / Step 9 Validation / Step 10 Retrospective** で完了済」と記述されているが、main マージ後の dev-workflow は **9 ステップ体系** (Step 7 External Review / Step 8 Validation / Step 9 Retrospective) に移行済であり、当該記述は旧 10 ステップ表記のまま取り残されている。
- **根拠:** `design.md:27` (本改訂の起因 #1「9 ステップ体系への移行」) および `design.md:522` 「**ステップ番号の置換**: design.md 内の旧 Step 番号 (Step 8 Self-Review / Step 9 External Review / Step 10 Retrospective) は本改訂で全て新 Step 番号 (Step 7 External Review / Step 8 Validation / Step 9 Retrospective) に置換済」と明示的に書かれており、design.md 外に類似の旧番号が残ることは想定外。`intent-spec.md:134` 規範的制約「workflow は main マージ後の **9 ステップ**体系のまま」との直接的な不整合。読み手 (本 Specialist 起動時の Main) が古い番号を信用して runbook を作る誤解を生じうる。
- **推奨アクション:** L135 を「各 workflow の **Step 7 External Review / Step 8 Validation / Step 9 Retrospective** で完了済」に修正する単一行差分の追補コミットを Step 6 で発行する。あわせて `ggrep -nE 'Step (8 External Review|9 Validation|10 Retrospective)' plugins/dev-workflow/skills/specialist-roadmap-*/SKILL.md plugins/dev-workflow/skills/dev-roadmap/SKILL.md` で類例残存がないか同時に検索しておくと再発防止になる (本レビュー時点の追加検索では他箇所には残存なし)。
- **設計との関連:** `design.md` §「main マージによる前提崩壊への追従 (本設計改訂の 4 起因)」#1 (L25-28)、§「Self-Review 削除と External Review への統合の影響 (機械的調整)」(L517-522)。

---

### #2 path 表記が新規スキル (新パス) と既存スキル (旧パス) で分裂、ファイル間で `docs/dev-workflow/<identifier>/` と `docs/workflow/<identifier>/` が混在

- **深刻度:** Major
- **該当箇所:**
  - Commit: `2949223` (T0 storage rename) 完了後の追加コミット群 (T8 / T9 / T10) はリネーム反映済だが、それ以外のファイルは未反映
  - File 列 (旧パス残存):
    - `plugins/dev-workflow/agents/architect.md:22`
    - `plugins/dev-workflow/agents/intent-analyst.md:22`
    - `plugins/dev-workflow/agents/planner.md:22`
    - `plugins/dev-workflow/agents/qa-analyst.md:25-26`
    - `plugins/dev-workflow/agents/researcher.md:22`
    - `plugins/dev-workflow/agents/reviewer.md:27`
    - `plugins/dev-workflow/agents/validator.md:25`
    - `plugins/dev-workflow/skills/specialist-architect/SKILL.md:27`
    - `plugins/dev-workflow/skills/specialist-implementer/SKILL.md:75`
    - `plugins/dev-workflow/skills/specialist-intent-analyst/SKILL.md:28`
    - `plugins/dev-workflow/skills/specialist-planner/SKILL.md:31`
    - `plugins/dev-workflow/skills/specialist-qa-analyst/SKILL.md:31`
    - `plugins/dev-workflow/skills/specialist-researcher/SKILL.md:27`
    - `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md:32`
    - `plugins/dev-workflow/skills/specialist-validator/SKILL.md:26, 70`
    - `plugins/dev-workflow/skills/shared-artifacts/references/intent-spec.md:15`
    - `plugins/dev-workflow/skills/shared-artifacts/references/research-note.md:15`
    - `plugins/dev-workflow/skills/shared-artifacts/references/design.md:15`
    - `plugins/dev-workflow/skills/shared-artifacts/references/qa-design.md:15, 53`
    - `plugins/dev-workflow/skills/shared-artifacts/references/qa-flow.md:15`
    - `plugins/dev-workflow/skills/shared-artifacts/references/task-plan.md:16`
    - `plugins/dev-workflow/skills/shared-artifacts/references/todo.md:15`
    - `plugins/dev-workflow/skills/shared-artifacts/references/implementation-log.md:20`
    - `plugins/dev-workflow/skills/shared-artifacts/references/review-report.md:15`
    - `plugins/dev-workflow/skills/shared-artifacts/references/validation-report.md:15, 17`
    - `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md:15`
    - `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md:15`
    - `plugins/dev-workflow/skills/shared-artifacts/templates/qa-design.md:40`
    - `plugins/dev-workflow/skills/shared-artifacts/templates/validation-report.md:54`
  - 残存総数: 33 箇所 (`grep -rn 'docs/dev-workflow' plugins/dev-workflow/` 実測)
- **問題の要約:** `intent-spec.md:23` および :75 で「path 表記は**全てリネーム後の新パス**を前提とする」と確定された方針に対し、本サイクルが触れる範囲 (= `dev-workflow/SKILL.md` / `specialist-common/SKILL.md` / `shared-artifacts/SKILL.md` の 3 ファイル + 新規 dev-roadmap 系) のみ新パスへ置換され、それ以外の既存 specialist-\* / agents / shared-artifacts/references / shared-artifacts/templates では旧 `docs/dev-workflow/<identifier>/` 表記が 33 箇所残存している。結果、プラグイン内で同じ作業ディレクトリを指す path 表記が分裂し、新規 dev-roadmap 系成果物 (新パス) と既存 dev-workflow 系成果物 (旧パス) の双方を読む Specialist / Main / ユーザーに認知負荷を与える。
- **根拠:** `intent-spec.md:23`「path 表記は全てリネーム後の新パスを前提とする」、`intent-spec.md:75-76`「既存の `docs/workflow/<identifier>/` と並列配置」「保存先リネームの先行コミット」と整合性がない。`design.md:313-326` の「path 一括置換」対象は dev-workflow/SKILL.md (21 箇所) / specialist-common/SKILL.md (2 箇所) / shared-artifacts/SKILL.md (9 箇所) のみに限定され、agents/ や shared-artifacts/references/_ / shared-artifacts/templates/_ および他 specialist-\* SKILL.md の path 表記は置換対象に含まれていなかった。`task-plan.md:252` の R1 緩和策では「Step 8 Validation で `ggrep -rn 'docs/dev-workflow' plugins/dev-workflow/` を実行して残存箇所が 0 件 (もしくは意図的歴史的記述のみ) であることを確認」と書かれており、design.md の置換タスク範囲 (3 ファイル) と task-plan.md / Validation 検査範囲 (プラグイン全域) の間にも齟齬がある。consistency 観点として最も問題なのはプラグイン内のファイル間で path 表記が分裂して **同一概念 (作業ディレクトリ) を指すのに表記が 2 種類存在** している事実。
- **推奨アクション:** ユーザー判断ポイントとして以下 3 案を提示:
  - **案 A (推奨、Step 6 戻し):** Step 6 に追加タスク T13 を立て、`ggrep -rln 'docs/dev-workflow/' plugins/dev-workflow/` で検出した 33 箇所を一括置換 (`docs/dev-workflow/<identifier>/` → `docs/workflow/<identifier>/`、`docs/dev-workflow/<id>` → `docs/workflow/<id>` の機械置換)。コミット 1 本で完結する小タスク。
  - **案 B (Retrospective 繰越):** 本サイクル外で別途「path 表記統一サイクル」を起こし、本サイクル Validation では「dev-roadmap 関連の path 整合性のみ確認、既存 dev-workflow 系の旧 path 残存は意図的に scope out」と Validation Report に明記する。
  - **案 C (現状維持 + 例外明記):** intent-spec.md / design.md の解釈を「本サイクルが触れた範囲内のみ新パスに統一、既存の他箇所は別サイクル対応」に明示的に絞り、shared-artifacts/SKILL.md または design.md 末尾に「path 統一の段階的移行を許容」と注記して残存を許容する。
    実装容易性の観点では案 A が最短だが、本サイクルのスコープ拡大判断 (specialist-common §4 ケース C) を伴うためユーザー承認が必要。
- **設計との関連:** `design.md` §「main マージによる前提崩壊への追従」#2「保存先ディレクトリのリネーム」(L28)、§「既存スキルへの最小変更影響表」(L313-326)、`intent-spec.md` §「スコープ → 保存先ディレクトリ」(L68-76)、`task-plan.md` §「R1 (T0 起因の path 整合性破綻)」(L252)。

---

### #3 specialist-roadmap-retrospective-writer の frontmatter に `version` フィールドが欠落 (同時新設の 2 specialist とのファミリー内不一致)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `011daa3` (T4 実装)
  - File: `plugins/dev-workflow/skills/specialist-roadmap-retrospective-writer/SKILL.md`
  - Line: 18-20 (frontmatter `metadata:` ブロック)
- **問題の要約:** `metadata: { author: totto2727 }` のみで `version: 1.0.0` が欠落している。同時に新設された `specialist-roadmap-analyst` (`version: 1.0.0`) および `specialist-roadmap-planner` (`version: 1.0.0`) は `version` を含むため、新規 3 specialist のうち本ファイルだけ frontmatter スキーマが揃っていない。`intent-spec.md:128` 規範的制約「frontmatter スキーマは既存 dev-workflow 系スキルと同一 (`name` / `description` / `metadata: { author, version }`)」とも厳密には不整合。
- **根拠:** 既存の `specialist-implementer` / `specialist-retrospective-writer` / `specialist-validator` も `version` を持たない (= 既存パターン側に揺れがある) ため、Major には届かないが、新規 3 specialist 内で frontmatter スキーマが分裂している事実は consistency 上の傷である。新規ファイル群のなかで揃えておけば、将来 frontmatter スキーマを正規化する別サイクルで一括対応しやすい。
- **推奨アクション:** Retrospective 繰越案件として記録。具体的には次のいずれかをユーザー判断:
  - 新規 3 specialist を `version: 1.0.0` で揃える 1 行追加コミット (1 ファイル / 1 行差分の極小修正)。
  - 既存パターンの揺れ (`specialist-implementer` 等の `version` 欠落) も含めて別サイクルで一括正規化する方針を Retrospective に記録。
- **設計との関連:** `intent-spec.md:128` 規範的制約「frontmatter スキーマ既存と同一」、`shared-artifacts/SKILL.md` の Reference / Template 1:1 対応原則とは無関係 (frontmatter 形式の話)。

---

### #4 dev-roadmap/SKILL.md L90-99 の「ワークフロー全体図」が他既存 SKILL.md (Mermaid) と異なり ASCII art 表現

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `ffd2f3f` (T1 実装)
  - File: `plugins/dev-workflow/skills/dev-roadmap/SKILL.md`
  - Line: 89-100
- **問題の要約:** 「ワークフロー全体図」セクションが ASCII art (`────┐` / `─────┤◄───`) で記述されている。一方、本サイクル内の他図 (L359-396「ディレクトリレイアウト」、design.md の各図) はすべて Mermaid `graph LR` で統一されており、design.md 確定 4「Mermaid `graph LR` で統一」とも整合している。本図のみ ASCII art の単独残存となっている。
- **根拠:** `design.md` §「代替案比較 確定 4 (Mermaid 記法)」(L357-358)「`graph LR` (既存パターン) **採用**: DAG 同型 + 最小変更 + 既存 task-plan.md の引用パターンとして自然」。同 SKILL.md 内の他 Mermaid 図は全て `graph LR` で統一されているため、ASCII art と Mermaid が同居する構成は表現スタイルの分裂を生んでいる。とはいえ ASCII art は単純なステップ並び (4 ステップ + 矢印 + ガード表記) を 1 画面に収める用途では可読性が高く、機能上の問題はない。
- **推奨アクション:** Retrospective 繰越案件として記録。Mermaid `graph LR` 化により他 SKILL.md (例: `dev-workflow/SKILL.md` のステップ遷移図がもしあれば、または `design.md` のフロー図) と表現を揃える小修正を別サイクルで検討してよい。本サイクルでの修正は不要。
- **設計との関連:** `design.md` 確定 4 (L357-358)。

---

### #5 specialist-roadmap-\* の本文セクション構造に `## 役割` 直前の 1 行説明文が無い (一部既存と微妙に異なる)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `7a2de10` / `c2b754d` / `011daa3` (T2 / T3 / T4 実装)
  - File: `plugins/dev-workflow/skills/specialist-roadmap-{analyst,planner,retrospective-writer}/SKILL.md`
  - Line: ヘッダ部 (継承宣言と概要表の直下、`## 役割` 見出し直前)
- **問題の要約:** 大セクション (役割 / 固有の入力 / 作業手順 / 固有の失敗モード / スコープ外) の構成は既存パターンと整合しているが、3 ファイルの間で導入文の有無や粒度に微妙なばらつきがある。例えば `specialist-roadmap-retrospective-writer` の概要表に「ライフサイクル」行 (揮発、次ロードマップ消化で削除) が追加されている一方、`specialist-roadmap-analyst` / `specialist-roadmap-planner` には同行が無い。これは既存 `specialist-retrospective-writer/SKILL.md` (workflow 用) との整合を取った結果とも読めるが、3 specialist 横並びの一覧性が若干損なわれている。
- **根拠:** 既存の `specialist-retrospective-writer/SKILL.md` (workflow 用) を踏襲する形で `specialist-roadmap-retrospective-writer` のみライフサイクル行を持たせる判断は妥当だが、テンプレート的な仕様規定は無いため consistency 上「揃える」「揃えない」のいずれが正解か明文ルールが存在しない。本指摘は将来 specialist-\* SKILL.md の導入部テンプレ化 (例: 概要表の必須カラム定義) を検討する材料として記録する。
- **推奨アクション:** Retrospective 繰越案件として記録。ルール化は本サイクル外で議論。本サイクルでの修正は不要。
- **設計との関連:** `specialist-common/SKILL.md` § 出力契約、`shared-artifacts/SKILL.md` § 1:1 対応 (frontmatter 形式と本文構造のテンプレ化議論は本サイクルのスコープ外)。

---

### #6 既存 agents/qa-analyst.md などとの "Do NOT use for" 記載粒度の差異が roadmap-analyst / roadmap-planner と roadmap-retrospective-writer で分裂

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `4f00400` (T5 実装)
  - File:
    - `plugins/dev-workflow/agents/roadmap-analyst.md` (Do NOT use for **無し**)
    - `plugins/dev-workflow/agents/roadmap-planner.md` (Do NOT use for **無し**)
    - `plugins/dev-workflow/agents/roadmap-retrospective-writer.md:10-13` (Do NOT use for **有り**、3 行)
  - Line: frontmatter description 末尾
- **問題の要約:** 既存 agents の運用としては `architect.md` / `implementer.md` / `intent-analyst.md` / `planner.md` / `qa-analyst.md` / `researcher.md` は Do NOT use for を含まず、`reviewer.md` / `validator.md` / `retrospective-writer.md` は含むという揺れがある。新規 `roadmap-retrospective-writer.md` は対応する `retrospective-writer.md` (含む) と整合している点で妥当だが、`roadmap-analyst.md` / `roadmap-planner.md` は含まないという既存パターンの揺れを再現する形になっている。consistency 観点としては「3 specialist のうち retrospective-writer だけ Do NOT use for を持つ」という分裂は、既存パターンを踏襲した結果である一方で、ファミリー単位での説明性 (roadmap 系全体の責務境界の一覧性) を多少損ねている。
- **根拠:** 既存の `agents/qa-analyst.md` (新パターン) は Do NOT use for を持たないため、`roadmap-analyst.md` / `roadmap-planner.md` の「持たない」判断は既存パターン整合的。一方、`roadmap-retrospective-writer.md` は対応する `retrospective-writer.md` の構造を踏襲して持つ。両者の判断はそれぞれ既存と整合しているが、ファミリーとしての一貫性 (3 specialist 横並びで Do NOT use for の有無が揃うこと) は確保されていない。本指摘は本質的には**既存パターン側の揺れ**を引き継いだ結果の指摘であり、新規追加のファイル単独で改修する性質のものではない。
- **推奨アクション:** Retrospective 繰越案件として記録。agents/\*.md の frontmatter 構造正規化 (Do NOT use for を全 agent に追加するか、全 agent から削除するか) は別サイクルで検討。本サイクルでの修正は不要。
- **設計との関連:** `design.md` §「コンポーネント構成」(L72-94) は agents 構造の詳細仕様を定めていないため、本論点は明示的なルールが無い。

---

### #7 `agents/roadmap-*.md` の参照スキルセクションは既存 `agents/qa-analyst.md` と整合 (整合確認、指摘なし)

- **深刻度:** Info
- **該当箇所:**
  - File: `plugins/dev-workflow/agents/roadmap-{analyst,planner,retrospective-writer}.md`
  - Line: `## 参照スキル` セクション (各 16-19 行付近)
- **問題の要約:** 各 agent ファイルが `specialist-common` + 対応する `specialist-roadmap-*` の 2 つを参照スキルとして列挙している点、「このエージェントが起動されたら、上記スキルを読み込んで作業を進めること」という規定文を含む点、概要・Main への要求・主要な責任範囲という大見出し構成も含めて、既存 `agents/qa-analyst.md` の構造と一致している。
- **根拠:** `task-plan.md:89` T5「既存 `agents/qa-analyst.md` の構造を踏襲して作成する」と整合。
- **推奨アクション:** 修正不要。Info レベルで「整合性確認済み」を記録。
- **設計との関連:** `task-plan.md:89` T5、`design.md` §「コンポーネント構成」L77-78 / L86-87。

---

### #8 1:1 対応の例外 3 件が `shared-artifacts/SKILL.md:24-30` と新規 `references/roadmap-progress-yaml.md:13` の双方で正しく記述 (整合確認、指摘なし)

- **深刻度:** Info
- **該当箇所:**
  - File:
    - `plugins/dev-workflow/skills/shared-artifacts/SKILL.md:24-30`
    - `plugins/dev-workflow/skills/shared-artifacts/references/roadmap-progress-yaml.md:9-13`
- **問題の要約:** `shared-artifacts/SKILL.md:24` の「以下 3 件は意図的な例外」と `references/roadmap-progress-yaml.md:13` の「**1:1 対応の例外 3 件目**」は相互に整合しており、`progress-yaml.md ↔ progress.yaml` / `todo.md ↔ TODO.md` / `roadmap-progress-yaml.md ↔ roadmap-progress.yaml` の 3 件が対応表として正しく列挙されている。`intent-spec.md:54-56` および `design.md` §「コンポーネント構成」L85-86 とも整合。
- **根拠:** `task-plan.md:111` T6 / `task-plan.md:131` T7 / `task-plan.md:143` T8 のカバレッジテストケース (TC-013) と整合。
- **推奨アクション:** 修正不要。Info レベルで「整合性確認済み」を記録。
- **設計との関連:** `design.md` §「既存スキルへの最小変更影響表」L323、`intent-spec.md` 成功基準 #5。

---

## 観点固有の評価項目

consistency (新規スキル / template / reference / agent と既存 dev-workflow / shared-artifacts / specialist-\* との一貫性) について、以下のチェックリスト項目別評価を記録する。

### 1. frontmatter スキーマの一貫性

- 新規 3 specialist (roadmap-analyst / planner / retrospective-writer) の frontmatter は `name` / `description` / `metadata.author` を全て備える。`metadata.version` は roadmap-analyst / roadmap-planner にあり、roadmap-retrospective-writer に無い (Minor #3)。`dev-roadmap/SKILL.md` の frontmatter は完備 (`version: 1.0.0`)。
- agents/roadmap-\*.md 3 件の frontmatter は全て `description` を備え、既存 `agents/qa-analyst.md` のスキーマと整合 (Info #7)。

### 2. 命名規則

- `specialist-<name>` パターン: `specialist-roadmap-analyst` / `specialist-roadmap-planner` / `specialist-roadmap-retrospective-writer` は既存命名と整合。
- `agents/<name>.md` パターン: 同上。
- 新規スキル名 `dev-roadmap` は既存 `dev-workflow` と並列のフラット命名で整合。
- `<roadmap-id>` の命名規則は `dev-roadmap/SKILL.md:411-414` および `shared-artifacts/SKILL.md:160-168` で一貫して定義。
- retrospective 集約 path の prefix `roadmap-` は `dev-roadmap/SKILL.md:400-407` / `shared-artifacts/SKILL.md:198` / `references/roadmap-retrospective.md:20-33` の 3 箇所で重複明記され整合。

### 3. 本文セクション構造

- 新規 3 specialist は既存 specialist-\* の標準セクション (役割 / 固有の入力 / 作業手順 / 固有の失敗モード / スコープ外) を踏襲。微差として `roadmap-retrospective-writer` の概要表に「ライフサイクル」行が追加されているが、対応する `specialist-retrospective-writer` (workflow 用) と整合 (Minor #5 で記録)。
- `dev-roadmap/SKILL.md` のセクション構成は既存 `dev-workflow/SKILL.md` の Main 用スキル構造と概ね整合 (基本方針 / 役割定義 / ステップ一覧 / ステップ詳細 / 接続プロトコル / 進捗管理 / 保存構造 / ゲート判定とコミット規約 / 再開プロトコル / ロールバック / 成果物テンプレ / プロジェクト固有ルール / このスキルが扱わないこと)。

### 4. テンプレート / リファレンス対応

- 1:1 対応の例外 3 件 (`progress-yaml.md ↔ progress.yaml` / `todo.md ↔ TODO.md` / `roadmap-progress-yaml.md ↔ roadmap-progress.yaml`) は `shared-artifacts/SKILL.md:24-30` と `references/roadmap-progress-yaml.md:9-13` の双方で整合 (Info #8)。
- 新規テンプレ 4 件 (`roadmap.md` / `milestone.md` / `roadmap-progress.yaml` / `roadmap-retrospective.md`) と対応 reference 4 件はすべて存在し、`shared-artifacts/SKILL.md:56-59` の成果物一覧テーブルにも追加済。

### 5. agent 構造

- 新規 agents/roadmap-\*.md 3 件は既存 `agents/qa-analyst.md` の構造 (frontmatter description / `## 参照スキル` / `## 概要` / `## Main への要求` / `## 主要な責任範囲`) を踏襲 (Info #7)。Do NOT use for の有無は既存揺れを反映 (Minor #6)。

### 6. path 表記の統一

- `docs/workflow/<identifier>/` / `docs/roadmap/<roadmap-id>/` / `docs/retrospective/<...>.md` (リネーム後の新パス) は新規 dev-roadmap 系全体および本サイクルで触った 3 ファイル (`dev-workflow/SKILL.md` / `specialist-common/SKILL.md` / `shared-artifacts/SKILL.md`) で完全に統一。
- 一方、本サイクルが触らなかった既存 specialist-\* / agents / shared-artifacts/references / shared-artifacts/templates の 33 箇所で旧 `docs/dev-workflow/<identifier>/` 表記が残存 (Major #2)。
- スキル名 `dev-workflow` / `dev-roadmap` 自体およびコミットスコープ表記 (`docs(dev-workflow/<identifier>): ...`) は **path 表記とは別の概念** として明示的に維持されており整合 (`design.md:319` 注記と一致)。

### 7. Mermaid 記法

- `graph LR` で統一。`flowchart LR` 表記は本サイクル全体で 0 件 (`grep -rn 'flowchart' plugins/dev-workflow/skills/dev-roadmap/ plugins/dev-workflow/skills/specialist-roadmap-*/ plugins/dev-workflow/skills/shared-artifacts/{templates,references}/{roadmap,milestone,roadmap-progress-yaml,roadmap-retrospective}.md` 実測)。
- `references/roadmap.md:73` で「`flowchart LR` ではなく `graph LR`」、`references/roadmap.md:116` で品質基準として「`flowchart LR` 表記」を ❌ 例として明示的に記録。
- 1 件のみ Mermaid ではなく ASCII art の図が `dev-roadmap/SKILL.md:89-100` に残存 (Minor #4)。これは記法統一の例外ではあるが、スコープ的にはステップ並びの簡易図示で機能上の問題なし。

### 8. 既存 dev-workflow との接続記述

- `dev-workflow/SKILL.md` の「ワークフロー開始時」段落追加 (intent-spec.md SC-7) と新規セクション「`roadmap-progress.yaml` 更新プロトコル」(intent-spec.md SC-8) は確認済。`grep -nF 'roadmap-progress.yaml' dev-workflow/SKILL.md` の件数も `design.md:309` 想定通り 3 件以上 (実測必要だが design 想定 7 件以上)。
- `progress.yaml.roadmap` ネストブロックの記述は `templates/progress.yaml:65` / `references/progress-yaml.md` の `roadmap` セクション / `dev-roadmap/SKILL.md:282-294` (双方向参照の構造図) / `references/roadmap-progress-yaml.md:167-173` (適用条件) の各箇所で整合。
- `roadmap` ブロック構造 `{id: <roadmap-id>, milestone: {id: <milestone-id>}}` は本サイクル全体で揃って記述されており、フラット 2 フィールド (`roadmap_id` / `milestone_id`) ではなくネスト構造を採用した方針 (intent-spec.md L152) と整合。

## 修正ラウンド履歴

| Round | Blocker | Major | Minor | 主要指摘 (要約)                                               | 修正コミット SHA       |
| ----- | ------- | ----- | ----- | ------------------------------------------------------------- | ---------------------- |
| 1     | 0       | 2     | 4     | 旧 10 ステップ番号残存 (Major #1) と path 表記分裂 (Major #2) | (Round 1 完了時に追加) |

Round 2 以降が発生した場合は本表を更新する。

## 他レビューとの整合性

なし (Round 1 では他観点 reviewer の出力を参照していない、`specialist-reviewer/SKILL.md` のクロスリファレンスルールに従い独立並列で動作)。

他 reviewer (security / performance / readability / test-quality / api-design / holistic) が別観点から重複指摘を出した場合は Round 2 で参照する。特に `holistic` 観点は本指摘 #1 / #2 と部分的に重なる可能性 (旧ステップ番号 = design.md 整合性違反 / path 分裂 = Intent Spec 成功基準充足見込みへの影響) があるため、Main は両 reviewer の指摘を比較してマージ判断を行うことを推奨する。
