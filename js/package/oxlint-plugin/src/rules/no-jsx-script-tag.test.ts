import { describe, expect, test } from 'vite-plus/test'

import { isScriptJsxElement } from './no-jsx-script-tag.ts'

describe('isScriptJsxElement', () => {
  describe('matches', () => {
    test('script JSXOpeningElement', () => {
      expect(
        isScriptJsxElement({
          name: { name: 'script', type: 'JSXIdentifier' },
          range: [0, 8],
          type: 'JSXOpeningElement',
        }),
      ).toBe(true)
    })
  })

  describe('does not match', () => {
    test('non-script JSXOpeningElement (div)', () => {
      expect(
        isScriptJsxElement({
          name: { name: 'div', type: 'JSXIdentifier' },
          range: [0, 5],
          type: 'JSXOpeningElement',
        }),
      ).toBe(false)
    })

    test('capitalized Script component (custom component)', () => {
      expect(
        isScriptJsxElement({
          name: { name: 'Script', type: 'JSXIdentifier' },
          range: [0, 8],
          type: 'JSXOpeningElement',
        }),
      ).toBe(false)
    })

    test('non-JSX node type', () => {
      expect(
        isScriptJsxElement({
          name: 'script',
          range: [0, 8],
          type: 'Identifier',
        }),
      ).toBe(false)
    })

    test('missing name property', () => {
      expect(
        isScriptJsxElement({
          range: [0, 8],
          type: 'JSXOpeningElement',
        }),
      ).toBe(false)
    })
  })
})
