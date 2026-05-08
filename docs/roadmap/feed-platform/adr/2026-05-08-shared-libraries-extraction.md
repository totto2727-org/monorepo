---
confirmed: false
scope: roadmap:feed-platform
---

# ADR: feed-platform 共通ライブラリ抽出 (effect-hono / remix-helper)

- **Filed at:** 2026-05-08
- **Filer:** architect (Step 3) — `confirmed: false` で起草。Step 6 (Implementation) で `share-adr` Roadmap mode を経由して `confirmed: true` に promote する
- **Originating step:** dev-workflow Step 3 (Design) of cycle `feed-platform-ms-01-shared-libraries`
- **Storage path:** docs/roadmap/feed-platform/adr/2026-05-08-shared-libraries-extraction.md

## Context

`feed-platform` ロードマップ (`docs/roadmap/feed-platform/roadmap.md`) の起点マイルストーン ms-01 (Workspace Foundation) は 2 phase 構成で進行している。Phase 1 cycle (`feed-platform-ms-01-workspace-foundation`、completed 2026-05-07) で 3 プロジェクト (`feed-platform-backend` / `feed-platform-web` / `identity-provider`) の Hello World レベル雛形を整備した結果、各プロジェクトに **完全同形コピーされた共通ロジック** が存在する状態となった (Phase 1 retrospective `docs/retrospective/feed-platform-ms-01-workspace-foundation.md` で言及済の DRY 違反候補)。

本 ADR は ms-01 Phase 2 cycle (`feed-platform-ms-01-shared-libraries`) Step 3 の設計判断束として、後続マイルストーン (ms-02〜ms-10) が引き継ぐ「共通ライブラリの責務分担と抽出原則」を永続記録する。

User 戦略指示 (2026-05-06): 「ms-02 (認証) 着手前に新規共通化マイルストーンをロードマップに挿入する。対象は dynamicLoggerLayer / makeDisposableRuntime / feature/env.ts / isFrameRequest / PageOrFrame / 他 Remix・Effect 横断ユーティリティ。」

Intent Spec (`docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md`) の Q1〜Q7 + Step 2 → Step 3 移行時 User confirm (`progress.yaml.step3_design_inputs`、2026-05-08) で確定した 5 件の決定事項を、本 ADR が単一の決定束として記録する。

影響範囲は **feed-platform ロードマップ内のすべての配下サイクル (ms-02〜ms-10)** に閉じる。新設 2 library の API surface は ms-02 以降のすべての cycle が前提とする ABI として機能するため Roadmap mode (`docs/roadmap/feed-platform/adr/`) として起票する。本リポジトリの他ロードマップへの影響は限定的 (= 本 cycle の判断は feed-platform 内 + 既存 monorepo 内に閉じる、他システム再利用視野の項目なし、Intent Spec L121)。

Phase 1 ADR-01 (`2026-05-05-project-structure-and-runtime.md`) が定めた architectural constraints (`process.env.NODE_ENV` 単一ソース / `await using` / `Layer.unwrap` + `Env.Service` 経由 Logger 切替 / Service tag namespace 規約) は本 ADR でもすべて継承される (本 ADR は Phase 1 ADR-01 を supersede しない、historical record として完結維持、Intent Spec L122)。

## Decision

本 ADR は 5 つの決定事項 (D-1〜D-5) を **1 つの決定束** として確定する。各決定はそれ単体では切り離せず、全体で「2 package 分割 + factory-only 抽出 + Hono フリー remix-helper + wrapper class 継承 + 既存分離維持」という共通ライブラリ層を構成する。

### D-1: 2 package 分割 (`effect-hono` + `remix-helper`)

`js/package/` 配下に 2 つの新規 library package を配置する:

- **`js/package/effect-hono/`** (Group A、Effect + Hono 統合領域): C-1 `dynamicLoggerLayer` / C-2 `makeDisposableRuntime` / C-3 `Env` (Service + `layer` + `makeLayer`) を集約
- **`js/package/remix-helper/`** (Group B、Remix v3 Frame UI 領域): C-4+5 統合 `createFrameHelpers(frames)` factory + 型関数 `InferFrameName<T>` を集約

両 package とも `private: true` / scope なし flat name (= 既存 `hono-remix-middleware` / `vite-plugin-remix` と同形、Research C F9)。命名規約は **`effect-hono` = Effect + Hono 統合の意味で将来 Hono middleware factory が増えたときに自然に absorb できる名前** / **`remix-helper` = 純粋な Remix v3 Frame helper、Hono とは無関係** (Intent Spec L60-L61)。

**根拠**: Intent Spec Q2 で確定 (案 B 採用)。責務 / 依存とも独立 (Research C F4-F5、grep evidence で重複なし)、命名上 User 強調と整合。1 package 統合案は責務範囲が異なる (Effect runtime layer vs Remix Frame UI layer) ため不採用。

### D-2: factory-only 抽出 (具体実装は consumer に残す)

各 candidate について **「具体を後から渡すべき箇所」と「抽象化するべき箇所」を一緒くたにしない** 原則 (Intent Spec L45) で抽出境界を確定:

| Candidate                      | library 抽出形式                                                                                              | consumer に残す具体                                                                                                                                                      |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| C-1 `dynamicLoggerLayer`       | factory 化せず **そのまま移植** (Layer<never> 完成形を 1 つ export)                                           | なし (= library を import するだけで使える)                                                                                                                              |
| C-2 `makeDisposableRuntime`    | **generic factory** (D-4 で詳述)                                                                              | `make` 関数 / Layer 合成内容 / Service tag namespace / runtime バリアント数                                                                                              |
| C-3 `Env`                      | factory 化せず **そのまま移植** (Service tag を **library 内 1 本に統一** = `'@app/effect-hono/env/Service'`) | なし (= Phase 1 で各 project が個別に持っていた `'@app/<project-name>/feature/env/Service'` namespace は廃止、3 consumer すべてが library 提供の同一 Service tag を使う) |
| C-4 + C-5 `createFrameHelpers` | **generic factory** + 型関数 `InferFrameName<T>` (D-3 で signature 詳述)                                      | frame names registry / adapter 1 行 helper / `Layout` 関数 / `PageOrFrame` の `Request` bind                                                                             |

**根拠**: Intent Spec L44-L53 + L62-L72 で User confirm 済。library API surface を最小化、consumer 側差分を import 切替の機械的作業に縮約する設計が抽象化原則 (Intent Spec L198) と整合。C-1 / C-3 の factory 化は将来 cycle に委譲 (= 本 cycle scope 最小化、Intent Spec L66 「ひとまず」)。

### D-3: `remix-helper` の Hono 切り離し signature

`createFrameHelpers` factory が返す `isFrameRequest` の signature を **`(request: Request, frame: T[number]) => boolean`** に確定する (= Hono `getContext()` 直呼びを廃し、`Request` を直接受け取る形)。`createPageOrFrame` も同様に **`(frameName, layout) => (request: Request) => (handle) => () => RemixNode`** で `Request` を中間段階で bind する形に変更する (Phase 1 既存実装の 3 段階カリーに `Request` 受け取り段階を 1 段挿入)。

`remix-helper` package は **`hono` を `peerDependencies` に持たない** (= 完全 Hono フリー化)。consumer 側 (4 projects) では以下の **3 行 adapter** を `routes.ts` (またはそれに相当する場所) に置く:

```typescript
import { getContext } from 'hono/context-storage'
import { createFrameHelpers, type InferFrameName } from 'remix-helper'

export const helpers = createFrameHelpers(['content'] as const)
export const isFrameRequest = (frame: InferFrameName<typeof helpers.frames>) =>
  helpers.isFrameRequest(getContext().req.raw, frame)
export type FrameName = InferFrameName<typeof helpers.frames>
```

frame name 型は **`F[keyof F]` (= string literal value union)** を採用 (= Phase 1 既存実装 `(typeof frames)[keyof typeof frames]` と整合、`x-remix-target` header 比較対象が value 側であるため)。Intent Spec L82 草案 `keyof F` (key union) は誤りで、本 ADR で訂正する。`InferFrameName<T>` は `<const T extends readonly string[]>` + `T[number]` 形 (Pattern P2、Research D F-1〜F-4 / I-2 で TS 5.9 環境で実機検証可能性を確認済)。

**根拠**: `progress.yaml.step3_design_inputs` U-1 + U-3 で User confirm 済 (2026-05-08T00:30:00Z)。Research B I-8 で発見された `getContext()` 依存問題 (= ユーザー強調「remix-helper は Hono と無関係」と既存実装 `hono/context-storage` 直呼びの矛盾) を完全解消。consumer 側 adapter 3 行で吸収可能、library 純度が optimal。

### D-4: `makeDisposableRuntime` wrapper class 継承

Effect 4.0.0-beta.60 の `ManagedRuntime` interface には **`[Symbol.asyncDispose]` が組み込まれていない** (Research A F-6: `node_modules/.../effect/dist/ManagedRuntime.d.ts:37-98` を直接確認)。よって `await using` 構文で自動破棄するための wrapper class を library 側で生成する以外に選択肢はない。

採用 signature (= Research A F-9 / I-1):

```typescript
import type { ManagedRuntime } from 'effect'

export const makeDisposableRuntime = <Args extends readonly unknown[], R, ER>(
  make: (...args: Args) => ManagedRuntime.ManagedRuntime<R, ER>,
) =>
  class implements AsyncDisposable {
    readonly instance: ManagedRuntime.ManagedRuntime<R, ER>
    constructor(...args: Args) {
      this.instance = make(...args)
    }
    async [Symbol.asyncDispose](): Promise<void> {
      await this.instance.dispose()
    }
  }
```

ジェネリクスは `<Args, R, ER>` の 3 つで足りる (Research A I-1)。`Layer<R, ER, never>` 制約は consumer 側 `ManagedRuntime.make(layer)` 呼び出しが Effect 側型システムで強制するため library 側で再表明する必要なし (Research A F-10)。

**根拠**: `progress.yaml.step3_design_inputs` U-other-A で User confirm 済。Phase 1 / saas-example 既存 pattern との互換性継承、Layer 直接受け取る factory (案 B) は consumer 側 `makeRuntime` を library 内に押し込む非互換が生じるため不採用 (Research A I-1 / U-5)。Effect 4.x stable で `Symbol.asyncDispose` が追加された場合の future-proofing は extension point として記録 (Research A U-3、本 cycle 意思決定には影響しない)。

### D-5: 既存 `js/package/*` との分離維持

既存 5 packages (`@totto2727/fp` / `hono-remix-middleware` / `vite-plugin-remix` / `@package/ui` / `@package/oxlint-plugin`) に対し、本 cycle では **一切の変更を行わない**。新規 2 packages (`effect-hono` / `remix-helper`) はいずれの既存 package も `dependencies` / `peerDependencies` で参照しない (Research C F2-F6 で重複ゼロを grep 確認済):

- **`@totto2727/fp`**: primitive FP / Effect Schema CUID / Vite+ task helper の薄い再 export 集合。Hono 依存ゼロ / Remix 依存ゼロ。`effect-hono` の Logger / Runtime / Env factory とは明確に異なる抽象層 (primitive level vs application-runtime level)
- **`hono-remix-middleware`**: Hono の `c.render()` を Remix v3 `renderToStream` に橋渡しする middleware (`remixRenderer`)。`remix-helper` の Frame name registry + Page/Frame Layout helper とは disjoint
- **`vite-plugin-remix`**: build-time + client boot。Server-side `isFrameRequest` 判定とは layer 違い
- **`@package/ui` / `@package/oxlint-plugin`**: UI primitives / Oxlint plugin、本 cycle と無関係

将来 `@totto2727/fp` への `effect-hono` 統合判断は別 cycle / 別ロードマップ責務 (= 本 cycle では「将来検討候補」として記録のみ、Intent Spec L57 / L135)。

**根拠**: Intent Spec Q6 確定 + Research Note `existing-js-package-isolation-check.md` F2-F6 で grep + コード読み込みベースで完全裏取り済。User 補足「fp は比較的プリミティブな API のみで構成、Hono のようなフレームワークは基本含めていない」「remix-helper については Hono と全く関係ない認識、そのため分離が正しい」(Intent Spec L107 / L111) と整合。

### Alternatives considered

| Option          | Summary                                                                                                                        | Adopted / Rejected | Rationale                                                                                                                                          |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A** (Adopted) | 2 package 分割 + factory-only 抽出 + Hono フリー remix-helper + wrapper class makeDisposableRuntime + 既存 5 packages 完全分離 | Adopted            | Intent Spec Q1〜Q7 + step3_design_inputs U-1/U-3/U-other-A/B/D を完全反映。Research A〜D で事実裏取り済、既存慣行と整合                            |
| **B**           | 1 package 統合 (`@feed-platform/shared` 等)                                                                                    | Rejected           | 責務範囲が異なる (Effect runtime layer vs Remix Frame UI layer)、命名上 User 強調「remix-helper は Hono と無関係」と矛盾                           |
| **C**           | `remix-helper` で `hono/context-storage` peer-dep を許容 (現状実装継承)                                                        | Rejected           | step3_design_inputs U-3 で User confirm 済 (案 A `Request` 直接受け取り採用)。consumer 側 adapter 3 行で吸収可能、library 純度が optimal           |
| **D**           | 全 candidate を generic factory 化 (C-1 / C-3 も factory 化)                                                                   | Rejected           | Intent Spec L62-L72 で User 「ひとまずそのまま移植」確定、本 cycle scope 最小化、将来 factory 化の余地は extension point として記録                |
| **E**           | `effect-hono` を `@totto2727/fp` に統合                                                                                        | Rejected           | `@totto2727/fp` は primitive FP のみ (Hono / Remix 非依存)、`effect-hono` は application-runtime level で抽象階層が異なる。将来統合は別 cycle 責務 |
| **F**           | `makeDisposableRuntime` を Layer 直接受け取る factory (案 B)                                                                   | Rejected           | step3_design_inputs U-other-A で案 A 確定。既存 Phase 1 / saas-example pattern との互換性、`Layer<R,ER,never>` 制約再表明不要                      |
| **G**           | `InferFrameName<T>` を Pattern P1 (`Record<string, string>` + `keyof T['frames']`)                                             | Rejected           | step3_design_inputs U-other-D で P2 確定。既存実装の意味論 (value union) と整合、conditional type 不要で reviewer 認知負荷最小                     |

## Consequences

本決定束による影響範囲を「新規追加 / 既存影響 / 将来制約」の 3 軸で記述する。

### Newly added

- **`js/package/effect-hono/`** が `package.json` (`name: "effect-hono"` / `private: true` / `type: module` / `peerDependencies.effect: catalog:effect`) + `tsconfig.json` (extends `@totto2727/fp/tsconfig/vite`) + `src/{index,env,logger,runtime,runtime.test}.ts` で配置される。`vite.config.ts` は不要 (root `vp` が check / test を提供、`hono-remix-middleware` 同形)
- **`js/package/remix-helper/`** が `package.json` (`name: "remix-helper"` / `private: true` / `peerDependencies.remix: catalog:remix`) + `tsconfig.json` (extends `@totto2727/fp/tsconfig/vite` + `jsxImportSource: "remix/ui"`) + `src/{index,frame-helpers,frame-helpers.test}.ts` で配置される
- **library API surface**:
  - `effect-hono`: `Env.Service` (= `'@app/effect-hono/env/Service'` 1 本) / `Env.layer` / `Env.makeLayer` / `dynamicLoggerLayer: Layer<never>` / `makeDisposableRuntime: <Args, R, ER>(make) => class implements AsyncDisposable`
  - `remix-helper`: `createFrameHelpers: <const T extends readonly string[]>(frames: T) => FrameHelpers<T>` / `InferFrameName<T extends readonly string[]> = T[number]` (export type)
- **consumer 側 adapter pattern** (4 projects 共通の 3 行 helper、design.md 参照): `getContext().req.raw` を `helpers.isFrameRequest` に渡す形

### Existing impact

- **`pnpm-workspace.yaml`**: 既存 `js/package/*` glob で新規 2 packages が自動取り込み (Research C F7、catalog 定義変更不要)
- **既存 CI (`vp run --parallel ci`)**: 追加変更なしで 2 library + 4 consumer を取り込む (Phase 1 ADR-01 D-6 整合)
- **3 effect-hono consumer projects** (`feed-platform-backend` / `feed-platform-web` / `identity-provider`): 旧 `feature/env.ts` (`Env.Service` namespace = `'@app/<project-name>/feature/env/Service'`) を削除し library import に切替。Phase 1 で確立された Service tag namespace は **library 内 1 本** (`'@app/effect-hono/env/Service'`) に統一される (= D-2 の副作用、Intent Spec L70-L72)
- **3 effect-hono consumer projects**: 旧 `feature/runtime/server.ts` の `dynamicLoggerLayer` 定義 (約 8 行) + `makeDisposableRuntime` HOF (約 17 行) を削除し library import に切替 (各 project 約 24 行純減 × 3 = 約 72 行削減、Research A I-7)
- **3 remix-helper consumer projects** (`feed-platform-web` / `identity-provider` / `hono-remix-v3-cloudflare-example`): `app/routes.ts` を library + adapter pattern に置換。`hono-remix-v3-cloudflare-example` のみ既存 `app/ui/page-or-frame.tsx` ファイル削除 + `app/ui/content-layout.tsx` の `createPageOrFrame` 呼出 adapter 経由化
- **`hono-remix-v3-cloudflare-example`**: Counter / TODO / Frame ナビゲーション既存 behavior は **保持** (refactor only、機能変更なし、Intent Spec L96-L97)。本 example は本 cycle で **C-4 / C-5 抽出の基準 source-of-truth** として位置付けられ、同時に migration target にも追加された (Intent Spec L94-L97)
- **既存 `js/package/*` 5 packages**: いずれも touch しない (D-5)

### Constraints going forward

後続マイルストーン (ms-02〜ms-10) は以下の不変制約を遵守する:

- **2 package 構成 (`effect-hono` + `remix-helper`) は不変**: ms-02 以降で 3 つ目の library を追加する場合、その判断は本 ADR の前提のもとで進めるか、または別 ADR で本 ADR を一部 supersede する形で実施する
- **`Env.Service` tag は library 内 1 本** (`'@app/effect-hono/env/Service'`) を維持。各 project が個別 namespace を再導入することは禁止 (= Phase 1 ADR-01 D-6 の Service tag namespace 規約 `@app/<project-name>/feature/<name>/Service` は本 ADR の `Env` 限定で **上書きされる**、他の Service は引き続き Phase 1 規約に従う)
- **`remix-helper` は Hono 非依存を維持**: 将来 `peerDependencies` に `hono` を追加することは本 ADR D-3 の前提を覆す変更となるため、別 ADR で supersede が必要
- **`makeDisposableRuntime` は wrapper class factory pattern 維持**: Effect 4.x stable で `[Symbol.asyncDispose]` が追加された場合 (Research A U-3)、本 ADR を supersede する別 ADR で「factory 不要 / library 削除」判断を起票してから実施する
- **既存 `js/package/*` 5 packages との分離維持**: ms-02 以降で `effect-hono` を `@totto2727/fp` に統合する判断は別 cycle / 別ロードマップ責務、本 ADR の射程外
- **factory-only 抽出原則の維持**: ms-02 以降で新規 candidate を library 化する際も「具体は consumer に残す / 抽象化部分のみ library に出す」境界を守る (Intent Spec L45 抽象化原則)
- **C-1 dynamicLoggerLayer / C-3 Env の generic 化**: 本 cycle では未着手、将来 factory 化する余地は extension point として残す (design.md "Anticipated extension points" 参照)。実施時は本 ADR の supersede ではなく **追加** ADR (= D-2 の境界を維持したまま新たな factory を library 内に追加) で対応可能

### Trade-offs と緩和策

- **Pros**:
  - 3 projects に同形コピーされていた共通ロジック (約 72 行 + 各 project の `routes.ts` 同形コピー) が library 1 箇所に集約され、DRY 違反が構造的に解消
  - factory-only 抽出により library API surface が最小化、consumer 側差分が import 切替の機械的作業に縮約
  - `remix-helper` の Hono フリー化により「remix-helper は純粋な Remix v3 Frame UI helper」という User 命名意図が **依存グラフ上でも保証**
  - `hono-remix-v3-cloudflare-example` を migration target に追加することで「本 cycle 抽出の factory が source-of-truth で動作する」ことが構造的に保証される
- **Cons**:
  - consumer 側 adapter pattern (3 行 helper) が 4 project に存在することになる (= 軽度の boilerplate)
  - `Env.Service` tag が library 内 1 本に統一されるため、3 project が同じ Service tag を import する形になる (= Phase 1 で各 project が個別 namespace を持っていたカプセル化は失われる)
- **Mitigation**:
  - 3 行 adapter は機械的 boilerplate で、将来 cycle で `effect-hono` に Hono adapter として追加する余地を残す (design.md extension points)
  - `Env.Service` 統一は Intent Spec L70-L72 で User 確認済の意図的判断 (3 projects が同じ ENV 抽象を共有することが本 cycle の目的)、副作用ではなく便益

## Related

- **Intent Spec**: [`docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md`](../../../workflow/feed-platform-ms-01-shared-libraries/intent-spec.md) (Q1〜Q7 確定事項 / SC-1〜SC-10)
- **Design Document**: [`docs/workflow/feed-platform-ms-01-shared-libraries/design.md`](../../../workflow/feed-platform-ms-01-shared-libraries/design.md) (本 ADR の決定束を実装可能な詳細度で展開)
- **Research Notes**:
  - [`research/effect-4-api-verification.md`](../../../workflow/feed-platform-ms-01-shared-libraries/research/effect-4-api-verification.md) (D-4 wrapper class factory の Effect 4.0.0-beta.60 API 裏取り)
  - [`research/hono-remix-v3-cloudflare-example-frame-helpers.md`](../../../workflow/feed-platform-ms-01-shared-libraries/research/hono-remix-v3-cloudflare-example-frame-helpers.md) (D-3 Hono フリー signature の根拠)
  - [`research/existing-js-package-isolation-check.md`](../../../workflow/feed-platform-ms-01-shared-libraries/research/existing-js-package-isolation-check.md) (D-5 既存 5 packages 分離維持の事実裏取り)
  - [`research/infer-frame-name-type-utility-pattern.md`](../../../workflow/feed-platform-ms-01-shared-libraries/research/infer-frame-name-type-utility-pattern.md) (D-3 `InferFrameName<T>` Pattern P2 採用根拠)
- **Phase 1 ADR-01**: [`2026-05-05-project-structure-and-runtime.md`](./2026-05-05-project-structure-and-runtime.md) (本 ADR は ADR-01 を supersede しない、Phase 1 の architectural constraints を継承)
- **Phase 1 retrospective**: [`docs/retrospective/feed-platform-ms-01-workspace-foundation.md`](../../../retrospective/feed-platform-ms-01-workspace-foundation.md) (DRY 違反候補の指摘元)
- **Roadmap**: [`docs/roadmap/feed-platform/roadmap.md`](../roadmap.md)
- **Milestone**: [`docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md`](../milestones/ms-01-workspace-foundation.md) (Phase 2 セクション)
- **既存 reference 実装**:
  - `js/app/hono-remix-v3-cloudflare-example/` (C-4 / C-5 抽出の source-of-truth、本 cycle で migration target に追加)
  - `js/app/saas-example/` (`makeDisposableRuntime` の引数あり版 reference、Research A F-8)
  - `js/package/hono-remix-middleware/` / `js/package/vite-plugin-remix/` (新規 2 library の `package.json` / `tsconfig.json` 構造踏襲元)
