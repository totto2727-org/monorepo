# Intent Spec: feed-platform Shared Libraries (ms-01 Phase 2)

- **Identifier:** feed-platform-ms-01-shared-libraries
- **Author:** totto2727 (Main 起草)
- **Created at:** 2026-05-07T03:55:00Z
- **Last updated:** 2026-05-07T05:15:00Z
- **Roadmap:** `feed-platform` / milestone `ms-01-workspace-foundation` (Phase 2)
- **Phase 1 (= 前 cycle):** `feed-platform-ms-01-workspace-foundation` (completed 2026-05-07、retrospective: `docs/retrospective/feed-platform-ms-01-workspace-foundation.md`)

## Background

Phase 1 cycle (`feed-platform-ms-01-workspace-foundation`) で 3 プロジェクト (`feed-platform-backend` / `feed-platform-web` / `identity-provider`) の Hello World レベル雛形を整備した結果、各プロジェクトに **完全同形コピーされた共通ロジック** が存在する状態となった (Phase 1 review reports / retrospective で言及済の DRY 違反候補)。

User 戦略指示 (2026-05-06): 「ms-02 (認証) 着手前に新規共通化マイルストーンをロードマップに挿入する。対象は dynamicLoggerLayer / makeDisposableRuntime / feature/env.ts / isFrameRequest / PageOrFrame / 他 Remix・Effect 横断ユーティリティ。」

本 cycle は ms-01 マイルストーンの Phase 2 として、上記同形コピーを `js/package/` 配下のライブラリに抽出し、3 プロジェクトすべてが共通ライブラリを参照する形に refactor する。

## Purpose

(Step 1 対話で確定 — TBD)

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

### 未確定 (後続ターンで追記)

### 抽出候補 (Step 1 対話で具体合意する一次入力)

User 戦略指示で挙げられた候補:

- **Effect runtime 系** (現在 3 プロジェクトの `feature/runtime/server.ts` に同形配置):
  - `dynamicLoggerLayer` (`Layer.unwrap` + `Env.Service` 経由 Logger 形式判定 + `Logger.consoleJson` / `Logger.consolePretty()` 切替)
  - `makeDisposableRuntime` HOF (TC39 `await using` + `DisposableRuntime` クラス + `Symbol.asyncDispose` 実装)
- **Effect Service 系** (現在 3 プロジェクトの `feature/env.ts` に同形配置):
  - `feature/env.ts` (`process.env.NODE_ENV` 経由 ENV 派生 + `Env.Service` + `makeLayer` (test 用))
- **Remix UI 系** (現在 web/IdP の `app/routes.ts` / `app/ui/` 系に同形配置 or 不在):
  - `isFrameRequest` (`hono-remix-v3-cloudflare-example/app/routes.ts` ベース)
  - `createPageOrFrame` (`hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx` ベース、ms-01 雛形では未採用、ms-04 / ms-07 で本格採用前提)
- **その他 Remix / Effect 横断ユーティリティ** (Step 1 対話で具体特定):
  - 候補例: `feature/runtime/hono.ts` の Hono middleware (`await using runtime = ...`)、`feature/greeting.ts` (もしくは Greeting Service の汎用化判断)、`feature/health.ts`、各プロジェクトの `tsconfig.json` 共通設定 等
  - 既存 `js/package/` (e.g., `@totto2727/fp` / `hono-remix-middleware` / `vite-plugin-remix`) との責務切り分けも論点

### 未確定 (後続ターンで追記)

- 抽出範囲の確定 (どの候補を本 cycle で扱うか、ms-02 以降に委譲する候補があるか)
- 共通ライブラリの配置先 (`js/package/<新規パッケージ名>` の構造、1 パッケージ集約 vs 複数パッケージ分割)
- 命名規約 (`@totto2727/...` / `@app/...` / `@<scope>/...` / scope なし flat name のいずれか)
- API surface (re-export 形式 / namespace / barrel export)
- 移行戦略 (3 プロジェクトの既存 import を一括書き換えするか / 段階的か)
- ADR 起票範囲 (Phase 1 ADR-01 を補足する形で本 cycle 用 ADR を起票するか / Phase 1 ADR-01 を Superseded して新 ADR を起票するか / 起票不要か)
- 既存 `@totto2727/fp` / `hono-remix-middleware` / `vite-plugin-remix` との責務切り分け方針

## Out of scope

(Step 1 対話で確定 — TBD)

## Success criteria

Step 1 対話で 1 つずつ確定し追記する (会話駆動・漸増方式)。観測可能な形で記述する。

- (TBD)

## Constraints

(Step 1 対話で確定 — TBD)

## Related links

- ロードマップ: `docs/roadmap/feed-platform/roadmap.md`
- マイルストーン: `docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md` (Phase 2 セクション)
- Phase 1 retrospective: `docs/retrospective/feed-platform-ms-01-workspace-foundation.md` (改善候補 + DRY 違反指摘)
- Phase 1 design: `docs/workflow/feed-platform-ms-01-workspace-foundation/design.md` (Anticipated extension points 表 + 3 プロジェクト共通 Effect skeleton snippet)
- Phase 1 ADR-01: `docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md`
- Phase 1 ADR-02: `docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md`
- ロードマップ進捗: `docs/roadmap/feed-platform/roadmap-progress.yaml`

## Open questions

Step 1 対話の進行に伴って追記。

- (TBD)
