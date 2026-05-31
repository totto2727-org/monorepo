import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { getForbiddenDateStaticMethod, isDateIdentifier } from './no-js-date.ts'

describe('isDateIdentifier', () => {
  test('Date identifier returns true', () => {
    expect(isDateIdentifier({ name: 'Date', type: 'Identifier' })).toBe(true)
  })

  test('non-Date identifier returns false', () => {
    expect(isDateIdentifier({ name: 'DateTime', type: 'Identifier' })).toBe(false)
  })

  test('non-Identifier returns false', () => {
    expect(isDateIdentifier({ type: 'Literal', value: 'Date' })).toBe(false)
  })

  test('non-object returns false', () => {
    expect(isDateIdentifier(null)).toBe(false)
  })
})

describe('getForbiddenDateStaticMethod', () => {
  test.each(['now', 'parse', 'UTC'])('Date.%s returns method name', (method) => {
    expect(
      getForbiddenDateStaticMethod({
        computed: false,
        object: { name: 'Date', type: 'Identifier' },
        property: { name: method, type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBe(method)
  })

  test('Date.toString returns null (not forbidden)', () => {
    expect(
      getForbiddenDateStaticMethod({
        computed: false,
        object: { name: 'Date', type: 'Identifier' },
        property: { name: 'toString', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBeNull()
  })

  test('Math.now returns null (not Date)', () => {
    expect(
      getForbiddenDateStaticMethod({
        computed: false,
        object: { name: 'Math', type: 'Identifier' },
        property: { name: 'now', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBeNull()
  })

  test('computed member expression returns null', () => {
    expect(
      getForbiddenDateStaticMethod({
        computed: true,
        object: { name: 'Date', type: 'Identifier' },
        property: { name: 'now', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBeNull()
  })
})

runRuleTest('no-js-date', rule, {
  invalid: [
    { code: 'const d = new Date()', errors: 1, name: 'new Date() is reported' },
    { code: 'const n = Date.now()', errors: 1, name: 'Date.now() is reported' },
    { code: "const p = Date.parse('2024-01-01')", errors: 1, name: 'Date.parse() is reported' },
    { code: 'const u = Date.UTC(2024, 0, 1)', errors: 1, name: 'Date.UTC() is reported' },
  ],
  valid: [
    { code: 'const d = DateTime.now()', name: 'Effect DateTime.now is allowed' },
    { code: 'const t = Duration.seconds(1)', name: 'Effect Duration is allowed' },
    { code: 'const x = Date', name: 'mere Date reference without member access or new is allowed' },
    { code: 'const x = Date.prototype', name: 'non-forbidden Date member access is allowed' },
  ],
})
