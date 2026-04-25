# Reference: `TODO.md` の書き方

## 目的

Construction 中の**タスク状態を永続化**する。Main の内部タスクリスト（`TaskCreate` で管理）は揮発性のため、作業引き継ぎ・中断再開のためにこのファイルが**真のソース**となる。セッション跨ぎで新規 Main が `TODO.md` を読めばタスク状態を完全復元できる。

## 作成者 / 更新タイミング

- **作成者:** Main（Specialist は作らない）
- **生成:** Construction 開始時に `task-plan.md` から生成
- **更新:** タスク状態変化のたび（`pending` → `in_progress` → `completed` / 再活性化時）、**必ず同時にコミット**

## ファイル位置

`docs/ai-dlc/<identifier>/TODO.md`

## 各セクションの書き方

### ヘッダ

- Source: `task-plan.md`
- Created at / Last updated: タイムスタンプ

### 後発追加タスク（`task-plan.md` 以降に発生したもの）

**`task-plan.md` は不変運用**のため、Construction 中に発見された追加タスクはここに明示する:

- 追加タスクの内容
- 追加理由
- どのタスクと依存関係があるか

### タスク

チェックボックス形式:

```markdown
- [x] **T1** — Setup database schema
  - status: completed
  - dependencies: -
  - started_at: 2026-04-24T09:00:00Z
  - completed_at: 2026-04-24T09:30:00Z
  - commit: abc1234
  - implementer: impl-1
  - re_activations: 0
  - notes: -
- [ ] **T3** — Implement auth endpoint
  - status: in_progress
  - dependencies: T1, T2
  - started_at: 2026-04-24T10:30:00Z
  - implementer: impl-3
```

各タスクに必ず記録する項目:

- **status**: `pending` / `in_progress` / `completed`
- **dependencies**: 先行タスク ID
- **started_at**: `in_progress` 遷移時に記録
- **completed_at**: `completed` 遷移時に記録
- **commit**: 担当 implementer の main コミット SHA
- **implementer**: インスタンス識別子
- **re_activations**: Self-Review High 指摘で Step 5 に戻った回数

### 状態遷移ガイド

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: `implementer` 起動中。`[ ]` 表示、`started_at` と `implementer` を記録
- `completed`: 完了。`[x]` 表示、`completed_at` と `commit` SHA を記録
- Self-Review High 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント

## TaskCreate との同期ルール

**TODO.md が真のソース、TaskCreate はそのビュー**。

1. 状態変化時: **TODO.md 更新 → コミット → TaskUpdate** の順で実行（永続側を先に確定）
2. セッション再開時: `TODO.md` を読み、`TaskCreate` で内部タスクリストを完全復元
3. 齟齬が発生した場合: TODO.md を正として TaskCreate を修正

## 品質基準

| ✅ よい                              | ❌ 悪い                            |
| ------------------------------------ | ---------------------------------- |
| 全タスク状態変化が即反映・即コミット | まとめて更新して粒度の細かさを失う |
| commit SHA が具体的に埋まっている    | commit 欄が空                      |
| re_activations カウンタを正確に追記  | ループ履歴が失われている           |
| 追加タスクの理由が書かれている       | 唐突に新タスクが現れる             |

## 関連成果物

- **入力:** `task-plan.md`（初期状態の元）
- **連携:** `progress.yaml`（フェーズ全体の進捗。TODO.md はタスクレベル、yaml はフェーズレベル）
- **参照:** Self-Review での High 指摘 → 該当タスクを `re_activations` カウントアップして `in_progress` に戻す
- **引き継ぎ:** `retrospective.md` が TODO.md のループ履歴を分析して学びを抽出
