# Research Note: hono-remix-v3-cloudflare-example-frame-helpers

- **Identifier:** feed-platform-ms-01-shared-libraries
- **Topic:** hono-remix-v3-cloudflare-example-frame-helpers
- **Researcher:** specialist-researcher (angle: source-of-truth implementation)
- **Created at:** 2026-05-07
- **Scope:** C-4 `isFrameRequest` + C-5 `createPageOrFrame` (および周辺の `frames` registry / `FrameName` 型 / `FrameLink` / `Frame` 利用箇所) を、`js/package/remix-helper/` への抽出基準として fix する。3 migration target (`hono-remix-v3-cloudflare-example` / `feed-platform-web` / `identity-provider`) を **diff レベル**で照合し、Phase 2 factory `createFrameHelpers(frames)` + 型関数 `InferFrameName<T>` を「同一 factory で表現可能か」を観測事実として確定する。

## Subject of investigation

Phase 2 cycle (`feed-platform-ms-01-shared-libraries`) Step 3 (Design) で `remix-helper` library の API signature を確定するための **source-of-truth** を確定する。

User 指示 (Intent Spec L94-L97): 「`hono-remix-v3-cloudflare-example` を C-4 / C-5 抽出の基準 source-of-truth として位置付ける」。よって本 Note は `js/app/hono-remix-v3-cloudflare-example/app/{routes.ts,ui/page-or-frame.tsx,ui/content-layout.tsx,ui/frame-link.tsx,ui/document.tsx,app.tsx}` を最小単位で観測し、他 2 projects との diff から factory 抽出可能性を判定する。

カバーする論点:

- `routes.ts` の `frames` registry / `FrameName` 型 / `isFrameRequest` 関数の現状実装を、文字レベルで確定する
- `ui/page-or-frame.tsx` の `createPageOrFrame` HOF の現状シグネチャ (ジェネリクス変位 / `Handle<P>` 制約 / `RemixNode` 制約 / `createElement` 採用理由) を確定する
- 3 projects (`hono-remix-v3-cloudflare-example` / `feed-platform-web` / `identity-provider`) の `routes.ts` / `document.tsx` を diff し、Phase 1 retrospective が言う「3 プロジェクト同形」がどこまで正確か観測する
- factory `createFrameHelpers(frames)` が、3 projects すべての現状実装を **同一 factory で表現可能** か (差分があるなら何か) を判定する
- 各 project の use case inventory (どの frame name を持つか / どの page を採用しているか)

カバーしない論点:

- factory の具体的 TypeScript signature (Step 3 Design 責務)
- `InferFrameName<T>` 実装パターン (別 researcher 角度 D で並列調査中)
- Effect API レベルの整合性 (別 researcher 角度 A で並列調査中)
- `Frame` / `FrameLink` 自体の library 化 (本 cycle 抽出対象外、C-4 / C-5 のみ)

## Findings

### F-1: `hono-remix-v3-cloudflare-example/app/routes.ts` (source-of-truth) は最小限の Hono context 依存実装

- `frames` は `{ content: 'content' } as const` の **1 entry のみ**を持つ object literal で、`as const` により `{ readonly content: 'content' }` 型に narrow される (`js/app/hono-remix-v3-cloudflare-example/app/routes.ts:11-13`)
- `FrameName` は `(typeof frames)[keyof typeof frames]` 経由で **value 側から union literal 型**を導出 (`:15`)。本 file 例では `'content'` 単一 literal
- `isFrameRequest` は `(frame: FrameName): boolean => getContext().req.header('x-remix-target') === frame` の **1 行関数** (`:26`)
  - 引数 `frame: FrameName` で typo を型エラー化
  - `hono/context-storage` の `getContext()` 経由で current Hono Context を取得 (依存: `contextStorage()` middleware が chain に必要)
  - 比較対象は HTTP header `x-remix-target` のみ (query / cookie 不参照)
- value (`frames.content` の string) と key (`'content'`) が同一文字列。これは慣例だが factory 上は強制不要 (後述 F-7)

### F-2: `createPageOrFrame` は 3 段階のカリー化 HOF で `RemixNode` 制約 children-handling を持つ

`js/app/hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx:20-31`:

```typescript
export const createPageOrFrame =
  <P extends { children?: RemixNode }>(frameName: FrameName, layout: (handle: Handle<P>) => () => RemixNode) =>
  (handle: Handle<P>) =>
  () => {
    if (isFrameRequest(frameName)) {
      return handle.props.children
    }
    return createElement(layout, handle.props)
  }
```

- `P extends { children?: RemixNode }` で **layout の props は children を受けられる任意の object**
- 引数: `frameName: FrameName` (literal narrowed) + `layout: (handle: Handle<P>) => () => RemixNode` (= Remix 3 系 component factory pattern)
- 戻り値: `(handle: Handle<P>) => () => RemixNode` の **Remix 3 component factory** そのもの (Remix の `<X>` JSX で展開可能)
- 実行時の dispatch:
  - `isFrameRequest(frameName)` が true → `return handle.props.children` (children のみを返す = frame fragment 出力)
  - false → `createElement(layout, handle.props)` (Layout 全体を render = 完全 page 出力)
- `<layout {...handle.props} />` ではなく `createElement(layout, handle.props)` を直接呼ぶ理由がコメントで明示 (`:27-29`): TS が generic `P` を JSX runtime の variance で reduce できないため。**runtime semantics は同一**

### F-3: `<Frame>` / `<FrameLink>` の type 仕様: `name` は `string` で literal narrowing は consumer 側で必要

`@remix-run/ui` (`remix/ui` re-export) の `FrameProps` (`node_modules/.pnpm/@remix-run+ui@0.1.1/node_modules/@remix-run/ui/dist/runtime/component.d.ts:133-142`):

```typescript
export interface FrameProps {
  name?: string // optional, plain string
  src: string
  fallback?: Renderable
  on?: Record<string, (event: Event, signal: AbortSignal) => void | Promise<void>>
}
```

- `Frame` 自体は `name: string` を受けるだけで、**literal narrowing しない**
- consumer 側 (= `hono-remix-v3-cloudflare-example/app/ui/content-layout.tsx:58` `<Frame name={frames.content} src={...} />` と `:48`,`:51` `<FrameLink rmx-target={frames.content} ...>`) で「frames literal を渡す」運用で typo を防いでいる
- アプリ独自の `FrameLink` (`js/app/hono-remix-v3-cloudflare-example/app/ui/frame-link.tsx:5-9`) のみが `'rmx-target': FrameName` で **literal 型を強制**: `rmx-target` で `FrameName` 以外の値を渡すと TS error

### F-4: `x-remix-target` header の semantic は remix runtime 側で確定済 (library 改変対象外)

- server 側生成: `js/package/hono-remix-middleware/src/renderer.tsx:60-61` (`headers.set('x-remix-target', target)`)
- client 側生成: `js/package/vite-plugin-remix/src/client/boot.ts:49-50` (同様)
- つまり `'x-remix-target'` という header 名と「target 名 = `<Frame name>` value」という protocol は本 cycle 改変対象外。`isFrameRequest` factory はこの protocol を保持する義務がある

### F-5: 3 projects の `routes.ts` は frames registry の中身以外完全同形 (= 同一 factory で表現可能)

- `hono-remix-v3-cloudflare-example/app/routes.ts:11-13` のみ `frames = { content: 'content' } as const` (1 entry)
- `feed-platform-web/app/routes.ts:13` と `identity-provider/app/routes.ts:13` は **両方とも `frames = {} as const`** (空 object、Phase 1 TC-022 で「PageOrFrame パターン未採用」のため空骨格)
- 3 ファイル間の diff は以下のみ (確認済):
  - frames object literal の中身 (`{ content: 'content' }` vs `{}`)
  - docstring 文言 (英語 vs 日本語、ms-01 状況説明)
- **`isFrameRequest` の実装行は 3 file とも完全同一**: `(frame: FrameName): boolean => getContext().req.header('x-remix-target') === frame`
- **`FrameName` 型導出も 3 file とも完全同一**: `(typeof frames)[keyof typeof frames]`

### F-6: 既知の TS quirk: `frames = {} as const` は `FrameName = never` を生む → `isFrameRequest` が呼出不能

Phase 1 review/api-design.md M-2 で記録された問題 (`docs/workflow/feed-platform-ms-01-workspace-foundation/review/api-design.md:15`):

- `frames = {} as const` は `FrameName = (typeof frames)[keyof typeof frames] = never`
- 結果 `isFrameRequest: (frame: never) => boolean` で **型レベル uncallable** (誰も値を渡せない関数になる)
- Phase 1 Round 2 (`dacf3e4`) の対応: 「IdP / web 両方とも `{} as const` に揃えて、ms-04 で frames を埋める前提を docstring に明示」(= API surface uncallable を accept する判断)
- これは Phase 2 factory 設計で **重要な検討点**: `createFrameHelpers({})` を渡せた場合に factory 戻り値の `isFrameRequest` が型レベル uncallable に縮退する挙動を「許容するか / 警告するか / disallow するか」を Step 3 で決める必要がある

### F-7: `frames` registry の key と value の semantic は分離している (factory 抽出時の自由度)

- `hono-remix-v3-cloudflare-example/app/routes.ts:11-13` では key=`'content'` / value=`'content'` で同一
- 利用箇所では:
  - **value 側を使う**: `<Frame name={frames.content}>` (`content-layout.tsx:58`), `<FrameLink rmx-target={frames.content}>` (`:48`, `:51`), `createPageOrFrame(frames.content, Layout)` (`:63`), `isFrameRequest(frame)` 引数 (`page-or-frame.tsx:24`)
  - **key 側を使う箇所は無い** (key は registry の identifier 役にのみ機能)
- つまり「`x-remix-target` header と `<Frame name>` で照合される文字列」は **value 側**であり、key は単なる alias
- factory 抽出では **value のほう**が `string` で、key は consumer の好みで自由に命名できる構造になる
- Intent Spec の `createFrameHelpers<F extends Record<string, string>>(frames: F)` (L80-L84) はこの観測と整合する

### F-8: `hono-remix-v3-cloudflare-example` のみ Counter / TODO / Frame UI を実装、web / IdP は document.tsx のみ

- `hono-remix-v3-cloudflare-example/app/ui/` 配下: `content-layout.tsx` / `counter.client.tsx` / `document.tsx` / `frame-link.tsx` / `page-or-frame.tsx` / `todo.client.tsx` (6 file)
- `feed-platform-web/app/ui/` 配下: `document.tsx` のみ (1 file)
- `identity-provider/app/ui/` 配下: `document.tsx` のみ (1 file)
- → C-5 `createPageOrFrame` 実装の **唯一の存在**は `hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx`。web / IdP は本 cycle で初めて採用する (= 既存 file の置換ではなく新規 import)

### F-9: 3 projects の `document.tsx` も完全同形 (title default 値以外)

- 3 file の structural diff:
  - `<title>` default: `'Hono Remix Example'` / `'feed-platform-web'` / `'Identity Provider'` の 3 通り
  - `Document` 関数本体 (HTML structure / `<Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js' />`) は **3 ファイル完全一致**
  - import (`import type { RemixNode } from 'remix/ui'` / `import { Script } from 'vite-plugin-remix/client'`) も完全一致
- 本 Note の責務外 (Document は C-11 / C-12 系で別 cycle 候補) だが、3 ファイル diff の検証対象としてカウント

### F-10: `app.tsx` で `PageOrFrame` を採用しているのは hono-remix-v3-cloudflare-example のみ

- `hono-remix-v3-cloudflare-example/app/app.tsx:20-34`:
  - `app.get('/', (c) => c.render(<PageOrFrame title='Counter'><h1>Counter</h1></PageOrFrame>))`
  - `app.get('/todo', (c) => c.render(<PageOrFrame title='TODO'><h1>TODO</h1><Todo /></PageOrFrame>))`
- `PageOrFrame` は `content-layout.tsx:63` で `createPageOrFrame(frames.content, Layout)` の closure として作られた **app-singleton** (frame name `'content'` を bind 済)
- 本 cycle migration では:
  - `hono-remix-v3-cloudflare-example`: `createPageOrFrame` import 元を `'./page-or-frame.tsx'` から `'remix-helper'` に切替 (behavior 不変、SC-7)
  - `feed-platform-web` / `identity-provider`: 現在は `c.render(<Document>...)` のみ (TC-022 観測)。本 cycle Step 3 で「現状の素朴な c.render を維持しつつ `createFrameHelpers` を import だけする」のか「PageOrFrame パターンを web/IdP にも適用するか」は Intent Spec SC-6 の「`createFrameHelpers` factory + `InferFrameName` 型関数が利用されている」要件 (各 project ≥ 1 hit) を満たす最小形で実装する判断が必要

## Sources

### 主要観測対象 (1 次情報)

- `js/app/hono-remix-v3-cloudflare-example/app/routes.ts:11-26` (frames / FrameName / isFrameRequest 全実装)
- `js/app/hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx:20-31` (createPageOrFrame 全実装)
- `js/app/hono-remix-v3-cloudflare-example/app/ui/content-layout.tsx:48-63` (frames.content の utilization 4 箇所 + PageOrFrame export)
- `js/app/hono-remix-v3-cloudflare-example/app/ui/frame-link.tsx:5-29` (FrameLink: FrameName 型強制した型付き anchor)
- `js/app/hono-remix-v3-cloudflare-example/app/app.tsx:20-34` (PageOrFrame の 2 route 採用)
- `js/app/hono-remix-v3-cloudflare-example/app/ui/document.tsx:1-22` (source-of-truth Document)
- `js/app/feed-platform-web/app/routes.ts:13-25` (web 側、frames は空)
- `js/app/feed-platform-web/app/ui/document.tsx:12-24` (web 側)
- `js/app/identity-provider/app/routes.ts:13-25` (IdP 側、frames は空)
- `js/app/identity-provider/app/ui/document.tsx:10-22` (IdP 側)

### 周辺仕様 (2 次情報)

- `node_modules/.pnpm/@remix-run+ui@0.1.1/node_modules/@remix-run/ui/dist/runtime/component.d.ts:133-142` (`FrameProps.name?: string`)
- `node_modules/.pnpm/@remix-run+ui@0.1.1/node_modules/@remix-run/ui/dist/index.d.ts:9-13` (`Frame` / `Handle` / `RemixNode` 等の export 情報)
- `js/package/hono-remix-middleware/src/renderer.tsx:60-61` (`x-remix-target` header server 側書込)
- `js/package/vite-plugin-remix/src/client/boot.ts:49-50` (同 client 側書込)

### Phase 1 履歴 (検証材料)

- `docs/workflow/feed-platform-ms-01-workspace-foundation/research/hono-remix-cloudflare-example-structure.md:204-218` (Phase 1 で観測された hono-remix 構造概要)
- `docs/workflow/feed-platform-ms-01-workspace-foundation/review/api-design.md:15` (`FrameName = never` poisoning 問題と Round 2 解消)
- `docs/workflow/feed-platform-ms-01-workspace-foundation/qa-design.md:87` (TC-022: web / IdP は createPageOrFrame 不採用観測仕様)
- `docs/retrospective/feed-platform-ms-01-workspace-foundation.md:90` (Step 3 で PageOrFrame future direction 決定)

### Intent Spec / Roadmap

- `docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md:73-89` (Q4: createFrameHelpers + InferFrameName 設計案)
- `docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md:90-104` (Q5: hono-remix-v3-cloudflare-example も migration target)
- `docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md:155-162` (SC-5 / SC-6 / SC-7)
- `docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md:150` (`createPageOrFrame` 採用は ms-04 / ms-07 で確定の経緯)

## Implications for design

Step 3 (Design) で `architect` が `js/package/remix-helper/` の API を fix する際、本 Note の観測から以下の制約と推奨が確定する。

### I-1: `createFrameHelpers` factory の input 型は `Record<string, string>` で十分 (key と value の semantic 分離)

- F-7 観測: 利用箇所はすべて value 側 (`frames.content`)、key は consumer alias
- 結論: factory の signature は `<F extends Record<string, string>>(frames: F) => { ... }` (Intent Spec L80-L84 案で問題なし)
- 設計者は **value を `<Frame name>` / `x-remix-target` 比較対象**として固定する documentation を library 内 docstring に書くこと

### I-2: `isFrameRequest` の return 型は `boolean` 単純、`getContext()` 依存は library 内に隠蔽

- F-1 観測: 関数本体は 1 行、`hono/context-storage` の `getContext()` 直呼び
- 結論: factory 戻り値の `isFrameRequest` は **`hono/context-storage` を peer-dependency**として明記し、library 内で `getContext()` を呼ぶ。consumer 側は `contextStorage()` middleware を chain に置く義務を docstring で明示
- 引数型は `keyof F` ではなく **`F[keyof F]`** (= value union) にする (F-7 / F-3 整合: header 比較対象は value 側)
- ただし Intent Spec L82 案は `name: keyof F` と書かれている。**ここに食い違いがある**: 既存実装は `(frame: FrameName)` で `FrameName = (typeof frames)[keyof typeof frames]` (= value union)。Step 3 で「Intent Spec の signature 案を `name: F[keyof F]` に訂正する」推奨

### I-3: `createPageOrFrame` の戻り値は Remix 3 component factory pattern を維持 (= `(handle) => () => RemixNode`)

- F-2 観測: 既存実装は `(layout: (handle: Handle<P>) => () => RemixNode) => (handle: Handle<P>) => () => RemixNode` の signature
- 結論: Step 3 で factory 戻り値の `createPageOrFrame` は **完全に既存と同じ signature** を維持する。ジェネリクス `P extends { children?: RemixNode }` も維持
- `createElement(layout, handle.props)` の採用理由 (TS variance 限界) は **library 内コメントとして引き継ぐ**こと。後続 maintainer が `<layout {...handle.props} />` に書き換えて build 失敗するのを防ぐ
- 呼び出し時の `frameName` 引数は `F[keyof F]` (value side) で I-2 と整合

### I-4: 3 project は単一 factory で表現可能 (差分は frames object literal の中身のみ)

- F-5 / F-9 観測: `routes.ts` 中 `isFrameRequest` 実装行と `FrameName` 型導出は完全同形、差分は frames literal の中身のみ
- 結論: factory `createFrameHelpers(frames)` を **3 projects すべてで同一 import / 同一呼出形**にできる
  - `hono-remix-v3-cloudflare-example`: `createFrameHelpers({ content: 'content' })`
  - `feed-platform-web` / `identity-provider`: `createFrameHelpers({})` (= ms-01 と同じ「PageOrFrame 未採用」状態を表す)
- 副作用: 各 project の `routes.ts` は library 呼出 1 行 + `InferFrameName` 型導出 1 行に縮約される (= Phase 1 で 3 ファイル同形コピーされていた 26 行が 3〜5 行に減る)

### I-5: 空 `frames` のときの `isFrameRequest` 縮退挙動 (F-6) は Step 3 で明示判断する

- F-6 観測: `frames = {}` を渡すと `isFrameRequest: (frame: never) => boolean` (uncallable) になる
- 既存 Phase 1 は「許容、ms-04 で埋める前提を docstring に書く」で着地済 (review/api-design M-2)
- 推奨: factory も同じ挙動 (`F[keyof F] = never` で uncallable に縮退) を継承する。理由: TS の自然な型推論結果なので歪めない / Phase 1 で User judgment 済
- ただし Step 3 では「`createFrameHelpers({})` を渡したときの戻り値の使い道は `frames` registry 提供のみ」を docstring 例に書くこと

### I-6: `Frame` / `FrameLink` 自体の type 強化は library 側に閉じない (consumer 側 helper)

- F-3 観測: `<Frame name>` は `string` 型で、literal narrowing は consumer 側 `FrameLink` (アプリ実装) で行われている
- 結論: 本 cycle で `FrameLink` は library 化対象外 (Intent Spec L78-L89 で C-4 / C-5 のみ抽出、Document / FrameLink は出してない)
- ただし Step 3 で「`createFrameHelpers` の戻り値に `FrameLink` factory も含めるか」を再検討する余地あり (User 判断要、Phase 2 scope 拡張議題)。**本 Note では現状の Intent Spec scope (C-4 / C-5 のみ) を尊重し、含めない方向で記録**
- migration では `hono-remix-v3-cloudflare-example/app/ui/frame-link.tsx` は consumer 側に残置。**ただし `FrameName` 型 import 元を `routes.ts` から `InferFrameName<typeof helpers>` 経由に書き換える必要**がある

### I-7: SC-6 (3 project 各 ≥ 1 hit) の最小達成形

- web / IdP は現在 PageOrFrame パターン未採用 (F-8 / F-10)。SC-6 の `grep -rn 'createFrameHelpers\|InferFrameName'` を 1 hit 出すための最小形は:
  - **option A**: `routes.ts` で `createFrameHelpers({})` 呼出のみ (PageOrFrame は未採用維持、Phase 1 同様)
  - **option B**: web / IdP にも PageOrFrame パターンを今 cycle で導入 (機能拡張)
- 観測事実から推奨: option A (= refactor only / 機能変更なし、Intent Spec L98-L99 commit 構造 atomic 整合 + SC-7 hono-remix behavior 保持と並列)
- option B を選ぶには別の Intent Spec 改訂が必要 (Phase 1 TC-022 の決定を覆すため)
- Step 3 では option A を default として進めることを推奨

### I-8: `hono/context-storage` 依存は `effect-hono` ではなく `remix-helper` に置く (パッケージ責務分離)

- F-1 観測: `isFrameRequest` の唯一の hard dependency は `hono/context-storage` のみ (Effect 一切非依存)
- 結論: Intent Spec Q3 で確定した「`remix-helper` は Hono と無関係」という User 表現 (L60-L61) と **観測事実は若干衝突**: `isFrameRequest` は `hono/context-storage` に依存している
- 推奨: User へ「`remix-helper` は `hono/context-storage` への peer dependency が必要だが、これは `hono` の middleware framework としての側面ではなく **HTTP context retrieval primitive**としての利用」を Step 3 design.md で明示する。あるいは Hono context をパラメータで受ける形に factory signature を拡張するか (= consumer が `getContext()` を呼んで factory に context を渡す) を Step 3 で再検討

## Remaining unknowns

### U-1: `isFrameRequest` 引数型を `keyof F` (Intent Spec 案) と `F[keyof F]` (既存実装) のどちらに揃えるか

- I-2 で詳述した signature の食い違い
- Intent Spec L80-L84 では `keyof F` (key 側 union)、既存実装では value union (`(typeof frames)[keyof typeof frames]`)
- factory 設計の正解は value union (header 比較対象が value 側だから) だが、Intent Spec の表記が key 側になっている
- **解決提案**: Step 3 architect が design.md で訂正案を提示し、Intent Spec corrigendum として Main 経由で User 確認 (Phase 1 retrospective で確立した「即時 corrigendum」プロセス)

### U-2: `frames = {}` (空 registry) の factory 戻り値 type 縮退を許容するか

- I-5 で示した F-6 由来の問題
- Phase 1 では「許容、docstring で警告」で着地済
- Phase 2 factory でも同じ着地で良いと観測されるが、library API 設計として「より厳格にエラーを出す」選択肢 (overload で空 object を弾く等) もあり
- **解決提案**: Step 3 で architect が「Phase 1 と同じ降格挙動を継承」を default 提案として記載、User confirm 不要 (Phase 1 で既に判断済)

### U-3: `remix-helper` への `hono/context-storage` peer-dep を許容するか

- I-8 で詳述した責務境界の question
- User 表現「remix-helper は Hono と無関係」(Intent Spec L61) と既存 `isFrameRequest` 実装の `getContext()` 直呼びは **観測事実として衝突**
- 解決の道は 2 つ:
  - (a) factory `isFrameRequest` の signature を `(req: Request, frame: F[keyof F]) => boolean` に変えて Hono dependency を消す (= consumer 側で `getContext().req.raw` を渡す)
  - (b) `hono/context-storage` peer-dep を許容、docstring で「context-storage middleware を chain に置く義務」を明記
- 既存実装は (b) 形なので migration cost は最小
- **解決提案**: Step 3 architect が両案 (a)(b) の比較表を design.md に書き、User judgment を受ける (= Main → User 経由で In-Progress 質問)

### U-4: web / IdP の SC-6 達成形 (option A vs option B、I-7 で詳述)

- 観測上は option A (refactor only / PageOrFrame 未採用継続) を推奨
- ただし Intent Spec が SC-6 で「`createFrameHelpers` factory + `InferFrameName` 型関数が利用されている」と書いており、最小限の利用形が「import + factory call 1 行」だけで成立するか、それとも実利用 (PageOrFrame 採用) まで含むか **解釈の余地あり**
- **解決提案**: Step 3 architect が design.md で option A を default 提案として明記、Step 4 (QA Design) で SC-6 観測仕様を「`grep` hit ≥ 1 で十分」と明文化

### U-5: `FrameLink` を library に含めるか (将来 cycle 議題)

- I-6 で議論済、現状 Intent Spec scope 外
- **解決提案**: Step 3 では含めない、Phase 2 retrospective で「次サイクル候補」として記録するに留める

### U-6: Phase 1 で `FrameName` を export していた consumer (frame-link.tsx 等) の import path 切替

- 観測: `js/app/hono-remix-v3-cloudflare-example/app/ui/frame-link.tsx:3` が `import type { FrameName } from '../routes.ts'`、`page-or-frame.tsx:5` も同様
- migration 後は `FrameName = InferFrameName<typeof helpers>` を `routes.ts` で再 export する形になる (= consumer 内 import path は不変、`routes.ts` が再 export する form を取れば break しない)
- **解決提案**: Step 3 で「`routes.ts` から `FrameName` を引き続き re-export する」design を明示。これにより `frame-link.tsx` 等の修正は不要 (= migration scope 縮小)
