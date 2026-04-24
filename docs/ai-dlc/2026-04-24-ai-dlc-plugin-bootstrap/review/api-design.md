# Review Report: api-design

- **Identifier:** 2026-04-24-ai-dlc-plugin-bootstrap
- **Aspect:** api-design
- **Reviewer:** verification-step7-external-review-specialist
- **Reviewed at:** 2026-04-24
- **Scope:** plugins/ai-dlc/ 配下の全成果物（skills/ / agents/ / .claude-plugin/）における契約・スキーマ・パス規約・プレースホルダ・ゲート契約の整合性。ソースコードの API 実装は対象外。

## サマリ

| 深刻度      | 件数 |
| ----------- | ---- |
| Blocker     | 0    |
| Major       | 4    |
| Minor       | 7    |

**Gate 判定:** needs_fix

## 指摘事項

### #1 `review-report.md` の観点固有評価項目が reference に欠落（api-design / プロジェクト固有）

- **深刻度:** Major
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/references/review-report.md`
  - Line: 50–80（観点固有の評価項目セクション）
- **問題の要約:** reference は `security` / `performance` / `readability` / `test-quality` の 4 観点の評価項目しか列挙していないが、テンプレート (`templates/review-report.md:4` コメント、`:54`)、`specialist-reviewer/SKILL.md:42`、`specialist-reviewer/SKILL.md:107–111`、`main-verification/SKILL.md:82` は `api-design` を正当な観点例として提示している。api-design を担当する reviewer が reference を参照した際、対応する評価項目の雛形が無いため、テンプレートの `{{aspect_specific_evaluation}}` を一貫した形で埋められない。
- **根拠:** reference と template は「1:1 対応」と `shared-artifacts/SKILL.md:30, 90` で宣言されているが、観点の網羅性で不整合が発生している。プロジェクト固有観点も同様の抜け。
- **推奨アクション:** `references/review-report.md` の「観点固有の評価項目」に `api-design`（後方互換性 / 契約の明確さ / エラーモデル / 命名・拡張性）節を追加し、`specialist-reviewer/SKILL.md:107–111` の内容と同期する。
- **設計との関連:** `shared-artifacts/SKILL.md` の「Reference / Template の変更ルール」（1:1 対応維持）

### #2 `review-report.md` の `Scope` フィールドと `specialist-reviewer` 入力契約が非対応

- **深刻度:** Major
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/review-report.md`
  - Line: 7
- **問題の要約:** テンプレートにはヘッダに `- **Scope:** {{review_scope}}` が存在するが、`specialist-reviewer/SKILL.md` の「固有の入力」（L48–54）、`agents/reviewer.md` の「Main への要求」（L32–40）、および `references/review-report.md` のどれも `review_scope` の書き方を定義していない。埋め手が reference を読んでも何を書くべきか特定できず、プレースホルダが `{{review_scope}}` のまま残るか、曖昧に埋められる。
- **根拠:** Main ↔ Specialist 入力契約 (`specialist-common/SKILL.md:62–74`) の「期待成果物フォーマット … 書き方の指針は reference を参照」原則に反する。
- **推奨アクション:** (a) `references/review-report.md` に `Scope` セクションの埋め方（「担当観点のスコープ境界を明示（例: 公開 API のみ、内部 util 除く）」等）を追記、かつ (b) `specialist-reviewer` の入力契約に "Scope 文言" の入力項目を追加、または Main-Specialist 契約側から scope を導出するルールを reference に明記。
- **設計との関連:** `main-workflow/SKILL.md:80–84`（Specialist 起動時の明示事項「これをやる / これはやらない」）

### #3 `progress.yaml` の `completed_steps.artifact` が単数形、複数成果物ステップと矛盾

- **深刻度:** Major
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/progress.yaml`
  - Line: 8–11
- **問題の要約:** テンプレートは `completed_steps[].artifact: <成果物ファイル相対パス>`（単数）となっている。しかし Step 2 (Research) と Step 7 (External Review) は観点ごと並列生成で**複数ファイル**が同一ステップの成果物となる（`main-inception/SKILL.md:105–114`, `main-verification/SKILL.md:99–101`）。また Step 8 は `validation-report.md` + `validation-evidence/*` の複数成果物を 1 コミットで扱う（`main-workflow/SKILL.md:373`）。スキーマ上 `artifact` が単数で、表現手段（配列化するか、複数行列挙するか）が未規定。
- **根拠:** `references/progress-yaml.md:61–63` では "複数作成される成果物（research, review）はリスト形式" と書かれているのは `artifacts` フィールドの話で、`completed_steps[].artifact` 側は単数扱いのまま。スキーマに一貫性がない。
- **推奨アクション:** `completed_steps[].artifact` を `artifacts: [<path>, ...]` と複数形リストに変更し、reference と同期させる。
- **設計との関連:** `references/progress-yaml.md:61`「複数作成される成果物はリスト形式」

### #4 `progress.yaml.active_specialists.status` の値域が `specialist-common` と不整合

- **深刻度:** Major
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/progress.yaml`
  - Line: 16–20
- **問題の要約:** テンプレートは `status: running | completed | blocked` と宣言する。しかし `active_specialists` は `references/progress-yaml.md:47` で「**現在走っている Specialist のみ**を記録。完了したら `completed_steps` 側に吸収され、このリストから削除される」と定義されており、ここに `completed` 値が入ることはあり得ない。また `specialist-common/SKILL.md` のライフサイクル規則上、Specialist 状態は「running（同一ステップ内存続）」と Blocker 状態の 2 種のみで、`completed` は別フィールドに遷移する。
- **根拠:** テンプレートのコメントとリファレンスの説明が矛盾している。Main が実装時に `completed` を `active_specialists` に残すと「running 状態が放置されセッション跨ぎで残る」（`references/progress-yaml.md:80`）のアンチパターンを誘発する。
- **推奨アクション:** テンプレートの列挙を `status: running | blocked`（あるいは `running | awaiting_feedback | blocked`）に修正し、`completed` は記載しない旨を reference に明記。
- **設計との関連:** `specialist-common/SKILL.md:46–56` / `references/progress-yaml.md:45–55`

### #5 ゲート判定の語彙が成果物ごとに非統一

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/review-report.md` (L17), `templates/self-review-report.md` (L16), `templates/validation-report.md` (L16)
- **問題の要約:** 判定フィールド名と値域が成果物間で揃っていない:
  - review-report: `Gate 判定` / `approved | needs_fix | blocked`
  - self-review-report: `Gate 判定` / `passed | failed`
  - validation-report: `全体判定` / `passed | failed | partially_passed`

  同じ「ゲート通過判断」を表す語なのに、フィールド名（Gate 判定 vs 全体判定）と値の命名法（動詞過去分詞 vs 形容詞）が混在している。Main が横断的に進捗集計する際に揺れる。
- **根拠:** `main-workflow/SKILL.md:217–229`（ゲート通過時プロトコル）では 3 種のゲート（ユーザー承認 / In-Progress / Main 判定）しか区別しておらず、成果物内の verdict は統一語彙が期待される。
- **推奨アクション:** 全成果物で `Gate 判定` に統一し、値域も `approved | needs_fix | blocked`（または `passed | failed | partial`）のいずれかに収斂させる。Validation の `partially_passed` は特殊なので例外として許容しつつ、命名は `partial` に縮約。
- **設計との関連:** `shared-artifacts/SKILL.md:90`（1:1 対応と仕様統一）

### #6 タイムスタンプフィールド名の非統一 (`Last updated` vs `Reviewed at` 欠落)

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/review-report.md`
  - Line: 5–6
- **問題の要約:** review-report は `Reviewed at` のみで `Last updated` を持たない。一方 self-review-report は両方持つ（L5–6）。Review Report も差し戻しで更新される可能性があるため、`updated_at` が必要（`specialist-reviewer/SKILL.md:114–118` のケース「詳細化・根拠追記の差し戻し」は同インスタンスでの更新を想定）。他の成果物 (`design.md`, `intent-spec.md`, `TODO.md`) は `Last updated: {{updated_at}}` を持つ。
- **根拠:** 同一成果物ドメインで差し戻し運用が規定されているのに更新時刻フィールドがない = 監査不能。
- **推奨アクション:** review-report テンプレートに `- **Last updated:** {{updated_at}}` を追加。
- **設計との関連:** `specialist-common/SKILL.md:107–112`（ケース A：差し戻し時の同インスタンス修正）

### #7 Placeholder 命名規則の揺れ（`{{name}}` 形式の実態不一致）

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/review-report.md`（L21–43）等全テンプレート
- **問題の要約:** `shared-artifacts/SKILL.md:68` は「プレースホルダは `{{name}}` 形式（将来 EJS 等に移行可能）」と宣言する。実態は:
  - 反復インデックス付き命名: `{{finding_1_title}}`, `{{finding_1_severity}}` 等（review-report / self-review-report）。EJS ならこれは `{{#findings}}...{{/findings}}` のような反復構文で書くべきで、将来移行時に単純置換できない
  - `metric_1` / `target_1` / `v_1` （validation-report L57–58）と `criterion_1_statement` 形式が混在
  - Retrospective の `{{intent_analyst_improvement}}` など、agent 名直書き（将来 agent 追加/削除で壊れる）
- **根拠:** 「将来 EJS 等に移行可能」という前提と現行のフラット命名が乖離。移行コストが暗黙に増加。
- **推奨アクション:** 反復セクションは `<!-- repeat per finding -->` コメントで範囲を明示し、インデックス命名はこの範囲内ローカルとする旨を `shared-artifacts/SKILL.md` に明記する。または将来変換用として Mustache セクション構文の例を併記。
- **設計との関連:** `shared-artifacts/SKILL.md:66–70`

### #8 パス表記規約が reference/skill 内で微妙に揺れている

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/SKILL.md:22`（「プラグインルートからの相対パス `shared-artifacts/references/<name>.md`」と宣言）
  - 対比: `main-workflow/SKILL.md:264–273`（同形式で `shared-artifacts/...` を利用、OK）
  - 対比: `main-inception/SKILL.md:45–48` 等（`shared-artifacts/references/...` 同形式、OK）
- **問題の要約:** 本件は**致命的ではない**が、`agents/reviewer.md:26–27` および各 agents/*.md では `shared-artifacts/references/...` を採用する一方、SKILL 本体で `references/<name>.md`（`shared-artifacts/` 省略）と呼ぶ箇所が散見される（例: `shared-artifacts/SKILL.md:77, 79, 82, 84` 内）。シンプルにするか、常にプラグインルート起点で書くかを統一すべき。
- **根拠:** SKILL.md:22 の規約宣言と、同 SKILL.md 本文の記述（L77–86 等）に齟齬がある。
- **推奨アクション:** `shared-artifacts/SKILL.md` 本文をすべて `shared-artifacts/references/<name>.md` / `shared-artifacts/templates/<name>.md` に統一。相対・フルパスのどちらかに決める。
- **設計との関連:** `shared-artifacts/SKILL.md:22`

### #9 エラーモデル（失敗時プロトコル）が specialist 役割ごとに粒度不揃い

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/specialist-reviewer/SKILL.md:113–118`
  - File: `plugins/ai-dlc/skills/specialist-validator/SKILL.md:73–79`
- **問題の要約:** `specialist-reviewer` は「固有の失敗モード」を 4 行の表形式で提示、`specialist-validator` は 4 行で同形式。`specialist-common/SKILL.md:105–141` はケース A–D を詳述し一貫。しかし役割別 specialist で表にまとめた失敗モードと common のケース A–D の対応関係が**明示されていない**（どの行が Case A に属するか、など）。
- **根拠:** `specialist-common` の「4. 失敗時 / Blocker 発生時のプロトコル」が親契約で、役割別は子契約のはず。親子の写像が不在なので、specialist は両者を独立に読むことになる。
- **推奨アクション:** 各 specialist-* の失敗モード表に `| 状況 | common ケース | 対応 |` の 3 列目を追加し A/B/C/D にマップ、または common 側で「役割別表は common ケースのインスタンスである」旨を明記。
- **設計との関連:** `specialist-common/SKILL.md:105–141`

### #10 Backward compatibility: `docs/ai-dlc/<id>/` レイアウトが暗黙に複数フィールドを前提

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/SKILL.md:102–123`（ディレクトリ構造）
- **問題の要約:** 構造ツリー図は `implementation-logs/`, `validation-evidence/` など**条件付きで生成されるサブディレクトリ**を同列に描いており、「存在しない可能性」のマーク（`(任意)`/`(必要な場合のみ)`）が一部にはあるが (L113, L120)、`research/` や `review/` には同様の注記が無い。サイクルが Step 2 / 7 を完遂せずに中断した場合の後方互換（再開時）挙動がドキュメント上で未定義。
- **根拠:** セッション再開 (`main-workflow/SKILL.md:241–254`) では `<identifier>/` 配下を全読込するが、部分的な構造を許容するか否かが曖昧。
- **推奨アクション:** ディレクトリ構造図で「必須」と「ステップ到達時のみ生成」をマーク分けする。
- **設計との関連:** `main-workflow/SKILL.md:241–254`

### #11 Gate 契約（user-approval / main-judgment / in-progress）の区別がコード的でない

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/main-workflow/SKILL.md:217–229`
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/progress.yaml:37–41`
- **問題の要約:** `main-workflow` で 3 種のゲートが定義され、`progress.yaml.user_approvals` は user-approval のみを記録する。Main 判定ゲートや In-Progress 一時レポートは **`progress.yaml` 側に構造化された痕跡を残さない**。結果として Retrospective 時に `references/retrospective.md:96` が要求する「user_approvals, rollbacks」の分析はできても、「Main 判定ゲート通過履歴」「In-Progress レポート起票履歴」は紐付け困難。
- **根拠:** Gate 契約の三分類と永続化スキーマの対称性が欠けている。
- **推奨アクション:** `progress.yaml` に `main_judgments: []` と `in_progress_reports: []`（path + 目的 + 発生ステップ）フィールドを追加し、ゲート種別ごとの記録を対称化する。
- **設計との関連:** `main-workflow/SKILL.md:217–229` / `templates/retrospective.md:97–104`

## 観点固有の評価項目

### 後方互換性（Backward Compatibility）

- **サイクルディレクトリ `docs/ai-dlc/<id>/` の形式安定性:** 部分的（#3, #10 で指摘のとおり、`completed_steps.artifact` スキーマ変更が破壊的になる）
- **Specialist スキル・エージェント追加時の影響:** Retrospective テンプレートが agent 名を直書きしているため（#7）、agent を増やすと既存サイクルの retrospective テンプレートが後方互換でなくなる
- **プレースホルダ形式の将来移行性:** `{{name}}` から EJS/Mustache への移行は「可能」と謳いつつ、反復構文を持たない命名法（#7）がネック

### 契約の明確さ（Contract Clarity）

- **Main ↔ Specialist 入力契約:** `specialist-common/SKILL.md:62–74` で 7 項目が表で明示され、役割別 specialist-* でも「固有の入力」セクションが共通形式。**基本は明確**。ただし:
  - `review_scope` のような一部プレースホルダに対し、書き方指針が reference 側に不在（#2）
  - プロジェクト固有スキルのパスを入力に含める指示 (`main-workflow/SKILL.md:323–325`) はあるが、入力契約表に明示列がない（`specialist-common/SKILL.md:62–74`）
- **Agent (`agents/*.md`) vs Skill (`specialist-*`) の責務分離:** agents は「Main への要求」リストが簡潔で、`specialist-common` と `specialist-*` を参照する明確な 2 段構成。良好
- **フェーズ遷移の入力成果物チェック表:** `main-workflow/SKILL.md:419–423` で表として明示されている。良好

### エラーモデル（Error / Failure Mode Handling）

- **Blocker プロトコル:** `specialist-common/SKILL.md:105–141` でケース A–D が網羅。適切
- **役割別特殊失敗モード:** specialist-reviewer / specialist-validator 等で固有モードが列挙されているが、common との写像が不明示（#9）
- **Rollback ルート:** `main-verification/SKILL.md:157–162` で原因別ロールバック先 (Step 5 / 3 / 1) が明示。良好
- **ループ上限:** Self-Review ループは 3 周で Inception Step 3 回帰を検討（`main-construction/SKILL.md:259–262`）と上限定義あり。Review Report のループ上限は未規定（改善余地）

## 他レビューとの整合性

本レビューは api-design 観点単独で実施。他観点（security / performance / readability / test-quality）のレビュー結果は本時点では未取得。以下の指摘は他観点からも同様に挙がる可能性がある:

- #3 / #4 の progress.yaml スキーマ整合は readability 観点でも検出され得る
- #7 のプレースホルダ命名は readability 観点で独立に検出される可能性
- #11 のゲート契約の永続化対称性は test-quality 観点（検証可能性）からも支持される

矛盾する可能性がある指摘:
- #5 のゲート語彙統一は readability からは賛成されるが、Validation Report の `partially_passed` を例外維持すべきという反論が来る可能性あり → Main が両レビューの根拠を比較して判断する題材。
