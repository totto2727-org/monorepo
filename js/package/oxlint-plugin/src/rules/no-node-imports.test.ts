import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { getNodeBuiltinSpecifier } from './no-node-imports.ts'

describe('getNodeBuiltinSpecifier', () => {
  test('returns builtin package without node protocol', () => {
    expect(getNodeBuiltinSpecifier('node:fs/promises')).toBe('fs/promises')
  })

  test('returns null for non-node imports', () => {
    expect(getNodeBuiltinSpecifier('effect')).toBe(null)
  })
})

runRuleTest('no-node-imports', rule, {
  invalid: [
    { code: "import { readFile } from 'node:fs/promises'", errors: 1, name: 'node import is reported' },
    { code: "export { readFile } from 'node:fs/promises'", errors: 1, name: 'node re-export is reported' },
    { code: "export * from 'node:fs/promises'", errors: 1, name: 'node export all is reported' },
  ],
  valid: [
    { code: "import { Effect } from 'effect'", name: 'non-node import is allowed' },
    {
      code: "import { join } from 'node:path'",
      name: 'array whitelist allows selected builtin',
      options: [['path']],
    },
    {
      code: "import { readFile } from 'node:fs/promises'",
      name: 'object allow whitelist allows selected builtin',
      options: [{ allow: ['fs/promises'] }],
    },
    {
      code: "import { readFile } from 'node:fs/promises'",
      name: 'object allowed whitelist allows selected builtin',
      options: [{ allowed: ['fs/promises'] }],
    },
  ],
})
