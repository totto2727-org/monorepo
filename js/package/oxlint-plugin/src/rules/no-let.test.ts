import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isLetDeclaration } from './no-let.ts'

describe('isLetDeclaration', () => {
  test('let declaration returns true', () => {
    expect(isLetDeclaration({ kind: 'let', type: 'VariableDeclaration' })).toBe(true)
  })

  test('const declaration returns false', () => {
    expect(isLetDeclaration({ kind: 'const', type: 'VariableDeclaration' })).toBe(false)
  })

  test('var declaration returns false', () => {
    expect(isLetDeclaration({ kind: 'var', type: 'VariableDeclaration' })).toBe(false)
  })

  test('non-object returns false', () => {
    expect(isLetDeclaration(null)).toBe(false)
    expect(isLetDeclaration('let')).toBe(false)
  })
})

runRuleTest('no-let', rule, {
  invalid: [
    { code: 'let x = 1', errors: 1, name: 'let declaration is reported' },
    { code: 'let x = 1, y = 2', errors: 1, name: 'multi-declarator let is reported once per declaration' },
  ],
  valid: [
    { code: 'const x = 1', name: 'const declaration is allowed' },
    { code: 'var x = 1', name: 'var declaration is not reported by this rule' },
  ],
})
