# Workflow CLI — Proposal

> Status: pre-cycle proposal (not yet promoted to a formal `intent-spec.md`)
> Author: drafted automatically based on user request `feat/workflow-cli`
> Scope: `dev-workflow` plugin の `progress.yaml` / `TODO.md` 等を更新する CLI を新設し、将来的に他ワークフローも同居できる構造にする

## 1. 目的

`dev-workflow` の Main エージェントが各ステップ完了時に編集する `progress.yaml` / `TODO.md` には以下の課題がある:

- 手書き YAML/Markdown 編集はミスが起きやすい (タイムスタンプ、ISO8601、リスト記法、`active_specialists` の状態遷移など)
- スキーマ違反を Main 側で発見できないため、`shared-artifacts` reference との整合が壊れていても気づきにくい
- 完了手順 (TODO.md 更新 → コミット → TaskUpdate の順、`re_activations` インクリメント等) が**手順化された定型操作**であるにもかかわらず CLI 化されていない
- 別セッション再開時、`progress.yaml` を機械的に検証する手段がない

そこで以下を提供する CLI を導入する:

1. `progress.yaml` のスキーマ検証付き読み書き
2. `TODO.md` の構造化編集 (タスク開始 / 完了 / 再活性化)
3. サイクルディレクトリの初期化 (テンプレート展開)
4. 状態遷移の単一エントリポイント (Main の作業を 1 コマンドに集約)

将来的に他ワークフロー (例: リリース手順、ADR 起票、リファクタ計画) を補助する CLI を同居させられるよう、**ワークフロー名前空間を切る構造**を採用する。

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
    │       ├── init.ts
    │       ├── status.ts
    │       ├── advance.ts
    │       ├── approve.ts
    │       ├── rollback.ts
    │       ├── blocker/
    │       │   ├── add.ts
    │       │   └── resolve.ts
    │       ├── specialist/
    │       │   ├── start.ts
    │       │   └── end.ts
    │       ├── artifact/
    │       │   ├── set.ts
    │       │   └── add.ts
    │       ├── complete-step.ts
    │       ├── validate.ts
    │       ├── scaffold.ts
    │       └── todo/
    │           ├── init.ts
    │           ├── start.ts
    │           ├── complete.ts
    │           ├── reactivate.ts
    │           ├── append.ts
    │           └── show.ts
    ├── lib/
    │   ├── cycle-resolver.ts # docs/dev-workflow/<id>/ の解決
    │   ├── plugin-paths.ts   # shared-artifacts テンプレ位置の解決
    │   ├── yaml-doc.ts       # コメント保持 YAML AST 操作
    │   ├── timestamp.ts      # ISO8601 (UTC, 秒精度) ヘルパ
    │   └── flags.ts          # 共通 --cycle / --root フラグ
    ├── schema/
    │   ├── progress.ts       # progress.yaml の Schema
    │   ├── todo.ts           # TODO.md の構造化モデル
    │   └── task-plan.ts      # task-plan.md からの抽出スキーマ
    └── service/
        ├── progress-rw.ts    # progress.yaml CRUD (yaml-doc 経由)
        ├── todo-rw.ts        # TODO.md CRUD
        ├── template-render.ts# テンプレ {{x}} 置換
        └── task-plan-parse.ts# task-plan.md → 初期 TODO 候補抽出
```

将来別ワークフロー (`release`, `adr-bulk`, `refactor-plan` 等) を追加する場合は `src/cli/<workflow>/` にディレクトリを足し、`bin.ts` のサブコマンド配列に追加するだけで拡張できる。共通基盤 (`yaml-doc`, `cycle-resolver`, `template-render`) は再利用可能。

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
    "yaml": "^2.6.x"            // ← 新規。コメント保持できる唯一現実的な選択
  },
  "devDependencies": {
    "@totto2727/fp": "workspace:*",
    "vite-plus": "catalog:"
  }
}
```

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

#### サイクル管理

| コマンド                                                     | 役割                                                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| `wfx dev-workflow init <identifier> [--from-template]`        | `docs/dev-workflow/<identifier>/` を作成し `progress.yaml` を初期化 (status: active) |
| `wfx dev-workflow status [--cycle <id>]`                      | 現在ステップ / 完了ステップ / 活性 Specialist / Blocker / Pending Gate を一覧表示    |
| `wfx dev-workflow validate [--cycle <id>]`                    | `progress.yaml` のスキーマ検証 + 一貫性チェック (artifact パスの実在等)              |
| `wfx dev-workflow set-step <step>`                            | `current_step` を更新                                                                 |
| `wfx dev-workflow complete-step <step> --artifact <path>...`  | `completed_steps` に追加 + `artifacts.<field>` 更新 + `updated_at` 刷新              |
| `wfx dev-workflow approve <gate-name> [--note <text>]`        | `user_approvals` に追記                                                               |
| `wfx dev-workflow rollback --from <step> --to <step> --reason <text>` | `rollbacks` に追記 + `current_step` を `<to>` に戻す                          |

#### Blocker / Specialist / Artifact

| コマンド                                                                              | 役割                                                                                 |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `wfx dev-workflow blocker add "<text>"`                                                | `blockers` に追記                                                                    |
| `wfx dev-workflow blocker resolve <id\|index>`                                         | `blockers` から削除                                                                  |
| `wfx dev-workflow specialist start --name <role> --task "<text>"`                      | `active_specialists` に `running` を追加                                             |
| `wfx dev-workflow specialist block --name <role> [--task "<text>"]`                    | 既存 Specialist を `blocked` に遷移                                                   |
| `wfx dev-workflow specialist end --name <role> [--task "<text>"]`                      | 完了として `active_specialists` から削除 (`completed_steps` への記録は別コマンド)     |
| `wfx dev-workflow artifact set <field> <path>`                                         | スカラー artifacts (`intent_spec`, `design`, `qa_design`, ...) を更新                |
| `wfx dev-workflow artifact add <field> <path>`                                         | リスト artifacts (`research`, `review`, `external_adrs`) に追記                      |

#### TODO 管理 (Step 6〜7 用)

| コマンド                                                                       | 役割                                                                              |
| ------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| `wfx dev-workflow todo init [--from task-plan.md]`                              | `task-plan.md` を解析して `TODO.md` を生成 (全タスク `pending`)                   |
| `wfx dev-workflow todo start <task-id> --implementer <id>`                      | 当該タスクを `in_progress` に。`started_at` と `implementer` を記録               |
| `wfx dev-workflow todo complete <task-id> --commit <sha>`                       | `[x]` に。`completed_at` と `commit` を記録                                        |
| `wfx dev-workflow todo reactivate <task-id>`                                    | `completed` → `in_progress` に戻し `re_activations` をインクリメント              |
| `wfx dev-workflow todo append --id T<n> --title "<t>" --reason "<r>" [--deps T1,T2]` | 後発追加タスクを「後発追加タスク」セクションに追記                          |
| `wfx dev-workflow todo show [--filter pending\|in_progress\|completed]`          | TODO.md の現在状態を表形式で表示                                                  |

#### スキャフォルド

| コマンド                                                                             | 役割                                                                              |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| `wfx dev-workflow scaffold <artifact-name> [--into <relative-path>]`                  | `shared-artifacts/templates/<name>.md` を `docs/dev-workflow/<id>/` 配下にコピー |
| `wfx dev-workflow scaffold list`                                                      | 利用可能なテンプレ一覧を表示                                                      |

### 4.3 共通フラグ

| フラグ                  | 役割                                                                                   |
| ----------------------- | -------------------------------------------------------------------------------------- |
| `--cycle <identifier>`  | 対象サイクルの明示指定。未指定時は active なものを自動検出 (複数あればエラーで指示要求) |
| `--root <path>`         | リポジトリルートの上書き (テスト用 / monorepo 外利用)                                   |
| `--dry-run`             | 書き込みを行わず差分のみ表示 (差分プレビュー)                                            |
| `--json`                | 出力を JSON 化 (status / show 系で有用、エージェントから扱いやすく)                     |

### 4.4 終了コード規約

- `0`: 成功
- `1`: スキーマ違反 / バリデーションエラー (validate コマンド含む)
- `2`: ファイル未存在 / サイクル未検出
- `3`: 入力引数の論理エラー (例: `complete <id>` に未知の task-id)
- `64`: 使い方ミス (`--help` 推奨ケース)

---

## 5. 仕組みとして実装が必要な要素

### 5.1 コメント保持 YAML 操作 (`lib/yaml-doc.ts`)

`progress.yaml` のテンプレ (`shared-artifacts/templates/progress.yaml`) は**説明コメントを大量に含む** (各フィールドの記述例が `#` で書かれている)。一般的な `JSON.parse` ライクな serialize ではコメントが失われる。

**採用案: `yaml` パッケージ (`eemeli/yaml` v2)**

- `parseDocument()` で AST レベルのドキュメントを取得
- `Document.toJSON()` でアプリ側の plain object として読み取り
- 編集後は `Document.contents` を直接操作 → `Document.toString()` で書き戻し
- → コメント・空行・リスト記法 (`-`) を維持可能

`yaml-doc.ts` に最小ラッパを置く:

```ts
export const load: (path: string) => Effect.Effect<{ doc: Document; data: ProgressYaml }, ProgressYamlError>
export const save: (path: string, doc: Document) => Effect.Effect<void>
export const setScalar: (doc: Document, key: string, value: unknown) => void
export const appendList: (doc: Document, key: string, value: unknown) => void
```

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

### 5.4 TODO.md の構造化編集 (`service/todo-rw.ts`)

TODO.md は markdown チェックボックス + ネストされた key:value インデント形式 (`shared-artifacts/templates/TODO.md` 参照)。

**採用案: マークダウンを正として双方向パース**

- パース: チェックボックス行 + 子インデント行を正規表現で抽出 → 構造化モデル化
- 書き込み: 構造化モデル → 既存テンプレ風レイアウトで再生成
- リスク: ユーザー手動編集による形式崩れ → `validate` コマンドで検出して直す
- 代替案 (採用しない): サイドカー JSON を真のソースに。シンプルだが「TODO.md が真のソース」という skill 設計と矛盾するため不採用

サポートするタスク属性: `status` / `dependencies` / `started_at` / `completed_at` / `commit` / `implementer` / `re_activations` / `notes`

### 5.5 task-plan.md パーサ (`service/task-plan-parse.ts`)

`todo init` の入力。`task-plan.md` の構造化部分 (タスク表) を抽出してタスク ID + タイトル + 依存リストを生成する。`shared-artifacts/templates/task-plan.md` のフォーマットに合わせる。

**初期実装方針:** タスク表の Markdown table を正規表現で抽出 (テンプレ依存)。将来テンプレが変わった際の脆さがあるため、`task-plan.md` 側に `<!-- wfx:task -->` HTML コメントマーカを入れる選択肢も検討可。

### 5.6 テンプレートレンダリング (`service/template-render.ts`)

- 入力: テンプレファイルパス + 値マップ
- 動作: `{{key}}` を素朴に置換 (EJS は導入しない、shared-artifacts のテンプレ仕様に合わせる)
- 値未指定の placeholder はそのまま残す (Specialist が後で埋める前提のため)

### 5.7 プラグインパス解決 (`lib/plugin-paths.ts`)

- ローカル monorepo 利用時: `<repo-root>/plugins/dev-workflow/skills/shared-artifacts/templates/<name>.md`
- 外部利用時 (将来): `c-plugin` のロックファイル機構と連動可能性を残すが、初期は monorepo 内固定パスでよい
- フラグで上書き可能にする: `--plugin-root <path>`

### 5.8 原子的書き込み

`c-plugin/service/lock-file.ts` のパターンを `lib/yaml-doc.ts` / `service/todo-rw.ts` で踏襲 (`writeFile` → `rename`)。

### 5.9 タイムスタンプ統一 (`lib/timestamp.ts`)

`progress.yaml` の `_at` フィールドは UTC ISO8601 を要求。`new Date().toISOString()` で十分だが、テスト用に `Clock` サービスを Effect で注入できるようにラップ。

### 5.10 git 連携

**初期方針: CLI 自身は git 操作をしない**。状態変更後に推奨コミットメッセージを stdout に出すだけに留める:

```
$ wfx dev-workflow todo complete T1 --commit abc1234
✓ Updated docs/dev-workflow/.../TODO.md
Suggested commit:
  git add docs/dev-workflow/<id>/TODO.md docs/dev-workflow/<id>/progress.yaml
  git commit -m "docs(dev-workflow/<id>): complete task T1"
```

理由:
- Pre-commit hook / GPG 署名 / コミット規約の柔軟性を保つ
- メモリ「git commit must run outside sandbox (pre-commit hooks need file write)」と整合
- Main エージェントが規約に応じてコミットを発行できればよい

将来 `--commit` フラグでオプトイン実行は追加余地あり。

### 5.11 テスト戦略

`bw` / `c-plugin` と同じく Vitest による単体テスト中心:

- `service/progress-rw.test.ts`: YAML round-trip / コメント保持 / フィールド更新の不変性
- `service/todo-rw.test.ts`: 状態遷移 / 再活性化カウンタ / 後発追加タスクの追記
- `service/task-plan-parse.test.ts`: テンプレ通りのタスク表からの抽出
- `lib/cycle-resolver.test.ts`: 単一 / 複数 / 0 件のサイクル検出

統合テストは `test/integration/` に置くオプション (実ファイルシステム operation を tmpdir で) — 初期は単体のみで可。

---

## 6. 拡張性の担保

### 6.1 ワークフロー追加時のチェックリスト

新ワークフロー (例: `release`) を追加する場合:

1. `src/cli/release/` 配下にコマンド群を追加
2. `src/schema/release/` に対応する Schema を追加
3. `src/service/` の共通モジュール (`yaml-doc`, `template-render`, `cycle-resolver`) はそのまま再利用
4. `src/bin.ts` のサブコマンド配列に `releaseCommand` を追加
5. プロジェクト固有の plugin (`plugins/release/skills/...`) と plugin-paths.ts を連動

### 6.2 共通化を意識する API 境界

- `yaml-doc`: 任意の YAML ドキュメントに使える汎用ラッパ。`progress.yaml` 専用化しない
- `template-render`: `{{key}}` 置換のみ。ワークフロー無依存
- `cycle-resolver`: 引数として `<docs-root>` を取る形に抽象化 (`docs/dev-workflow` をハードコードしない)

これにより将来 `docs/release/<version>/` のような別ディレクトリにも転用可能。

### 6.3 エージェント側の利用更新

CLI 完成後、`dev-workflow` skill の以下を更新する (本提案では実装しない、Step 6 以降で):

- 「ステップ完了時のコミット規約」セクションに CLI コマンド例を併記
- `shared-artifacts/references/progress-yaml.md` / `todo.md` に「CLI による更新を推奨」と注記

---

## 7. リスクと留意点

| リスク                                           | 対策                                                                          |
| ------------------------------------------------ | ----------------------------------------------------------------------------- |
| YAML コメント保持がライブラリ依存                | `yaml` パッケージ (eemeli) は de facto standard、ロングタームメンテも安定    |
| TODO.md 双方向パースの脆さ                       | `validate` コマンドで形式崩れを早期検出。テンプレ側に `<!-- wfx -->` 補助    |
| task-plan.md パースのテンプレ依存                | テンプレ変更時の対応コストを Retrospective に蓄積。マーカ方式への移行検討     |
| `effect/unstable/cli` の不安定 API               | bw / c-plugin が既に同じ API を採用済み、追従コストは monorepo 横断で済む    |
| Main エージェントの学習コスト (CLI vs 手書き)    | 初期は両方許容、CLI 動作が安定したら skill 側で CLI 推奨に切り替え          |
| サンドボックス内で `--cycle` 自動検出の glob 失敗 | `--cycle` 明示を推奨、エラーメッセージで `--cycle` 指定を促す                |

---

## 8. 確認したい事項 (ユーザー判断ポイント)

帰宅後に判断いただきたい項目:

1. **CLI 名: `wfx` で確定してよいか** (代替: `wf` / `dwf` / その他)
2. **パッケージ配置: `js/app/wfx/` でよいか** (`js/package/` に置く案もあり、ただし bin を持つので `app/` が妥当)
3. **YAML ライブラリ: `yaml` パッケージを catalog 化** (`yaml-tools.yaml` カテゴリ新設)
4. **dev-workflow ディレクトリのパス: `docs/dev-workflow/` を前提でよいか** (プロジェクトによっては `doc/specs/` 等にしたい場合の対応指針)
5. **git 連携: 初期は「推奨コマンド出力のみ」とする方針でよいか** (将来 `--commit` 実行モード追加の余地は残す)
6. **タスクパース: `task-plan.md` の Markdown table 形式に依存することの是非** (テンプレ変更時の脆さを許容するか、HTML マーカを入れるか)
7. **TODO.md の真ソース方針: 「TODO.md を正・サイドカー JSON 不採用」の方針でよいか** (skill 設計との整合は維持)

---

## 9. 次ステップ案 (ユーザー承認後)

承認が得られたら、`dev-workflow` の正式 Step 1 に昇格させる:

1. 本 `proposal.md` を `intent-spec.md` に再構成 (本 Section 1 / 8 が intent / 成功基準に対応)
2. `progress.yaml` を初期化して Step 1 〜 Step 10 を回す
3. Step 2 (Research) で `effect/unstable/cli` 最新 API / `yaml` パッケージ最新版の確認
4. Step 3 (Design) で本提案を `design.md` に再構成 (本 Section 3〜6 を反映)
5. Step 4 (QA Design) でテストケース表 / qa-flow を作成
6. Step 5 (Task Decomposition) で本提案 Section 3.2 のディレクトリを単位に分解
7. Step 6 以降を順次実行

---

## 10. 参考にした既存実装

- `js/app/c-plugin/src/bin.ts` — サブコマンドツリーの組み方
- `js/app/c-plugin/src/cli/skill/sync.ts` — Effect.gen + Service 呼び出し
- `js/app/c-plugin/src/service/lock-file.ts` — Schema 検証 + 原子的書き込み
- `js/app/c-plugin/src/lib/paths.ts` — パス解決ヘルパ
- `js/app/bw/src/bin.ts` — 並列サブコマンド合成
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md` — ワークフロー全体仕様
- `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md` — `progress.yaml` 正準仕様
- `plugins/dev-workflow/skills/shared-artifacts/references/todo.md` — `TODO.md` 正準仕様
- `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml` / `templates/TODO.md` — テンプレ
