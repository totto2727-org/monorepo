import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isTypePredicateAnnotation } from './no-type-predicate.ts'

const tsParserOptions: { languageOptions: { parserOptions: { lang: 'ts' } } } = {
  languageOptions: { parserOptions: { lang: 'ts' } },
}

describe('isTypePredicateAnnotation', () => {
  test('detects TypeScript type predicate annotations', () => {
    expect(isTypePredicateAnnotation({ type: 'TSTypePredicate' })).toBe(true)
  })

  test('ignores boolean type annotations', () => {
    expect(isTypePredicateAnnotation({ type: 'TSBooleanKeyword' })).toBe(false)
  })
})

runRuleTest('no-type-predicate', rule, {
  invalid: [
    {
      code: 'const isUser = (value: unknown): value is User => true',
      errors: 1,
      name: 'arrow function type predicate is reported',
      ...tsParserOptions,
    },
    {
      code: 'function isUser(value: unknown): value is User { return true }',
      errors: 1,
      name: 'function declaration type predicate is reported',
      ...tsParserOptions,
    },
  ],
  valid: [
    { code: 'const isUser = Schema.is(User)', name: 'schema predicate helper is allowed' },
    {
      code: 'const isReady = (value: State): boolean => true',
      name: 'is-prefixed boolean helper is allowed',
      ...tsParserOptions,
    },
    {
      code: 'function isReady(value: State): boolean { return true }',
      name: 'is-prefixed boolean function is allowed',
      ...tsParserOptions,
    },
  ],
})
