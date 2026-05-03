# Review Report: Holistic (全体整合性チェック)

- **Cycle:** 2026-05-03-pr-ci-integration
- **Aspect:** holistic — Task Plan 完了判定 / `design.md` 整合性 / Intent Spec 成功基準充足見込み / 明白な bug の早期検出 / コミット粒度 / サイクル間影響範囲
- **First reviewed:** 2026-05-03
- **Last updated:** 2026-05-03
- **Final Gate:** approved
- **Round count:** 1

## 指摘一覧

| ID  | 深刻度 | 指摘内容                                                                                                                                                                                                                                                                                                               | 状態           | 検出 Round | 解消 commit | Notes                                                                                                                                        |
| --- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ---------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| m-1 | Minor  | T1 実装規模が design.md 見立て (約 110 行) に対して実測 195 行 (+77%)。仕様逸脱はないが計画ズレが大きい。                                                                                                                                                                                                              | accepted-as-is | 1          | -           | design.md L527 / task-plan.md `見積り規模 M (約 1〜2 時間)` に対する実装ボリューム差。内容自体は design.md の章節を網羅。Retrospective 材料  |
| m-2 | Minor  | progress-yaml.md L61 の CI failure 例文と design.md L436-L443 提示文例で「リトライ回数」の表現が異なる。design.md は「3 回連続失敗」、実装は「2 回連続失敗 → リトライ上限到達」。意味は同等だが文字列は不一致。                                                                                                        | accepted-as-is | 1          | -           | 実運用ルール (最大 2 回までリトライ → 3 回目失敗で Blocker) のどちらの数値も読み手が再構成可能で誤解の幅は小さい。Retrospective 材料         |
| m-3 | Minor  | Step 9 セクション (L539-L568) Exit Criteria 内に Ready 化文言が直接含まれず、別セクション「## サイクル PR と CI 連携プロトコル § Step 9 完了後の Ready 化」(L945) に分離されている。SC-4 grep は通るが「同一セクション内」読者導線は弱い                                                                               | accepted-as-is | 1          | -           | Intent Spec SC-4 の「Step 9 セクションまたは関連セクションで」の文言で許容範囲。L559 の Exit Criteria 末尾参照 + L945 の独立節で導線維持     |
| i-1 | Info   | T1 が 195 行 / T2 が 9 行 / T3 が 4 行 / T4 が 1 行 / T5 が 2 行で、いずれも単一ファイル単一目的のクリーンな diff。1 タスク = 1 feat コミット粒度ルールを完全遵守。                                                                                                                                                    | (整合確認のみ) | 1          | -           | コミット履歴: bc1a84d / 8a2aff6 / 45dff2b / 1509c57 / 0001ed9。T6 (oxfmt cleanup) / T7 (TC-009 補正) は cycle artefacts への補正で別コミット |
| i-2 | Info   | 過去サイクルディレクトリ (`docs/workflow/2026-04-29-*/`) への意図しない変更なし。`git diff main..HEAD --stat -- docs/workflow/2026-04-29-*/` が空。                                                                                                                                                                    | (整合確認のみ) | 1          | -           | サイクル隔離原則維持                                                                                                                         |
| i-3 | Info   | T6 (oxfmt cleanup) / T7 (qa-design TC-009 補正) が「後発追加タスク」として TODO.md L10-L15 に正しく記録されている。task-plan.md は不変原則を維持。                                                                                                                                                                     | (整合確認のみ) | 1          | -           | TODO.md コミット 80ce71a で T6/T7 が `[x]` マーキング。task-plan.md は Step 5 確定時のまま不変                                               |
| i-4 | Info   | progress.yaml.completed_steps が Step 1〜6 を完備、`current_step: 'Step 7 (External Review)'`。各 Step の `artifacts` / `notes` 充実。`blockers: []` (本サイクル中に未解消 Blocker なし)。                                                                                                                             | (整合確認のみ) | 1          | -           | progress.yaml と TODO.md / git log の三者整合済                                                                                              |
| i-5 | Info   | design.md のシェル擬似コード (Draft PR 初期化 / PR 概要更新 / `gh run watch` / リトライ / Ready 化) が SKILL.md 新セクションに変数名・コマンド完全一致でコピーされている。                                                                                                                                             | (整合確認のみ) | 1          | -           | design.md L168-L267 ↔ SKILL.md L798-L963。`existing_pr` / `IS_DRAFT` / `--exit-status --interval 10 --compact` 等の主要識別子が一致          |
| i-6 | Info   | T2 で追加された Exit Criteria 文言が 8 箇所 (Step 1〜5, 7〜9) で完全同一、Step 6 のみ「全タスク単位コミットそれぞれの CI が PASS」と微修正。task-plan.md R4 リスクで指摘された文言ばらつきを回避済                                                                                                                     | (整合確認のみ) | 1          | -           | SKILL.md L164 / L194 / L228 / L277 / L315 / L382 / L437 / L524 / L559 で実測確認                                                             |
| i-7 | Info   | qa-design.md TC-009 の検証パターン `^## (役割定義\|ステップ詳細\|ステップ完了時のコミット規約)` と実 SKILL.md 見出しが完全整合。`grep -c` 実測値が `3`。                                                                                                                                                               | (整合確認のみ) | 1          | -           | T7 補正 (commit 80ce71a) の有効性確認。Step 8 Validator が SC リグレッション検証で同パターン使用                                             |
| i-8 | Info   | SC-1〜SC-4 (静的検証) の `grep` 期待件数を Step 6 完了時点で実測:<br>- SC-1 `Draft PR`: **3 件** (要求 ≥1)<br>- SC-2 `PR 概要 / description`: **10 件** (要求 ≥2)<br>- SC-3 `CI / gh run`: **30 件** (要求 ≥3)<br>- SC-3 `2 回 / リトライ`: **15 件** (要求 ≥1)<br>- SC-4 `Ready (for review\|化)`: **3 件** (要求 ≥1) | (整合確認のみ) | 1          | -           | すべて閾値を大幅に超過。SC-1〜SC-4 は Step 8 Validator 実行で PASS 確実                                                                      |
| i-9 | Info   | SKILL.md L835-L876 の `## Summary` / `## Cycle artefacts` / `## Progress checklist` 等の H2 見出しは PR description テンプレートのコードフェンス内 (` ```markdown`〜` ``` `) に位置し、SKILL.md の文書構造そのものではない                                                                                             | (整合確認のみ) | 1          | -           | フェンス内であることを L834 (` ```markdown`) と L881 (` ``` `) で確認。Skill ローダ・読者導線への影響なし                                    |

## 詳細セクション

### m-1 詳細: T1 実装規模の design.md 見立てとの乖離

**事実:**

- design.md L527 / task-plan.md L80 では T1 を「約 110 行 / 中規模 M / 1〜2 時間」と見積もり
- 実測コミット 45dff2b は `1 file changed, 195 insertions(+)`
- 内訳: 新セクション (L784-L975) が約 192 行、+ 既存「## ステップ完了時のコミット規約」末尾の T3 拡張に隣接する位置決め

**評価:**

- 実装内容は design.md「主要な型・インターフェース」全体 (L98-L267) を忠実に転記しており、章節の追加発明や独自肉付けはない
- 増加分 (+85 行) の主因は (a) 各サブセクションの説明文 (L786, L790, L815-L823, L832, L885 など)、(b) Markdown コードブロック内の PR description テンプレート全文 (約 50 行)、(c) インラインの責任所在宣言 (L788, L790)。いずれも design.md L104-L153 / L412-L417 / L420-L424 / L967-L975 等で記述された必要要素
- design.md がコード行数だけを「約 110 行」と推定し、コード周辺の説明文・宣言文を含めなかった見立てが原因。**実装の誤りではなく計画見積りの過小評価**

**推奨アクション:**

- 修正不要 (Step 6 戻し不要、内容が仕様通り)
- Retrospective 材料: 「ドキュメント改修タスクの行数見積りはコード抜粋部分だけでなく、文章・宣言文・テンプレート全体を含めて算出する」を Step 9 改善案候補に挙げる

### m-2 詳細: progress-yaml.md L61 の CI failure 例文と design.md 例文の数値表現差

**事実:**

- design.md L436-L443:

  ```markdown
  blockers:

  - 'Step 3 完了コミット <abbrev-sha> の CI が 3 回連続失敗 (oxfmt Formatting)。Step 3 を完了と認められない。対応方針: ユーザー判断仰ぎ中 (run URL: ...)'
  ```

- 実装 progress-yaml.md L61: `Step 6 task-T1 commit abc1234 の CI が 2 回連続失敗 (run id 25270xxxx) → リトライ上限到達のため Blocker 化`
- SKILL.md L920 (新セクション): 「最大 **2 回までリトライ**…3 回目の失敗で **Blocker** 化」

**評価:**

- 「3 回連続失敗」(design.md) と「2 回連続失敗 → リトライ上限到達」(実装) は**運用上同じ意味**:
  - design.md は (1 回目失敗) + (2 回リトライ後失敗) = **3 回連続失敗**を指して Blocker 化と表現
  - 実装は **リトライを 2 回連続失敗** = リトライ上限到達 (= 3 回目の失敗) を指して Blocker 化と表現
- どちらも SKILL.md L920 の「最大 2 回までリトライ → 3 回目で Blocker」と整合
- 文字列としては不一致だが、運用ルールの解釈は一意

**推奨アクション:**

- 修正不要 (運用ルールに齟齬なし、実装文例は具体性で勝る = `commit abc1234` / `run id` 例示)
- Retrospective 材料: 「複数ファイルに散在する例文は数値表現を揃える」を改善案候補に

### m-3 詳細: Step 9 Exit Criteria の Ready 化文言分離

**事実:**

- Step 9 セクション (L539-L568) の Exit Criteria (L555-L559):
  - retrospective.md コミット済
  - 次サイクル開始時に参照可能な場所・名称
  - 該当ステップ完了コミットに紐付く CI が PASS している (T2 追加分)
- Ready 化文言は別セクション「## サイクル PR と CI 連携プロトコル」内のサブセクション「### Step 9 完了後の Ready 化」(L945-L965) に分離

**評価:**

- Intent Spec SC-4 文言「Step 9 セクション**または関連セクション**で『Retrospective 完了後に PR を Draft → Ready 化する』旨が記述されている」を満たしている
- design.md L40-L48「アプローチの概要」で 5 ルールを 1 セクションに集約する方針を採用しているため、Step 9 セクション内に Ready 化を二重記載しないのは設計判断と整合
- L559 の Exit Criteria 文言は「## サイクル PR と CI 連携プロトコル」を参照するクロスリンクを明示
- 読者は Step 9 セクション → クロスリンク → 別セクション (L945) と 2 ホップで Ready 化フローに到達

**推奨アクション:**

- 修正不要 (設計判断と整合)
- 余地があれば Retrospective で「Step 9 Exit Criteria 末尾に『Step 9 完了後の PR Ready 化は『## サイクル PR と CI 連携プロトコル § Step 9 完了後の Ready 化』を参照』の 1 行追加」を改善案として記録 (任意)

## SC 充足見込みのサマリ

Step 8 Validator が実行する前の現時点での定性評価:

| SC   | 内容                                                        | 充足見込み                                                                     | 備考                                                                                                        |
| ---- | ----------------------------------------------------------- | ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| SC-1 | SKILL.md に `Draft PR` 言及 ≥ 1                             | **PASS 確実**                                                                  | 実測 3 件                                                                                                   |
| SC-2 | SKILL.md に `PR 概要 / description` ≥ 2                     | **PASS 確実**                                                                  | 実測 10 件 + 「各ステップ完了時に必ず」「適宜」相当の表現を L815-L817 / L780 で確認                         |
| SC-3 | SKILL.md に `CI / gh run` ≥ 3 + リトライ ≥ 1 + Blocker 接続 | **PASS 確実**                                                                  | 実測 CI 30 件 / リトライ 15 件、L920 / L939-L940 で Blocker 化 + In-Progress 問い合わせ接続を明示           |
| SC-4 | Step 9 セクション/関連で Ready 化 ≥ 1                       | **PASS 確実**                                                                  | 実測 3 件 (L945 / L947 / L965)                                                                              |
| SC-5 | 本サイクル PR Draft 作成                                    | **PASS 見込み (PR #95 として作成済の認識)**                                    | サンドボックス制約で gh CLI 検証不可だが、ミッションで「PR #95 の commit 履歴」と明示。Step 8 で実測確認    |
| SC-6 | PR description 複数回更新トレース                           | **PASS 見込み (要 Step 8 実測)**                                               | gh CLI 検証不可。各 Step 完了時の Main 操作有無は progress.yaml notes / timeline で Step 8 Validator が確認 |
| SC-7 | 各 Step 完了コミット CI が最終的に PASS                     | **PASS 見込み (progress.yaml L115 で「各タスクコミットの CI も全 PASS」記録)** | gh CLI 検証不可。Step 8 Validator が `gh run list --branch <b> --json conclusion,headSha` で機械検証必須    |
| SC-8 | Step 9 完了後 Ready 化                                      | **未達 (現時点では Step 7 進行中)**                                            | Step 9 (Retrospective) 完了および Ready 化は本サイクルの最終アクション。設計通り Step 9 完了後に達成見込み  |

**全体評価:**

- **静的検証 (SC-1〜SC-4)**: Step 6 完了時点で grep 期待件数を大幅に超過しており Step 8 PASS 確実
- **動的検証 (SC-5〜SC-7)**: progress.yaml / TODO.md / git log の自己申告記録は整合しており、Step 8 で `gh` CLI 実測すれば PASS 見込み
- **最終アクション (SC-8)**: Step 9 完了後の Ready 化は本サイクル設計の最終フェーズで達成見込み

## Round 履歴メタ

| Round | 実行日     | reviewer instance   | 単独 Gate |
| ----- | ---------- | ------------------- | --------- |
| 1     | 2026-05-03 | reviewer (holistic) | approved  |

最終 Gate: `approved`。Major / Blocker **0 件**、Minor **3 件** (m-1 / m-2 / m-3 すべて `accepted-as-is`)、Info **9 件**。

<!--
書き方ガイド: shared-artifacts/references/review-report.md
状態ラベル詳細・観点別の重点項目は specialist-reviewer/SKILL.md に委譲。
本 Round 1 では他 reviewer 出力をクロスリファレンスせず独立並列で実施。
-->
