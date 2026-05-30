import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isNewErrorWithCauseOption } from './no-error-cause-option.ts'

describe('isNewErrorWithCauseOption', () => {
  test('detects new Error with cause option', () => {
    expect(
      isNewErrorWithCauseOption({
        arguments: [
          { type: 'Literal', value: 'boom' },
          {
            properties: [{ key: { name: 'cause', type: 'Identifier' }, type: 'Property' }],
            type: 'ObjectExpression',
          },
        ],
        callee: { name: 'Error', type: 'Identifier' },
        type: 'NewExpression',
      }),
    ).toBe(true)
  })
})

runRuleTest('no-error-cause-option', rule, {
  invalid: [{ code: "new Error('boom', { cause: error })", errors: 1, name: 'cause option is reported' }],
  valid: [
    { code: "new Error('boom', { error })", name: 'error option is allowed' },
    { code: "new TypeError('boom', { cause: error })", name: 'non-Error constructors are allowed' },
  ],
})
