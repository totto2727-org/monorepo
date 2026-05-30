import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { classifyLengthComparison } from './force-array-empty.ts'

describe('classifyLengthComparison', () => {
  describe('literal === 0', () => {
    test('=== 0 is empty', () => {
      expect(classifyLengthComparison('===', 'right', 0)).toBe('empty')
      expect(classifyLengthComparison('===', 'left', 0)).toBe('empty')
    })

    test('!== 0 is non-empty', () => {
      expect(classifyLengthComparison('!==', 'right', 0)).toBe('non-empty')
      expect(classifyLengthComparison('!==', 'left', 0)).toBe('non-empty')
    })

    test('== 0 is empty', () => {
      expect(classifyLengthComparison('==', 'right', 0)).toBe('empty')
      expect(classifyLengthComparison('==', 'left', 0)).toBe('empty')
    })

    test('!= 0 is non-empty', () => {
      expect(classifyLengthComparison('!=', 'right', 0)).toBe('non-empty')
      expect(classifyLengthComparison('!=', 'left', 0)).toBe('non-empty')
    })

    test('length > 0 / 0 < length is non-empty', () => {
      expect(classifyLengthComparison('>', 'right', 0)).toBe('non-empty')
      expect(classifyLengthComparison('<', 'left', 0)).toBe('non-empty')
    })

    test('length < 0 / 0 > length is impossible (length is always >= 0) and not classified', () => {
      expect(classifyLengthComparison('<', 'right', 0)).toBeNull()
      expect(classifyLengthComparison('>', 'left', 0)).toBeNull()
    })

    test('length >= 0 / 0 <= length is a tautology and not classified', () => {
      expect(classifyLengthComparison('>=', 'right', 0)).toBeNull()
      expect(classifyLengthComparison('<=', 'left', 0)).toBeNull()
    })

    test('length <= 0 / 0 >= length is empty', () => {
      expect(classifyLengthComparison('<=', 'right', 0)).toBe('empty')
      expect(classifyLengthComparison('>=', 'left', 0)).toBe('empty')
    })
  })

  describe('literal === 1', () => {
    test('=== 1 is not classified (not an empty-check pattern)', () => {
      expect(classifyLengthComparison('===', 'right', 1)).toBeNull()
      expect(classifyLengthComparison('===', 'left', 1)).toBeNull()
    })

    test('!== 1 is not classified (not an empty-check pattern)', () => {
      expect(classifyLengthComparison('!==', 'right', 1)).toBeNull()
      expect(classifyLengthComparison('!==', 'left', 1)).toBeNull()
    })

    test('length < 1 / 1 > length is empty', () => {
      expect(classifyLengthComparison('<', 'right', 1)).toBe('empty')
      expect(classifyLengthComparison('>', 'left', 1)).toBe('empty')
    })

    test('length >= 1 / 1 <= length is non-empty', () => {
      expect(classifyLengthComparison('>=', 'right', 1)).toBe('non-empty')
      expect(classifyLengthComparison('<=', 'left', 1)).toBe('non-empty')
    })

    test('length > 1 / 1 < length means length >= 2 and not classified', () => {
      expect(classifyLengthComparison('>', 'right', 1)).toBeNull()
      expect(classifyLengthComparison('<', 'left', 1)).toBeNull()
    })

    test('length <= 1 / 1 >= length means length is 0 or 1 and not classified', () => {
      expect(classifyLengthComparison('<=', 'right', 1)).toBeNull()
      expect(classifyLengthComparison('>=', 'left', 1)).toBeNull()
    })
  })

  describe('other literals', () => {
    test('=== 2 is not classified', () => {
      expect(classifyLengthComparison('===', 'right', 2)).toBeNull()
    })

    test('> 2 is not classified', () => {
      expect(classifyLengthComparison('>', 'right', 2)).toBeNull()
    })
  })
})

runRuleTest('force-array-empty', rule, {
  invalid: [
    { code: 'if (arr.length === 0) {}', errors: 1, name: 'length === 0 reports empty' },
    { code: 'if (arr.length !== 0) {}', errors: 1, name: 'length !== 0 reports non-empty' },
    { code: 'if (arr.length > 0) {}', errors: 1, name: 'length > 0 reports non-empty' },
    { code: 'if (0 < arr.length) {}', errors: 1, name: '0 < length reports non-empty' },
    { code: 'if (arr.length < 1) {}', errors: 1, name: 'length < 1 reports empty' },
    { code: 'if (arr.length >= 1) {}', errors: 1, name: 'length >= 1 reports non-empty' },
  ],
  valid: [
    { code: 'if (arr.length === 5) {}', name: 'comparison with arbitrary literal is ignored' },
    { code: 'if (arr.length > 5) {}', name: 'comparison with non-empty-check literal is ignored' },
    { code: 'if (Array.isEmpty(arr)) {}', name: 'recommended Array.isEmpty call' },
    { code: 'if (arr.size === 0) {}', name: 'unrelated .size member is ignored' },
  ],
})
