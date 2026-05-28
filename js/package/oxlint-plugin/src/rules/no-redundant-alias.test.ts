import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isIdentifierInitDeclarator, isRedundantTypeAlias } from './no-redundant-alias.ts'

describe('isRedundantTypeAlias', () => {
  test('plain type reference without generics returns true', () => {
    expect(
      isRedundantTypeAlias({
        type: 'TSTypeAliasDeclaration',
        typeAnnotation: { type: 'TSTypeReference' },
      }),
    ).toBe(true)
  })

  test('type reference with typeArguments returns false (generic application)', () => {
    expect(
      isRedundantTypeAlias({
        type: 'TSTypeAliasDeclaration',
        typeAnnotation: { type: 'TSTypeReference', typeArguments: { params: [] } },
      }),
    ).toBe(false)
  })

  test('alias with typeParameters returns false (generic alias definition)', () => {
    expect(
      isRedundantTypeAlias({
        type: 'TSTypeAliasDeclaration',
        typeAnnotation: { type: 'TSTypeReference' },
        typeParameters: { params: [{ name: 'T' }] },
      }),
    ).toBe(false)
  })

  test('non-TSTypeReference annotation returns false', () => {
    expect(
      isRedundantTypeAlias({
        type: 'TSTypeAliasDeclaration',
        typeAnnotation: { type: 'TSStringKeyword' },
      }),
    ).toBe(false)
  })

  test('non-TSTypeAliasDeclaration returns false', () => {
    expect(isRedundantTypeAlias({ type: 'TSInterfaceDeclaration' })).toBe(false)
  })
})

describe('isIdentifierInitDeclarator', () => {
  test('const a = b declarator returns true', () => {
    expect(
      isIdentifierInitDeclarator({
        id: { name: 'a', type: 'Identifier' },
        init: { name: 'b', type: 'Identifier' },
        type: 'VariableDeclarator',
      }),
    ).toBe(true)
  })

  test('const a = 1 declarator returns false (non-identifier init)', () => {
    expect(
      isIdentifierInitDeclarator({
        id: { name: 'a', type: 'Identifier' },
        init: { type: 'Literal', value: 1 },
        type: 'VariableDeclarator',
      }),
    ).toBe(false)
  })

  test('const [a] = b declarator returns false (non-identifier id)', () => {
    expect(
      isIdentifierInitDeclarator({
        id: { elements: [], type: 'ArrayPattern' },
        init: { name: 'b', type: 'Identifier' },
        type: 'VariableDeclarator',
      }),
    ).toBe(false)
  })

  test('declarator without init returns false', () => {
    expect(
      isIdentifierInitDeclarator({
        id: { name: 'a', type: 'Identifier' },
        type: 'VariableDeclarator',
      }),
    ).toBe(false)
  })
})

runRuleTest('no-redundant-alias', rule, {
  invalid: [
    {
      code: 'type SentEmail = SendParams',
      errors: 1,
      filename: 'test.ts',
      name: 'plain type-alias rename is reported',
    },
    {
      code: 'export const sentEmail = sendParams',
      errors: 1,
      filename: 'test.ts',
      name: 'exported identifier-only re-binding is reported',
    },
  ],
  valid: [
    {
      code: 'type SentEmail = SendParams & { sentAt: Date }',
      filename: 'test.ts',
      name: 'type alias that adds structure is allowed',
    },
    {
      code: 'type Wrapped<T> = Box<T>',
      filename: 'test.ts',
      name: 'generic alias is allowed',
    },
    {
      code: 'export const sentEmail = makeSentEmail()',
      filename: 'test.ts',
      name: 'exported binding initialised by a call expression is allowed',
    },
    {
      code: 'const sentEmail = sendParams',
      filename: 'test.ts',
      name: 'non-exported identifier re-binding is allowed',
    },
  ],
})
