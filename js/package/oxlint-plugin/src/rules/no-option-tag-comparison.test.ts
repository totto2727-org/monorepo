import { describe, expect, test } from 'vite-plus/test'

import { getOptionTag, isTagPropertyAccess } from './no-option-tag-comparison.ts'

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
