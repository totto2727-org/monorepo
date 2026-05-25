import { describe, expect, test } from 'vite-plus/test'

import { hasDisableReason, isOxlintDisableDirective } from './require-disable-reason.ts'

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
