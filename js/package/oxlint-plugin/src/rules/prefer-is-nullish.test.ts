import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { getNullishPredicateMember } from './prefer-is-nullish.ts'

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

runRuleTest('prefer-is-nullish', rule, {
  invalid: [
    { code: 'if (Predicate.isNull(x)) {}', errors: 1, name: 'Predicate.isNull is reported' },
    { code: 'if (Predicate.isNotNull(x)) {}', errors: 1, name: 'Predicate.isNotNull is reported' },
    { code: 'if (Predicate.isUndefined(x)) {}', errors: 1, name: 'Predicate.isUndefined is reported' },
    { code: 'if (Predicate.isNotUndefined(x)) {}', errors: 1, name: 'Predicate.isNotUndefined is reported' },
  ],
  valid: [
    { code: 'if (Predicate.isNullish(x)) {}', name: 'Predicate.isNullish is allowed' },
    { code: 'if (Predicate.isNotNullish(x)) {}', name: 'Predicate.isNotNullish is allowed' },
    { code: 'if (Predicate.isString(x)) {}', name: 'unrelated Predicate method is allowed' },
    { code: 'if (Other.isNull(x)) {}', name: 'non-Predicate namespace isNull is allowed' },
  ],
})
