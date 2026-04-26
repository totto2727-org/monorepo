# Workflow CLI — Proposal

> Status: pre-cycle proposal (not yet promoted to a formal `intent-spec.md`)
> Author: drafted automatically based on user request `feat/workflow-cli`
> Scope: `dev-workflow` plugin の `progress.yaml` を更新する CLI を新設し、将来的に他ワークフローの構造化ファイル (YAML / JSON) も同居できる構造にする
> Revision: 2026-04-26 r4 — author feedback を反映:
> - r2: 「コメント保持は不要・必要なら明示パラメータ・既存形式は CLI 都合で変更可」
> - r3: 「Markdown は管理しにくいので CLI 対象外」(TODO.md / task-plan.md など Markdown ファイルは CLI が触らない)
> - r4: 「汎用 CRUD ではなく、各 skill / agent が実際に呼び出す操作のみを対象にする。ただしサブコマンドは構造化する」

## 設計原則 (本提案の前提)

1. **機械可読性ファースト**: CLI が扱うのは構造化フォーマット (YAML / JSON) のみ。Markdown は人間が直接編集する対象とし、CLI は触らない
2. **説明は明示パラメータ**: 「なぜそうしたか」の補足が必要な操作は CLI 引数 (`--note`, `--reason` 等) として受け取り、構造化フィールドに格納する
3. **コメントによる注釈は持たない**: YAML 内のコメントは CLI で管理しない。フィールド意味の説明は `shared-artifacts/references/progress-yaml.md` 側に一元化する
4. **既存テンプレ・reference はリファクタリング対象**: `shared-artifacts/templates/progress.yaml` の説明コメントは CLI 化に合わせて削除・整理する
5. **操作意図ファースト (汎用 CRUD は持たない)**: CLI のサブコマンドは「skill / agent が実際に行う 1 操作」と 1:1 対応させる。任意フィールドを書き換える `set <field> <value>` のような汎用編集は提供しない。これにより skill 側のドキュメントと CLI コマンドが互いに対応づき、Main エージェントが操作を選びやすくなる
6. **サブコマンドの構造化**: 操作はドメインで階層化する (`cycle` / `step` / `gate` / `specialist` / `blocker`)。ドメイン内の操作は動詞で並べる (`init` / `complete` / `approve` 等)

## 1. 目的

`dev-workflow` の Main エージェントが各ステップ完了時に編集する `progress.yaml` には以下の課題がある:

- 手書き YAML 編集はミスが起きやすい (タイムスタンプ、ISO8601、リスト記法、`active_specialists` の状態遷移など)
- スキーマ違反を Main 側で発見できないため、`shared-artifacts` reference との整合が壊れていても気づきにくい
- 状態遷移の手順 (`completed_steps` 追記 → `current_step` 更新 → `updated_at` 刷新 → `artifacts.<field>` 反映) が**定型操作**であるにもかかわらず CLI 化されていない
- 別セッション再開時、`progress.yaml` を機械的に検証する手段がない

そこで以下を提供する CLI を導入する:

1. `progress.yaml` のスキーマ検証付き読み書き
2. サイクルディレクトリの初期化 (`progress.yaml` のスケルトン生成)
3. 状態遷移の単一エントリポイント (Main の作業を 1 コマンドに集約)
4. 進捗の表示 / 検証コマンド

将来的に他ワークフロー (例: リリース手順、ADR 起票、リファクタ計画) を補助する CLI を同居させられるよう、**ワークフロー名前空間を切る構造**を採用する。

### 対象外 (CLI が触らないもの)

- **Markdown ファイル全般** (`TODO.md` / `intent-spec.md` / `design.md` / `task-plan.md` / `qa-design.md` / `qa-flow.md` / `*-report.md` / `retrospective.md` 等)
  - 理由: Markdown は構造化フォーマットでないため CLI からシステマチックに扱いにくい。Specialist と Main が手で編集する従来運用を維持
  - 例外: 将来 `progress.yaml` 以外でも構造化 (YAML / JSON) フォーマットの管理ファイルが追加された場合は CLI 対象に含める

---

## 2. 既存 CLI 実装の分析 (`bw` / `c-plugin`)

| 観点                | 採用パターン                                                                                  |
| ------------------- | --------------------------------------------------------------------------------------------- |
| ランタイム          | Effect (`effect@beta`) + `effect/unstable/cli`                                                |
| エントリ            | `src/bin.ts` で `Command.run` → `Effect.runFork` / `NodeRuntime.runMain`                      |
| ディレクトリ構成    | `src/bin.ts` / `src/cli/<group>/<cmd>.ts` / `src/lib/` / `src/schema/` / `src/service/`       |
| サブコマンド合成    | `Command.make('group').pipe(Command.withSubcommands([...]))` を `bin.ts` でツリー化           |
| Flag / Argument     | `Flag.boolean()` / `Argument.string()` / `Prompt.select` / `Prompt.multiSelect`               |
| パッケージ          | `package.json#bin` + `vite-plus` (`vp pack`) で `dist/bin.mjs` を生成                         |
| 命名                | 単語ベース (`bw`, `c-plugin`)、`@totto2727/<name>` スコープ、`workspace:*` で内部依存         |
| Schema              | `effect/Schema` で `Schema.Struct` 定義 → `Schema.decodeUnknownEffect` で検証                 |
| 永続化              | tmp ファイルに書いて `Fs.rename` で原子的差し替え (`c-plugin/service/lock-file.ts`)           |
| 設定読み書き        | `read` で `Effect.orElseSucceed(emptyXxx)` で空状態フォールバック (`c-plugin` lock-file 参照) |
| 内部依存            | `@totto2727/fp` (workspace), `vite-plus` (dev), `@effect/platform-node` (catalog:effect)      |
| 設定ファイル        | `vite.config.ts` で `defineConfig({ pack: { entry: ['src/bin.ts'] } })`                       |
| imports field       | `#@/*` → `./src/*` で内部参照を統一                                                           |
| テスト              | Vitest (`*.test.ts`) でサービス層単位                                                         |

CLI 新設はこのテンプレートを踏襲する。**新たに必要となる外部依存は YAML パーサのみ**。

---

## 3. パッケージ設計

### 3.1 命名

候補 (短さと識別性のバランス):

| 案    | bin 名 | パッケージ名               | 評価                                                    |
| ----- | ------ | -------------------------- | ------------------------------------------------------- |
| `wf`  | `wf`   | `@totto2727/wf`            | 短い。`wf` は他 OSS 衝突あり (`workflow.kts` 等)        |
| `wfx` | `wfx`  | `@totto2727/wfx`           | bw / vpx と命名トーンが揃う。衝突少                     |
| `dwf` | `dwf`  | `@totto2727/dwf`           | dev-workflow に寄りすぎ、汎用化したい意図とずれる       |

**推奨: `wfx`** (workflow-execution の略。bw / vpx と同じ短縮トーン)。

### 3.2 パッケージレイアウト

```
js/app/wfx/
├── package.json              # @totto2727/wfx, bin: { wfx: ./dist/bin.mjs }
├── vite.config.ts            # defineConfig({ pack: { entry: ['src/bin.ts'] } })
├── tsconfig.json
└── src/
    ├── bin.ts                # トップレベル CLI の合成
    ├── cli/
    │   └── dev-workflow/     # ワークフロー名前空間
    │       ├── index.ts      # 'dev-workflow' Command の集約
    │       ├── cycle/
    │       │   ├── init.ts        # サイクル新規作成
    │       │   ├── status.ts      # 現在地表示
    │       │   ├── resume.ts      # 再開マーカ (updated_at 更新)
    │       │   ├── close.ts       # サイクル完了 (status: completed)
    │       │   └── validate.ts    # 整合性検証
    │       ├── step/
    │       │   ├── advance.ts     # 次ステップへ進む (current_step 更新)
    │       │   ├── complete.ts    # ステップ完了 (completed_steps 追記)
    │       │   └── rollback.ts    # ロールバック (rollbacks 追記 + current_step 戻し)
    │       ├── gate/
    │       │   ├── request.ts     # ユーザー承認待ち登録 (pending_gates 追記)
    │       │   └── approve.ts     # 承認記録 (user_approvals 追記 + pending_gates から削除)
    │       ├── specialist/
    │       │   ├── start.ts       # Specialist 起動記録 (running)
    │       │   ├── block.ts       # blocked 遷移
    │       │   └── end.ts         # 役割終了
    │       └── blocker/
    │           ├── add.ts         # 単独追加 (Specialist 経由でない場合)
    │           └── resolve.ts     # 解消
    ├── lib/
    │   ├── cycle-resolver.ts # docs/dev-workflow/<id>/ の解決
    │   ├── timestamp.ts      # ISO8601 (UTC, 秒精度) ヘルパ
    │   └── flags.ts          # 共通 --cycle / --root フラグ
    ├── schema/
    │   └── progress.ts       # progress.yaml の Schema
    └── service/
        └── progress-rw.ts    # progress.yaml read / update / write (Schema + tmp→rename)
```

将来別ワークフロー (`release`, `adr-bulk`, `refactor-plan` 等) を追加する場合は `src/cli/<workflow>/` にディレクトリを足し、`bin.ts` のサブコマンド配列に追加するだけで拡張できる。共通基盤 (`cycle-resolver`, `timestamp`, `flags`, `progress-rw` 相当) は再利用可能。

`shared-artifacts/templates/progress.yaml` の物理コピーは行わず、`cycle init` コマンドはスキーマから空のオブジェクトを構築して書き出す (`shared-artifacts` 側のテンプレも将来は削除可。`reference` 側だけが仕様の正本となる)。

### 3.3 依存関係

```jsonc
// package.json (抜粋)
{
  "name": "@totto2727/wfx",
  "bin": { "wfx": "./dist/bin.mjs" },
  "type": "module",
  "imports": { "#@/*": "./src/*" },
  "scripts": {
    "build": "vp pack",
    "bin": "node dist/bin.mjs",
    "check": "pnpm run --parallel /check:.*/"
  },
  "dependencies": {
    "@effect/platform-node": "catalog:effect",
    "effect": "catalog:effect",
    "yaml": "^2.6.x"            // ← 新規。プレーン YAML round-trip 用
  },
  "devDependencies": {
    "@totto2727/fp": "workspace:*",
    "vite-plus": "catalog:"
  }
}
```

`yaml` パッケージは `parse` / `stringify` のみを使う**最小利用**。コメント保持・AST 操作機能は使わず、`Schema` で正規化された JS オブジェクトを stringify する。

新規 catalog エントリの提案: `pnpm-workspace.yaml` の `catalogs` に `yaml-tools.yaml: ^2.6.x` を追加 (将来別パッケージでも使えるよう catalog 化)。

---

## 4. CLI コマンド設計

### 4.1 トップレベル

```
wfx <workflow> <subcommand> [flags]
wfx --version
wfx --help
```

現状は `wfx dev-workflow ...` のみ。将来 `wfx release ...` 等を追加可能。

### 4.2 `wfx dev-workflow` サブコマンド一覧

CLI が触るのは `progress.yaml` のみ。Markdown 系成果物 (`TODO.md` / `intent-spec.md` 等) は対象外。
**各サブコマンドは dev-workflow skill の特定操作と 1:1 対応する** (Section 4.3 のマッピング表参照)。汎用的な「任意フィールド書き換え」は提供しない。

#### `cycle` — サイクル全体のライフサイクル

| コマンド                                                       | 役割                                                                              | dev-workflow 内の対応箇所                  |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------ |
| `wfx dev-workflow cycle init <identifier>`                      | サイクルディレクトリ作成 + `progress.yaml` を Schema から初期化 (`status: active`) | 「ワークフロー開始時」                      |
| `wfx dev-workflow cycle status [--cycle <id>] [--json]`         | 現在ステップ / 完了ステップ / 活性 Specialist / Blocker / Pending Gate を表示    | 「セッション再開時」「各ステップ進行中」    |
| `wfx dev-workflow cycle resume [--cycle <id>]`                  | `updated_at` を現在時刻に更新 (再開マーカ)                                        | 「セッション再開時」                        |
| `wfx dev-workflow cycle close [--cycle <id>]`                   | `status: completed` に更新                                                        | Step 10 完了時                              |
| `wfx dev-workflow cycle validate [--cycle <id>]`                | スキーマ検証 + 一貫性チェック (`artifacts` のパス実在等)                          | 整合性確認 (任意・CI 連携想定)              |

#### `step` — ステップ進行

| コマンド                                                                                               | 役割                                                                          | dev-workflow 内の対応箇所                |
| ------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------- | ---------------------------------------- |
| `wfx dev-workflow step advance <step-name>`                                                             | `current_step` を `<step-name>` に更新                                        | 各ステップ着手時                          |
| `wfx dev-workflow step complete <step-name> [--artifact <field>=<path>]...`                             | `completed_steps` 追記 + `artifacts.<field>` 更新 + `updated_at` 刷新         | 「ステップ完了時のコミット規約」          |
| `wfx dev-workflow step rollback --from <step> --to <step> --reason <text>`                              | `rollbacks` 追記 + `current_step` を `<to>` に戻す                            | 「ロールバック先早見表」                  |

`--artifact` の `<field>` は Schema で定義された `artifacts.*` のキー (`intent_spec` / `research` / `design` / `qa_design` / `qa_flow` / `task_plan` / `todo` / `self_review` / `review` / `validation` / `retrospective` / `external_adrs`)。スカラーかリストかは Schema が判断し、自動で適切に書き込む。

#### `gate` — ユーザー承認ゲート

| コマンド                                                            | 役割                                                                          | dev-workflow 内の対応箇所            |
| ------------------------------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------ |
| `wfx dev-workflow gate request <gate-name>`                          | `pending_gates` に追記                                                        | ユーザー承認ゲート手前               |
| `wfx dev-workflow gate approve <gate-name> [--note <text>]`          | `user_approvals` 追記 + `pending_gates` から削除                              | 「ゲート通過時 (ユーザー承認ゲート)」 |

#### `specialist` — Specialist インスタンスの状態管理

| コマンド                                                                         | 役割                                                                                      | dev-workflow 内の対応箇所             |
| -------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------- |
| `wfx dev-workflow specialist start --name <role> --task "<text>"`                 | `active_specialists` に `running` 追加                                                    | Specialist 起動時                      |
| `wfx dev-workflow specialist block --name <role> [--task "<text>"] [--reason <text>]` | 既存 Specialist を `blocked` に遷移 (`--reason` 指定時は `blockers` にも追記)            | 「Blocker 発生時」                    |
| `wfx dev-workflow specialist end --name <role> [--task "<text>"]`                 | 役割終了として `active_specialists` から削除                                              | ステップ完了時 / Specialist 役割終了時 |

#### `blocker` — Specialist 経由でない Blocker

| コマンド                                                                          | 役割                                                                                      | dev-workflow 内の対応箇所                                  |
| --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| `wfx dev-workflow blocker add "<text>"`                                            | `blockers` に単独追記 (Specialist 経由でない場面)                                         | 「Blocker 発生時」(Main 自身が検知した場合)                |
| `wfx dev-workflow blocker resolve <index>`                                         | 指定インデックスを `blockers` から削除                                                    | Blocker 解消後                                              |

### 4.3 dev-workflow skill / agent との対応マッピング

| 呼び出すドキュメント (skill / agent)                       | 想定タイミング                                  | 対応 CLI コマンド                                                                  |
| ---------------------------------------------------------- | ----------------------------------------------- | ---------------------------------------------------------------------------------- |
| `dev-workflow` SKILL「ワークフロー開始時」                  | サイクル新規開始                                | `cycle init <identifier>`                                                          |
| `dev-workflow` SKILL「セッション再開時」 step 1〜2           | progress.yaml 読み込み + 状態確認               | `cycle status`                                                                     |
| `dev-workflow` SKILL「セッション再開時」 step 8              | `updated_at` 更新                               | `cycle resume`                                                                     |
| 各 Specialist 起動時 (Main が `specialist-*` 起動)          | 役割・タスク・status を記録                     | `specialist start --name <role> --task "<text>"`                                   |
| Specialist が Blocker 報告 (`specialist-common` 失敗時挙動) | `active_specialists.status` 遷移 + Blocker 記録 | `specialist block --name <role> --reason "<text>"`                                 |
| ステップ完了時 (Main が Exit Criteria 充足判定)             | `completed_steps` + `artifacts.*` + `updated_at` | `step complete "<step-name>" --artifact <field>=<path> ...`                       |
| Specialist 役割終了時                                       | `active_specialists` から削除                   | `specialist end --name <role>`                                                     |
| ユーザー承認ゲート手前                                      | 待ち状態を可視化                                | `gate request <gate-name>`                                                         |
| ユーザー承認ゲート通過                                      | 承認履歴を記録                                  | `gate approve <gate-name> [--note "<text>"]`                                       |
| ロールバック発生時                                          | `rollbacks` + `current_step` 戻し               | `step rollback --from "<step>" --to "<step>" --reason "<text>"`                    |
| Main 自身が Blocker を検知                                  | Specialist 経由でない単独追記                   | `blocker add "<text>"`                                                             |
| Blocker 解消                                                | リストから削除                                  | `blocker resolve <index>`                                                          |
| Step 10 完了 / サイクル完了                                 | `status: completed`                             | `cycle close`                                                                      |
| 整合性チェック (任意 / pre-commit hook で利用想定)          | スキーマ違反検出                                | `cycle validate`                                                                   |

新たな skill / agent 操作が CLI 化を必要としない場合は YAML を書き換えない設計にする (CLI が必要となった時点で初めて新サブコマンドを追加)。

### 4.4 共通フラグ

| フラグ                  | 役割                                                                                   |
| ----------------------- | -------------------------------------------------------------------------------------- |
| `--cycle <identifier>`  | 対象サイクルの明示指定。未指定時は active なものを自動検出 (複数あればエラーで指示要求) |
| `--root <path>`         | リポジトリルートの上書き (テスト用 / monorepo 外利用)                                   |
| `--dry-run`             | 書き込みを行わず差分のみ表示 (差分プレビュー)                                            |
| `--json`                | 出力を JSON 化 (`cycle status` 等で有用、エージェントから扱いやすく)                    |

### 4.5 終了コード規約

- `0`: 成功
- `1`: スキーマ違反 / バリデーションエラー (`cycle validate` 含む)
- `2`: ファイル未存在 / サイクル未検出
- `3`: 入力引数の論理エラー (例: `step complete` で未知の `<step-name>`、`gate approve` で `pending_gates` に存在しないゲート名)
- `64`: 使い方ミス (`--help` 推奨ケース)

---

## 5. 仕組みとして実装が必要な要素

### 5.1 YAML 読み書き (`service/progress-rw.ts`)

**方針: プレーン YAML round-trip**。コメントは保持しない。

- 読み込み: `Fs.readFile` → `YAML.parse(content)` → `Schema.decodeUnknown(ProgressYaml)`
- 書き込み: `Schema.encode(ProgressYaml)` → `YAML.stringify(value, options)` → tmp ファイル → `Fs.rename`

`yaml` パッケージ (`eemeli/yaml`) を使うが、`parse` / `stringify` の標準 API のみ。AST 操作・コメント保持は使わない。

```ts
export const read: (path: string) => Effect.Effect<ProgressYaml, ProgressYamlError>
export const write: (path: string, value: ProgressYaml) => Effect.Effect<void>
export const update: (
  path: string,
  fn: (current: ProgressYaml) => ProgressYaml,
) => Effect.Effect<ProgressYaml, ProgressYamlError>
```

`update` で「読み → 純粋関数で変形 → 書き戻し」を 1 ステップに集約。各サブコマンドはこの関数に変形ロジックを渡すだけになる。

**`shared-artifacts/templates/progress.yaml` の改訂方針 (本提案実装と同時に実施):**

- 説明コメント (`# active | completed | blocked` 等) を全て削除
- 各フィールドの意味は `shared-artifacts/references/progress-yaml.md` に集約 (既に書かれている)
- テンプレファイル自体も将来削除可能 (CLI が Schema からスケルトンを生成するため、コピー元として不要になる)

### 5.2 スキーマ定義 (`schema/progress.ts`)

```ts
export const ActiveSpecialist = Schema.Struct({
  name: Schema.String,
  task: Schema.String,
  status: Schema.Literals(['running', 'blocked']),
  started_at: Schema.String, // ISO8601
})

export const CompletedStep = Schema.Struct({
  step: Schema.String,
  completed_at: Schema.String,
  artifacts: Schema.Array(Schema.String),
})

export const Artifacts = Schema.Struct({
  intent_spec: Schema.NullOr(Schema.String),
  research: Schema.Array(Schema.String),
  design: Schema.NullOr(Schema.String),
  qa_design: Schema.NullOr(Schema.String),
  qa_flow: Schema.NullOr(Schema.String),
  external_adrs: Schema.Array(Schema.String),
  task_plan: Schema.NullOr(Schema.String),
  todo: Schema.NullOr(Schema.String),
  self_review: Schema.NullOr(Schema.String),
  review: Schema.Array(Schema.String),
  validation: Schema.NullOr(Schema.String),
  retrospective: Schema.NullOr(Schema.String),
})

export const ProgressYaml = Schema.Struct({
  identifier: Schema.String,
  started_at: Schema.String,
  updated_at: Schema.String,
  status: Schema.Literals(['active', 'completed', 'blocked']),
  current_step: Schema.String,
  completed_steps: Schema.Array(CompletedStep),
  pending_gates: Schema.Array(Schema.String),
  active_specialists: Schema.Array(ActiveSpecialist),
  blockers: Schema.Array(Schema.String),
  artifacts: Artifacts,
  user_approvals: Schema.Array(/* ... */),
  rollbacks: Schema.Array(/* ... */),
})
```

`reference/progress-yaml.md` に書かれているフィールド定義をそのまま反映。Schema による検証は読み込み直後と書き込み直前の双方で実行する。

### 5.3 サイクルリゾルバ (`lib/cycle-resolver.ts`)

- 入力: `--cycle <id>` または未指定
- 動作:
  1. `<repo-root>/docs/dev-workflow/<id>/progress.yaml` を直接探す (id 指定時)
  2. 未指定時: `docs/dev-workflow/*/progress.yaml` を glob → `status: active` のものを抽出
  3. 0 件 → 「init してください」エラー
  4. 1 件 → そのサイクル
  5. 2 件以上 → エラーで `--cycle` を要求

リポジトリルートは `git rev-parse --show-toplevel` または `--root` フラグで上書き。

### 5.4 原子的書き込み

`c-plugin/service/lock-file.ts` のパターンを `service/progress-rw.ts` で踏襲 (`writeFile(tmp)` → `rename(tmp, path)`)。失敗時に既存ファイルを破損させないため。

### 5.5 タイムスタンプ統一 (`lib/timestamp.ts`)

`progress.yaml` の `_at` フィールドは UTC ISO8601 を要求。`new Date().toISOString()` で十分だが、テスト用に Effect の `Clock` サービスを介して注入できるよう薄くラップする。

### 5.6 git 連携

**初期方針: CLI 自身は git 操作をしない**。状態変更後に推奨コミットメッセージを stdout に出すだけに留める:

```
$ wfx dev-workflow complete-step "Step 1: Intent Clarification" \
    --artifact intent_spec=docs/dev-workflow/<id>/intent-spec.md
✓ Updated docs/dev-workflow/<id>/progress.yaml
Suggested commit:
  git add docs/dev-workflow/<id>/intent-spec.md docs/dev-workflow/<id>/progress.yaml
  git commit -m "docs(dev-workflow/<id>): complete Step 1 (Intent Clarification)"
```

理由:
- Pre-commit hook / GPG 署名 / コミット規約の柔軟性を保つ
- Main エージェントが規約に応じてコミットを発行できればよい (CLI は YAML 編集に専念)

将来 `--commit` フラグでオプトイン実行を追加する余地はあるが、初期スコープには含めない。

### 5.7 テスト戦略

`bw` / `c-plugin` と同じく Vitest による単体テスト中心:

- `service/progress-rw.test.ts`: YAML round-trip / Schema 検証エラー / 部分更新の不変性 (関係ないフィールドが書き換わらないこと)
- `lib/cycle-resolver.test.ts`: 単一 / 複数 / 0 件のサイクル検出
- 各サブコマンド (`cli/dev-workflow/*.ts`) の純粋変形関数: 入力 ProgressYaml + 引数 → 期待出力 ProgressYaml

統合テストは `test/integration/` に置くオプション (実ファイルシステム operation を tmpdir で) — 初期は単体のみで可。

---

## 6. 拡張性の担保

### 6.1 ワークフロー追加時のチェックリスト

新ワークフロー (例: `release`) を追加する場合:

1. `src/cli/release/` 配下にコマンド群を追加
2. `src/schema/release/` に対応する Schema を追加 (構造化ファイル前提)
3. `src/lib/cycle-resolver.ts` / `src/service/progress-rw.ts` 等の共通モジュールは再利用 (パス引数化されているため)
4. `src/bin.ts` のサブコマンド配列に `releaseCommand` を追加

### 6.2 共通化を意識する API 境界

- `cycle-resolver`: 引数として `<docs-root>` を取る形に抽象化 (`docs/dev-workflow` をハードコードしない)
- `progress-rw`: 「Schema 制約付き YAML round-trip」という汎用処理に抽象化可能。将来 `release-rw` 等を作る際に共通モジュールへ昇格させる
- `timestamp` / `flags`: ワークフロー無依存

これにより将来 `docs/release/<version>/state.yaml` のような別構造ファイルにも転用可能。

### 6.3 エージェント側の利用更新

CLI 完成後、`dev-workflow` skill の以下を更新する (本提案では実装しない、後続サイクルで):

- 「ステップ完了時のコミット規約」セクションに CLI コマンド例を併記
- `shared-artifacts/references/progress-yaml.md` に「CLI による更新を必須/推奨」と注記
- `shared-artifacts/templates/progress.yaml` の説明コメントを削除 (Section 5.1 の改訂方針)

---

## 7. リスクと留意点

| リスク                                                       | 対策                                                                                                  |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `effect/unstable/cli` の不安定 API                           | bw / c-plugin が既に同じ API を採用済み、追従コストは monorepo 横断で済む                            |
| Main エージェントの学習コスト (CLI vs 手書き)                | 初期は両方許容、CLI 動作が安定したら skill 側で CLI 必須に切り替え                                   |
| サンドボックス内で `--cycle` 自動検出の glob 失敗            | `--cycle` 明示を推奨、エラーメッセージで `--cycle` 指定を促す                                        |
| `shared-artifacts/templates/progress.yaml` 改訂と既存サイクルの非互換 | 既存サイクルの `progress.yaml` は Schema が後方互換なら追加更新不要。non-null 化等の破壊変更時は `validate` で検出 |
| 並列 Specialist が同時に CLI を呼ぶレース                    | tmp→rename で原子的書き込みは保証されるが、最終勝者の上書き問題は残る。Step 6 並列実装での同時更新パターンを設計時に確認 |

---

## 8. 確認したい事項 (ユーザー判断ポイント)

帰宅後に判断いただきたい項目:

1. **CLI 名: `wfx` で確定してよいか** (代替: `wf` / `dwf` / その他)
2. **パッケージ配置: `js/app/wfx/` でよいか** (`js/package/` に置く案もあり、ただし bin を持つので `app/` が妥当)
3. **YAML ライブラリ: `yaml` パッケージを catalog 化してよいか** (`yaml-tools.yaml` カテゴリ新設)
4. **dev-workflow ディレクトリのパス: `docs/dev-workflow/` を前提でよいか** (プロジェクトによっては別パスにしたい場合は `--root` フラグで対応)
5. **git 連携: 初期は「推奨コマンド出力のみ」とする方針でよいか** (将来 `--commit` 実行モード追加の余地は残す)
6. **`shared-artifacts/templates/progress.yaml` の改訂を本提案実装に含めてよいか** (説明コメント削除 + 将来の物理テンプレ廃止)
7. **`shared-artifacts/references/progress-yaml.md` の更新方針** (CLI 必須 / 推奨 / 任意 のいずれにするか)
8. **既存サイクル (`docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap` / `2026-04-26-add-qa-design-step`) の `progress.yaml` をスキーマ準拠に整合させるかどうか** (CLI 投入時の移行作業の要否)
9. **Section 4.3 のマッピング表は dev-workflow skill の「Main 操作」を漏れなく拾えているか** (不足操作があれば該当サブコマンド追加。例: `pending_gates` への遷移を `gate request` で十分か、`step complete` 内に統合すべきか等)
10. **`step advance` を別コマンドとして切り出すか、`step complete` の自動次ステップ計算に統合するか** (skill 上は別工程として記述されているため独立コマンドが順当だが、現状 Main は `current_step` 設定だけのために 2 コマンド呼ぶことになる)

---

## 9. 次ステップ案 (ユーザー承認後)

承認が得られたら、`dev-workflow` の正式 Step 1 に昇格させる:

1. 本 `proposal.md` を `intent-spec.md` に再構成 (本 Section 1 / 8 が intent / 成功基準に対応)
2. `progress.yaml` を初期化して Step 1 〜 Step 10 を回す
3. Step 2 (Research) で `effect/unstable/cli` 最新 API / `yaml` パッケージ最新版の確認
4. Step 3 (Design) で本提案を `design.md` に再構成 (本 Section 3〜6 を反映)
5. Step 4 (QA Design) でテストケース表 / qa-flow を作成
6. Step 5 (Task Decomposition) で本提案 Section 3.2 のディレクトリを単位に分解
7. Step 6 以降を順次実行 (`shared-artifacts/templates/progress.yaml` の改訂タスクも含む)

---

## 10. 参考にした既存実装

- `js/app/c-plugin/src/bin.ts` — サブコマンドツリーの組み方
- `js/app/c-plugin/src/cli/skill/sync.ts` — Effect.gen + Service 呼び出し
- `js/app/c-plugin/src/service/lock-file.ts` — Schema 検証 + 原子的書き込み
- `js/app/c-plugin/src/lib/paths.ts` — パス解決ヘルパ
- `js/app/bw/src/bin.ts` — 並列サブコマンド合成
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md` — ワークフロー全体仕様
- `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md` — `progress.yaml` 正準仕様
- `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml` — 既存テンプレ (本提案で改訂対象)
