import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isInstanceofErrorMessageConditional } from './no-error-message-instanceof.ts'

describe('isInstanceofErrorMessageConditional', () => {
  test('detects error instanceof Error ? error.message', () => {
    expect(
      isInstanceofErrorMessageConditional({
        alternate: { name: 'fallback', type: 'Identifier' },
        consequent: {
          computed: false,
          object: { name: 'error', type: 'Identifier' },
          property: { name: 'message', type: 'Identifier' },
          type: 'MemberExpression',
        },
        test: {
          left: { name: 'error', type: 'Identifier' },
          operator: 'instanceof',
          right: { name: 'Error', type: 'Identifier' },
          type: 'BinaryExpression',
        },
        type: 'ConditionalExpression',
      }),
    ).toBe(true)
  })
})

runRuleTest('no-error-message-instanceof', rule, {
  invalid: [
    {
      code: 'const message = error instanceof Error ? error.message : String(error)',
      errors: 1,
      name: 'inline Error message conditional is reported',
    },
    {
      code: "new Foo({ message: err instanceof Error ? err.message : 'unknown' })",
      errors: 1,
      name: 'nested Error message conditional is reported',
    },
  ],
  valid: [
    { code: 'const message = errorMessageOrDefault(error)', name: 'helper is allowed' },
    {
      code: "const message = error instanceof TypeError ? 'type' : 'other'",
      name: 'non-message conditional is allowed',
    },
    { code: "const message = error instanceof Error ? 'error' : 'other'", name: 'non-message consequent is allowed' },
  ],
})
