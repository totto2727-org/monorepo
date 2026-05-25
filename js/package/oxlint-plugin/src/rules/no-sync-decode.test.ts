import { describe, expect, test } from 'vite-plus/test'

import { isSchemaBannedDecodeCall } from './no-sync-decode.ts'

const makeSchemaCall = (method: string) => ({
  callee: {
    computed: false,
    object: { name: 'Schema', type: 'Identifier' },
    property: { name: method, type: 'Identifier' },
    type: 'MemberExpression',
  },
  type: 'CallExpression',
})

describe('isSchemaBannedDecodeCall', () => {
  test.each(['decodeSync', 'decodePromise', 'decodeUnknownSync', 'decodeUnknownPromise'])(
    '%s returns method name',
    (method) => {
      expect(isSchemaBannedDecodeCall(makeSchemaCall(method))).toBe(method)
    },
  )

  test('decodeEffect returns null (allowed method)', () => {
    expect(isSchemaBannedDecodeCall(makeSchemaCall('decodeEffect'))).toBeNull()
  })

  test('decodeExit returns null (allowed method)', () => {
    expect(isSchemaBannedDecodeCall(makeSchemaCall('decodeExit'))).toBeNull()
  })

  test('non-Schema object returns null', () => {
    expect(
      isSchemaBannedDecodeCall({
        callee: {
          computed: false,
          object: { name: 'Other', type: 'Identifier' },
          property: { name: 'decodeSync', type: 'Identifier' },
          type: 'MemberExpression',
        },
        type: 'CallExpression',
      }),
    ).toBeNull()
  })

  test('non-CallExpression returns null', () => {
    expect(isSchemaBannedDecodeCall({ name: 'decodeSync', type: 'Identifier' })).toBeNull()
  })
})
