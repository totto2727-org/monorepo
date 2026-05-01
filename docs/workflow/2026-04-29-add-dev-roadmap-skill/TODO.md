# Task List: 2026-04-29-add-dev-roadmap-skill

- **Source:** `task-plan.md`
- **Active Steps:** Step 6〜7 (Implementation / External Review)
- **Created at:** 2026-05-01T03:30:00Z
- **Last updated:** 2026-05-01T06:30:00Z

> **Path 注記**: T0 (storage rename) は完了済。本ファイルは現在 `docs/workflow/2026-04-29-add-dev-roadmap-skill/TODO.md` に位置している。

このファイルは**永続化されたタスク状態**。Main 内部の `TaskCreate` タスクリストと同期するが、**こちらが真のソース**。状態変化時は TODO.md 更新 → コミット → TaskUpdate の順で実行する。

## 後発追加タスク (`task-plan.md` 以降に発生したもの)

- なし (デフォルト)

## タスク

- [x] **T0** — 保存先ディレクトリの一括リネーム (`docs/dev-workflow/` → `docs/workflow/`、`docs/roadmap/` 新規作成)
  - status: completed
  - dependencies: なし
  - started_at: 2026-05-01T03:35:00Z
  - completed_at: 2026-05-01T03:50:00Z
  - commit: 2949223
  - implementer: main (mechanical git mv only)
  - re_activations: 0
  - notes: 70 files renamed at 100% similarity, .gitkeep added.

- [x] **T1** — `dev-roadmap/SKILL.md` 新規作成
  - status: completed
  - dependencies: T0
  - started_at: 2026-05-01T04:00:00Z
  - completed_at: 2026-05-01T04:25:00Z
  - commit: ffd2f3f
  - implementer: implementer-T1
  - re_activations: 0
  - notes: 572 lines, all TC-001/002/003/031/032/033 self-checked PASS.

- [x] **T2** — `specialist-roadmap-analyst/SKILL.md` 新規作成
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-01T04:30:00Z
  - completed_at: 2026-05-01T05:00:00Z
  - commit: 7a2de10
  - implementer: implementer-T2
  - re_activations: 0
  - notes: 113 行、TC-004/006 PASS

- [x] **T3** — `specialist-roadmap-planner/SKILL.md` 新規作成
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-01T04:30:00Z
  - completed_at: 2026-05-01T05:05:00Z
  - commit: c2b754d
  - implementer: implementer-T3
  - re_activations: 0
  - notes: 136 行、TC-004/006 PASS

- [x] **T4** — `specialist-roadmap-retrospective-writer/SKILL.md` 新規作成
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-01T04:30:00Z
  - completed_at: 2026-05-01T05:10:00Z
  - commit: 011daa3
  - implementer: implementer-T4
  - re_activations: 0
  - notes: 140 行、TC-005/006/033 PASS

- [x] **T5** — roadmap 系 Agent 定義 3 個の新規作成
  - status: completed
  - dependencies: T2, T3, T4
  - started_at: 2026-05-01T05:30:00Z
  - completed_at: 2026-05-01T05:55:00Z
  - commit: 4f00400
  - implementer: implementer-T5
  - re_activations: 0
  - notes: TC-007/008 PASS

- [x] **T6** — `progress.yaml` テンプレート + reference 拡張 (`roadmap` ネストブロック)
  - status: completed
  - dependencies: T0
  - started_at: 2026-05-01T04:00:00Z
  - completed_at: 2026-05-01T04:25:00Z
  - commit: 744d7f6
  - implementer: implementer-T6
  - re_activations: 0
  - notes: TC-014/015/016 PASS. Formatter quirk noted (comment placed before key not after).

- [x] **T7** — 新規テンプレート/リファレンス 4 セット (roadmap.md / milestone.md / roadmap-progress.yaml / roadmap-retrospective.md)
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-01T04:30:00Z
  - completed_at: 2026-05-01T05:25:00Z
  - commit: fca9a23
  - implementer: implementer-T7
  - re_activations: 0
  - notes: 8 ファイル新規。TC-009/010/011/023/024/033 PASS

- [x] **T8** — `shared-artifacts/SKILL.md` 追記 (成果物一覧 + 1:1 例外 + 保存構造 + path 置換)
  - status: completed
  - dependencies: T7
  - started_at: 2026-05-01T05:30:00Z
  - completed_at: 2026-05-01T06:00:00Z
  - commit: 4244cb2
  - implementer: implementer-T8
  - re_activations: 0
  - notes: 7 箇所 path 置換、TC-012/013/031/032 PASS

- [x] **T9** — `dev-workflow/SKILL.md` 追記 (起動時連携 + roadmap-progress.yaml 更新プロトコル + path 置換)
  - status: completed
  - dependencies: T6
  - started_at: 2026-05-01T05:30:00Z
  - completed_at: 2026-05-01T06:15:00Z
  - commit: 6b6206b
  - implementer: implementer-T9
  - re_activations: 0
  - notes: 21 箇所 path 置換、`roadmap-progress.yaml` 言及 11 件、TC-018/019/020/021 PASS

- [x] **T10** — `specialist-common/SKILL.md` 追記 (Specialist 列挙 9 → 12 + Do NOT use for + path 置換)
  - status: completed
  - dependencies: T2, T3, T4
  - started_at: 2026-05-01T05:30:00Z
  - completed_at: 2026-05-01T05:50:00Z
  - commit: eac161d
  - implementer: implementer-T10
  - re_activations: 0
  - notes: 12 specialists 列挙、Do NOT use for 拡張、TC-029/030 PASS

- [ ] **T11** — `plugins/dev-workflow/README.md` 追記 (dev-roadmap の位置づけ)
  - status: in_progress
  - dependencies: T5, T8, T9, T10
  - started_at: 2026-05-01T06:30:00Z
  - completed_at: -
  - commit: -
  - implementer: implementer-T11
  - re_activations: 0
  - notes: 収束タスク

- [ ] **T12** — 検証用 manual-tests 手順書 (TC-025 / TC-032)
  - status: in_progress
  - dependencies: T1, T7, T8
  - started_at: 2026-05-01T06:30:00Z
  - completed_at: -
  - commit: -
  - implementer: implementer-T12
  - re_activations: 0
  - notes: -

## 状態遷移ガイド

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: `implementer` 起動中。`[ ]` 表示、`started_at` と `implementer` を記録
- `completed`: 完了。`[x]` 表示、`completed_at` と `commit` SHA を記録
- External Review Blocker 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント

## コミット規約

- 各タスク状態変化ごとに 1 コミット (頻繁)
- コミットメッセージ例:
  - `docs(dev-workflow/2026-04-29-add-dev-roadmap-skill): start task T1`
  - `feat(dev-workflow/2026-04-29-add-dev-roadmap-skill/task-T1): create dev-roadmap SKILL.md`
  - `docs(dev-workflow/2026-04-29-add-dev-roadmap-skill): complete task T1`
