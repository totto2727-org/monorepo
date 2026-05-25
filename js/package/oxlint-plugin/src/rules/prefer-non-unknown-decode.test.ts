import { describe, expect, test } from 'vite-plus/test'

import { isSchemaUnknownDecodeCall } from './prefer-non-unknown-decode.ts'

const makeSchemaCall = (method: string) => ({
  callee: {
    computed: false,
    object: { name: 'Schema', type: 'Identifier' },
    property: { name: method, type: 'Identifier' },
    type: 'MemberExpression',
  },
  type: 'CallExpression',
})

describe('isSchemaUnknownDecodeCall', () => {
  test.each(['decodeUnknownEffect', 'decodeUnknownExit'])('%s returns method name', (method) => {
    expect(isSchemaUnknownDecodeCall(makeSchemaCall(method))).toBe(method)
  })

  test('decodeEffect returns null (non-unknown variant)', () => {
    expect(isSchemaUnknownDecodeCall(makeSchemaCall('decodeEffect'))).toBeNull()
  })

  test('decodeExit returns null (non-unknown variant)', () => {
    expect(isSchemaUnknownDecodeCall(makeSchemaCall('decodeExit'))).toBeNull()
  })

  test('non-Schema object returns null', () => {
    expect(
      isSchemaUnknownDecodeCall({
        callee: {
          computed: false,
          object: { name: 'Other', type: 'Identifier' },
          property: { name: 'decodeUnknownEffect', type: 'Identifier' },
          type: 'MemberExpression',
        },
        type: 'CallExpression',
      }),
    ).toBeNull()
  })
})
