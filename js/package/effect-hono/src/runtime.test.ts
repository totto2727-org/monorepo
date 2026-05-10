import { Effect, Layer, ManagedRuntime } from 'effect'
import { describe, expect, expectTypeOf, test } from 'vite-plus/test'

import { makeDisposableRuntime } from './runtime.ts'

describe('makeDisposableRuntime', () => {
  test('factory が AsyncDisposable な class を返し、instance に ManagedRuntime を露出する', async () => {
    const Klass = makeDisposableRuntime(() => ManagedRuntime.make(Layer.empty))

    await using rt = new Klass()

    // type-level: rt.instance は ManagedRuntime
    expectTypeOf(rt.instance.runPromise).toBeFunction()
    expectTypeOf(rt.instance.runFork).toBeFunction()

    // type-level: rt は AsyncDisposable
    expectTypeOf(rt[Symbol.asyncDispose]).toBeFunction()

    // runtime: instance が Effect を実行できる
    const result = await rt.instance.runPromise(Effect.succeed(42))
    expect(result).toBe(42)
  })

  test('Args を受け取る make 関数を渡すと、constructor 引数として転送される', async () => {
    const Klass = makeDisposableRuntime((layer: Layer.Layer<never>) => ManagedRuntime.make(layer))

    await using rt = new Klass(Layer.empty)

    const result = await rt.instance.runPromise(Effect.succeed('ok' as const))
    expect(result).toBe('ok')
  })
})
