import { describe, expect, test } from 'vite-plus/test'

import { isHoistableDecoderCall } from './require-top-level-decoder.ts'

const makeCall = (namespace: string, method: string) => ({
  callee: {
    computed: false,
    object: { name: namespace, type: 'Identifier' },
    property: { name: method, type: 'Identifier' },
    type: 'MemberExpression',
  },
  type: 'CallExpression',
})

describe('isHoistableDecoderCall', () => {
  describe('Schema.decode* variants', () => {
    test.each(['decode', 'decodeEffect', 'decodeSync', 'decodeUnknownEffect', 'decodeUnknownSync'])(
      'Schema.%s returns true',
      (method) => {
        expect(isHoistableDecoderCall(makeCall('Schema', method))).toBe(true)
      },
    )
  })

  describe('HttpClientResponse.schema* variants', () => {
    test.each(['schemaJson', 'schemaBodyJson', 'schema'])('HttpClientResponse.%s returns true', (method) => {
      expect(isHoistableDecoderCall(makeCall('HttpClientResponse', method))).toBe(true)
    })
  })

  test('Schema.parse returns false (not a decode* method)', () => {
    expect(isHoistableDecoderCall(makeCall('Schema', 'parse'))).toBe(false)
  })

  test('Other.decode returns false (not a known namespace)', () => {
    expect(isHoistableDecoderCall(makeCall('Other', 'decode'))).toBe(false)
  })

  test('non-CallExpression returns false', () => {
    expect(isHoistableDecoderCall({ name: 'decode', type: 'Identifier' })).toBe(false)
  })
})
