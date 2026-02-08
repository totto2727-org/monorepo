import { describe, expect, test } from 'bun:test'

import { Cause, Exit } from '../effect.js'
import { Result } from '../option-t.js'
import { fromExit } from './effect.js'

describe('Convert Success type to Ok', () => {
  test('Data First', () => {
    const actual = fromExit(Exit.succeed('success value'), (cause) => cause)

    const expected = Result.createOk('success value')
    expect(actual).toEqual(expected)
  })

  test('Data Last', () => {
    const fn = fromExit((cause) => cause)
    const actual = fn(Exit.succeed('success value'))

    const expected = Result.createOk('success value')
    expect(actual).toEqual(expected)
  })
})

describe('Convert Failure type to Err', () => {
  test('Data First', () => {
    const actual = fromExit(Exit.fail('error message'), (cause) => Cause.squash(cause))

    const expected = Result.createErr('error message')
    expect(actual).toEqual(expected)
  })

  test('Data Last', () => {
    const fn = fromExit((cause) => Cause.squash(cause))
    const actual = fn(Exit.fail('error message'))

    const expected = Result.createErr('error message')
    expect(actual).toEqual(expected)
  })
})
