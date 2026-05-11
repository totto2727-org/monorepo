# Intent Spec: feed-platform Shared Libraries (ms-01 Phase 2)

- **Identifier:** feed-platform-ms-01-shared-libraries
- **Author:** totto2727 (Main 起草)
- **Created at:** 2026-05-07T03:55:00Z
- **Last updated:** 2026-05-07T05:30:00Z
- **Roadmap:** `feed-platform` / milestone `ms-01-workspace-foundation` (Phase 2)
- **Phase 1 (= 前 cycle):** `feed-platform-ms-01-workspace-foundation` (completed 2026-05-07、retrospective: `docs/retrospective/feed-platform-ms-01-workspace-foundation.md`)

## Background

Phase 1 cycle (`feed-platform-ms-01-workspace-foundation`) で 3 プロジェクト (`feed-platform-backend` / `feed-platform-web` / `identity-provider`) の Hello World レベル雛形を整備した結果、各プロジェクトに **完全同形コピーされた共通ロジック** が存在する状態となった (Phase 1 review reports / retrospective で言及済の DRY 違反候補)。

User 戦略指示 (2026-05-06): 「ms-02 (認証) 着手前に新規共通化マイルストーンをロードマップに挿入する。対象は dynamicLoggerLayer / makeDisposableRuntime / feature/env.ts / isFrameRequest / PageOrFrame / 他 Remix・Effect 横断ユーティリティ。」

本 cycle は ms-01 マイルストーンの Phase 2 として、上記同形コピーを `js/package/` 配下のライブラリに抽出し、3 プロジェクトすべてが共通ライブラリを参照する形に refactor する。

## Purpose

本 cycle 完了時点で以下を成立させる:

1. **`js/package/effect-hono/`** と **`js/package/remix-helper/`** の 2 つの新規 library package が配置され、`vp check` / `vp test` / `vp run -r build` が通過する
2. 5 candidates (C-1 〜 C-5) が **factory のみ抽出 / 具体実装は consumer に残す** 原則 (User 強調) で各 library に実装される
   - C-1 dynamicLoggerLayer / C-3 feature/env.ts: そのまま移植 (factory 化しない、library 内で完結)
   - C-2 makeDisposableRuntime: ジェネリクス化 factory
   - C-4+5 isFrameRequest + createPageOrFrame: 統合 factory `createFrameHelpers(frames)` + 別途 `InferFrameName<T>` 型関数
3. **4 projects (`feed-platform-backend` / `feed-platform-web` / `identity-provider` / `hono-remix-v3-cloudflare-example`)** で旧同形コピーコードを削除し library import に切替 (一括移行、atomic commit)
4. **`hono-remix-v3-cloudflare-example`** の Counter / TODO / Frame ナビゲーション既存 behavior は refactor 後も保持 (機能変更なし)
5. **ADR-03 (Roadmap mode)** が起票され、本 cycle の 6 決定事項 (D-1〜D-6) が ms-02 以降の前提として永続記録される

## Scope

Step 1 対話で 1 つずつ確定し追記する (会話駆動・漸増方式、`feedback_conversational_workflow.md` 準拠)。

### 確定済み

- **抽出対象範囲: User 戦略指示の 5 候補のみ (ミニマル)** (Q1 確定 — 2026-05-07)
  - **C-1: `dynamicLoggerLayer`** (`Layer.unwrap` + `Env.Service` 経由 Logger 形式判定 + `Logger.consoleJson` / `Logger.consolePretty()` 切替) — 現状 3 プロジェクトの `feature/runtime/server.ts` 内に完全同形コピー
  - **C-2: `makeDisposableRuntime` HOF** (TC39 `await using` + `DisposableRuntime` クラス + `Symbol.asyncDispose` 実装) — 現状 3 プロジェクトの `feature/runtime/server.ts` 内に完全同形コピー
  - **C-3: `feature/env.ts`** (`process.env.NODE_ENV` 経由 ENV 派生 + `Env.Service` + `makeLayer` (test 用)) — namespace 違いのみ、ロジックは完全同形
  - **C-4: `isFrameRequest`** — 現状 web/IdP の `app/routes.ts` で同形 (現在 `frames = {} as const`、最小骨格)
  - **C-5: `createPageOrFrame`** — Phase 1 では未採用 (ms-04/ms-07 で本格採用予定)。`hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx` をベースに抽出
  - 除外候補: C-6 (hono.ts middleware) / C-7 (Greeting) / C-8 (Health) / C-10 (Hono factory) / C-11 (Document) / C-12 (client entry) は本 cycle 対象外、必要時に ms-02 以降で個別判断
- **抽出粒度: factory 部分のみ、具体実装は移植しない** (Q1-extension 確定 — 2026-05-07)
  - **重要原則**: 各候補について **「具体を後から渡すべき箇所」と「抽象化するべき箇所」を一緒くたにしない**
  - **抽出する側**: 型推論可能な generic factory / HOF / 抽象 helper (= ライブラリの責務)
  - **アプリ側に残す側**: 具体的な Runtime 構成 (Layer 合成内容、Service tag namespace、frame registry の具体値、ENV 派生ロジックの具体形等)
  - 各候補のインターフェイスは **必要に応じて変更可** (現状の Phase 1 実装は未抽象、ジェネリクス化等で形を変える)
  - 例 (具体は Step 3 Design で確定):
    - `makeDisposableRuntime`: 現状は `(make: (env) => ManagedRuntime<...>) => DisposableRuntime` HOF。**ジェネリクス化して任意の引数 / 任意の ManagedRuntime を返す factory に拡張**
    - `dynamicLoggerLayer`: 現状は Env.Service ハードコード + Logger.consoleJson/consolePretty ハードコード。**汎用化: 条件判定式と 2 つの Logger を引数に取り Layer.unwrap で動的選択する factory**
    - `feature/env.ts`: 現状は `ENV: 'production' | 'development'` 固定 + Service tag namespace 固定。**汎用化: ENV 型もインターフェイスもアプリが決める形に factory 化** (詳細は Q4 で確定)
    - `isFrameRequest` + `createPageOrFrame`: 現状は frames registry を module-level で hardcode + `FrameName` 型を export。**汎用化: frames を引数に渡す factory が `{ FrameName 型, isFrameRequest 関数, createPageOrFrame 関数 }` を返す形 (型推論経由)**
- **パッケージ構造: 2 分割 新規 packages** (Q2 確定 — 2026-05-07、案 B 採用)
  - **`js/package/effect-hono/`** (Group A): C-1 dynamicLoggerLayer factory / C-2 makeDisposableRuntime factory / C-3 env factory を集約
  - **`js/package/remix-helper/`** (Group B): C-4 isFrameRequest factory / C-5 createPageOrFrame factory を集約
  - **将来計画**: 利用拡大に応じて `@totto2727/fp` への統合も検討 (本 cycle では独立 package 維持)
- **パッケージ命名: `effect-hono` と `remix-helper`** (Q3 確定 — 2026-05-07)
  - scope なし flat name (既存 `hono-remix-middleware` / `vite-plugin-remix` と同じ慣行)
  - `effect-hono` は Effect + Hono 統合の意味で、将来 Hono middleware factory が増えたときに自然に absorb できる名前
  - `remix-helper` は **Remix v3 の Frame UI helper factory 群** (= `hono-remix-middleware` のような middleware ではなく、純粋に Remix v3 の Frame 機能を扱う。**Hono とは無関係**)
- **各候補の抽象化境界 (= library 提供 vs consumer 提供)** (Q4 確定 — 2026-05-07、User 確認後修正版)
  - **C-1 dynamicLoggerLayer: そのまま移植 (factory 化しない)**
    - library 側が `Env.Service` 経由 + `Logger.consoleJson` / `Logger.consolePretty()` ハードコードの完成形 Layer を 1 つ export
    - `process.env.NODE_ENV` 直参照、Logger 関数も固定
    - 「ひとまず」(User 表現)、将来 factory 化する余地は残すが本 cycle では未抽象
  - **C-2 makeDisposableRuntime: ジェネリクス化 factory** (User 元方針通り)
    - 任意の引数 `Args extends any[]` と任意の `ManagedRuntime<R, ER>` をジェネリクスで受ける HOF
    - 具体シグネチャは Step 3 Design で確定
  - **C-3 feature/env.ts: そのまま移植 (factory 化しない)**
    - library 側が `Env.Type` interface + `Env.Service` (= Service tag、library 内で 1 本に統一) + `Env.layer` (`process.env.NODE_ENV` 経由) + `Env.makeLayer` (test 用 explicit value 注入) を export
    - **副作用**: Phase 1 では各プロジェクトが個別の `@app/<project-name>/feature/env/Service` namespace を持っていたが、library 統合後は library 内 1 つの Service tag に統一される (3 プロジェクトすべてが同じ `Env.Service` を import する形)
  - **C-4 + C-5 isFrameRequest + createPageOrFrame: 統合 factory + 別途 `InferFrameName` 型関数**
    - **重要訂正**: TypeScript の制約上、関数から型は値として返せない (型は型レベルでのみアクセス可)。よって以下の構造で抽出:
      - **value 側**: `createFrameHelpers(frames)` factory が `{ frames, isFrameRequest, createPageOrFrame }` (値 3 つ) を返す
      - **type 側**: `InferFrameName<T>` 型関数 (型ユーティリティ) を別途 export し、consumer は `type FrameName = InferFrameName<typeof helpers>` で型を取り出す
    - 具体シグネチャ案 (Step 3 Design で詳細確定):
      ```typescript
      // library
      export const createFrameHelpers = <F extends Record<string, string>>(frames: F) => ({
        frames,
        isFrameRequest: (name: keyof F): boolean => { /* ... */ },
        createPageOrFrame: <P>(frameName: keyof F, layout: ...) => { /* ... */ },
      })
      export type InferFrameName<T extends ReturnType<typeof createFrameHelpers>> = keyof T['frames']
      // consumer
      const helpers = createFrameHelpers({ content: 'content-frame' })
      type FrameName = InferFrameName<typeof helpers>
      ```
- **移行戦略: 一括移行 + `hono-remix-v3-cloudflare-example` も migration 対象** (Q5 確定 — 2026-05-07、案 A 採用 + scope 拡張)
  - **migration target**:
    - **Effect 系 (effect-hono library 利用)**: feed-platform-backend / feed-platform-web / identity-provider の 3 projects (= Phase 1 で同形コピーした分の置換)
    - **Remix UI 系 (remix-helper library 利用)**: feed-platform-web / identity-provider / **`hono-remix-v3-cloudflare-example`** の 3 projects (backend は Remix を持たないため対象外、`hono-remix-v3-cloudflare-example` は本 cycle で **scope 追加**)
  - **`hono-remix-v3-cloudflare-example` の位置付け** (User 指示):
    - **C-4 / C-5 抽出の基準 source-of-truth** として位置付ける (元祖実装 `hono-remix-v3-cloudflare-example/app/routes.ts` + `app/ui/page-or-frame.tsx` をベースに `remix-helper` library の抽象化 factory を設計)
    - 同時に **migration target に追加**: 抽出後の `remix-helper` library を `hono-remix-v3-cloudflare-example` 自身も使うように書き換え (= 「`hono-remix-v3-cloudflare-example` でも適用できる形」を担保)
    - 既存 behavior (Counter / TODO ページ + Frame ナビゲーション) は **保持** (refactor only、機能変更なし)
  - **commit 構造**:
    - 推奨: library 作成 commit と consumer 移行 commit を分割
      - Step 1: `effect-hono` / `remix-helper` library skeleton 作成 commits
      - Step 2: library 中身 (factory / 抽象 helper) 実装 commits
      - Step 3: 4 projects の一括 migration commit (Effect 系 3 + Remix UI 系 3、ただし重複 web/IdP は 1 commit にまとめ可)
    - 中間状態 (一部 projects のみ移行済) は許容しない (= migration commit は atomic)
  - **既存ファイル削除**: 旧 `feature/env.ts` (3 projects) / 旧 `dynamicLoggerLayer` / 旧 `makeDisposableRuntime` 等のコードは migration commit と同時に削除
- **既存 `js/package/` との関係: 完全分離維持** (Q6 確定 — 2026-05-07)
  - **`@totto2727/fp` (`js/package/fp`) との関係**: **分離維持**
    - User 補足: 「fp は比較的プリミティブな API のみで構成、Hono のようなフレームワークは基本含めていない」
    - `effect-hono` は Hono framework 統合の patterns を含むため、`@totto2727/fp` の責務範囲外
    - 将来の統合可能性は残るが、本 cycle では完全分離 (= fp に touch しない)
  - **`hono-remix-middleware` (`js/package/hono-remix-middleware`) との関係**: **分離維持**
    - User 補足: 「remix-helper については Hono と全く関係ない認識、そのため分離が正しい」
    - `hono-remix-middleware` は Hono+Remix middleware 専門 (`remixRenderer`)、`remix-helper` は **純粋な Remix v3 Frame UI helper** (Hono 非依存)
    - 責務 / 依存とも独立、統合の利点なし
  - **その他 `js/package/*`** (`vite-plugin-remix` / `oxlint-plugin` / `ui`): 関連薄、本 cycle で touch しない
  - **本 cycle では既存 package への変更を一切行わない**: `effect-hono` / `remix-helper` は完全新規 package、影響範囲は新規 package + migration target 4 projects のみ

- **横断 ADR の起票範囲: 新規 ADR-03 (Roadmap mode) を 1 本起票** (Q7 確定 — 2026-05-07、案 A 採用)
  - **ADR-03**: `docs/roadmap/feed-platform/adr/2026-05-07-shared-libraries-extraction.md`
    - 含む決定事項: D-1 抽出粒度 (factory のみ) / D-2 パッケージ構造 (2 分割新規) / D-3 命名規約 (scope なし flat name) / D-4 各 candidate 抽象化境界 / D-5 移行戦略 (一括 + hono-remix-v3-cloudflare-example も対象) / D-6 既存 js/package との分離維持
    - 影響範囲: feed-platform ロードマップ内の ms-02 以降 (effect-hono / remix-helper を import する形になる ABI 提供)
    - General mode は不採用 (本 cycle の判断は feed-platform 内 + 既存 monorepo 内に閉じる、他システム再利用視野の項目なし)
  - **Phase 1 ADR-01 / ADR-02 は touch しない** (historical record として完結)
  - **起票タイミング**: Step 6 (Implementation) で library 作成 + migration 実装と並行、`share-adr` Roadmap mode 経由

### 未確定 (後続ターンで追記)

(Step 1 内で残った論点はなし。Step 3 Design で詰める具体シグネチャ / Step 6 で発見されうる Effect 4.x API 制約は本 Step 1 のスコープ外)

## Out of scope

本 cycle では扱わず、後続マイルストーン (or 別 cycle) に委譲する事項:

- **抽出対象外の候補**: C-6 hono.ts middleware / C-7 Greeting / C-8 Health / C-10 Hono factory / C-11 Document / C-12 client entry — 必要時に ms-02 以降で個別判断
- **既存 `js/package/*` への変更** (`@totto2727/fp` / `hono-remix-middleware` / `vite-plugin-remix` / `oxlint-plugin` / `ui` 等) — 完全分離維持、本 cycle で touch しない
- **将来の `@totto2727/fp` への `effect-hono` 統合判断** — 別 cycle / 別ロードマップ責務、本 cycle では「将来検討候補」として記録のみ
- **C-1 dynamicLoggerLayer の汎用化 (factory 化)** — User 「ひとまずそのまま」、将来 factory 化の余地は残すが本 cycle では未抽象
- **認証認可実装** (Better Auth / jose / Casbin / Passkey / Magic Link / RBAC 等) — ms-02 / ms-03 / ms-04 責務
- **イベントストア / プロジェクション / Aggregate 実装** — ms-05 責務
- **入力 / 出力プラグイン契約 interface 定義と参照実装** — ms-06 / ms-07 責務
- **定期実行基盤 / AI 要約機能 / 統合検証** — ms-08 / ms-09 / ms-10 責務
- **CI / 本番デプロイ自動化** — 別ロードマップ
- **Cloudflare Workers 以外のサーバレス実行環境への対応** — ロードマップ Intent 非スコープ
- **Hono middleware の library 化** (= `feature/runtime/hono.ts` 相当) — consumer 側に残置 (Phase 1 で 3 プロジェクト同形だが、本 cycle 抽出対象外、ms-02 以降で再評価可)

## Success criteria

各 SC は観測可能な形で記述。verification 手段を併記。

- **SC-1**: `js/package/effect-hono/` と `js/package/remix-helper/` の 2 ディレクトリが存在し、各々に `package.json` が配置されている
  - 観測: `ls js/package/{effect-hono,remix-helper}/package.json` が exit 0
- **SC-2**: 2 library + 4 migration target projects 計 6 packages すべてで `vp run --filter <pkg> check` が exit 0 で終了
  - 観測: 各 package で `vp run --filter <pkg> check; echo $?` が `0`
- **SC-3**: 2 library それぞれに smoke test が ≥ 1 件配置され、`vp run --filter <pkg> test` が exit 0 で PASS する
  - 観測: 各 library で `vp run --filter <pkg> test; echo $?` が `0` かつ test 件数 ≥ 1
- **SC-4**: `vp run -r build` が exit 0、4 migration target projects (web / IdP / hono-remix-v3-cloudflare-example) のビルド成果物 (`dist/client/`) が出力される
  - 観測: `vp run -r build; echo $?` が `0` かつ各 web 系 project の `dist/client/` にファイル存在
- **SC-5**: 4 migration target projects (`feed-platform-backend` / `feed-platform-web` / `identity-provider` / `hono-remix-v3-cloudflare-example`) で旧 `feature/env.ts` / 旧 `dynamicLoggerLayer` / 旧 `makeDisposableRuntime` 等のコードが削除されており、library import に切替済
  - 観測: `grep -rE 'dynamicLoggerLayer|DisposableRuntime' --include='*.ts' js/app/{feed-platform-backend,feed-platform-web,identity-provider,hono-remix-v3-cloudflare-example}/` で hit 数 0 (= consumer 側に旧コードが残っていない)
- **SC-6**: `feed-platform-web` / `identity-provider` / `hono-remix-v3-cloudflare-example` で `remix-helper` の `createFrameHelpers` factory + `InferFrameName` 型関数が利用されている
  - 観測: `grep -rn 'createFrameHelpers\|InferFrameName' --include='*.ts' js/app/{feed-platform-web,identity-provider,hono-remix-v3-cloudflare-example}/` で各 project ≥ 1 hit
- **SC-7**: `hono-remix-v3-cloudflare-example` の Counter / TODO / Frame ナビゲーション動作が refactor 前後で同等 (機能変更なし)
  - 観測: 既存 example の test 群があれば PASS、もしくは smoke レベルで `vp run --filter hono-remix-v3-cloudflare-example test` が exit 0
- **SC-8**: ADR-03 (`docs/roadmap/feed-platform/adr/2026-05-07-shared-libraries-extraction.md`) が起票され、D-1〜D-6 の 6 決定事項が記録されている
  - 観測: ファイル存在 + 主要セクション (Status / Context / Decision / Consequences / References) を満たす
- **SC-9**: GitHub Actions CI が本 cycle の最終コミットで PASS する
  - 観測: PR の `## CI status` セクションに `success` 記録 (share-ci-monitoring 二重チェック)
- **SC-10**: `roadmap-progress.yaml.milestones[ms-01-workspace-foundation]` を `completed` に再遷移可能 (Phase 1 + Phase 2 ともに完了状態に到達)
  - 観測: SC-1〜SC-9 全 PASS の前提下で、Phase 2 cycle の Step 9 retrospective 完了時に `active → completed` 遷移可能

## Constraints

### 技術的制約 (Phase 1 ADR-01 / ADR-02 の継承 + 本 cycle 固有)

- **採用ワークスペース: `js/`** (Phase 1 ADR-01 D-1 継承)
- **実行環境: Cloudflare Workers** (Phase 1 ADR-01 D-6 継承)
- **フレームワーク**: Effect / Hono / Remix v3 / Vite+ (Phase 1 継承)
- **パッケージ管理**: pnpm workspace + catalog (Phase 1 継承、新規 packages も catalog 利用)
- **Lint / Format**: Ultracite (Oxlint + Oxfmt) (継承)
- **テスト**: vp (Vitest) + `vite-plus/test` 共通 default、`vitest.config.*` 新設しない (Phase 1 CC-5 継承)
- **依存関係**: 新規 2 packages も全依存を `devDependencies` に集約 (Phase 1 継承、フルバンドル運用整合)
- **`vite.config.ts` の `run.tasks`**: 各 library で `setup` / `build` を定義 (`@totto2727/fp/vite` の `defineTaskInputFromOutput` 利用)
- **Phase 1 user-gate-driven refinements は維持** (Logger Env Service 経由 / `await using` / `process.env.NODE_ENV` 採用 / `feature/<name>.test.ts` colocation 等は Phase 1 で確定済、本 cycle で再変更しない)
- **TypeScript `using` / `await using` 構文**: `@totto2727/fp/tsconfig/vite` (target: esnext) で Phase 1 から有効
- **ADR は本リポジトリ内の `share-adr` スキルに準拠** (Roadmap mode = `docs/roadmap/feed-platform/adr/`)

### 組織的制約

- 個人開発 (totto2727 単独)、Specialist は dev-workflow の subagent として並列起動
- 並行 dev-workflow サイクル数の上限: **2** (ロードマップ Intent `roadmap.md:71`)
- 本 cycle は ms-01 Phase 2 として単独進行 (Phase 1 closed、ms-02 未着手)

### 規範的制約

- ロードマップ Intent の「大局的制約」継承 (`roadmap.md` 「大局的制約」節)
- 既存プロジェクト固有スキル (`effect-layer` / `effect-runtime` / `effect-hono` / `git-workflow` / `share-adr` / `script-rules` / `totto2727-fp` 等) のパターン優先
- 機密情報 (API キー / 個人情報 / トークン等) をリポジトリに保存しない (Phase 1 継承)
- 本 cycle が `dev-workflow` の 9 ステップ体系および `dev-roadmap` の 4 ステップ体系に準拠
- **抽象化原則** (User 強調): 「具体を後から渡すべき箇所と抽象化するべき箇所を一緒くたにしない」を本 cycle の全 design / implementation 判断で適用
- **`hono-remix-v3-cloudflare-example` の既存 behavior 保持**: refactor only、機能変更なし

## Related links

- ロードマップ: `docs/roadmap/feed-platform/roadmap.md`
- マイルストーン: `docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md` (Phase 2 セクション)
- Phase 1 retrospective: `docs/retrospective/feed-platform-ms-01-workspace-foundation.md` (改善候補 + DRY 違反指摘)
- Phase 1 design: `docs/workflow/feed-platform-ms-01-workspace-foundation/design.md` (Anticipated extension points 表 + 3 プロジェクト共通 Effect skeleton snippet)
- Phase 1 ADR-01: `docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md`
- Phase 1 ADR-02: `docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md`
- ロードマップ進捗: `docs/roadmap/feed-platform/roadmap-progress.yaml`

## Open questions

Step 1 対話で残った論点は以下のみ (すべて後続 Step で扱う前提、本 Step 1 のスコープ外):

- 各 factory の **具体 TypeScript シグネチャ** (ジェネリクス引数、変位、`as const`、Effect 4.x の `Layer.unwrap` / `Context.Tag` API 制約) — Step 3 (Design) で詳細確定
- Step 6 (Implementation) で発見されうる **Effect 4.0.0-beta.60 API 制約** (Phase 1 で `ServiceMap.Service` → `Context.Service` deviation が発生したのと同様の事例) — 発見時に design.md 即時 corrigendum (Phase 1 retrospective Process improvements 反映)
- `hono-remix-v3-cloudflare-example` migration で Counter / TODO ページの既存 behavior をどう test するか — Step 4 (QA Design) で観測仕様確定 (= 既存 test がない場合は smoke レベルでカバー)

なお Step 1 (Intent Clarification) 自体は本セクションに「Step 1 内で解決すべき残論点」が存在しない状態で完了する。
