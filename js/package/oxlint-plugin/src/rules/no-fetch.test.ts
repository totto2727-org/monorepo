import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isFetchIdentifier, isFetchOnGlobal } from './no-fetch.ts'

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

runRuleTest('no-fetch', rule, {
  invalid: [
    { code: "fetch('https://example.com')", errors: 1, name: 'bare fetch call is reported' },
    { code: "globalThis.fetch('https://example.com')", errors: 1, name: 'globalThis.fetch is reported' },
    { code: "window.fetch('https://example.com')", errors: 1, name: 'window.fetch is reported' },
    { code: "self.fetch('https://example.com')", errors: 1, name: 'self.fetch is reported' },
  ],
  valid: [
    { code: "myClient.fetch('https://example.com')", name: 'non-global .fetch call is allowed' },
    { code: 'const f = fetch; f()', name: 'reference to fetch without call site is not reported' },
    { code: "httpClient.get('https://example.com')", name: 'arbitrary client call is allowed' },
  ],
})
