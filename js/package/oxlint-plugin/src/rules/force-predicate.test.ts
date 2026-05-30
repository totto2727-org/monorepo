import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { getNullishSide, getStringValue, getTypeofType } from './force-predicate.ts'

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

runRuleTest('force-predicate', rule, {
  invalid: [
    { code: 'if (x === null) {}', errors: 1, name: '=== null reports Predicate.isNull' },
    { code: 'if (null === x) {}', errors: 1, name: 'null === x reports Predicate.isNull' },
    { code: 'if (x !== undefined) {}', errors: 1, name: '!== undefined reports Predicate.isUndefined' },
    { code: "if (typeof x === 'string') {}", errors: 1, name: "typeof === 'string' reports Predicate.isString" },
    { code: "if (typeof x === 'object') {}", errors: 1, name: "typeof === 'object' reports Predicate.isObject" },
    { code: "if (typeof x === 'function') {}", errors: 1, name: "typeof === 'function' reports Predicate.isFunction" },
  ],
  valid: [
    { code: 'if (Predicate.isNull(x)) {}', name: 'recommended Predicate.isNull call' },
    { code: 'if (Predicate.isString(x)) {}', name: 'recommended Predicate.isString call' },
    { code: 'if (x === 1) {}', name: 'unrelated numeric comparison is ignored' },
    { code: "if (typeof x === 'unknownType') {}", name: 'unknown typeof string is ignored' },
  ],
})
