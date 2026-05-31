import { describe, expect, it } from 'vite-plus/test'

import { isSafeReturnTo, withReturnTo } from '#@/ui/return-to.ts'

describe('isSafeReturnTo', () => {
  it('accepts a single-slash absolute path', () => {
    expect(isSafeReturnTo('/app/login')).toBe(true)
  })

  it('accepts a path with query string', () => {
    expect(isSafeReturnTo('/api/v1/auth/oauth2/authorize?client_id=x&state=y')).toBe(true)
  })

  it('rejects empty string', () => {
    expect(isSafeReturnTo('')).toBe(false)
  })

  it('rejects an absolute URL with scheme', () => {
    expect(isSafeReturnTo('https://evil.example.com/callback')).toBe(false)
  })

  it('rejects a protocol-relative URL (open redirect)', () => {
    expect(isSafeReturnTo('//evil.example.com/path')).toBe(false)
  })

  it('rejects a path without leading slash', () => {
    expect(isSafeReturnTo('app/login')).toBe(false)
  })
})

describe('withReturnTo', () => {
  it('appends ?return_to= when value is safe', () => {
    expect(withReturnTo('/app/login/passkey', '/app/account')).toBe('/app/login/passkey?return_to=%2Fapp%2Faccount')
  })

  it('URL-encodes a return_to containing query string and slashes', () => {
    expect(withReturnTo('/app/auth/passkey/callback', '/api/v1/auth/oauth2/authorize?client_id=x&state=y')).toBe(
      '/app/auth/passkey/callback?return_to=%2Fapi%2Fv1%2Fauth%2Foauth2%2Fauthorize%3Fclient_id%3Dx%26state%3Dy',
    )
  })

  it('returns basePath unchanged when return_to is undefined', () => {
    const noReturnTo: string | undefined = undefined
    expect(withReturnTo('/app/login/passkey', noReturnTo)).toBe('/app/login/passkey')
  })

  it('returns basePath unchanged when return_to is unsafe (protocol-relative)', () => {
    expect(withReturnTo('/app/login/passkey', '//evil.example.com')).toBe('/app/login/passkey')
  })

  it('returns basePath unchanged when return_to is an absolute URL', () => {
    expect(withReturnTo('/app/login/passkey', 'https://evil.example.com/cb')).toBe('/app/login/passkey')
  })
})
