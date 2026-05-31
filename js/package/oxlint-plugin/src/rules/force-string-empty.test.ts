import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isEmptyStringLiteral } from './force-string-empty.ts'

describe('isEmptyStringLiteral', () => {
  test('empty string literal returns true', () => {
    expect(isEmptyStringLiteral({ type: 'Literal', value: '' })).toBe(true)
  })

  test('non-empty string literal returns false', () => {
    expect(isEmptyStringLiteral({ type: 'Literal', value: 'hello' })).toBe(false)
  })

  test('number literal returns false', () => {
    expect(isEmptyStringLiteral({ type: 'Literal', value: 0 })).toBe(false)
  })

  test('null literal returns false', () => {
    expect(isEmptyStringLiteral({ type: 'Literal', value: null })).toBe(false)
  })

  test('non-literal node returns false', () => {
    expect(isEmptyStringLiteral({ name: '', type: 'Identifier' })).toBe(false)
  })
})

runRuleTest('force-string-empty', rule, {
  invalid: [
    { code: "if (s === '') {}", errors: 1, name: "=== '' reports String.isEmpty" },
    { code: "if ('' === s) {}", errors: 1, name: "'' === s reports String.isEmpty" },
    { code: "if (s !== '') {}", errors: 1, name: "!== '' reports String.isNonEmpty" },
  ],
  valid: [
    { code: 'if (String.isEmpty(s)) {}', name: 'recommended String.isEmpty call' },
    { code: "if (s === 'hello') {}", name: 'comparison with non-empty literal is ignored' },
    { code: 'if (s === 0) {}', name: 'numeric comparison is ignored' },
  ],
})
