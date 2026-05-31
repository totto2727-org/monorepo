import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isEffectEcosystemImport } from './no-effect-import-as.ts'

describe('isEffectEcosystemImport', () => {
  describe('effect ecosystem packages', () => {
    test.each(['effect', '@effect/platform', '@effect/platform-node', 'effect/unstable'])(
      '%s returns true',
      (source) => {
        expect(isEffectEcosystemImport(source)).toBe(true)
      },
    )
  })

  describe('non-effect packages', () => {
    test.each(['react', 'vue', 'vite', 'zod', '@tanstack/react-query'])('%s returns false', (source) => {
      expect(isEffectEcosystemImport(source)).toBe(false)
    })
  })
})

runRuleTest('no-effect-import-as', rule, {
  invalid: [
    {
      code: "import * as Effect from 'effect'",
      errors: 1,
      name: 'namespace import from effect is reported',
    },
    {
      code: "import { Schema as S } from 'effect'",
      errors: 1,
      name: 'aliased named import from effect is reported',
    },
    {
      code: "import * as Platform from '@effect/platform-node'",
      errors: 1,
      name: 'namespace import from @effect scope is reported',
    },
  ],
  valid: [
    { code: "import { Effect, Schema } from 'effect'", name: 'plain named imports from effect are allowed' },
    {
      code: "import { NodeRuntime } from '@effect/platform-node'",
      name: 'plain named imports from @effect scope are allowed',
    },
    { code: "import * as React from 'react'", name: 'namespace import from non-effect package is allowed' },
    {
      code: "import { foo as bar } from 'unrelated'",
      name: 'aliased import from non-effect package is allowed',
    },
  ],
})
