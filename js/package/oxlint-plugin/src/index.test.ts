import { describe, expect, test } from 'vite-plus/test'

import { classifyLengthComparison, matchJsImport } from './index.ts'

describe('matchJsImport', () => {
  describe('matches', () => {
    test('relative path with single dot', () => {
      expect(matchJsImport('./foo.js')).toEqual({ path: '/foo', start: '.', x: '' })
    })

    test('relative path with double dot and jsx', () => {
      expect(matchJsImport('../bar.jsx')).toEqual({ path: '/bar', start: '..', x: 'x' })
    })

    test('subpath import with single hash', () => {
      expect(matchJsImport('#/qux.jsx')).toEqual({ path: '/qux', start: '#', x: 'x' })
    })

    test('subpath import with hash alias', () => {
      expect(matchJsImport('#@/baz.js')).toEqual({ path: '/baz', start: '#@', x: '' })
    })

    test('nested relative path', () => {
      expect(matchJsImport('./reexport.js')).toEqual({ path: '/reexport', start: '.', x: '' })
    })
  })

  describe('does not match', () => {
    test('bare package name', () => {
      expect(matchJsImport('package-name')).toBeNull()
    })

    test('package name with .js but no slash', () => {
      expect(matchJsImport('package.js')).toBeNull()
    })

    test('double-hash subpath import', () => {
      expect(matchJsImport('##storybook/utils')).toBeNull()
    })

    test('relative ts file', () => {
      expect(matchJsImport('./ok.ts')).toBeNull()
    })

    test('relative tsx file', () => {
      expect(matchJsImport('../ok.tsx')).toBeNull()
    })

    test('absolute path starting with slash', () => {
      expect(matchJsImport('/foo.js')).toBeNull()
    })
  })

  describe('terminates quickly on adversarial input', () => {
    test('many leading slashes (no js suffix)', () => {
      const malicious = `${'/'.repeat(100_000)}a`
      const start = performance.now()
      const result = matchJsImport(malicious)
      const elapsed = performance.now() - start
      expect(result).toBeNull()
      expect(elapsed).toBeLessThan(100)
    })

    test('many slashes after hash prefix', () => {
      const malicious = `#${'/'.repeat(100_000)}a`
      const start = performance.now()
      const result = matchJsImport(malicious)
      const elapsed = performance.now() - start
      expect(result).toBeNull()
      expect(elapsed).toBeLessThan(100)
    })

    test('many dots without slash', () => {
      const malicious = '.'.repeat(100_000)
      const start = performance.now()
      const result = matchJsImport(malicious)
      const elapsed = performance.now() - start
      expect(result).toBeNull()
      expect(elapsed).toBeLessThan(100)
    })
  })
})

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
    })

    test('!= 0 is non-empty', () => {
      expect(classifyLengthComparison('!=', 'right', 0)).toBe('non-empty')
    })

    test('length > 0 is non-empty (literal on right)', () => {
      expect(classifyLengthComparison('>', 'right', 0)).toBe('non-empty')
    })

    test('0 > length is empty (literal on left) — captures "0 > arr.length" as a no-op empty check', () => {
      expect(classifyLengthComparison('>', 'left', 0)).toBe('empty')
    })

    test('length < 0 is empty', () => {
      expect(classifyLengthComparison('<', 'right', 0)).toBe('empty')
    })

    test('0 < length is non-empty', () => {
      expect(classifyLengthComparison('<', 'left', 0)).toBe('non-empty')
    })

    test('length >= 0 is meaningless and not classified', () => {
      expect(classifyLengthComparison('>=', 'right', 0)).toBeNull()
    })

    test('0 >= length is empty', () => {
      expect(classifyLengthComparison('>=', 'left', 0)).toBe('empty')
    })

    test('length <= 0 is empty', () => {
      expect(classifyLengthComparison('<=', 'right', 0)).toBe('empty')
    })

    test('0 <= length is meaningless and not classified', () => {
      expect(classifyLengthComparison('<=', 'left', 0)).toBeNull()
    })
  })

  describe('literal === 1', () => {
    test('length < 1 is empty', () => {
      expect(classifyLengthComparison('<', 'right', 1)).toBe('empty')
    })

    test('1 < length is non-empty', () => {
      expect(classifyLengthComparison('<', 'left', 1)).toBe('non-empty')
    })

    test('length >= 1 is non-empty', () => {
      expect(classifyLengthComparison('>=', 'right', 1)).toBe('non-empty')
    })

    test('1 >= length is empty', () => {
      expect(classifyLengthComparison('>=', 'left', 1)).toBe('empty')
    })

    test('=== 1 is not classified (not an empty-check pattern)', () => {
      expect(classifyLengthComparison('===', 'right', 1)).toBeNull()
    })

    test('!== 1 is not classified (not an empty-check pattern)', () => {
      expect(classifyLengthComparison('!==', 'right', 1)).toBeNull()
    })

    test('1 > length is empty', () => {
      expect(classifyLengthComparison('>', 'left', 1)).toBe('empty')
    })

    test('length > 1 is not classified (means length >= 2)', () => {
      expect(classifyLengthComparison('>', 'right', 1)).toBeNull()
    })

    test('1 <= length is non-empty', () => {
      expect(classifyLengthComparison('<=', 'left', 1)).toBe('non-empty')
    })

    test('length <= 1 is not classified (means 0 or 1)', () => {
      expect(classifyLengthComparison('<=', 'right', 1)).toBeNull()
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
