import { describe, expect, test } from 'vite-plus/test'

import { isFetchIdentifier, isFetchOnGlobal } from './no-fetch.ts'

describe('isFetchIdentifier', () => {
  test('fetch identifier returns true', () => {
    expect(isFetchIdentifier({ name: 'fetch', type: 'Identifier' })).toBe(true)
  })

  test('non-fetch identifier returns false', () => {
    expect(isFetchIdentifier({ name: 'axios', type: 'Identifier' })).toBe(false)
  })

  test('non-Identifier returns false', () => {
    expect(isFetchIdentifier({ type: 'Literal', value: 'fetch' })).toBe(false)
  })
})

describe('isFetchOnGlobal', () => {
  test.each(['globalThis', 'window', 'self'])('%s.fetch returns true', (global) => {
    expect(
      isFetchOnGlobal({
        computed: false,
        object: { name: global, type: 'Identifier' },
        property: { name: 'fetch', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBe(true)
  })

  test('document.fetch returns false (not a recognized global)', () => {
    expect(
      isFetchOnGlobal({
        computed: false,
        object: { name: 'document', type: 'Identifier' },
        property: { name: 'fetch', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBe(false)
  })

  test('globalThis.axios returns false (not fetch)', () => {
    expect(
      isFetchOnGlobal({
        computed: false,
        object: { name: 'globalThis', type: 'Identifier' },
        property: { name: 'axios', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBe(false)
  })

  test('computed member expression returns false', () => {
    expect(
      isFetchOnGlobal({
        computed: true,
        object: { name: 'globalThis', type: 'Identifier' },
        property: { name: 'fetch', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBe(false)
  })
})
