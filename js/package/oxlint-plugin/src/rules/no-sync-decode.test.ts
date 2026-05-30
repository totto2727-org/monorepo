import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isSchemaBannedDecodeCall } from './no-sync-decode.ts'

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

runRuleTest('no-sync-decode', rule, {
  invalid: [
    { code: 'Schema.decodeSync(schema)(input)', errors: 1, name: 'decodeSync is reported' },
    { code: 'Schema.decodePromise(schema)(input)', errors: 1, name: 'decodePromise is reported' },
    { code: 'Schema.decodeUnknownSync(schema)(input)', errors: 1, name: 'decodeUnknownSync is reported' },
    { code: 'Schema.decodeUnknownPromise(schema)(input)', errors: 1, name: 'decodeUnknownPromise is reported' },
  ],
  valid: [
    { code: 'Schema.decodeEffect(schema)(input)', name: 'decodeEffect is allowed' },
    { code: 'Schema.decodeUnknownEffect(schema)(input)', name: 'decodeUnknownEffect is allowed' },
    { code: 'Schema.decodeExit(schema)(input)', name: 'decodeExit is allowed' },
    { code: 'Other.decodeSync(schema)(input)', name: 'unrelated namespace decodeSync is ignored' },
  ],
})
