import { describe, expect, test } from 'vite-plus/test'

import { getForbiddenDateStaticMethod, isDateIdentifier } from './no-js-date.ts'

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
