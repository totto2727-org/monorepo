import { describe, expect, test } from 'vite-plus/test'

import { isAllowedEffectImport } from './no-effect-subpath-import.ts'

describe('isAllowedEffectImport', () => {
  describe('allowed imports', () => {
    test('effect root package', () => {
      expect(isAllowedEffectImport('effect')).toBe(true)
    })

    test('@effect/platform root (single segment after @effect/)', () => {
      expect(isAllowedEffectImport('@effect/platform')).toBe(true)
    })

    test('@effect/platform-node root', () => {
      expect(isAllowedEffectImport('@effect/platform-node')).toBe(true)
    })

    test('effect/unstable/HttpClient (single segment under unstable/)', () => {
      expect(isAllowedEffectImport('effect/unstable/HttpClient')).toBe(true)
    })
  })

  describe('disallowed subpath imports', () => {
    test('@effect/platform/NodeRuntime', () => {
      expect(isAllowedEffectImport('@effect/platform/NodeRuntime')).toBe(false)
    })

    test('effect/Stream subpath', () => {
      expect(isAllowedEffectImport('effect/Stream')).toBe(false)
    })

    test('effect/unstable/foo/bar (double segment under unstable/)', () => {
      expect(isAllowedEffectImport('effect/unstable/foo/bar')).toBe(false)
    })
  })
})
