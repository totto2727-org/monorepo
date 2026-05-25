import { describe, expect, test } from 'vite-plus/test'

import { hasStringStyleValue } from './no-string-style.ts'

describe('hasStringStyleValue', () => {
  test('string style attribute returns true', () => {
    expect(
      hasStringStyleValue({
        name: { name: 'style', type: 'JSXIdentifier' },
        type: 'JSXAttribute',
        value: { type: 'Literal', value: 'color: red' },
      }),
    ).toBe(true)
  })

  test('object style attribute (JSXExpressionContainer) returns false', () => {
    expect(
      hasStringStyleValue({
        name: { name: 'style', type: 'JSXIdentifier' },
        type: 'JSXAttribute',
        value: { expression: {}, type: 'JSXExpressionContainer' },
      }),
    ).toBe(false)
  })

  test('non-style attribute returns false', () => {
    expect(
      hasStringStyleValue({
        name: { name: 'className', type: 'JSXIdentifier' },
        type: 'JSXAttribute',
        value: { type: 'Literal', value: 'foo' },
      }),
    ).toBe(false)
  })

  test('non-JSXAttribute type returns false', () => {
    expect(
      hasStringStyleValue({
        name: { name: 'style', type: 'JSXIdentifier' },
        type: 'Attribute',
        value: { type: 'Literal', value: 'color: red' },
      }),
    ).toBe(false)
  })
})
