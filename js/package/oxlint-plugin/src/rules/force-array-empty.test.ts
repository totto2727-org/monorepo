import { describe, expect, test } from 'vite-plus/test'

import { classifyLengthComparison } from './force-array-empty.ts'

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
