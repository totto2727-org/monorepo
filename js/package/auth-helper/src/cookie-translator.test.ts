import { describe, expect, test } from 'vite-plus/test'

import { extractBearerFromCookie } from './cookie-translator.ts'

describe('extractBearerFromCookie', () => {
  test('returns Bearer token when cookie is present', () => {
    expect(extractBearerFromCookie('feed-session', 'feed-session=abc.def.ghi')).toBe('Bearer abc.def.ghi')
  })

  test('returns null when cookieHeader is undefined', () => {
    const noCookie: string | undefined = undefined
    expect(extractBearerFromCookie('feed-session', noCookie)).toBeNull()
  })

  test('returns null when cookie name is not found', () => {
    expect(extractBearerFromCookie('feed-session', 'other-cookie=xyz')).toBeNull()
  })

  test('returns null when cookie value is empty', () => {
    expect(extractBearerFromCookie('feed-session', 'feed-session=')).toBeNull()
  })

  test('handles multiple cookies and finds the matching one', () => {
    expect(extractBearerFromCookie('feed-session', 'a=1; feed-session=tok.en; b=2')).toBe('Bearer tok.en')
  })

  test('handles JWT tokens with = padding in value', () => {
    expect(extractBearerFromCookie('feed-session', 'feed-session=aGVsbG8=')).toBe('Bearer aGVsbG8=')
  })

  test('trims whitespace around cookie name and value', () => {
    expect(extractBearerFromCookie('feed-session', '  feed-session =  abc123  ')).toBe('Bearer abc123')
  })

  test('returns null when cookie value is only whitespace', () => {
    expect(extractBearerFromCookie('feed-session', 'feed-session=   ')).toBeNull()
  })
})
