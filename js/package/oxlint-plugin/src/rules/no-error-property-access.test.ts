import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isErrorPropertyAccess } from './no-error-property-access.ts'

describe('isErrorPropertyAccess', () => {
  test('detects property access on error receiver names', () => {
    expect(
      isErrorPropertyAccess({
        computed: false,
        object: { name: 'error', type: 'Identifier' },
        property: { name: 'message', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBe(true)
  })
})

runRuleTest('no-error-property-access', rule, {
  invalid: [
    { code: 'const message = error.message', errors: 1, name: 'error.message is reported' },
    { code: "const message = err['message']", errors: 1, name: 'err bracket access is reported' },
    { code: 'const tag = e._tag', errors: 1, name: 'e tag access is reported' },
    { code: 'const tag = c._tag', errors: 1, name: 'c tag access is reported' },
    { code: 'const tag = cause._tag', errors: 1, name: 'cause tag access is reported' },
  ],
  valid: [
    { code: 'new ConfigFileError({ error })', name: 'raw caught error is allowed' },
    { code: 'expect(result.failure._tag).toBe("X")', name: 'non-error receiver names are allowed' },
  ],
})
