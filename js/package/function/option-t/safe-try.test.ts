/*
 * This is a port of [neverthrow](https://github.com/supermacro/neverthrow)'s `safeUnwrap` and `safeTry` to [option-t](https://github.com/gcanti/option-t).
 *
 * https://github.com/supermacro/neverthrow/blob/master/tests/safe-try.test.ts
 *
 * MIT License
 *
 * Copyright (c) 2019 Giorgio Delgado
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import { Result } from '#@/option-t.js'
import { describe, expect, test } from 'bun:test'

import { safeTry, safeUnwrap } from './safe-try.js'

describe('Returns what is returned from the generator function', () => {
  test('With synchronous Ok', () => {
    const actual = Result.unwrapOk(
      safeTry(function* () {
        return Result.createOk('value')
      }),
    )

    expect(actual).toBe('value')
  })

  test('With synchronous Err', () => {
    const actual = Result.unwrapErr(
      safeTry(function* () {
        return Result.createErr('value')
      }),
    )

    expect(actual).toBe('value')
  })

  test('With async Ok', async () => {
    const actual = Result.unwrapOk(
      await safeTry(async function* () {
        return Result.createOk('value')
      }),
    )

    const expected = 'value'

    expect(actual).toBe(expected)
  })

  test('With async Err', async () => {
    const actual = Result.unwrapErr(
      await safeTry(async function* () {
        return Result.createErr('value')
      }),
    )

    expect(actual).toBe('value')
  })
})

describe("Returns the first occurrence of Err instance as yield*'s operand", () => {
  describe('Only synchronous', () => {
    const okValues: string[] = []

    const result = safeTry(function* () {
      const okFoo = yield* safeUnwrap(Result.createOk('foo'))
      okValues.push(okFoo)

      const okBar = yield* safeUnwrap(Result.createOk('bar'))
      okValues.push(okBar)

      yield* safeUnwrap(Result.createErr('err'))

      throw new Error('This line should not be executed')
    })

    test('Run until Error', () => {
      const actual = okValues
      const expected = ['foo', 'bar']
      expect(actual).toEqual(expected)
    })

    test('Return Err', () => {
      const actual = Result.isErr(result)
      const expected = true
      expect(actual).toBe(expected)
    })
  })

  describe('Only async', async () => {
    const okValues: string[] = []

    const result = Result.unwrapErr(
      await safeTry(async function* () {
        const okFoo = yield* safeUnwrap(Promise.resolve(Result.createOk('foo')))
        okValues.push(okFoo)

        const okBar = yield* safeUnwrap(Promise.resolve(Result.createOk('bar')))
        okValues.push(okBar)

        yield* safeUnwrap(Promise.resolve(Result.createErr('err')))

        throw new Error('This line should not be executed')
      }),
    )

    test('Run until Error', () => {
      const actual = okValues
      const expected = ['foo', 'bar']
      expect(actual).toEqual(expected)
    })

    test('Return Err', () => {
      const actual = result
      const expected = 'err'
      expect(actual).toBe(expected)
    })
  })

  describe('Mix synchronous and async', async () => {
    const okValues: string[] = []

    const result = Result.unwrapErr(
      await safeTry(async function* () {
        const okFoo = yield* safeUnwrap(Promise.resolve(Result.createOk('foo')))
        okValues.push(okFoo)

        const okBar = yield* safeUnwrap(Result.createOk('bar'))
        okValues.push(okBar)

        yield* safeUnwrap(Result.createErr('err'))

        throw new Error('This line should not be executed')
      }),
    )

    test('Run until Error', () => {
      const actual = okValues

      const expected = ['foo', 'bar']
      expect(actual).toEqual(expected)
    })

    test('Return Err', () => {
      const actual = result

      const expected = 'err'
      expect(actual).toBe(expected)
    })
  })
})
