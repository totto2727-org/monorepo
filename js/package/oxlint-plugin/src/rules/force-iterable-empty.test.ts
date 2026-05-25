import { describe, expect, test } from 'vite-plus/test'

import { isIterableSizeCall } from './force-iterable-empty.ts'

const makeIterableSize = (objectName: string, methodName: string) => ({
  callee: {
    computed: false,
    object: { name: objectName, type: 'Identifier' },
    property: { name: methodName, type: 'Identifier' },
    type: 'MemberExpression',
  },
  type: 'CallExpression',
})

describe('isIterableSizeCall', () => {
  test('Iterable.size() returns true', () => {
    expect(isIterableSizeCall(makeIterableSize('Iterable', 'size'))).toBe(true)
  })

  test('Array.size() returns false (not Iterable)', () => {
    expect(isIterableSizeCall(makeIterableSize('Array', 'size'))).toBe(false)
  })

  test('Iterable.map() returns false (not size)', () => {
    expect(isIterableSizeCall(makeIterableSize('Iterable', 'map'))).toBe(false)
  })

  test('computed member expression returns false', () => {
    expect(
      isIterableSizeCall({
        callee: {
          computed: true,
          object: { name: 'Iterable', type: 'Identifier' },
          property: { name: 'size', type: 'Identifier' },
          type: 'MemberExpression',
        },
        type: 'CallExpression',
      }),
    ).toBe(false)
  })

  test('non-CallExpression returns false', () => {
    expect(isIterableSizeCall({ name: 'size', type: 'Identifier' })).toBe(false)
  })
})
