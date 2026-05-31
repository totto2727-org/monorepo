import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { hasStringStyleValue } from './no-string-style.ts'

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

runRuleTest('no-string-style', rule, {
  invalid: [
    {
      code: "const el = <div style='color: red' />",
      errors: 1,
      filename: 'test.tsx',
      name: 'string-valued style attribute is reported',
    },
  ],
  valid: [
    {
      code: "const el = <div style={{ color: 'red' }} />",
      filename: 'test.tsx',
      name: 'object-valued style attribute is allowed',
    },
    {
      code: "const el = <div className='x' />",
      filename: 'test.tsx',
      name: 'string-valued non-style attribute is allowed',
    },
  ],
})
