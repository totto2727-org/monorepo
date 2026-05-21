import { describe, expect, it } from 'vite-plus/test'

import { extractBearerFromCookie } from './cookie-translator.ts'

describe('extractBearerFromCookie', () => {
  it('returns Bearer token when cookie is present', () => {
    expect(extractBearerFromCookie('feed-session', 'feed-session=abc.def.ghi')).toBe('Bearer abc.def.ghi')
  })

  it('returns null when cookieHeader is undefined', () => {
    expect(extractBearerFromCookie('feed-session')).toBeNull()
  })

  it('returns null when cookie name is not found', () => {
    expect(extractBearerFromCookie('feed-session', 'other-cookie=xyz')).toBeNull()
  })

  it('returns null when cookie value is empty', () => {
    expect(extractBearerFromCookie('feed-session', 'feed-session=')).toBeNull()
  })

  it('handles multiple cookies and finds the right one', () => {
    expect(extractBearerFromCookie('feed-session', 'a=1; feed-session=tok.en; b=2')).toBe('Bearer tok.en')
  })

  it('handles JWT tokens with = padding in value', () => {
    const token = 'aGVsbG8='
    expect(extractBearerFromCookie('feed-session', `feed-session=${token}`)).toBe(`Bearer ${token}`)
  })
})
