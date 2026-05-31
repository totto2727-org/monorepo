import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, { getOptionTag, isTagPropertyAccess } from './no-option-tag-comparison.ts'

describe('getOptionTag', () => {
  test('"Some" returns "Some"', () => {
    expect(getOptionTag({ type: 'Literal', value: 'Some' })).toBe('Some')
  })

  test('"None" returns "None"', () => {
    expect(getOptionTag({ type: 'Literal', value: 'None' })).toBe('None')
  })

  test('"Left" returns null (not a recognized tag)', () => {
    expect(getOptionTag({ type: 'Literal', value: 'Left' })).toBeNull()
  })

  test('number literal returns null', () => {
    expect(getOptionTag({ type: 'Literal', value: 42 })).toBeNull()
  })

  test('non-literal returns null', () => {
    expect(getOptionTag({ name: 'Some', type: 'Identifier' })).toBeNull()
  })
})

describe('isTagPropertyAccess', () => {
  test('x._tag MemberExpression returns true', () => {
    expect(
      isTagPropertyAccess({
        computed: false,
        object: { name: 'x', type: 'Identifier' },
        property: { name: '_tag', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBe(true)
  })

  test('computed member expression returns false', () => {
    expect(
      isTagPropertyAccess({
        computed: true,
        object: { name: 'x', type: 'Identifier' },
        property: { name: '_tag', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBe(false)
  })

  test('x.tag (not _tag) returns false', () => {
    expect(
      isTagPropertyAccess({
        computed: false,
        object: { name: 'x', type: 'Identifier' },
        property: { name: 'tag', type: 'Identifier' },
        type: 'MemberExpression',
      }),
    ).toBe(false)
  })

  test('non-MemberExpression returns false', () => {
    expect(isTagPropertyAccess({ name: '_tag', type: 'Identifier' })).toBe(false)
  })
})

runRuleTest('no-option-tag-comparison', rule, {
  invalid: [
    {
      code: "if (opt._tag === 'Some') {}",
      errors: 1,
      name: '_tag === Some is reported and fixed to Option.isSome',
      output: 'if (Option.isSome(opt)) {}',
    },
    {
      code: "if (opt._tag === 'None') {}",
      errors: 1,
      name: '_tag === None is reported and fixed to Option.isNone',
      output: 'if (Option.isNone(opt)) {}',
    },
    {
      code: "if (opt._tag !== 'Some') {}",
      errors: 1,
      name: '_tag !== Some is reported and fixed to !Option.isSome',
      output: 'if (!Option.isSome(opt)) {}',
    },
  ],
  valid: [
    { code: 'if (Option.isSome(opt)) {}', name: 'recommended Option.isSome call' },
    { code: 'if (Option.isNone(opt)) {}', name: 'recommended Option.isNone call' },
    { code: "if (opt._tag === 'Other') {}", name: 'unknown tag is ignored' },
    { code: "if (x === 'Some') {}", name: 'tag-shaped string against non _tag access is ignored' },
  ],
})
