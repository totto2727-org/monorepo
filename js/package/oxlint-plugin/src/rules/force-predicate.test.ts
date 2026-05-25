import { describe, expect, test } from 'vite-plus/test'

import { getNullishSide, getStringValue, getTypeofType } from './force-predicate.ts'

describe('getNullishSide', () => {
  test('null literal returns "null"', () => {
    expect(getNullishSide({ type: 'Literal', value: null })).toBe('null')
  })

  test('undefined identifier returns "undefined"', () => {
    expect(getNullishSide({ name: 'undefined', type: 'Identifier' })).toBe('undefined')
  })

  test('number literal returns null', () => {
    expect(getNullishSide({ type: 'Literal', value: 42 })).toBeNull()
  })

  test('non-undefined identifier returns null', () => {
    expect(getNullishSide({ name: 'foo', type: 'Identifier' })).toBeNull()
  })

  test('non-object returns null', () => {
    expect(getNullishSide(null)).toBeNull()
    expect(getNullishSide('null')).toBeNull()
  })
})

describe('getTypeofType', () => {
  test('typeof UnaryExpression returns "typeof"', () => {
    expect(getTypeofType({ argument: {}, operator: 'typeof', type: 'UnaryExpression' })).toBe('typeof')
  })

  test('non-typeof unary expression returns null', () => {
    expect(getTypeofType({ argument: {}, operator: '!', type: 'UnaryExpression' })).toBeNull()
  })

  test('non-UnaryExpression returns null', () => {
    expect(getTypeofType({ type: 'Literal', value: 42 })).toBeNull()
  })
})

describe('getStringValue', () => {
  test('string literal returns its value', () => {
    expect(getStringValue({ type: 'Literal', value: 'hello' })).toBe('hello')
  })

  test('empty string literal returns empty string', () => {
    expect(getStringValue({ type: 'Literal', value: '' })).toBe('')
  })

  test('number literal returns null', () => {
    expect(getStringValue({ type: 'Literal', value: 42 })).toBeNull()
  })

  test('non-literal returns null', () => {
    expect(getStringValue({ name: 'foo', type: 'Identifier' })).toBeNull()
  })
})
