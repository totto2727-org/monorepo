import { describe, expect, expectTypeOf, test } from 'vite-plus/test'

import { createFrameHelpers } from './frame-helpers.ts'

describe('createFrameHelpers', () => {
  test('isFrameRequest が header 比較で true / false を返す', () => {
    const helpers = createFrameHelpers<'content' | 'sidebar'>()

    // type-level: frame パラメータは union に拘束される
    expectTypeOf(helpers.isFrameRequest).parameter(1).toEqualTypeOf<'content' | 'sidebar'>()

    const matchingRequest = new Request('http://localhost', { headers: { 'x-remix-target': 'content' } })
    expect(helpers.isFrameRequest(matchingRequest, 'content')).toBe(true)
    expect(helpers.isFrameRequest(matchingRequest, 'sidebar')).toBe(false)

    const missingHeaderRequest = new Request('http://localhost')
    expect(helpers.isFrameRequest(missingHeaderRequest, 'content')).toBe(false)
    expect(helpers.isFrameRequest(missingHeaderRequest, 'sidebar')).toBe(false)
  })

  test('createFrameHelpers が FrameLink を含む期待の shape を返す', () => {
    const helpers = createFrameHelpers<'content'>()

    // type-level: 全プロパティが function 型を持つ
    expectTypeOf(helpers.isFrameRequest).toBeFunction()
    expectTypeOf(helpers.createPageOrFrame).toBeFunction()
    expectTypeOf(helpers.FrameLink).toBeFunction()
  })
})
