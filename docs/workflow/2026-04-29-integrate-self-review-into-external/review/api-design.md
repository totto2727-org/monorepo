# Review Report: api-design

- **Identifier:** 2026-04-29-integrate-self-review-into-external
- **Aspect:** api-design (本サイクルでは Specialist 間の入出力契約 / 成果物スキーマ / プラグイン公開 contract を「API 相当」として検証)
- **Reviewer:** reviewer (api-design instance)
- **Reviewed at:** 2026-04-29
- **Scope:** `plugins/dev-workflow/` 配下の Markdown / JSON / YAML 全件。実行コードレベルの API 後方互換性は本サイクル非該当。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 3    |
| Minor   | 4    |

**Gate 判定:** `needs_fix`（Major 3 件は Step 7 内追加修正で解決可能。Blocker 不在のため Step 8 進行を阻害しない）

## 9 件の責務範囲の検証結果

1. **Specialist 間の責務分離** — PASS (`specialist-self-reviewer` 言及 0 件)
2. **shared-artifacts の reference / template の 1:1 対応** — PASS
3. **`progress.yaml` スキーマ後方互換性** — Major #2
4. **`plugin.json` description の 9-step 表記** — PASS
5. **公開 agent 一覧 (agents/\*.md) の整合性** — PASS (Minor #4)
6. **shared-artifacts/SKILL.md の成果物一覧テーブルの番号連続性** — PASS (Minor #6)
7. **`<aspect>` enum 拡張 (5 → 6 観点) の影響範囲** — Major #1
8. **旧 `self-review-report.md` 参照残存** — PASS (grep 0 件)
9. **`progress.yaml.artifacts.review` フィールド構造維持 (リスト維持)** — PASS

## 指摘事項

### #1 (Major) review-report.md template の `<aspect>` コメントに `holistic` 未明記

- **該当箇所:** `plugins/dev-workflow/skills/shared-artifacts/templates/review-report.md:2`
- **問題:** template 冒頭コメント `<!-- security | performance | readability | test-quality | api-design | etc. -->` に `holistic` を明示していない。reference / specialist-reviewer / agents / dev-workflow SKILL / shared-artifacts SKILL / README の 6 箇所では `holistic` を明示しているのに、template だけ `etc.` で省略。
- **推奨アクション:** `<!-- security | performance | readability | test-quality | api-design | holistic | etc. -->` に修正。

### #2 (Major) 古い progress.yaml の `self_review:` キー残存ケースに対する取扱い指針が未記載

- **該当箇所:** `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md:62-77`
- **問題:** 過去サイクルの progress.yaml には `artifacts.self_review:` キーが残っており、再開時の取扱いが reference に未記載。
- **推奨アクション:** reference のフィールド一覧直後に "**廃止フィールド:** 過去サイクル (2026-04 以前) の `progress.yaml` には `self_review:` キーが存在する場合があるが、本フィールドは Step 7 廃止に伴い読み捨て対象。新規追加は禁止" を追記。

### #3 (Major) review-report に「修正ラウンド履歴」セクションが新設されていない (design.md 未達)

- **該当箇所:** `plugins/dev-workflow/skills/shared-artifacts/templates/review-report.md`, `references/review-report.md`, `specialist-reviewer/SKILL.md`
- **問題:** design.md L324-L328 で「review-report 内に Round 履歴を持つ」と決まっていたのに、実装に反映されていない。`grep -nE '修正ラウンド|round_history' ...` が 0 件。Round 履歴が無いと 3 周ルールの観測性が失われる。
- **推奨アクション:**
  1. template に「修正ラウンド履歴」セクションを追加 (Round 別 Blocker / Major / Minor 集計表)
  2. reference に対応する解説セクションを追加
  3. specialist-reviewer SKILL の作業手順に「Round 完了時に履歴を追記する」を追加

### #4 (Minor) agents/reviewer.md の Main 要求リストに `holistic` 限定の Round 別契約が書かれていない

- **該当箇所:** `plugins/dev-workflow/agents/reviewer.md:32-41`
- **問題:** description の Main への要求 6 項目に `holistic` 観点の Round 1/Round 2 入力差分が含まれていない。
- **推奨アクション:** 「7. (holistic 限定) Round 番号と他 reviewer 出力の参照可否」を追加。

### #5 (Minor) retrospective.md template のループ表プレースホルダ命名が旧 Step 番号に由来

- **該当箇所:** `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md:36-38`
- **問題:** `loop_5_6` / `rollback_c_i3` / `root_cause_5_6` などが旧フェーズ/旧 Step 番号由来。
- **推奨アクション:** 新フローに合わせてリネーム (`loop_6_7` / `rollback_67_3` 等)。

### #6 (Minor) shared-artifacts/SKILL.md ASCII 図の `holistic.md` 後の空行

- **該当箇所:** `plugins/dev-workflow/skills/shared-artifacts/SKILL.md:130-132`
- **問題:** `└── holistic.md` 直後の空行で縦線 `│` が途切れる。
- **推奨アクション:** 空行を削除。

### #7 (Minor) plugin.json description が 1 行 173 文字 (将来拡張時のリスク)

- **該当箇所:** `plugins/dev-workflow/.claude-plugin/plugin.json:3`
- **問題:** 現状動作問題なし。将来 9 観点拡張時に押し込む形になる懸念。
- **推奨アクション:** 本サイクルでは対応不要。

## 後方互換性の明示的評価

- 既存 progress.yaml への破壊的変更: **無し** (Intent Spec L107 で遡及修正禁止)
- 新スキーマで古い yaml を読んだ際のクラッシュ可能性: **低** (YAML として未知キーは無視される)
- Specialist 実装に与える影響: **低〜中** (Major #2 で対応可能)
- 復旧手順 (旧サイクルを再開する場合): **未定義** (`dev-workflow/SKILL.md` に過渡期サイクルの扱いが書かれていない)
- 新規サイクルへの影響: **無し** (新 template から生成すれば `self_review:` は出現しない)

## 推奨アクション総工数

Major 3 件で約 50〜70 分、Minor 含めても 80〜100 分。Step 7 内の Round 2 で吸収可能。Blocker 不在のため Step 8 進行を阻害しない。
