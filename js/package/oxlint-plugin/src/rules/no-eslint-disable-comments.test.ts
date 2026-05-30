import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { matchesEslintDisable } from './no-eslint-disable-comments.ts'

describe('matchesEslintDisable', () => {
  test('eslint-disable matches', () => {
    expect(matchesEslintDisable(' eslint-disable')).toBe(true)
  })

  test('eslint-disable-next-line with rule matches', () => {
    expect(matchesEslintDisable(' eslint-disable-next-line no-console')).toBe(true)
  })

  test('eslint-disable-line with rule matches', () => {
    expect(matchesEslintDisable(' eslint-disable-line no-console')).toBe(true)
  })

  test('leading whitespace matches', () => {
    expect(matchesEslintDisable('   eslint-disable-next-line')).toBe(true)
  })

  test('oxlint-disable does not match', () => {
    expect(matchesEslintDisable(' oxlint-disable')).toBe(false)
  })

  test('regular comment does not match', () => {
    expect(matchesEslintDisable(' this is a regular comment')).toBe(false)
  })

  test('eslint-enable does not match (not a disable directive)', () => {
    expect(matchesEslintDisable(' eslint-enable')).toBe(false)
  })
})

runRuleTest('no-eslint-disable-comments', rule, {
  invalid: [
    {
      code: '// eslint-disable-next-line no-console\nconsole.log(1)',
      errors: 1,
      name: 'line eslint-disable-next-line is reported and fixed',
      output: '// oxlint-disable-next-line no-console\nconsole.log(1)',
    },
    {
      code: '/* eslint-disable no-console */\nconsole.log(1)',
      errors: 1,
      name: 'block eslint-disable is reported and fixed',
      output: '/* oxlint-disable no-console */\nconsole.log(1)',
    },
  ],
  valid: [
    { code: '// oxlint-disable-next-line no-console\nconsole.log(1)', name: 'oxlint-disable comments are allowed' },
    { code: '// just a regular comment\nconst x = 1', name: 'regular comments are allowed' },
  ],
})
