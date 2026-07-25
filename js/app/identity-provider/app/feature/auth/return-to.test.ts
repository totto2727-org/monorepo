import { describe, expect, it } from 'vite-plus/test'

import { getReturnToPath } from './return-to.ts'

describe('getReturnToPath', () => {
  it.each([
    ['/app/account?tab=security', '/app/account?tab=security'],
    ['https%3A%2F%2Fclient.example%2Fcallback%3Fcode%3D123', '/callback?code=123'],
    ['?tab=security', '/?tab=security'],
  ])('returns the local path and query for %s', (value, expected) => {
    const result = getReturnToPath(value)

    expect(result).toBe(expected)
  })

  it.each([undefined, '', '%'])('returns no path for missing or malformed input %s', (value) => {
    const result = getReturnToPath(value)

    expect(result).toBeUndefined()
  })

  it('returns no path when the target uses an unknown URL scheme', () => {
    const result = getReturnToPath('data:text/plain,external')

    expect(result).toBeUndefined()
  })
})
