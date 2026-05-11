# Research Note: infer-frame-name-type-utility-pattern

- **Identifier:** feed-platform-ms-01-shared-libraries
- **Topic:** infer-frame-name-type-utility-pattern
- **Researcher:** researcher (Phase 2 Step 2, angle "InferFrameName type utility pattern")
- **Created at:** 2026-05-07T06:30:00Z
- **Scope:** `createFrameHelpers` factory と並んで提供する `InferFrameName<T>` 型関数の TypeScript 実装パターン (型レベル設計のみ)。値レベルの factory 振る舞い・ Effect API 統合・他 candidate (C-1〜C-3) は対象外。

## Subject of investigation

Phase 2 Q4 で確定した「factory 戻り値 (値) と `InferFrameName<T>` (型) を分離する」方針のうち、**型関数側** の実装パターンを確定するための調査。具体的には次の 5 点:

1. factory が返す struct から、入力 frame names の string literal union を **type-level** で抽出する標準 TypeScript パターンの整理
2. user 指示「型は返せないのではないでしょうか？InferFrameName のような型関数を別途用意するのがいい」 (intent-spec.md:74-75) に対し、`InferFrameName<T>` の **型引数 T には何を渡すべきか** の選択肢
3. 想定 use case: `const helpers = createFrameHelpers(...)` → `type Frame = InferFrameName<typeof helpers>` で literal union を取り出す体験
4. consumer に `as const` を強制するか / TypeScript 5.x の `<const T extends readonly ...>` で吸収するか
5. effect / `@totto2727/fp` 等の先行 `Infer*` パターン参照

intent-spec.md の Success Criteria SC-6 (3 projects + hono-remix-v3-cloudflare-example で `createFrameHelpers` + `InferFrameName` が利用されている) と Constraint「抽象化原則: 具体を後から渡す箇所と抽象化する箇所を一緒くたにしない」 (intent-spec.md:198) に応える設計情報を、Step 3 (Design) の architect が直接 design.md に取り込める粒度で提供する。

## Findings

### F-1. リポジトリの TypeScript バージョンと tsconfig

- catalog 上の TypeScript バージョン: `typescript: ^5.9.2` (`pnpm-workspace.yaml:26`)。同 catalog に `@typescript/native-preview: 7.0.0-dev.20251117.1` (`pnpm-workspace.yaml:25`) も存在するが本 cycle の対象は `tsc` 5.9 系。
- `js/package/` 配下の library 用 tsconfig preset (`js/package/fp/src/tsconfig/vite.json`):
  - `target: esnext` / `module: esnext` / `moduleResolution: bundler` (`vite.json:7-9`)
  - `@tsconfig/strictest` を `extends` (`vite.json:3`)
  - `verbatimModuleSyntax: true` (`vite.json:24`) — 型 export と値 export の分離が必要
  - `erasableSyntaxOnly: true` (`vite.json:18`) — namespace の値同梱は不可、`namespace X { export type Y = ... }` 形式のみ可
- 結論: TypeScript 5.0 で導入された `const` type parameters / `satisfies` operator (TS 4.9+) / `infer extends` (TS 4.7+) はすべて利用可能。

### F-2. 既存 frame helpers の現状コード (= 抽出元)

`hono-remix-v3-cloudflare-example/app/routes.ts:11-26`:

```typescript
export const frames = {
  content: 'content',
} as const

export type FrameName = (typeof frames)[keyof typeof frames]

export const isFrameRequest = (frame: FrameName): boolean => getContext().req.header('x-remix-target') === frame
```

`feed-platform-web/app/routes.ts:13-26` と `identity-provider/app/routes.ts:13-26` は **完全同形** で、`frames = {} as const` (空の placeholder) のみ違い。

重要観察:

- `frames` は `Record<string, string>` (key-value map: `{ content: 'content' }`) の形 — **key と value が独立**
- `FrameName` は **values の union** (= `(typeof frames)[keyof typeof frames]`)。**keys の union ではない** ことに注意
- `as const` が consumer 側で必須 (現状は手動)
- intent-spec.md:80-89 の草案 `keyof F` (= keys を取り出す) は既存実装の `(typeof frames)[keyof typeof frames]` (= values を取り出す) と意味論が異なる — Step 3 design でどちらを採るか確定すべき論点として残る (本 Research Note では両方扱う)

### F-3. リポジトリ内の先行 `Infer*` パターン

リポジトリ内に同種の type-level extraction パターンが既に存在:

- **`InferOk<T>` / `InferErr<T>`** (`js/package/fp/src/option-t/safe-try.ts:46`, `:53`):

  ```typescript
  export type InferOk<T extends R.Result<unknown, unknown>> = T extends R.Ok<infer O> ? O : never
  export type InferErr<T extends R.Result<unknown, unknown>> = T extends R.Err<infer E> ? E : never
  ```

  conditional type + `infer` で型引数を取り出す古典パターン。consumer は `type X = InferOk<typeof result>` で利用。

- **`Array.ReadonlyArray.Infer<S>`** (Effect 4.0.0-beta.60 公式; `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Array.d.ts:5249-5264`):

  ```typescript
  export declare namespace ReadonlyArray {
    type Infer<S extends Iterable<any>> = S extends ReadonlyArray<infer A> ? A : S extends Iterable<infer A> ? A : never
  }
  ```

  これも conditional type + `infer` の組み合わせ。`<const T>` + `Infer<T>` の併用は同 Effect ライブラリの `js/package/fp/src/effect/util.ts:43` で確立 (例: `const tap = <const T extends readonly unknown[]>(fn: (v: Array.ReadonlyArray.Infer<T>) => void)`)。

- **`Schema.Schema.Type<S>`** (Effect Schema; `node_modules/.../effect/dist/Schema.d.ts:467`):

  ```typescript
  type Type<S> = S extends Top ? S['Type'] : never
  ```

  phantom property (`["Type"]`) による型抽出。schema が値として保持する型情報の取り出しに使う。

### F-4. TypeScript 5.0+ `const` type parameters の公式仕様

公式 release notes (https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html) より:

- `<const T extends Constraint>` の形で literal-style inference を関数引数に強制できる (TS 5.0+)
- `readonly` constraint と組み合わせない場合、mutable な constraint (`string[]` 等) では effect が無く `T` は wide な型に推論される
- **重要な制約**: 「変数経由」だと `const` 修飾の効果が消える:

  ```typescript
  declare function fn<const T extends readonly string[]>(args: T): void
  fn(['a', 'b']) // T = readonly ['a', 'b']
  const arr = ['a', 'b']
  fn(arr) // T = string[] (consumer に as const が再び必要)
  ```

実装上の意味: consumer が `createFrameHelpers(['header', 'footer'])` のように **inline literal** を渡す限り `<const T>` で as const 不要。`const arr = [...]; createFrameHelpers(arr)` 形の場合は consumer 側で `as const` が必要 (これは TypeScript 言語仕様上不可避)。

### F-5. user 指示の解釈 (intent-spec.md:74-75)

user 指示原文: 「型は返せないのではないでしょうか？InferFrameName のような型関数を別途用意するのがいい」 (Q4 dialogue で確定、intent-spec.md:74-89 反映)。

解釈:

- 値レベル factory `createFrameHelpers(...)` は **値のみ** (object: `{ frames, isFrameRequest, createPageOrFrame }` 等) を返す
- 型は値レベルでは返せない (TypeScript の値/型分離原則)
- consumer が型を取り出すための **型関数 `InferFrameName<T>`** を library が別途 export
- `T` には consumer の **使用箇所** で `typeof helpers` (factory 戻り値) または `typeof someConst` (input frames 自体) を渡す

→ 「型関数」= TypeScript の `type Foo<T> = ...` 構文で書かれる generic type alias (Effect の `Schema.Type<S>` や fp の `InferOk<T>` と同種)。

### F-6. zod / valibot の literal-union 推論パターン (参考のみ)

dependencies に追加しないが、設計パターン参考として:

- **zod**: `z.enum(['a', 'b'] as const)` で enum を作り、`z.infer<typeof e>` で `'a' | 'b'` を取り出す。`z.infer<T>` の実装は `T extends ZodType<infer O> ? O : never` 系の conditional type
- **valibot**: `v.picklist(['a', 'b'])` + `v.InferOutput<typeof p>` で同様。`InferOutput<T>` も conditional + `infer` パターン
- 両者とも **schema を保持する object に phantom type 情報を埋めて取り出す** (Effect Schema の `S["Type"]` と同型)

→ 本 cycle の `createFrameHelpers` も同種の object を返すので、`InferFrameName<T>` は両 ecosystem と整合する書き方が可能。

## Sources

- TypeScript 5.0 Release Notes "const Type Parameters": https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html
- TypeScript Handbook "Conditional Types / Inferring Within Conditional Types": https://www.typescriptlang.org/docs/handbook/2/conditional-types.html
- pnpm-workspace catalog TypeScript version: `pnpm-workspace.yaml:26`
- Library tsconfig preset: `js/package/fp/src/tsconfig/vite.json:3-25`
- 既存 frame helpers (抽出元): `js/app/hono-remix-v3-cloudflare-example/app/routes.ts:11-26`, `js/app/hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx:20-31`, `js/app/hono-remix-v3-cloudflare-example/app/ui/frame-link.tsx:1-29`
- 同形コピー (placeholder): `js/app/feed-platform-web/app/routes.ts:13-26`, `js/app/identity-provider/app/routes.ts:13-26`
- 既存 `Infer*` 型関数: `js/package/fp/src/option-t/safe-try.ts:46`, `:53`
- `<const T>` + `Infer<T>` 併用パターン: `js/package/fp/src/effect/util.ts:43`
- Effect 4.0.0-beta.60 `Array.ReadonlyArray.Infer`: `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Array.d.ts:5264`
- Effect 4.0.0-beta.60 `Schema.Schema.Type`: `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Schema.d.ts:467`
- Intent Spec Q4 確定内容: `docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md:62-89`

## Implications for design

### I-1. 型関数の実装は "conditional type + `infer`" の古典パターンで十分

リポジトリ内 (`InferOk` / `InferErr`) と Effect 公式 (`ReadonlyArray.Infer` / `Schema.Type`) のいずれも同一パターン (`T extends Pattern<infer X> ? X : never`) で確立済。`InferFrameName<T>` も同パターンに乗せれば、reviewer の認知負荷が最小化される。Step 3 design でこのパターンを起点にすればよい。

### I-2. 比較対象パターン 3 種の整理 (Step 3 で 1 つに収束)

Phase 2 Q4 で「`Record<string, string>` を受ける」草案 (intent-spec.md:80-89) が記録されているが、本 Research Note の調査結果から **少なくとも 3 つの型関数設計** が候補として浮上する。Step 3 design で 1 つに収束させる。

#### Pattern P1: factory 戻り値型から keys を抜く (intent-spec.md 草案準拠)

```typescript
// library
export const createFrameHelpers = <const F extends Record<string, string>>(frames: F) => ({
  frames,
  isFrameRequest: (name: keyof F): boolean => /* ... */,
  // ...
})

export type InferFrameName<T extends ReturnType<typeof createFrameHelpers>> = keyof T['frames']

// consumer
const helpers = createFrameHelpers({ content: 'content', sidebar: 'sidebar' })
type FrameName = InferFrameName<typeof helpers>  // 'content' | 'sidebar'
```

| 観点              | 評価                                                                                                                                                                                                                                                             |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pros              | (1) intent-spec.md 草案と整合、(2) consumer は `InferFrameName<typeof helpers>` の 1 行で取り出せる                                                                                                                                                              |
| Cons              | (1) 既存 `hono-remix-v3-cloudflare-example/app/routes.ts:15` の `(typeof frames)[keyof typeof frames]` (= **values の union**) と意味論が異なる (= keys を採る)、(2) `ReturnType<typeof createFrameHelpers>` の型がジェネリクスをまたぐと推論が脆くなる (未検証) |
| TS バージョン要件 | 5.0+ (`<const F>` のため)。conditional type 部分自体は TS 2.8+                                                                                                                                                                                                   |
| Step 3 で要検証   | `ReturnType<typeof createFrameHelpers>` のジェネリクス T が consumer 側 `typeof helpers` から逆推論できるか (= F が distributed されるか) — **未検証 (Step 3 Design で実機検証要)**                                                                              |

#### Pattern P2: 入力配列 (string literal tuple) を直接渡す

```typescript
// library
export const createFrameHelpers = <const T extends readonly string[]>(frames: T) => ({
  frames,
  isFrameRequest: (name: T[number]): boolean => /* ... */,
  // ...
})

// 型関数の T には input 配列の型を渡す (factory 戻り値ではなく)
export type InferFrameName<T extends readonly string[]> = T[number]

// consumer
const FRAMES = ['header', 'footer'] as const
const helpers = createFrameHelpers(FRAMES)
type FrameName = InferFrameName<typeof FRAMES>  // 'header' | 'footer'

// もしくは inline で <const T> に頼り as const 不要:
const helpers2 = createFrameHelpers(['header', 'footer'])
type FrameName2 = (typeof helpers2)['frames'][number]  // ← ただしこれは別途 helper 経由が良い
```

| 観点              | 評価                                                                                                                                                                            |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pros              | (1) 型関数が conditional type 不要で `T[number]` 一発、(2) 意味論が明快 (= input tuple → element union)                                                                         |
| Cons              | (1) `T` に渡すべきものが「factory 戻り値」ではなく「input 配列」になる体験が、Pattern P1 と異なる、(2) 既存 `routes.ts` は `Record<string, string>` 形なので mapping 工夫が必要 |
| TS バージョン要件 | 5.0+ (`<const T>` のため)                                                                                                                                                       |
| Step 3 で要検証   | 既存 `Record<string, string>` 形の object も受け付けたい場合のオーバーロード設計 — **未検証 (Step 3 Design で実機検証要)**                                                      |

#### Pattern P3: factory 戻り値型から phantom property を取り出す (Effect Schema 風)

```typescript
// library
const FrameNameBrand = Symbol.for('@feed-platform/remix-helper/InferFrameName')

export type FrameHelpers<N extends string> = {
  frames: readonly N[]
  isFrameRequest: (name: N) => boolean
  // ...
  readonly [FrameNameBrand]?: N // phantom (実体 undefined)
}

export const createFrameHelpers = <const T extends readonly string[]>(frames: T): FrameHelpers<T[number]> => ({
  frames /* ... */,
})

export type InferFrameName<T> = T extends FrameHelpers<infer N> ? N : never

// consumer
const helpers = createFrameHelpers(['header', 'footer'])
type FrameName = InferFrameName<typeof helpers> // 'header' | 'footer'
```

| 観点              | 評価                                                                                                                                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Pros              | (1) Effect Schema / zod / valibot と同型 (industry-standard)、(2) `InferFrameName<T>` の `T` 制約が緩い (`T extends FrameHelpers<...>` の構造マッチで吸収)、(3) library 側の戻り値型を明示できる |
| Cons              | (1) phantom property の Symbol 設計が必要 (= 実装複雑度が P1/P2 より高い)、(2) `verbatimModuleSyntax: true` 環境で `FrameHelpers` の export が `export type` になる必要                          |
| TS バージョン要件 | 5.0+ (`<const T>` のため)。phantom + conditional + `infer` 自体は TS 2.8+                                                                                                                        |
| Step 3 で要検証   | Symbol-keyed phantom が tree-shaking / Worker bundle で問題ないか — **未検証 (Step 3 Design で実機検証要)**                                                                                      |

### I-3. user 指示「型は返せない」の本質的整合は 3 パターンとも満たす

P1/P2/P3 すべて「factory は値のみ返す + 型関数を別途 export」の構造を満たすので user 指示違反はない。Step 3 design で **どれが最も「具体を後から渡す箇所と抽象化する箇所を一緒くたにしない」原則 (intent-spec.md:198 抽象化原則) と整合するか** を判断軸に選択すべき。

私見 (researcher 提案、architect 判断材料):

- P2 が「frame names は string literal の集合である」という抽象化の本質に最も近い (= consumer は string list を渡す、library は Frame 機能を提供)
- P1 は既存 `routes.ts` の `Record<string, string>` 形を保ちたい場合に良いが、key/value が同じ value (`{ content: 'content' }`) になっている現状から、`Record` 形は冗長 (key と value を独立させる必然がない)
- P3 は将来 `FrameHelpers<N>` の interface 自体を library 内で別 factory 経由でも生成可能になる拡張性を持つが、本 cycle の SC-6 (3 + 1 projects で利用) には過剰

### I-4. consumer 体験の as const 要否

- inline literal (`createFrameHelpers(['a', 'b'])` または `createFrameHelpers({ a: 'a', b: 'b' })`) → `<const T>` で as const 不要 (TS 5.0+ 公式仕様、F-4 参照)
- 変数経由 (`const FRAMES = [...]` → `createFrameHelpers(FRAMES)`) → consumer 側で `FRAMES = [...] as const` が必要 (= TypeScript 言語仕様上不可避)

→ Step 3 design でドキュメント (`README.md` または JSDoc) に **consumer pitfall** として明記すべき。

### I-5. `verbatimModuleSyntax: true` 下での export 方針

`InferFrameName` は型関数なので **必ず `export type InferFrameName<...> = ...`** で export する必要 (`verbatimModuleSyntax: true` の制約、F-1 参照)。consumer 側の import も `import type { InferFrameName } from 'remix-helper'` 形が望ましい。Step 3 design で interface 定義時に明示。

### I-6. テスト戦略 (Step 4 QA Design への申し送り)

型関数のテストは `vitest` の `expectTypeOf` または TypeScript の `// @ts-expect-error` コメントで型エラーを検出する形が標準。本 cycle SC-3 (smoke test ≥ 1 件) を満たすため、`InferFrameName<typeof helpers>` が想定 union を返すことを **type-level assertion** で書くのが最小コスト。値レベル test と並列で 1〜2 件 (= P1/P2/P3 のいずれが採用されても適用可)。

## Remaining unknowns

1. **`Record<string, string>` (P1) vs `readonly string[]` (P2) のどちらが consumer 側で自然か** — Step 3 design で architect が判断 (本 Note では両方の pros/cons を提示済)。intent-spec.md:80-89 草案は P1 寄り、既存 `routes.ts:15` は valuesベース (≒ P2 寄り) と内部矛盾がある — Step 3 で解消必要。
2. **既存 `routes.ts` の `Record<string, string>` (key/value 同名) を残すか、`readonly string[]` に migration するか** — もし残すなら P1、変えるなら P2 が自然。intent-spec.md:96-97 の「既存 behavior 保持」は **画面挙動** の保持であり、frames registry の型形式は refactor 自由 (= 内部 API のみ)。Step 3 で確認。
3. **`createPageOrFrame` の signature と `FrameName` 型の関係** — 本 Research Note では `InferFrameName<T>` の単独 signature のみ扱った。`createPageOrFrame(frameName: FrameName, layout: ...)` の `FrameName` 部分が library 内で `T[number]` / `keyof F` / phantom `N` のどれを使うかは Step 3 で他 angle (researcher B / architect) と統合判断。
4. **Step 3 design 実機検証項目**: P1 の `ReturnType<typeof createFrameHelpers>` の generic 推論が逆方向に通るか / P3 の Symbol phantom が `verbatimModuleSyntax: true` + Workers bundle で挙動するか — **未検証 (Step 3 Design で実機検証要)**。
