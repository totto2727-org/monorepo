# Research Note: effect-4-api-verification

- **Identifier:** feed-platform-ms-01-shared-libraries
- **Topic:** effect-4-api-verification
- **Researcher:** specialist-researcher (subagent, single instance)
- **Created at:** 2026-05-07T21:35:00Z
- **Scope:** Effect 4.0.0-beta.60 における Phase 2 C-2 `makeDisposableRuntime` ジェネリクス factory 化のための API 仕様確定情報。`ManagedRuntime` / `Layer` / `Context.Service` / `Symbol.asyncDispose` 連携。Phase 1 同形コピー実装 (3 プロジェクト) の差分確認とジェネリクス境界の判断材料。

## Subject of investigation

本 Research Note は **Phase 2 C-2 `makeDisposableRuntime` をジェネリクス factory として library 化する** ための前提となる Effect 4.0.0-beta.60 の API レベルでの実現可能性を検証する。Intent Spec の Open questions に列挙されている「各 factory の具体 TypeScript シグネチャ (ジェネリクス引数、変位、`as const`、Effect 4.x の `Layer.unwrap` / `Context.Tag` API 制約) — Step 3 (Design) で詳細確定」に対する **API 確定情報** を提供する。

スコープ外 (本 Note では扱わない):

- C-1 `dynamicLoggerLayer` の API 検証 (Q4 で「factory 化しない・そのまま移植」確定済、Logger.layer / Layer.unwrap が現状のまま動くことだけ確認)
- C-3 `feature/env.ts` の Service tag 命名規約 (Q4 で「library 内 1 本に統一」確定済)
- C-4 / C-5 `createFrameHelpers` の API 検証 (別 researcher 角度)

## Findings

### F-1. Effect の version と TypeScript の使用環境

- 本リポジトリで実際に解決される `effect` の version は **`4.0.0-beta.60`**
  (`pnpm-workspace.yaml` の catalog `effect: { effect: beta }` → `feed-platform-backend/node_modules/effect` symlink が `node_modules/.pnpm/effect@4.0.0-beta.60/...` を指す)。
- TypeScript 環境は `@totto2727/fp/tsconfig/vite` 由来で `target: esnext` / `lib: ["ESNext", "DOM", ...]` / `module: esnext` / `moduleResolution: bundler` (= `js/package/fp/src/tsconfig/vite.json:1-26`)。`Symbol.asyncDispose` 含む TC39 Explicit Resource Management の lib (`lib.esnext.disposable.d.ts`) は ESNext 経由で有効。

### F-2. `ManagedRuntime.make` の正確なシグネチャ

`ManagedRuntime.d.ts:129-131` に記載:

```typescript
export declare const make: <R, ER>(
  layer: Layer.Layer<R, ER, never>,
  options?: { readonly memoMap?: Layer.MemoMap | undefined } | undefined,
) => ManagedRuntime<R, ER>
```

- 入力 Layer の **第 3 型パラメータ `RIn` は `never` に閉じている必要がある** (= 依存先 Service が完全に注入済みで Context が空であること)。
- 戻り値は `ManagedRuntime<R, ER>` (R = 提供されるサービス集合、ER = layer 構築時に発生し得るエラー)。
- Type-level utilities (`ManagedRuntime.d.ts:21-32`):
  - `ManagedRuntime.Services<T>` で `R` を抽出
  - `ManagedRuntime.Error<T>` で `ER` を抽出

### F-3. `Layer<ROut, E, RIn>` の型パラメータ順と各 API シグネチャ

`Layer.d.ts:45` で **`Layer<in ROut, out E = never, out RIn = never>`** と宣言されている (= 第 1 引数が出力 Service `ROut` (= R)、第 2 が Error、第 3 が入力 Service `RIn`)。

主要 API のシグネチャ:

| API                                     | シグネチャ                                                                                                                                                                |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Layer.succeed`                         | `<I, S>(service: Context.Key<I, S>): (resource: S) => Layer<I>` (`Layer.d.ts:686-729`)                                                                                    |
| `Layer.sync`                            | `<I, S>(service: Context.Key<I, S>): (evaluate: LazyArg<S>) => Layer<I>` (`Layer.d.ts:804-851`)                                                                           |
| `Layer.effect`                          | `<I, S>(service: Context.Key<I, S>): <E, R>(effect: Effect<S, E, R>) => Layer<I, E, Exclude<R, Scope.Scope>>` (`Layer.d.ts:909-974`)                                      |
| `Layer.unwrap`                          | `<A, E1, R1, E, R>(self: Effect<Layer<A, E1, R1>, E, R>) => Layer<A, E \| E1, R1 \| Exclude<R, Scope.Scope>>` (`Layer.d.ts:1079`)                                         |
| `Layer.provide` (data-last 2-args)      | `<RIn2, E2, ROut2, RIn, E, ROut>(self: Layer<ROut2, E2, RIn2>, that: Layer<ROut, E, RIn>): Layer<ROut2, E \| E2, RIn \| Exclude<RIn2, ROut>>` (`Layer.d.ts:1540`)         |
| `Layer.provideMerge` (data-last 2-args) | `<RIn2, E2, ROut2, RIn, E, ROut>(self: Layer<ROut2, E2, RIn2>, that: Layer<ROut, E, RIn>): Layer<ROut \| ROut2, E \| E2, RIn \| Exclude<RIn2, ROut>>` (`Layer.d.ts:1900`) |
| `Layer.merge` (data-last 2-args)        | `<RIn2, E2, ROut2, RIn, E, ROut>(self: Layer<ROut2, E2, RIn2>, that: Layer<ROut, E, RIn>): Layer<ROut \| ROut2, E \| E2, RIn \| RIn2>` (`Layer.d.ts:1239`)                |

差異:

- `provide`: `that` の出力 `ROut` を `self` の入力 `RIn2` から閉じる、ただし出力には残さない (RIn2 ← ROut で消費、ROut2 のみ output)。
- `provideMerge`: `provide` と同じく入力を閉じるが、出力に `ROut | ROut2` で **両方残す**。
- `merge`: 入力同士を `RIn | RIn2` でユニオン、出力同士を `ROut | ROut2` でユニオン (依存解決はしない、純粋な並行合成)。

### F-4. `Context.Service` のオーバーロード形式

`Context.d.ts:115-202` に 3 形式のオーバーロード:

1. **value form** (`Context.d.ts:141`):
   `<Identifier, Shape = Identifier>(key: string): Service<Identifier, Shape>`
   → Phase 1 の `Env.Service = Context.Service<Type>('@app/.../env/Service')` がこの形式 (= `js/app/feed-platform-backend/src/feature/env.ts:7`)。
2. **class form (基本)** (`Context.d.ts:167-171`):
   `<Self, Shape>() => <Identifier extends string, ...>(id: Identifier, options?: { make?: ...}) => ServiceClass<Self, Identifier, Shape> & ...`
3. **class form (make 必須)** (`Context.d.ts:197-201`):
   `<Self>() => <Identifier, Make extends Effect | Function>(id, { make: Make }) => ServiceClass<...>`

Service 値の `Service` 型は `Yieldable<Service<Identifier, Shape>, Shape, never, Identifier>` を継承 (`Context.d.ts:61`) するため、Effect.gen 内で `yield* Env.Service` で Shape を取り出せる (これが Phase 1 `dynamicLoggerLayer` 実装の前提 = `js/app/feed-platform-backend/src/feature/runtime/server.ts:13`)。

### F-5. `Effect.runFork` / `Effect.runPromise` のシグネチャ

`Effect.d.ts:14889` / `Effect.d.ts:15037`:

```typescript
runFork: <A, E>(effect: Effect<A, E, never>, options?: RunOptions) => Fiber<A, E>
runPromise: <A, E>(effect: Effect<A, E>, options?: RunOptions) => Promise<A>
```

両者とも `Effect<A, E, never>` (= R = never、Context が空) を要求する。一方で `ManagedRuntime<R, ER>.runFork` / `runPromise` は `Effect<A, E, R>` を受け取れる (= R が事前注入済み、`ManagedRuntime.d.ts:48` / `81`)。よって library 化した Disposable wrapper の **`instance` プロパティを介して `runtime.instance.runFork(effect)` を呼ぶ既存パターンが正攻法**。

### F-6. `Symbol.asyncDispose` の TS lib 定義

`lib.esnext.disposable.d.ts:21-39`:

```typescript
interface SymbolConstructor {
  readonly asyncDispose: unique symbol
}
interface AsyncDisposable {
  [Symbol.asyncDispose](): PromiseLike<void>
}
```

- 戻り値の契約は **`PromiseLike<void>`**。Phase 1 実装は `async [Symbol.asyncDispose](): Promise<void>` (`js/app/feed-platform-backend/src/feature/runtime/server.ts:47`) で、`Promise` は `PromiseLike` を満たすため OK。
- `ManagedRuntime` interface 自体は `[Symbol.asyncDispose]` を **持たない** (= `ManagedRuntime.d.ts:37-98` 全体に定義なし)。よって既存実装が「`ManagedRuntime` を `instance` フィールドに包み、`asyncDispose` で `instance.dispose()` を呼ぶ wrapper class」を作っているのは **Effect 4.x 側に asyncDispose 実装がないため必須の対応** (= ライブラリ側で wrap する以外に選択肢がない)。

### F-7. Phase 1 同形コピー実装の差分確認 (3 プロジェクト)

3 ファイル (`js/app/feed-platform-backend/src/feature/runtime/server.ts` / `js/app/feed-platform-web/app/feature/runtime/server.ts` / `js/app/identity-provider/app/feature/runtime/server.ts`) を逐次比較した結果:

- **3 ファイルの行 1 から行 60 まで完全一致** (`makeDisposableRuntime` 部分は line 39-50)。差分は `import` パスを含めて 0 行。
- 唯一存在し得る差分は **同階層モジュール (`../env.ts` / `../greeting.ts` / `../health.ts`) の中身が各プロジェクトで微差**だが、`server.ts` 自身の中身は完全同形コピー。

### F-8. Phase 1 と既存 saas-example 実装の差異 (= ジェネリクス factory が吸収すべき差分)

`saas-example/src/feature/runtime/server.ts:7-58` と Phase 1 3 プロジェクト実装を比較:

| 項目                              | Phase 1 (3 projects)                                                                                    | saas-example                                                                                                          | ジェネリクス factory での吸収方針                                                     |
| --------------------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `makeRuntime` の引数              | `() => ManagedRuntime<...>` (引数 0 個)                                                                 | `(env: Env.Type) => ManagedRuntime<...>` (引数 1 個)                                                                  | `<Args extends readonly unknown[]>` で可変長受け                                      |
| `Layer` 合成の中身                | `Health.layer.pipe(provideMerge(Greeting.layer), provideMerge(Env.layer), provide(dynamicLoggerLayer))` | `BetterAuth.layer.pipe(provideMerge(DB.remoteLayer), provideMerge(Env.makeLayer(env)), provide(Logger.layer([...])))` | factory **外側** に残す (consumer 責務、Q1-ext / Q4 確定済)                           |
| Logger 切替方式                   | `dynamicLoggerLayer` (Layer.unwrap + Env.Service)                                                       | `makeRuntime` / `makeDevRuntime` の二系統で静的に切替                                                                 | factory **外側** に残す                                                               |
| `DisposableRuntime` の class 部分 | `constructor() { this.instance = make() }`                                                              | `constructor(env: Env.Type) { this.instance = make(env) }`                                                            | constructor が `(...args: Args)` を受け、`make(...args)` に委譲する形でジェネリクス化 |
| 公開 `make`                       | `() => new DisposableRuntime()`                                                                         | `(env) => import.meta.env.PROD ? new DisposableRuntime(env) : new DisposableDevRuntime(env)`                          | factory **外側** に残す (consumer が runtime バリアントを選ぶロジック)                |

差分の本質: **`makeDisposableRuntime` が抽象化すべき箇所は「`make` 関数の引数列 (`Args`) と戻り値の `ManagedRuntime<R, ER>` を保持したまま `AsyncDisposable` wrapper class を生成すること」のみ**。具体的な Layer 合成内容、Service tag namespace、runtime バリアント数 (1 / 3) などはすべて consumer に残す。

### F-9. ジェネリクス factory の実現可能性 (型推論レベル)

Effect 4.0.0-beta.60 の上記 API シグネチャと TypeScript 型推論の挙動から、以下の形式は **問題なく型付けできる**:

```typescript
// effect-hono library 側
import type { ManagedRuntime } from 'effect'

interface DisposableRuntime<R, ER> extends AsyncDisposable {
  readonly instance: ManagedRuntime.ManagedRuntime<R, ER>
}

export const makeDisposableRuntime = <Args extends readonly unknown[], R, ER>(
  make: (...args: Args) => ManagedRuntime.ManagedRuntime<R, ER>,
) =>
  class implements DisposableRuntime<R, ER> {
    readonly instance: ManagedRuntime.ManagedRuntime<R, ER>
    constructor(...args: Args) {
      this.instance = make(...args)
    }
    async [Symbol.asyncDispose](): Promise<void> {
      await this.instance.dispose()
    }
  }
```

型推論挙動:

- 入力 `make` のシグネチャから `Args` / `R` / `ER` の 3 つを TypeScript が同時に推論する (= 関数型からの structural inference、標準パターン)。
- 戻り class の constructor は `new DisposableRuntime(...args: Args)`、`instance: ManagedRuntime<R, ER>` で公開される。
- `[Symbol.asyncDispose]` は `Promise<void>` を返し、global `AsyncDisposable` interface (`PromiseLike<void>`) と互換。
- `await using` 利用側では `await using rt = new Klass(...args)` 経由で `rt.instance` が `ManagedRuntime<R, ER>` 型として参照可能。

代替案として「Layer を直接受け取る factory」も可能:

```typescript
// 案 B: Layer を引数に取る
export const makeDisposableRuntimeFromLayer = <Args extends readonly unknown[], R, ER>(
  makeLayer: (...args: Args) => Layer.Layer<R, ER, never>,
) => class { ... }
```

ただし intent-spec.md L50 の表現 (「任意の引数 / 任意の ManagedRuntime を返す factory」) は **案 A** (= make 関数を受け取る形) を直接指している。saas-example および Phase 1 の既存パターンも `make: typeof makeRuntime` を渡す形 (= 案 A) なので、案 A が継承パターンとして自然。

### F-10. `Layer<R, E, RIn>` の `RIn` を `never` に閉じる制約の表現

`ManagedRuntime.make` (`ManagedRuntime.d.ts:129`) は `Layer<R, ER, never>` を要求する。Layer の RIn が `never` でない (= 依存が残っている) Layer を渡すと **コンパイルエラー** で弾かれる。よって library 側で `Layer<R, ER, never>` 制約を表現する必要が出るのは「案 B (Layer を直接受け取る factory)」を採用した場合のみ。

案 A (make 関数を受け取る形) では、make 関数自身が `ManagedRuntime<R, ER>` を返す責務を持つため、library 側で `Layer<...,never>` 制約を再表明する必要は **ない** (= consumer が `ManagedRuntime.make(layer)` を呼ぶ時点で既に Effect 側の型システムが制約を強制している)。これは案 A をライブラリ抽象化境界として選ぶ強い動機になる。

## Sources

- Effect 型定義 (Source of Truth):
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/ManagedRuntime.d.ts:21-32` (type-level utilities `Services` / `Error`)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/ManagedRuntime.d.ts:37-98` (interface `ManagedRuntime<in R, out ER>` 全 API)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/ManagedRuntime.d.ts:129-131` (`make` シグネチャ)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Layer.d.ts:45` (`Layer<in ROut, out E = never, out RIn = never>`)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Layer.d.ts:686-729` (`Layer.succeed`)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Layer.d.ts:804-851` (`Layer.sync`)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Layer.d.ts:909-974` (`Layer.effect`)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Layer.d.ts:1079` (`Layer.unwrap`)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Layer.d.ts:1239` (`Layer.merge` data-last 2-args)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Layer.d.ts:1540` (`Layer.provide` data-last 2-args)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Layer.d.ts:1900` (`Layer.provideMerge` data-last 2-args)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Context.d.ts:115-202` (`Context.Service` 3 オーバーロード)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Effect.d.ts:14889` (`Effect.runFork`)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Effect.d.ts:15037` (`Effect.runPromise`)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Logger.d.ts:594-599` (`Logger.consolePretty`)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Logger.d.ts:756` (`Logger.consoleJson`)
  - `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect/dist/Logger.d.ts:850-852` (`Logger.layer`)
- TypeScript lib:
  - `node_modules/.pnpm/typescript@6.0.3/node_modules/typescript/lib/lib.esnext.disposable.d.ts:21-39` (Symbol.asyncDispose / AsyncDisposable interface)
- 本リポジトリ Phase 1 実装 (3 プロジェクトの完全同形コピー):
  - `js/app/feed-platform-backend/src/feature/runtime/server.ts:1-60`
  - `js/app/feed-platform-web/app/feature/runtime/server.ts:1-60`
  - `js/app/identity-provider/app/feature/runtime/server.ts:1-60`
  - `js/app/feed-platform-backend/src/feature/runtime/hono.ts:1-25` (consumer side `await using` 使用パターン、3 プロジェクトでも同形)
  - `js/app/feed-platform-backend/src/feature/env.ts:1-23` (`Env.Service` value form 使用例)
- 参考実装:
  - `js/app/saas-example/src/feature/runtime/server.ts:1-59` (Phase 2 Intent Spec が言及する saas-example 由来パターン、引数あり版 makeRuntime / 3 バリアント版 DisposableRuntime)
  - `js/app/saas-example/src/feature/runtime/hono.ts:1-12` (引数あり版 await using consumer side)
- Workspace / 環境設定:
  - `pnpm-workspace.yaml` の catalog `effect: { effect: beta }` (= effect 4.x beta)
  - `js/app/feed-platform-backend/node_modules/effect` symlink → `node_modules/.pnpm/effect@4.0.0-beta.60/node_modules/effect` (実 version 確定)
  - `js/package/fp/src/tsconfig/vite.json:1-26` (target: esnext, lib に ESNext 含む)
- Intent Spec 該当箇所:
  - `docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md:39` (C-2 候補定義)
  - `docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md:50` (「ジェネリクス化して任意の引数 / 任意の ManagedRuntime を返す factory に拡張」)
  - `docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md:67-69` (Q4 C-2 確定: 任意の `Args extends any[]` と任意の `ManagedRuntime<R, ER>`)
  - `docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md:215-216` (Open questions: Effect 4.x API 制約)

## Implications for design

以下、Step 3 (Design) で `architect` が `makeDisposableRuntime` 抽象化境界を確定する際に直接利用できる形にまとめる:

- **I-1 (factory 引数の型シグネチャ確定)**: 採用すべきは **「`make` 関数を受け取る factory」(案 A)**。理由: (a) Phase 1 / saas-example の既存パターンの自然な継承、(b) `Layer<R, ER, never>` 制約は consumer 側の `ManagedRuntime.make(layer)` 呼び出しが自動で強制するため library 側で再表明不要、(c) intent-spec.md L50 の表現と直接一致。最終形:

  ```typescript
  export const makeDisposableRuntime = <
    Args extends readonly unknown[],
    R,
    ER,
  >(
    make: (...args: Args) => ManagedRuntime.ManagedRuntime<R, ER>,
  ) => class { ... constructor(...args: Args) { ... } ... }
  ```

  ジェネリクスは **3 つ (`Args` / `R` / `ER`)** のみで足りる。Effect 4.x の Layer 中間型を library 側で扱う必要なし。

- **I-2 (戻り class の export 形式)**: factory が **無名 class を直接 return** する形 (= `() => class { ... }`) で OK。consumer は `const DisposableRuntime = makeDisposableRuntime(makeRuntime)` で名前を付ける既存パターンを継続できる (`feed-platform-backend/src/feature/runtime/server.ts:52` と同形)。`new DisposableRuntime(...args)` で構築、`await using rt = new DisposableRuntime(...args)` で AsyncDisposable として使える。

- **I-3 (型 export の必要性)**: consumer が `ManagedRuntime<R, ER>` 型を再利用する場合 (例: Hono `Variables` 定義の `runtime: Runtime.Runtime`) のために、`Runtime` 型 alias の export パターン自体は **consumer 側に残す**。Phase 1 では `export type Runtime = ReturnType<typeof makeRuntime>` (`server.ts:30`) で表現。library が `DisposableRuntime` interface を export して consumer がそれを使うことも可能だが、必須ではない。

- **I-4 (asyncDispose 戻り値型)**: factory 内 class の `[Symbol.asyncDispose]` メソッドは Phase 1 と同じく **`async [Symbol.asyncDispose](): Promise<void>`** で十分。global `AsyncDisposable` interface は `PromiseLike<void>` を要求するが `Promise<void>` がそれを満たす。`PromiseLike<void>` を返り値型に書くと non-async 化できるが、`async`/`await this.instance.dispose()` のパターンを維持する方が読みやすく既存と整合。

- **I-5 (`AsyncDisposable` interface の `implements` 表記)**: Phase 1 では library 内 interface `DisposableRuntimeInterface` を `implements` していたが (`server.ts:34-37`)、library 化したら **`implements AsyncDisposable` (global interface) を直接使う** か、library 側で `interface DisposableRuntime<R, ER> extends AsyncDisposable { readonly instance: ManagedRuntime<R, ER> }` を export してそれを implements するか、設計選択肢が 2 つある。後者なら consumer 側で型注釈に使えるメリットがある。

- **I-6 (smoke test 設計のヒント)**: `makeDisposableRuntime` の smoke test (SC-3) は以下で十分 (= Effect 4.x API モックなしで構築可能):
  - Step 1: 適当な空 `Layer.empty` (= `Layer<never>`、`Layer.d.ts:781`) で `ManagedRuntime.make` を呼んで `make` 関数を作る
  - Step 2: `makeDisposableRuntime(make)` で class を生成
  - Step 3: `await using rt = new Klass()` で構築・スコープ離脱で `Symbol.asyncDispose` が呼ばれることを確認
  - Step 4: `rt.instance` が `ManagedRuntime` 型 (= `runFork` / `runPromise` メソッドを持つ) であることを確認

- **I-7 (consumer 側コードの変化量)**: 3 プロジェクトの consumer 側で必要な変更は最小:
  - `import { makeDisposableRuntime } from '@app/effect-hono'` (新規 import) を追加
  - `const makeDisposableRuntime = (make: typeof makeRuntime) => class DisposableRuntime ...` (15 行) を削除
  - `export const DisposableRuntime = makeDisposableRuntime(makeRuntime)` 行は **そのまま残る** (factory への引数も同じ)
    → 削減行数 ≒ 各プロジェクト 16-17 行 × 3 = 約 50 行。

- **I-8 (Phase 1 同形コピーの差分なし確認による安心材料)**: 3 プロジェクトの `server.ts` の `makeDisposableRuntime` 部分は完全同形コピー (F-7) なので、library 化に伴う semantic 変化が発生しない。consumer 側 import 切替は機械的な作業として Step 6 (Implementation) で実施可能。

- **I-9 (`memoMap` option の扱い)**: `ManagedRuntime.make` は第 2 引数で `{ memoMap?: Layer.MemoMap }` を受け取れる (`ManagedRuntime.d.ts:129-131`) が Phase 1 / saas-example はどちらも未使用。library 側でも **第 2 引数を意識しない** 形で良い (= consumer 側 `make` 関数内部で `ManagedRuntime.make(layer, options)` を呼ぶ形にすれば、library が memoMap を露出する必要なし)。

## Remaining unknowns

- **U-1 (確認可能だが未確認: `instance` プロパティ名の慣行)**: Phase 1 / saas-example 共に `readonly instance: Runtime` と命名しているが、これが Effect コミュニティ標準の慣行か独自命名か未確認。library 化に際し別の命名 (`runtime` / `value` / `unwrap()` メソッド形式等) も技術的には可能。Step 3 (Design) で命名を確定させる必要あり (= 未検証だが design 判断としては low risk)。
- **U-2 (確認可能だが未確認: `runFork` 等の direct exposure)**: library 側 class が `runFork` / `runPromise` を `instance` 経由ではなくクラス直下に exposure するパターン (= class が `ManagedRuntime` interface 自体を proxy する) も技術的には可能だが、Phase 1 / saas-example はそれをしていない。設計選択肢として記録するが、本 cycle での採用は推奨しない (= 既存パターンの継承を優先)。
- **U-3 (Effect 4.x の future-proofing は対象外)**: Effect 4.x が beta 段階のため、stable リリースで `ManagedRuntime` interface に `[Symbol.asyncDispose]` が追加される可能性は否定できない。本 Note の検証時点 (4.0.0-beta.60) ではまだ未実装。stable 後に library が薄くなる可能性は **記録のみ**、本 cycle の意思決定には影響しない。
- **U-4 (公式 docs サイトの確認は未実施)**: sandbox 制約で https://effect.website に直接アクセスしていない。ただし型定義 (`.d.ts`) と JSDoc 内の example を直接読んでおり、API 仕様の根拠としては型定義が最終 source of truth であるため不足はない (= U-4 は本 Note の発見の妥当性に影響しない、補強情報のみ未取得)。
- **U-5 (案 B「Layer を渡す factory」の採否)**: I-1 で案 A を強く推奨したが、Step 3 で architect が案 B を選ぶ可能性も formally は残る。案 B を採るなら library 側で `Layer<R, ER, never>` の `never` 制約を型に書く必要があり、ジェネリクス引数が 1 つ増える (`<Args, R, ER>` のみで済む案 A に対し、案 B は事実上 1 引数の Layer を受けるため `<R, ER>` のみ)。だが「make 関数全体ではなく Layer を渡す」と consumer 側の `makeRuntime` を library 内に押し込むことになり、既存パターンとの非互換が生じるため非推奨。
