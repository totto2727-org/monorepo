---
name: share-artifacts
description: >
  [Main / Specialist 共通] dev-workflow ワークフローで作成する全成果物の目次と仕様を提供する。
  各成果物の書き方（references/）とテンプレート（templates/）が 1:1 で対応する。
  Main がステップ進行時に、Specialist が成果物作成時に、それぞれ該当ドキュメントを
  参照して統一された形式で成果物を作成・評価できるようにする。
  起動トリガー: 成果物の作成・レビュー・参照を行うすべての場面。Main / Specialist 共通。
  "成果物の書き方", "ドキュメントテンプレート", "share-artifacts" で参照可能。
  Do NOT use for: ワークフロー手順（dev-workflow スキル）、Specialist の役割定義
  （specialist-* スキル）、成果物以外のドキュメント作成。
allowed-tools: Read, Glob, Grep
---

# Shared Artifacts — dev-workflow 成果物リファレンス

ユースケースカテゴリ: **Document & Asset Creation**（成果物の仕様と雛形を集約する目次スキル）
設計パターン: **Domain Intelligence**（成果物ドメインの書き方と品質基準を埋め込む）

dev-workflow ワークフローで作成される全成果物について、**書き方ガイド（`share-artifacts/references/`）とテンプレート（`share-artifacts/templates/`）**を集約する。

**パス表記ルール:** 本スキル内で成果物ファイルを参照する際は、プラグインルートからの相対パス `share-artifacts/references/<name>.md` / `share-artifacts/templates/<name>.md` で統一表記する（他スキルからの参照と同じ形式）。

**ファイル名の 1:1 対応と例外:** references と templates は**原則として同名ファイルで対応**する（例: `references/intent-spec.md` ↔ `templates/intent-spec.md`）。以下 3 件は意図的な例外で、目次表のカラム対応で紐付ける:

- `references/progress-yaml.md` ↔ `templates/progress.yaml`（書き方ガイドは Markdown、テンプレートは YAML として読み込まれる前提のため拡張子が異なる）
- `references/todo.md` ↔ `templates/TODO.md`（`TODO.md` は成果物としての慣用的大文字表記を踏襲。reference 側はファイル名規則の kebab-case を優先）
- `references/roadmap-progress-yaml.md` ↔ `templates/roadmap-progress.yaml`（dev-roadmap 用の進捗 YAML。書き方ガイドは Markdown、テンプレートは YAML として読み込まれる前提のため拡張子が異なる。`progress.yaml` と同じ理由）

これら 3 件以外で同名対応が崩れる成果物を追加してはならない。

## 前提

- Main が成果物を管理し、Specialist が作成する
- 各成果物は `docs/workflow/<identifier>/` 配下に保存される（詳細: `dev-workflow` の「成果物保存構造」）
- references と templates は **1:1 対応**。同名ファイルで紐付く
- Specialist はテンプレートを埋める際に必ず対応する reference を参照する
- Main は成果物をレビューする際に対応する reference を品質基準として使う

## 成果物一覧（目次）

| #   | 成果物                                       | Phase / Step          | 作成者 (Specialist)                    | Reference                                              | Template                                              |
| --- | -------------------------------------------- | --------------------- | -------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------- |
| 1   | `progress.yaml`                              | 全サイクル            | (Main が維持)                          | `share-artifacts/references/progress-yaml.md`         | `share-artifacts/templates/progress.yaml`            |
| 2   | `intent-spec.md`                             | Step 1                | `intent-analyst`                       | `share-artifacts/references/intent-spec.md`           | `share-artifacts/templates/intent-spec.md`           |
| 3   | `research/<topic>.md`                        | Step 2                | `researcher` (観点ごと並列)            | `share-artifacts/references/research-note.md`         | `share-artifacts/templates/research-note.md`         |
| 4   | `design.md`                                  | Step 3                | `architect`                            | `share-artifacts/references/design.md`                | `share-artifacts/templates/design.md`                |
| 5   | `qa-design.md`                               | Step 4                | `qa-analyst`                           | `share-artifacts/references/qa-design.md`             | `share-artifacts/templates/qa-design.md`             |
| 6   | `qa-flow.md`                                 | Step 4                | `qa-analyst`                           | `share-artifacts/references/qa-flow.md`               | `share-artifacts/templates/qa-flow.md`               |
| 7   | `task-plan.md`                               | Step 5                | `planner`                              | `share-artifacts/references/task-plan.md`             | `share-artifacts/templates/task-plan.md`             |
| 8   | `TODO.md`                                    | Step 6〜7 全体        | (Main が維持、`task-plan.md` から生成) | `share-artifacts/references/todo.md`                  | `share-artifacts/templates/TODO.md`                  |
| 9   | `implementation-logs/<id>.md`                | Step 6                | `implementer` (タスクごと並列)         | `share-artifacts/references/implementation-log.md`    | `share-artifacts/templates/implementation-log.md`    |
| 10  | `review/<aspect>.md`                         | Step 7                | `reviewer` (6 観点並列)                | `share-artifacts/references/review-report.md`         | `share-artifacts/templates/review-report.md`         |
| 11  | `validation-report.md`                       | Step 8                | `validator`                            | `share-artifacts/references/validation-report.md`     | `share-artifacts/templates/validation-report.md`     |
| 12  | `docs/retrospective/<id>.md`                 | Step 9 (集約)         | `retrospective-writer`                 | `share-artifacts/references/retrospective.md`         | `share-artifacts/templates/retrospective.md`         |
| 13  | `roadmap.md`                                 | dev-roadmap Step 1    | `roadmap-analyst`                      | `share-artifacts/references/roadmap.md`               | `share-artifacts/templates/roadmap.md`               |
| 14  | `milestones/<milestone-id>.md`               | dev-roadmap Step 2    | `roadmap-planner`                      | `share-artifacts/references/milestone.md`             | `share-artifacts/templates/milestone.md`             |
| 15  | `roadmap-progress.yaml`                      | dev-roadmap Step 1〜4 | (Main / dev-workflow 自律更新)         | `share-artifacts/references/roadmap-progress-yaml.md` | `share-artifacts/templates/roadmap-progress.yaml`    |
| 16  | `docs/retrospective/roadmap-<roadmap-id>.md` | dev-roadmap Step 4    | `roadmap-retrospective-writer`         | `share-artifacts/references/roadmap-retrospective.md` | `share-artifacts/templates/roadmap-retrospective.md` |
| 17  | PR description (GitHub のみ永続)             | 全サイクル (各 Step)  | (Main が `gh pr edit` で送信)          | `share-artifacts/references/pr-body.md`               | `share-artifacts/templates/pr-body.md`               |

## Reference と Template の使い分け

### Reference（`share-artifacts/references/<name>.md`）

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

### Template（`share-artifacts/templates/<name>.md`）

**埋めるべき雛形**。プレースホルダは `{{name}}` 形式（将来 EJS 等に移行可能）。

- Specialist はテンプレートをコピーして `docs/workflow/<identifier>/` 配下に配置し、プレースホルダを埋める
- プレースホルダはすべて埋めるか、該当なしなら明示的に「N/A」等を記述する

## 使い方

### Specialist が成果物を作成するとき

1. 対応する `share-artifacts/references/<name>.md` を読み、書き方を理解する
2. `share-artifacts/templates/<name>.md` をコピーして `docs/workflow/<identifier>/<artifact>.md` に配置
3. プレースホルダを埋める（references の指針に従う）
4. 完成したら Main に返却

### Main が成果物をレビューするとき

1. 対応する `share-artifacts/references/<name>.md` の品質基準を参照
2. 成果物が基準を満たしているかチェック
3. 不足があれば該当 Specialist に差し戻し（新規インスタンス作成ではなく同一インスタンスにフィードバック）

## Reference / Template の変更ルール

- Reference を更新したら、Template も同じ観点で整合性を確認する（1:1 対応を維持）
- 新規成果物を追加する場合は、Reference と Template の両方を同時に追加し、SKILL.md の目次に登録する
- プロジェクト固有のカスタマイズが必要な場合は、該当プロジェクトで派生バージョンを作らず、このプラグインの本体を更新する方針を原則とする

---

## 成果物保存構造（サイクル作業ディレクトリ）

dev-workflow の成果物および進捗記録は、**サイクルごとに独立したディレクトリに集約**してリポジトリにコミットする。これにより**作業の中断と再開**が可能になる（別のセッションが同一ディレクトリを読めば現在地を把握できる）。

### ディレクトリ構造

```
docs/workflow/<identifier>/
├── progress.yaml              # 進捗記録（Main が各ターンで更新）
├── intent-spec.md             # Step 1 成果物
├── research/                  # Step 2 成果物（観点ごとにファイル分割）
│   ├── <topic-1>.md
│   └── ...
├── design.md                  # Step 3 成果物（設計ドキュメント本体）
├── qa-design.md               # Step 4 成果物（テストケース集合 + カバレッジ表）
├── qa-flow.md                 # Step 4 成果物（本質ロジック分岐 Mermaid flowchart）
├── task-plan.md               # Step 5 成果物（planner が生成した不変なタスク分解）
├── TODO.md                    # Step 6 進行中のタスク状態（Main が維持）
├── implementation-logs/       # Step 6 の長大な動作確認ログ（必要な場合のみ）
│   └── <task-id>.md
├── review/                    # Step 7 成果物（6 観点ごとにファイル分割）
│   ├── security.md
│   ├── performance.md
│   ├── readability.md
│   ├── test-quality.md
│   ├── api-design.md
│   └── holistic.md
├── validation-report.md       # Step 8 成果物
└── validation-evidence/       # Step 8 の大きな証跡（必要な場合のみ）
    └── <evidence-file>
```

Step 9 (Retrospective) の成果物 `<identifier>.md` はサイクル作業ディレクトリ外の `docs/retrospective/` に集約 (詳細は後述「サイクル外の成果物」)。

各ファイルの詳細な書き方は `share-artifacts/references/<name>.md` を参照。

### roadmap 作業ディレクトリ

`dev-roadmap` スキル配下のロードマップ成果物は、サイクル作業ディレクトリ (`docs/workflow/<identifier>/`) と**並列配置**される独立ディレクトリ `docs/roadmap/<roadmap-id>/` に集約する。配下 `dev-workflow` サイクル群と物理的に分離されることで、戦略層 (roadmap) と戦術層 (workflow サイクル) が互いの作業ディレクトリを汚染せずに並走できる。

```
docs/roadmap/<roadmap-id>/
├── roadmap.md                  # dev-roadmap Step 1 成果物（ロードマップ全体像）
├── milestones/                 # dev-roadmap Step 2 成果物（マイルストーンごとにファイル分割）
│   ├── <milestone-id-1>.md
│   └── ...
└── roadmap-progress.yaml       # dev-roadmap Step 1〜4 を通じて継続更新される進捗記録
```

Step 4 (Roadmap Retrospective) の成果物 `roadmap-<roadmap-id>.md` はロードマップ作業ディレクトリ外の `docs/retrospective/` に集約 (詳細は後述「サイクル外の成果物」)。配下 `dev-workflow` サイクルの成果物 (`docs/workflow/<identifier>/`) は本ディレクトリに含めず、`roadmap-progress.yaml.milestones[].workflow_identifiers[]` を介して双方向に紐付ける。

#### `<roadmap-id>` の命名ルール

`<identifier>` と同様にプロジェクトごとに決める。使用候補:

- 戦略目標名（例: `oauth-platform`, `multi-tenant-foundation`）
- 日付 + スラッグ（例: `2026-04-29-payment-overhaul`）
- ロードマップチケット ID（例: `EPIC-1234`）

ロードマップ起動時に Main がユーザーと合意して決定する。配下 `dev-workflow` サイクルの `<identifier>` と命名衝突しないよう留意する (集約 `docs/retrospective/` で `roadmap-` prefix により衝突回避する。後述「サイクル外の成果物」参照)。

### `<identifier>` の命名ルール

プロジェクトごとに決める。使用候補:

- チケット ID（例: `JIRA-1234`, `issue-567`）
- 機能名（例: `user-auth-refactor`, `oauth-support`）
- 日付 + スラッグ（例: `2026-04-24-cache-layer`）

サイクル開始時に Main がユーザーと合意して決定する。命名ルールがプロジェクトで既に決まっていればそれを踏襲する。

### サイクル外の成果物

以下はサイクル作業ディレクトリ (`docs/workflow/<identifier>/`) **外**に保存される:

#### サイクル境界を越える ADR (General / Roadmap mode)

- **保存場所:**
  - **General mode** (複数 roadmap / 独立した複数 dev-workflow サイクル / プロジェクト全体に効く判断): `docs/adr/<YYYY-MM-DD-title>.md`
  - **Roadmap mode** (単一 roadmap 配下の複数サイクルが共有する判断): `docs/roadmap/<roadmap-id>/adr/<YYYY-MM-DD-title>.md`
- **起票条件:** サイクル内で発生した判断が**現サイクルを越えて影響する**場合のみ。モード判定 (どちらの保存先に置くか) は `share-adr/SKILL.md` の「モード判定フロー」、`design.md` 内に書くべきか ADR を起票するべきかは `share-artifacts/references/design.md` の「ADR 起票の判定基準」参照
- **サイクルからの参照:** `progress.yaml.artifacts.external_adrs` にパスを記録 (General / Roadmap mode どちらも同列に列挙、scope は ADR 本体 frontmatter `scope: general` / `scope: roadmap:<roadmap-id>` で識別)、`design.md` からリンクを張る
- **ライフサイクル:** 永続。`confirmed: true` 化後は不変 (詳細フォーマット・運用ルールは `share-adr/SKILL.md` に集約)

#### Retrospective (Step 9 成果物)

- **保存場所:** `docs/retrospective/<identifier>.md`（`docs/adr/` 同パターンの集約ディレクトリ）
- **作成タイミング:** Step 9 完了時に `retrospective-writer` が生成
- **ライフサイクル:** **揮発**。次サイクルが改善案項目を消化した時点で削除する一時的な報告ボックス。永続記録すべき判断は ADR に切り出す
- **ADR との対比:** ADR は永続記録 (`confirmed: true` で不変)、retrospective は揮発レポート

`dev-roadmap` Step 4 の roadmap retrospective も同じ集約ディレクトリ `docs/retrospective/roadmap-<roadmap-id>.md` に保存される (`roadmap-` prefix で配下 `dev-workflow` サイクルの `<identifier>.md` と命名衝突を回避)。詳細は `share-artifacts/references/roadmap-retrospective.md` を参照。

#### In-Progress ユーザー問い合わせ用一時レポート

- **保存場所:** `$TMPDIR/dev-workflow/<phase>-<step>-<purpose>.md`
- **役割:** 作業途中のユーザー判断要請（Blocker 対応、選択肢提示等）のみ使用。ステップ完了時の承認ゲートには使わない
- **コミット:** **しない**。Retrospective で件数・トピックのサマリのみ `retrospective.md` に反映
- **使い分けの詳細:** `dev-workflow` の「基本方針」セクション（Artifact-as-Gate-Review / Report-Based Confirmation for In-Progress Questions）を参照

#### PR description (`#17`、揮発成果物 + GitHub 永続)

- **テンプレート:** `share-artifacts/templates/pr-body.md`、書き方ガイド: `share-artifacts/references/pr-body.md`
- **揮発生成先:** `$TMPDIR/dev-workflow/<identifier>-pr-body.md` (Main が `gh pr edit --body-file` で送信する直前に再生成)
- **永続先:** GitHub PR body (リポジトリ内には永続化しない、Single-Source-of-Progress 原則)
- **更新タイミング:** サイクル初期化時 + 各ステップ完了コミット直後 (必須、9 回) + 適宜
- **責任所在:** Main 専属 (`specialist-common §7` 参照、Specialist は `gh pr edit` を実行しない)
- **PR 操作手順 (write/read 全般):** `share-pr-manager` スキル参照
- **CI status セクションの埋め方:** `share-ci-monitoring` スキル参照

---

## 成果物のライフサイクル

### 作成から承認まで

1. Main が該当 Specialist を起動（テンプレート・reference・入力成果物のパスを伝える）
2. Specialist が `share-artifacts/templates/<name>.md` をコピーして `docs/workflow/<identifier>/<artifact>.md` に配置
3. `share-artifacts/references/<name>.md` の指針に従ってプレースホルダを全て埋める
4. Specialist が Main に成果物パス + 要約を返却
5. Main が `share-artifacts/references/<name>.md` の品質基準で成果物をレビュー
6. 不十分なら**同じ Specialist インスタンス**にフィードバックを差し戻し（終了させない）
7. ユーザー承認ゲートがあれば、Main が成果物そのものを提示して承認を得る（一時レポートは作らない）

### コミット規約

成果物はステップ完了時に確実にリポジトリへ反映する。詳細は `dev-workflow` の「ステップ完了時のコミット規約」を参照。

### 再開時の扱い

別セッション／別ユーザーが中断済みサイクルを再開する際、`docs/workflow/<identifier>/` 配下のファイル群だけで文脈を完全復元できる設計になっている。再開プロトコルの詳細は `dev-workflow` の「セッション再開時」を参照。

---

## このスキルが扱わないこと

- ワークフロー手順（ステップの進め方・コミット規約・再開プロトコル） → `dev-workflow`
- Specialist の役割定義・失敗モード → `specialist-*` スキル
- Specialist 共通ルール → `specialist-common`
- エージェント起動エントリポイント → `agents/*.md`
- 成果物以外のドキュメント（CLAUDE.md 等のプロジェクトドキュメント）

---

## 発火の想定例（Triggering Test）

**Should trigger:**

- 「`intent-spec.md` の書き方を教えて」「`design.md` のテンプレートをコピーしたい」
- Main が「Step 5 の成果物をレビューしたい」と判断した場面
- Specialist が成果物作成前に書き方と品質基準を確認する場面

**Should NOT trigger:**

- 「Step 1〜5 (Intent Clarification 〜 Task Decomposition)を開始して」 → `dev-workflow`
- 「architect としてレビューして」 → `specialist-architect`
- 「CLAUDE.md を更新して」 → このスキルの対象外
