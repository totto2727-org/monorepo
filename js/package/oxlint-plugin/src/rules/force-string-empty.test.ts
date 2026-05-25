import { describe, expect, test } from 'vite-plus/test'

import { isEmptyStringLiteral } from './force-string-empty.ts'

describe('isEmptyStringLiteral', () => {
  test('empty string literal returns true', () => {
    expect(isEmptyStringLiteral({ type: 'Literal', value: '' })).toBe(true)
  })

  test('non-empty string literal returns false', () => {
    expect(isEmptyStringLiteral({ type: 'Literal', value: 'hello' })).toBe(false)
  })

  test('number literal returns false', () => {
    expect(isEmptyStringLiteral({ type: 'Literal', value: 0 })).toBe(false)
  })

  test('null literal returns false', () => {
    expect(isEmptyStringLiteral({ type: 'Literal', value: null })).toBe(false)
  })

  test('non-literal node returns false', () => {
    expect(isEmptyStringLiteral({ name: '', type: 'Identifier' })).toBe(false)
  })
})
