import type { ManagedRuntime } from 'effect'

// Effect 4.0.0-beta.60 の `ManagedRuntime` interface には `[Symbol.asyncDispose]` が組み込まれていないため、
// `await using` (TC39 explicit resource management) で自動破棄するには library 側で wrapper class を被せる以外に選択肢がない。
// 本 factory は `make` 関数 (任意 Args を受けて `ManagedRuntime` を生成する関数) を引数に取り、
// `AsyncDisposable` を実装する class を返す。consumer 側は `class MyRuntime extends DisposableRuntime {}` を
// 経由せずとも `new Klass()` / `new Klass(...args)` で直接 instance を構築できる。
//
// 例 (consumer):
//   const makeRuntime = () => ManagedRuntime.make(layer)
//   const DisposableRuntime = makeDisposableRuntime(makeRuntime)
//   await using rt = new DisposableRuntime()
//   await rt.instance.runPromise(effect)
//   // scope 離脱時に Symbol.asyncDispose が自動実行される
export const makeDisposableRuntime = <Args extends readonly unknown[], R, ER>(
  make: (...args: Args) => ManagedRuntime.ManagedRuntime<R, ER>,
) =>
  class DisposableRuntime implements AsyncDisposable {
    readonly instance: ManagedRuntime.ManagedRuntime<R, ER>

    constructor(...args: Args) {
      this.instance = make(...args)
    }

    async [Symbol.asyncDispose](): Promise<void> {
      await this.instance.dispose()
    }
  }
