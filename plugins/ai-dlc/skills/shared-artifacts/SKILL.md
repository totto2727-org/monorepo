---
name: shared-artifacts
description: >
  [Main / Specialist 共通] AI-DLC ワークフローで作成する全成果物の目次と仕様を提供する。
  各成果物の書き方（references/）とテンプレート（templates/）が 1:1 で対応する。
  Main がステップ進行時に、Specialist が成果物作成時に、それぞれ該当ドキュメントを
  参照して統一された形式で成果物を作成・評価できるようにする。
  起動トリガー: 成果物の作成・レビュー・参照を行うすべての場面。Main / Specialist 共通。
  "成果物の書き方", "ドキュメントテンプレート", "shared-artifacts" で参照可能。
  Do NOT use for: ワークフロー手順（main-* スキル）、Specialist の役割定義
  （specialist-* スキル）、成果物以外のドキュメント作成。
allowed-tools: Read, Glob, Grep
---

# Shared Artifacts — AI-DLC 成果物リファレンス

ユースケースカテゴリ: **Document & Asset Creation**（成果物の仕様と雛形を集約する目次スキル）
設計パターン: **Domain Intelligence**（成果物ドメインの書き方と品質基準を埋め込む）

AI-DLC ワークフローで作成される全成果物について、**書き方ガイド（`shared-artifacts/references/`）とテンプレート（`shared-artifacts/templates/`）**を集約する。

**パス表記ルール:** 本スキル内で成果物ファイルを参照する際は、プラグインルートからの相対パス `shared-artifacts/references/<name>.md` / `shared-artifacts/templates/<name>.md` で統一表記する（他スキルからの参照と同じ形式）。

**ファイル名の 1:1 対応と例外:** references と templates は**原則として同名ファイルで対応**する（例: `references/intent-spec.md` ↔ `templates/intent-spec.md`）。以下 2 件は意図的な例外で、目次表のカラム対応で紐付ける:

- `references/progress-yaml.md` ↔ `templates/progress.yaml`（書き方ガイドは Markdown、テンプレートは YAML として読み込まれる前提のため拡張子が異なる）
- `references/todo.md` ↔ `templates/TODO.md`（`TODO.md` は成果物としての慣用的大文字表記を踏襲。reference 側はファイル名規則の kebab-case を優先）

これら 2 件以外で同名対応が崩れる成果物を追加してはならない。

## 前提

- Main が成果物を管理し、Specialist が作成する
- 各成果物は `docs/ai-dlc/<identifier>/` 配下に保存される（詳細: `main-workflow` の「成果物保存構造」）
- references と templates は **1:1 対応**。同名ファイルで紐付く
- Specialist はテンプレートを埋める際に必ず対応する reference を参照する
- Main は成果物をレビューする際に対応する reference を品質基準として使う

## 成果物一覧（目次）

| # | 成果物                         | Phase / Step            | 作成者 (Specialist)                    | Reference                                  | Template                                  |
| - | ------------------------------ | ----------------------- | -------------------------------------- | ------------------------------------------ | ----------------------------------------- |
| 1 | `progress.yaml`                | 全サイクル             | (Main が維持)                          | `shared-artifacts/references/progress-yaml.md`              | `shared-artifacts/templates/progress.yaml`                 |
| 2 | `intent-spec.md`               | Inception Step 1        | `intent-analyst`                       | `shared-artifacts/references/intent-spec.md`                | `shared-artifacts/templates/intent-spec.md`                |
| 3 | `research/<topic>.md`          | Inception Step 2        | `researcher` (観点ごと並列)            | `shared-artifacts/references/research-note.md`              | `shared-artifacts/templates/research-note.md`              |
| 4 | `design.md`                    | Inception Step 3        | `architect`                            | `shared-artifacts/references/design.md`                     | `shared-artifacts/templates/design.md`                     |
| 5 | `task-plan.md`                 | Inception Step 4        | `planner`                              | `shared-artifacts/references/task-plan.md`                  | `shared-artifacts/templates/task-plan.md`                  |
| 6 | `TODO.md`                      | Construction 全体       | (Main が維持、`task-plan.md` から生成) | `shared-artifacts/references/todo.md`                       | `shared-artifacts/templates/TODO.md`                       |
| 7 | `implementation-logs/<id>.md`  | Construction Step 5     | `implementer` (タスクごと並列)         | `shared-artifacts/references/implementation-log.md`         | `shared-artifacts/templates/implementation-log.md`         |
| 8 | `self-review-report.md`        | Construction Step 6     | `self-reviewer`                        | `shared-artifacts/references/self-review-report.md`         | `shared-artifacts/templates/self-review-report.md`         |
| 9 | `review/<aspect>.md`           | Verification Step 7     | `reviewer` (観点ごと並列)              | `shared-artifacts/references/review-report.md`              | `shared-artifacts/templates/review-report.md`              |
|10 | `validation-report.md`         | Verification Step 8     | `validator`                            | `shared-artifacts/references/validation-report.md`          | `shared-artifacts/templates/validation-report.md`          |
|11 | `retrospective.md`             | Verification Step 9     | `retrospective-writer`                 | `shared-artifacts/references/retrospective.md`              | `shared-artifacts/templates/retrospective.md`              |

## Reference と Template の使い分け

### Reference（`shared-artifacts/references/<name>.md`）

**成果物の書き方ガイド**。以下を含む:

- 目的: この成果物が何のために存在するか
- 作成タイミングと作成者: どのステップで誰が作るか
- 各セクションの書き方: プレースホルダを埋める際の具体的指針
- 品質基準: 何がよい成果物で、何がそうでないか（良例 / 悪例）
- 関連成果物との関係: 入力・出力のつながり

**誰が読むか:**

- **Specialist**: 作成時の指針として
- **Main**: レビュー時の品質基準として
- **ユーザー**: 成果物を理解するための背景情報として

### Template（`shared-artifacts/templates/<name>.md`）

**埋めるべき雛形**。プレースホルダは `{{name}}` 形式（将来 EJS 等に移行可能）。

- Specialist はテンプレートをコピーして `docs/ai-dlc/<identifier>/` 配下に配置し、プレースホルダを埋める
- プレースホルダはすべて埋めるか、該当なしなら明示的に「N/A」等を記述する

## 使い方

### Specialist が成果物を作成するとき

1. 対応する `shared-artifacts/references/<name>.md` を読み、書き方を理解する
2. `shared-artifacts/templates/<name>.md` をコピーして `docs/ai-dlc/<identifier>/<artifact>.md` に配置
3. プレースホルダを埋める（references の指針に従う）
4. 完成したら Main に返却

### Main が成果物をレビューするとき

1. 対応する `shared-artifacts/references/<name>.md` の品質基準を参照
2. 成果物が基準を満たしているかチェック
3. 不足があれば該当 Specialist に差し戻し（新規インスタンス作成ではなく同一インスタンスにフィードバック）

## Reference / Template の変更ルール

- Reference を更新したら、Template も同じ観点で整合性を確認する（1:1 対応を維持）
- 新規成果物を追加する場合は、Reference と Template の両方を同時に追加し、SKILL.md の目次に登録する
- プロジェクト固有のカスタマイズが必要な場合は、該当プロジェクトで派生バージョンを作らず、このプラグインの本体を更新する方針を原則とする

---

## 成果物保存構造（サイクル作業ディレクトリ）

AI-DLC の成果物および進捗記録は、**サイクルごとに独立したディレクトリに集約**してリポジトリにコミットする。これにより**作業の中断と再開**が可能になる（別のセッションが同一ディレクトリを読めば現在地を把握できる）。

### ディレクトリ構造

```
docs/ai-dlc/<identifier>/
├── progress.yaml              # 進捗記録（Main が各ターンで更新）
├── intent-spec.md             # Step 1 成果物
├── research/                  # Step 2 成果物（観点ごとにファイル分割）
│   ├── <topic-1>.md
│   └── ...
├── design.md                  # Step 3 成果物（設計ドキュメント本体）
├── task-plan.md               # Step 4 成果物（planner が生成した不変なタスク分解）
├── TODO.md                    # Construction 進行中のタスク状態（Main が維持）
├── implementation-logs/       # Step 5 の長大な動作確認ログ（必要な場合のみ）
│   └── <task-id>.md
├── self-review-report.md      # Step 6 成果物
├── review/                    # Step 7 成果物（観点ごとにファイル分割）
│   ├── security.md
│   ├── performance.md
│   └── ...
├── validation-report.md       # Step 8 成果物
├── validation-evidence/       # Step 8 の大きな証跡（必要な場合のみ）
│   └── <evidence-file>
└── retrospective.md           # Step 9 成果物
```

各ファイルの詳細な書き方は `shared-artifacts/references/<name>.md` を参照。

### `<identifier>` の命名ルール

プロジェクトごとに決める。使用候補:

- チケット ID（例: `JIRA-1234`, `issue-567`）
- 機能名（例: `user-auth-refactor`, `oauth-support`）
- 日付 + スラッグ（例: `2026-04-24-cache-layer`）

サイクル開始時に Main がユーザーと合意して決定する。命名ルールがプロジェクトで既に決まっていればそれを踏襲する。

### サイクル外の成果物

以下はサイクル作業ディレクトリ (`docs/ai-dlc/<identifier>/`) **外**に保存される:

#### プロジェクト横断 ADR

- **保存場所:** プロジェクト既存の ADR 格納場所（例: `doc/adr/YYYY-MM-DD-title.md`）
- **起票条件:** サイクル内で発生した判断が**プロジェクト全体に及ぶ**場合のみ（詳細は `shared-artifacts/references/design.md` の「ADR 起票の判定基準」参照）
- **サイクルからの参照:** `progress.yaml.artifacts.external_adrs` にパスを記録、`design.md` からリンクを張る

#### In-Progress ユーザー問い合わせ用一時レポート

- **保存場所:** `$TMPDIR/ai-dlc/<phase>-<step>-<purpose>.md`
- **役割:** 作業途中のユーザー判断要請（Blocker 対応、選択肢提示等）のみ使用。ステップ完了時の承認ゲートには使わない
- **コミット:** **しない**。Retrospective で件数・トピックのサマリのみ `retrospective.md` に反映
- **使い分けの詳細:** `main-workflow` の「基本方針」セクション（Artifact-as-Gate-Review / Report-Based Confirmation for In-Progress Questions）を参照

---

## 成果物のライフサイクル

### 作成から承認まで

1. Main が該当 Specialist を起動（テンプレート・reference・入力成果物のパスを伝える）
2. Specialist が `shared-artifacts/templates/<name>.md` をコピーして `docs/ai-dlc/<identifier>/<artifact>.md` に配置
3. `shared-artifacts/references/<name>.md` の指針に従ってプレースホルダを全て埋める
4. Specialist が Main に成果物パス + 要約を返却
5. Main が `shared-artifacts/references/<name>.md` の品質基準で成果物をレビュー
6. 不十分なら**同じ Specialist インスタンス**にフィードバックを差し戻し（終了させない）
7. ユーザー承認ゲートがあれば、Main が成果物そのものを提示して承認を得る（一時レポートは作らない）

### コミット規約

成果物はステップ完了時に確実にリポジトリへ反映する。詳細は `main-workflow` の「ステップ完了時のコミット規約」を参照。

### 再開時の扱い

別セッション／別ユーザーが中断済みサイクルを再開する際、`docs/ai-dlc/<identifier>/` 配下のファイル群だけで文脈を完全復元できる設計になっている。再開プロトコルの詳細は `main-workflow` の「セッション再開時」を参照。

---

## このスキルが扱わないこと

- ワークフロー手順（ステップの進め方・コミット規約・再開プロトコル） → `main-workflow` / `main-inception` / `main-construction` / `main-verification`
- Specialist の役割定義・失敗モード → `specialist-*` スキル
- Specialist 共通ルール → `specialist-common`
- エージェント起動エントリポイント → `agents/*.md`
- 成果物以外のドキュメント（CLAUDE.md 等のプロジェクトドキュメント）

---

## 発火の想定例（Triggering Test）

**Should trigger:**

- 「`intent-spec.md` の書き方を教えて」「`design.md` のテンプレートをコピーしたい」
- Main が「Step 4 の成果物をレビューしたい」と判断した場面
- Specialist が成果物作成前に書き方と品質基準を確認する場面

**Should NOT trigger:**

- 「Inception フェーズを開始して」 → `main-inception`
- 「architect としてレビューして」 → `specialist-architect`
- 「CLAUDE.md を更新して」 → このスキルの対象外
