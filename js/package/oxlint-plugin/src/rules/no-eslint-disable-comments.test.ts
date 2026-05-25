import { describe, expect, test } from 'vite-plus/test'

import { matchesEslintDisable } from './no-eslint-disable-comments.ts'

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
