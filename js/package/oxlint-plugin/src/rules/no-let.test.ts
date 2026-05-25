import { describe, expect, test } from 'vite-plus/test'

import { isLetDeclaration } from './no-let.ts'

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
