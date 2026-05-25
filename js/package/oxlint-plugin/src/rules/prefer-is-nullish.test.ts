import { describe, expect, test } from 'vite-plus/test'

import { getNullishPredicateMember } from './prefer-is-nullish.ts'

const makePredicateMember = (method: string) => ({
  object: { name: 'Predicate', type: 'Identifier' },
  property: { name: method, type: 'Identifier' },
  type: 'MemberExpression',
})

describe('getNullishPredicateMember', () => {
  test.each(['isNull', 'isNotNull', 'isUndefined', 'isNotUndefined'])('%s returns method name', (method) => {
    expect(getNullishPredicateMember(makePredicateMember(method))).toBe(method)
  })

  test('isNullish returns null (not in the banned set)', () => {
    expect(getNullishPredicateMember(makePredicateMember('isNullish'))).toBeNull()
  })

  test('isNotNullish returns null (not in the banned set)', () => {
    expect(getNullishPredicateMember(makePredicateMember('isNotNullish'))).toBeNull()
  })

  test('non-Predicate object returns null', () => {
    expect(
      getNullishPredicateMember({
        object: { name: 'Option', type: 'Identifier' },
        property: { name: 'isNull', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBeNull()
  })

  test('non-MemberExpression returns null', () => {
    expect(getNullishPredicateMember({ name: 'isNull', type: 'Identifier' })).toBeNull()
  })
})
