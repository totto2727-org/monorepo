import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { isScriptJsxElement } from './no-jsx-script-tag.ts'

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

runRuleTest('no-jsx-script-tag', rule, {
  invalid: [
    {
      code: 'const el = <script>alert(1)</script>',
      errors: 1,
      filename: 'test.tsx',
      name: 'lowercase script JSX element is reported',
    },
    {
      code: "const el = <script src='/x.js'></script>",
      errors: 1,
      filename: 'test.tsx',
      name: 'self-attributed script JSX element is reported',
    },
  ],
  valid: [
    { code: 'const el = <div>hello</div>', filename: 'test.tsx', name: 'plain div element is allowed' },
    {
      code: "const el = <Script src='/x.js' />",
      filename: 'test.tsx',
      name: 'capitalised Script component is allowed (not the lowercase script HTML tag)',
    },
  ],
})
