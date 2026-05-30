import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isInstanceofError } from './no-instanceof-error.ts'

describe('isInstanceofError', () => {
  test('detects instanceof Error', () => {
    expect(
      isInstanceofError({
        left: { name: 'error', type: 'Identifier' },
        operator: 'instanceof',
        right: { name: 'Error', type: 'Identifier' },
        type: 'BinaryExpression',
      }),
    ).toBe(true)
  })
})

runRuleTest('no-instanceof-error', rule, {
  invalid: [{ code: 'const isError = error instanceof Error', errors: 1, name: 'instanceof Error is reported' }],
  valid: [
    { code: 'const isTypeError = error instanceof TypeError', name: 'other constructors are allowed' },
    { code: 'new ConfigFileError({ error })', name: 'raw caught error is allowed' },
  ],
})
