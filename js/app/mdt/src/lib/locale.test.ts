import { Effect, Exit } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import { normalize } from './locale.ts'

describe('normalize', () => {
  test('returns lowercase form for simple language code', async () => {
    const result = await Effect.runPromise(normalize('ja'))
    expect(result).toBe('ja')
  })

  test('uppercases input to lowercase canonical', async () => {
    const result = await Effect.runPromise(normalize('JA'))
    expect(result).toBe('ja')
  })

  test('lowercases canonical region form', async () => {
    const result = await Effect.runPromise(normalize('ja-jp'))
    expect(result).toBe('ja-jp')
  })

  test('mixed case region is normalized to lowercase', async () => {
    const result = await Effect.runPromise(normalize('JA-jp'))
    expect(result).toBe('ja-jp')
  })

  test('fails on invalid syntax', async () => {
    const exit = await Effect.runPromiseExit(normalize('invalid!'))
    expect(Exit.isFailure(exit)).toBe(true)
  })

  test('fails on empty string', async () => {
    const exit = await Effect.runPromiseExit(normalize(''))
    expect(Exit.isFailure(exit)).toBe(true)
  })
})
