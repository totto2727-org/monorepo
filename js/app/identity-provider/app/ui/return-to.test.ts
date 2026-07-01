import { describe, expect, it } from 'vite-plus/test'

import { getSafeReturnTo, withReturnTo } from '#@/ui/return-to.ts'

describe('getSafeReturnTo', () => {
  it('returns pathname+search for a safe path', () => {
    expect(getSafeReturnTo('/app/login')).toBe('/app/login')
  })

  it('returns pathname+search for a path with query string', () => {
    expect(getSafeReturnTo('/api/v1/auth/oauth2/authorize?client_id=x&state=y')).toBe(
      '/api/v1/auth/oauth2/authorize?client_id=x&state=y',
    )
  })

  it('returns undefined for empty string', () => {
    expect(getSafeReturnTo('')).toBeUndefined()
  })

  it('returns undefined for undefined', () => {
    // oxlint-disable-next-line unicorn/no-useless-undefined -- Explicit undefined tests the nullish input branch.
    expect(getSafeReturnTo(undefined)).toBeUndefined()
  })

  it('extracts pathname from an absolute URL', () => {
    expect(getSafeReturnTo('https://evil.example.com/callback')).toBe('/callback')
  })

  it('extracts pathname from a protocol-relative URL', () => {
    expect(getSafeReturnTo('//evil.example.com/path')).toBe('/path')
  })

  it('resolves a relative path without leading slash', () => {
    expect(getSafeReturnTo('app/login')).toBe('/app/login')
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

  it('appends return_to for a protocol-relative URL', () => {
    expect(withReturnTo('/app/login/passkey', '//evil.example.com')).toBe('/app/login/passkey?return_to=%2F')
  })

  it('appends return_to for an absolute URL', () => {
    expect(withReturnTo('/app/login/passkey', 'https://evil.example.com/cb')).toBe('/app/login/passkey?return_to=%2Fcb')
  })
})
