# QA Design: {{title}}

- **Identifier:** {{identifier}}
- **Author:** {{qa_analyst_instance_id}}
- **Source:** `intent-spec.md`, `design.md`
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}
- **Status:** {{status}} <!-- draft | approved -->

このドキュメントは **Step 4 で確定する本質テスト設計**。Step 6 (Implementation) で implementer が「実装段階で発見されたテスト」を追記する。書き方の詳細は `shared-artifacts/references/qa-design.md` を参照。

## 概要

{{overview}}

`intent-spec.md` の成功基準を観測可能な形まで深掘りした要約。

例:

- SC-1: User がログインフォームに正しい認証情報を送信すると、JWT を含む 200 レスポンスを 500ms 以内に受け取る
- SC-2: 不正な認証情報の場合、401 を返す
- SC-3: ログイン試行 5 回失敗で IP ベースの一時ブロック (15 分)

## 自動 vs 手動の判断方針

{{automation_rationale}}

`design.md` のアーキテクチャ判断を踏まえ、各テストの実行主体 (automated / ai-driven / manual) 選定根拠を 1〜3 段落で記述する。

## テストファイル配置ポリシー

{{file_placement_policy}}

カテゴリ別の配置方針を記述。具体的なファイルパスは Step 5 (task-plan) / Step 6 (implementer) で確定する。

例:

- `automated × assertion`: ソースファイルと co-located (例: `foo.ts` と `foo.test.ts` を同ディレクトリ)
- `automated × scenario`: `e2e/` 直下
- `manual × inspection`: 手順書を `docs/dev-workflow/{{identifier}}/manual-tests/<TC-ID>.md` に配置

## 本質テストケース (TC-NNN)

仕様レベルで表現可能な振る舞いを検証するケース。Step 4 で qa-analyst が起点を設計、Step 6 で implementer が「振る舞いの追加パターン」を継続採番で追記する。

| ID     | 対象成功基準 | 期待される振る舞い | 実行主体    | 検証スタイル | 判定基準        | 必要理由 (条件付き) | 備考 (任意) |
| ------ | ------------ | ------------------ | ----------- | ------------ | --------------- | ------------------- | ----------- |
| TC-001 | {{sc_id_1}}  | {{behavior_1}}     | {{actor_1}} | {{style_1}}  | {{criterion_1}} | -                   | -           |
| TC-002 | {{sc_id_2}}  | {{behavior_2}}     | {{actor_2}} | {{style_2}}  | {{criterion_2}} | -                   | -           |
| TC-003 | (なし)       | {{behavior_3}}     | {{actor_3}} | {{style_3}}  | {{criterion_3}} | {{reason_3}}        | -           |

<!-- 必要な数だけ TC-004, TC-005, ... を追加 -->

### enum 値の早見表

- **実行主体 (`実行主体` 列):** `automated` | `ai-driven` | `manual`
- **検証スタイル (`検証スタイル` 列):** `assertion` | `scenario` | `observation` | `inspection`
- **禁止組み合わせ:** `automated × inspection` (使用不可)
- **要備考組み合わせ (△):** `ai-driven × assertion`, `manual × assertion`, `manual × observation` — 採用時は `備考` 列に理由必須

## 実装都合テストケース (TC-IMPL-NNN)

ライブラリ / フレームワーク / OS など、具体実装でのみ発生する防御的分岐を検証するケース。Step 4 では空、Step 6 で implementer が発見した場合のみ追記する。

| ID          | 対象成功基準 | 期待される振る舞い  | 実行主体         | 検証スタイル     | 判定基準             | 必要理由 (必須)   | 備考 (任意) |
| ----------- | ------------ | ------------------- | ---------------- | ---------------- | -------------------- | ----------------- | ----------- |
| TC-IMPL-001 | (なし)       | {{impl_behavior_1}} | {{impl_actor_1}} | {{impl_style_1}} | {{impl_criterion_1}} | {{impl_reason_1}} | -           |

<!-- Step 6 で implementer が必要に応じて追記。Step 4 では空欄でよい -->

## カバレッジ表

成功基準 → TC-ID の逆引き。Step 7 validator がカバレッジ確認に使用する。本質テスト (TC-NNN) のみが対象。

| 成功基準 ID | 対応する TC-ID  | 注記 |
| ----------- | --------------- | ---- |
| SC-1        | {{tc_for_sc_1}} | -    |
| SC-2        | {{tc_for_sc_2}} | -    |
| SC-3        | {{tc_for_sc_3}} | -    |

<!-- intent-spec.md の全成功基準について 1 行ずつ記述。対応 TC が 0 件なら Step 4 ロールバック -->
