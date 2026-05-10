# Research Note: Cloudflare Workers + wrangler を 1 プロジェクト内で複数 entry に分割し、個別デプロイ可能にするパターン調査

- **Identifier:** feed-platform-ms-01-workspace-foundation
- **Topic:** wrangler-multi-entry-monorepo
- **Researcher:** researcher (single instance)
- **Created at:** 2026-05-04
- **Scope:** `feed-platform-backend` の SC-5 (≥ 2 件の `worker.ts` + `wrangler.jsonc` ペア) を Cloudflare Workers + wrangler 構成で実現するための、1 pnpm-workspace パッケージ内 multi-entry 配置パターン

## Subject of investigation

Intent Spec Q2.9 / Q2.10 / Q2.12 で確定した「`feed-platform-backend` = 1 パッケージ + 内部に複数 worker.ts + wrangler.jsonc のペア = 各 entry が個別デプロイ可能」という要件を満たすための、具体パターン (ディレクトリ配置 / wrangler コマンド呼び出し / Vite+ task 整え方 / 型生成戦略) を調査する。スコープは backend の multi-entry 構造に限定。Web フロント (`feed-platform-web`) の Hono+Remix v3 構成、Effect 統合、Vite+ task system 一般論には触れない。

## Findings

### 1. 既存 monorepo 内の multi-entry 実装の有無

- 既存 `js/app/*` 配下で「1 パッケージに 複数 `worker.ts` + 複数 `wrangler.jsonc`」を持つ実装は **存在しない**。
  - `find js/ -name 'wrangler.jsonc' -not -path '*/node_modules/*'` の結果は 3 件のみで、すべて 1 パッケージ = 1 wrangler.jsonc:
    - `js/app/saas-example/wrangler.jsonc`
    - `js/app/rss-graphql/wrangler.jsonc`
    - `js/app/hono-remix-v3-cloudflare-example/wrangler.jsonc`
  - `find js/ -name 'worker.ts' -not -path '*/node_modules/*'` は **0 件**。既存は `entry.worker.ts` 命名 (例: `js/app/hono-remix-v3-cloudflare-example/app/entry.worker.ts:1`、`js/app/saas-example/src/entry.worker.ts`)。
- 結論: backend の multi-entry 配置は本リポジトリで前例がなく、ms-01 が **最初のリファレンス実装** となる。命名 (`worker.ts` vs `entry.worker.ts`) も既存規約と整合させるか新規に決めるか論点になる。

### 2. wrangler 公式の multi-config / multi-worker 機能

- wrangler は **すべてのコマンドにグローバル `--config` (`-c`) フラグ** を備え、デフォルト位置 (CWD の `wrangler.json` / `wrangler.jsonc`) 以外を指定できる。
  - 公式: 「`--config`: Path to Wrangler configuration file」(コマンド共通フラグ)
  - 例: `wrangler deploy --config ./src/bff/wrangler.jsonc`、`wrangler dev -c ./src/worker-input/wrangler.jsonc`
- `wrangler dev` は **複数 `-c` を渡して複数 Worker を 1 コマンドで同時起動** できる。最初の config が primary (`http://localhost:8787`) になり、残りは auxiliary worker として service binding 経由で参照可能。
  - 例: `wrangler dev -c ./app/wrangler.jsonc -c ./api/wrangler.jsonc`
- `wrangler deploy` は **1 コマンドで 1 worker のみ**。entry ごとに `wrangler deploy --config <path>` を別々に呼び出す必要がある (= 個別デプロイ可能の根拠)。
- 「環境機能」(`[env.production]` / `--env staging`) は **bindings が継承されない** 仕様で、本質的に「同じ worker の deploy variation」用途。**コードエントリ (`main`) を変える用途には適さず**、別 worker は別 `wrangler.jsonc` に分けるのが公式想定。

### 3. ディレクトリ配置パターン

公式 ci-cd advanced-setups の monorepo example は **`workers/<service-name>/` 直下に `wrangler.jsonc` + `src/`** を置く配置を提示:

```
ecommerce-monorepo/
├── workers/
│   ├── product-service/
│   │   ├── src/
│   │   └── wrangler.jsonc
│   ├── order-service/
│   │   ├── src/
│   │   └── wrangler.jsonc
│   └── notification-service/
│       ├── src/
│       └── wrangler.jsonc
├── packages/
│   └── schema/
└── README.md
```

これは「1 worker = 1 package」前提の配置。**1 package 内で multi-entry** にする場合、対応関係を保ちつつ「`src/<entry-name>/` ごとに `worker.ts` + `wrangler.jsonc`」とフォルダで隔離する派生形が直接的なマッピングとなる。

公式は「1 package + multi-entry」の specific layout を明示していないが、`wrangler.jsonc` の `main` は相対パスでよいため、配置自由度は高い。Intent Spec 例示 (`src/bff/worker.ts` + `src/bff/wrangler.jsonc`) はこの派生形そのもの。

### 4. ビルド成果物の出力先制御

- wrangler は entry ごとに **`wrangler.jsonc` と同じディレクトリの `.wrangler/` に build artifact を出す** (デフォルト)。`main` の解決とビルド出力は config ディレクトリ基準。
- `wrangler.jsonc` 内で `build.cwd` / `assets.directory` を相対指定すれば、各 entry が個別ディレクトリで完結する。
- backend は Hello World 相当 (Q2.10) で `assets` 不要、`vite build` 不要。**wrangler 直接実行 (`wrangler deploy --config ...`) のみで完結** する (Q2.12 確定)。Vite plugin (`@cloudflare/vite-plugin`) は web フロント側の責務であり、backend の multi-entry には不要。
- 結論: backend は entry ごとに `wrangler` 任せで OK。`vite build` を介さない分、出力先制御は wrangler の標準動作 (`.wrangler/` / `dist/` のデフォルト) に委ねるのが最小構成。

### 5. `wrangler dev` / `wrangler deploy` の起動コマンド

- 個別実行 (deploy 用):
  ```sh
  wrangler deploy --config src/bff/wrangler.jsonc
  wrangler deploy --config src/worker-input/wrangler.jsonc
  ```
- 個別実行 (dev 用、別ターミナル):
  ```sh
  wrangler dev --config src/bff/wrangler.jsonc
  wrangler dev --config src/worker-input/wrangler.jsonc
  ```
- 同時 dev (1 コマンドで両方起動、service binding 越し):
  ```sh
  wrangler dev -c src/bff/wrangler.jsonc -c src/worker-input/wrangler.jsonc
  ```
- 既存パッケージ (`hono-remix-v3-cloudflare-example/package.json:9-12`) は `"deploy": "wrangler deploy"` / `"start": "wrangler dev"` のように単一スクリプトを置く慣習。multi-entry では entry ごとに名前を分けたスクリプトを定義する (例: `deploy:bff` / `deploy:worker-input`) のが妥当。

### 6. TypeScript 型生成 (`wrangler types`)

- `wrangler types` は **デフォルトで `./worker-configuration.d.ts`** に出力。`PATH` 引数で出力先カスタマイズ可能 (`.d.ts` 拡張子必須)。
- bindings が entry ごとに異なるため、**entry ごとに別ファイルを生成** するのが安全:
  ```sh
  wrangler types --config src/bff/wrangler.jsonc src/bff/worker-configuration.d.ts
  wrangler types --config src/worker-input/wrangler.jsonc src/worker-input/worker-configuration.d.ts
  ```
- `--check` フラグで再生成不要チェックが可能 (CI 向け、exit code 0/1)。
- 既存 `js/app/saas-example/vite.config.ts:48-51` は `setup:cloudflare` task で `wrangler types` を呼ぶパターンが確立している:
  ```ts
  'setup:cloudflare': {
    command: 'wrangler types',
    input: taskInput.setup.cloudflare,
  }
  ```
  ms-01 backend では同じ task を **entry ごとに fan-out** し、`setup` で `dependsOn` 集約する形が自然。

### 7. Vite+ task system からの呼び出しパターン

既存 `js/app/saas-example/vite.config.ts:37-67` に **fan-out + dependsOn 集約** の参照実装が存在:

```ts
run: {
  tasks: {
    build: {
      command: 'vp build',
      dependsOn: ['setup'],
      input: taskInput.build,
    },
    setup: {
      command: '',
      dependsOn: ['setup:cloudflare', 'setup:kysely', 'setup:paraglide', 'setup:tsr'],
    },
    'setup:cloudflare': {
      command: 'wrangler types',
      input: taskInput.setup.cloudflare,
    },
    // ...
  },
}
```

- 親 task (`setup`) は空 `command: ''` + `dependsOn` でサブ task を fan-out
- 各サブ task は `input` で再実行条件を細かく制御 (`@totto2727/fp/vite` の `defineTaskInputFromOutput` で型安全に定義)
- backend の multi-entry にこのパターンを適用すれば、`setup:cloudflare:bff` / `setup:cloudflare:worker-input` を `setup` 親タスクで集約可能

### 8. 公式ドキュメント / 信頼できる外部記事 (取得日: 2026-05-04)

- [Wrangler Configuration](https://developers.cloudflare.com/workers/wrangler/configuration/) — `wrangler.jsonc` 仕様 (環境機能の継承不可など)
- [Wrangler Commands - General](https://developers.cloudflare.com/workers/wrangler/commands/general/) — `--config` グローバルフラグ
- [Wrangler Commands - Workers (`wrangler types`)](https://developers.cloudflare.com/workers/wrangler/commands/workers/) — 型生成コマンド仕様
- [Developing with multiple Workers](https://developers.cloudflare.com/workers/development-testing/multi-workers/) — `wrangler dev -c <path1> -c <path2>` の multi-config 起動と auxiliary worker 解説
- [Workers CI/CD - Advanced setups (Monorepo)](https://developers.cloudflare.com/workers/ci-cd/builds/advanced-setups/) — `workers/<service>/wrangler.jsonc` の monorepo ディレクトリ構造例
- 参考 (1 package = 1 worker 構成の monorepo 例): [kristianfreeman/lerna-wrangler-monorepo-example](https://github.com/kristianfreeman/lerna-wrangler-monorepo-example) — 本リポジトリのケース (1 package 内 multi-entry) とは構造が異なるが、wrangler を monorepo で扱う先行事例

公式は「1 package 内 multi-entry」の specific layout を明示していないが、(1) `--config` で任意パスを指定可能、(2) ci-cd advanced-setups の monorepo 例が `workers/<entry>/wrangler.jsonc` を示している、の 2 点から、本要件は wrangler の標準機能の組み合わせで成立する。

### 9. ms-01 で採用すべき具体パターンの推奨案

ディレクトリ配置 (Intent Spec Q2.10 例示と整合):

```
js/app/feed-platform-backend/
├── package.json
├── tsconfig.json
├── vite.config.ts
└── src/
    ├── bff/
    │   ├── worker.ts                      # entry: import → export default app
    │   ├── wrangler.jsonc                 # main: ./worker.ts, name: "feed-platform-backend-bff"
    │   └── worker-configuration.d.ts      # wrangler types で生成
    └── worker-input/
        ├── worker.ts
        ├── wrangler.jsonc                 # main: ./worker.ts, name: "feed-platform-backend-worker-input"
        └── worker-configuration.d.ts
```

- ファイル命名は Intent Spec 明記 (`worker.ts` + `wrangler.jsonc`) を優先。既存 `entry.worker.ts` 命名 (Web フロント / saas-example) と差異が出るが、これは「Web フロント = Vite + Remix 経由で 1 entry」「backend = wrangler 直 + multi-entry」の用途差を反映するもので許容範囲。
- 各 `wrangler.jsonc` の `main` は **相対パス** (`"./worker.ts"`) で記述。
- `name` は entry ごとに一意 (例: `feed-platform-backend-bff` / `feed-platform-backend-worker-input`)。

`package.json` scripts (entry ごとに分離):

```json
{
  "scripts": {
    "dev:bff": "wrangler dev --config src/bff/wrangler.jsonc",
    "dev:worker-input": "wrangler dev --config src/worker-input/wrangler.jsonc",
    "deploy:bff": "wrangler deploy --config src/bff/wrangler.jsonc",
    "deploy:worker-input": "wrangler deploy --config src/worker-input/wrangler.jsonc"
  }
}
```

Vite+ task 定義 (`vite.config.ts`、`saas-example` パターン踏襲):

```ts
import { defineTaskInputFromOutput } from '@totto2727/fp/vite'
import { defineConfig } from 'vite-plus'

const taskInput = defineTaskInputFromOutput({
  setup: {
    'cloudflare:bff': ['.wrangler/**', 'src/bff/worker-configuration.d.ts'],
    'cloudflare:worker-input': ['.wrangler/**', 'src/worker-input/worker-configuration.d.ts'],
  },
})

export default defineConfig({
  run: {
    tasks: {
      setup: {
        command: '',
        dependsOn: ['setup:cloudflare:bff', 'setup:cloudflare:worker-input'],
      },
      'setup:cloudflare:bff': {
        command: 'wrangler types --config src/bff/wrangler.jsonc src/bff/worker-configuration.d.ts',
        input: taskInput.setup['cloudflare:bff'],
      },
      'setup:cloudflare:worker-input': {
        command: 'wrangler types --config src/worker-input/wrangler.jsonc src/worker-input/worker-configuration.d.ts',
        input: taskInput.setup['cloudflare:worker-input'],
      },
    },
  },
})
```

- `build` task は **不要** (backend は wrangler 直で deploy 時にビルド)。SC-4 で `vp run -r build` 通過要件があるため、no-op `build` タスク (`command: ''` + dependsOn 空) を定義しておくか、`setup` を `build` の別名として置くかは Step 3 設計の判断材料。
- `check` / `fix` / `test` は monorepo 共通規約 (root の `vp check` / `vp test`) でカバーされるため、本パッケージ固有定義は不要 (Web フロント / saas-example も同様に未定義)。

SC-5 の達成確認:

```sh
find js/app/feed-platform-backend/src -name 'worker.ts' | wc -l           # ≥ 2
find js/app/feed-platform-backend/src -name 'wrangler.jsonc' | wc -l      # ≥ 2 かつ各 worker.ts と同ディレクトリ
```

## Sources

- 既存 monorepo 内 wrangler.jsonc 配置:
  - `js/app/hono-remix-v3-cloudflare-example/wrangler.jsonc:1-20`
  - `js/app/rss-graphql/wrangler.jsonc:1-17`
  - `js/app/saas-example/wrangler.jsonc:1-17`
- 既存 entry.worker.ts:
  - `js/app/hono-remix-v3-cloudflare-example/app/entry.worker.ts:1-3`
- Vite+ task fan-out 参照実装:
  - `js/app/saas-example/vite.config.ts:37-67` (`setup` 親 + `setup:cloudflare`/`setup:kysely`/`setup:paraglide`/`setup:tsr` のサブ task)
  - `js/app/hono-remix-v3-cloudflare-example/vite.config.ts:5-15` (最小構成)
- 既存 package.json scripts 慣習:
  - `js/app/hono-remix-v3-cloudflare-example/package.json:8-13` (`"deploy": "wrangler deploy"` / `"start": "wrangler dev"`)
  - `js/app/hono-remix-v3-cloudflare-example/CLAUDE.md` (各 script の役割と vp 経由の呼び出し方法)
- Intent Spec の確定事項:
  - `docs/workflow/feed-platform-ms-01-workspace-foundation/intent-spec.md:62-67` (Q2.9 — 1 プロジェクト + 複数サーバレス関数)
  - `docs/workflow/feed-platform-ms-01-workspace-foundation/intent-spec.md:70` (Q2.10 — `src/bff/worker.ts` + `src/bff/wrangler.jsonc` 例示)
  - `docs/workflow/feed-platform-ms-01-workspace-foundation/intent-spec.md:76-82` (Q2.12 — wrangler 直接実行 / Vite+ task 規約)
  - `docs/workflow/feed-platform-ms-01-workspace-foundation/intent-spec.md:139-140` (SC-5 観測仕様)
- 公式ドキュメント (取得日 2026-05-04、URL は Findings §8 参照):
  - Wrangler Configuration / Commands General / Commands Workers / multi-workers / ci-cd advanced-setups
- 関連 (1 package = 1 worker monorepo 先行事例): GitHub `kristianfreeman/lerna-wrangler-monorepo-example`

## Implications for design

Step 3 (Design) で `architect` が `design.md` を起こす際、以下を直接採用できる:

- **ディレクトリ配置を確定**: `src/<entry-name>/worker.ts` + `src/<entry-name>/wrangler.jsonc` の Intent Spec 例示形をそのまま採用。`workers/<entry-name>/` 形は backend の `src/` 構造との二重化を招くため不採用。
- **wrangler コマンド呼び出しは `--config <relative-path>` を使う**: 環境機能 (`--env`) は bindings が継承されない仕様のため不採用。entry ごとに完全独立した `wrangler.jsonc` で `main` / `name` / 将来の bindings を分離。
- **`wrangler types` は entry ごとに別ファイル生成**: `src/<entry>/worker-configuration.d.ts` に出力し、TypeScript の型解決を entry 内で閉じる。1 ファイル共有は将来 bindings が divergent した時点で破綻するため最初から分離。
- **Vite+ task は `saas-example` パターンを踏襲**: `setup` 親タスク + `setup:cloudflare:<entry>` サブタスクの fan-out。これにより SC-4 (`vp run -r build`) でも fan-out 経由で entry 横断の一貫性が確保される。
- **`build` task の取り扱いは Step 3 で判断**: backend は wrangler 直で deploy 時にビルドするため `build` 実体不要。ただし SC-4 の「ワークスペース全体ビルドが成功」観測で `vp run -r build` が backend を skip しないようにするため、no-op `build` (or `setup` を `build` 名で再エクスポート) の整え方は設計段階で確定。
- **`name` 命名規約**: `wrangler.jsonc.name` は Cloudflare 上で一意性を持つ deploy 単位。`feed-platform-backend-<entry>` のような prefix 付け規則を採用すれば、ms-01 以降の entry 増加にも整合する。
- **dev 起動の使い分け**: 単独 entry を試す場合は `wrangler dev --config <path>`、entry 間連携 (将来の service binding 追加時) は `wrangler dev -c <a> -c <b>` の同時起動。ms-01 では Hello World 相当のため単独で十分。
- **公式 monorepo example との差**: 公式は「1 package = 1 worker」を `workers/<service>/` で示すが、本サイクルは Q2.9 で「1 package + multi-entry」を確定済み。両者は wrangler 機能上は同等 (どちらも `--config` で個別呼び出し) であり、本案は Intent Spec 確定事項を優先。

## Remaining unknowns

Step 3 で詰める論点 (Blocker ではないが、Design で明示的判断が必要):

- **`build` task の no-op vs setup 再エクスポート**: SC-4 (`vp run -r build` 成功) 観測のために backend に `build` task を置くべきか / `command: ''` の no-op で済ませるか / `setup` を `build` で再定義するか。Web フロント (`feed-platform-web`) 側が Vite で `build` 実体を持つため、3 プロジェクト間の `build` 意味を揃える設計判断が必要。
- **`worker.ts` vs `entry.worker.ts` 命名**: Intent Spec は `worker.ts` を例示。既存 Web フロント / saas-example は `entry.worker.ts`。SC-5 観測 (`find ... -name 'worker.ts'`) は Intent Spec を字面通り採用しており、SC 字面遵守と既存命名統一のどちらを優先するか Step 3 で確定。本調査では Intent Spec 字面を尊重して `worker.ts` を推奨。
- **`wrangler.jsonc.name` 命名規約**: `feed-platform-backend-bff` 形 (本案推奨) vs `feed-platform-bff` 形 (バックエンドプレフィックス省略) vs `bff` 形 (パッケージ内一意のみ)。Cloudflare 上は account 単位の一意性のみ要件。Step 3 で命名規約として確定し ADR-01 に記録するのが適切。
- **`assets` / `compatibility_date` / `placement` 等のテンプレート設定**: 既存 (`hono-remix-v3-cloudflare-example/wrangler.jsonc:1-20`) は `compatibility_date: "2026-02-01"` / `placement.mode: "smart"` / `observability.enabled: true` を共通設定として持つ。backend multi-entry の各 `wrangler.jsonc` でこれを共通化する仕組み (継承 / コピペ / wrangler の include 機能の有無) は本調査範囲外。Step 3 で必要に応じて確認。
- **`setup` task の出力 path に `.wrangler/**`を含めることの是非**:`saas-example/vite.config.ts:13`は`.wrangler/\*\*`を`setup:cloudflare`の output に含めているが、multi-entry では`.wrangler/` がパッケージルート 1 個か entry ごとか、wrangler の挙動確認が必要。
