import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { hasDisableReason, isOxlintDisableDirective } from './require-disable-reason.ts'

describe('isOxlintDisableDirective', () => {
  test('oxlint-disable matches', () => {
    expect(isOxlintDisableDirective(' oxlint-disable')).toBe(true)
  })

  test('oxlint-disable-next-line with rule matches', () => {
    expect(isOxlintDisableDirective(' oxlint-disable-next-line rules/no-let')).toBe(true)
  })

  test('oxlint-disable-line matches', () => {
    expect(isOxlintDisableDirective(' oxlint-disable-line rules/no-let')).toBe(true)
  })

  test('eslint-disable does not match', () => {
    expect(isOxlintDisableDirective(' eslint-disable')).toBe(false)
  })

  test('regular comment does not match', () => {
    expect(isOxlintDisableDirective(' some comment')).toBe(false)
  })
})

describe('hasDisableReason', () => {
  test('comment with reason after " -- " matches', () => {
    expect(hasDisableReason(' oxlint-disable -- some reason here')).toBe(true)
  })

  test('comment without reason does not match', () => {
    expect(hasDisableReason(' oxlint-disable-next-line rules/no-let')).toBe(false)
  })

  test('double dash without trailing space does not match', () => {
    expect(hasDisableReason(' oxlint-disable --reason')).toBe(false)
  })

  test('double dash without leading space does not match', () => {
    expect(hasDisableReason(' oxlint-disable-- reason')).toBe(false)
  })
})

runRuleTest('require-disable-reason', rule, {
  invalid: [
    {
      code: '// oxlint-disable-next-line no-fetch\nfetch("x")',
      errors: 1,
      name: 'line oxlint-disable without reason is reported',
    },
    {
      code: '/* oxlint-disable no-fetch */\nfetch("x")',
      errors: 1,
      name: 'block oxlint-disable without reason is reported',
    },
  ],
  valid: [
    {
      code: '// oxlint-disable-next-line no-fetch -- bypass for external API\nfetch("x")',
      name: 'line oxlint-disable with reason is allowed',
    },
    {
      code: '/* oxlint-disable no-fetch -- anti-corruption boundary */\nfetch("x")',
      name: 'block oxlint-disable with reason is allowed',
    },
    { code: '// regular comment\nconst x = 1', name: 'non-directive comments are allowed' },
    { code: '// eslint-disable-next-line foo\nconst x = 1', name: 'eslint-disable directives are out of scope' },
  ],
})
