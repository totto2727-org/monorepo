import { describe, expect, test } from 'vite-plus/test'

import { isEffectEcosystemImport } from './no-effect-import-as.ts'

describe('isEffectEcosystemImport', () => {
  describe('effect ecosystem packages', () => {
    test.each(['effect', '@effect/platform', '@effect/platform-node', 'effect/unstable'])(
      '%s returns true',
      (source) => {
        expect(isEffectEcosystemImport(source)).toBe(true)
      },
    )
  })

  describe('non-effect packages', () => {
    test.each(['react', 'vue', 'vite', 'zod', '@tanstack/react-query'])('%s returns false', (source) => {
      expect(isEffectEcosystemImport(source)).toBe(false)
    })
  })
})
