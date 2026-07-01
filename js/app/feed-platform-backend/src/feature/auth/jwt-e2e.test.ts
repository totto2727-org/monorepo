import { Hono } from 'hono'
import type * as JoseModule from 'jose'
import { generateKeyPair, SignJWT } from 'jose'
import { describe, expect, it, vi } from 'vite-plus/test'

import type { AppJWTPayload } from '#@/feature/auth/jwt-payload.ts'

const IDP_BASE_URL = 'http://localhost:8787'
const AUDIENCE = 'feed-platform-web'
const TEST_KID = 'test-key-1'

const issuerKeyPair = await generateKeyPair('ES256', { extractable: true })
const otherKeyPair = await generateKeyPair('ES256', { extractable: true })

vi.mock('jose', async (importOriginal) => {
  const actual = await importOriginal<typeof JoseModule>()
  return {
    ...actual,
    createRemoteJWKSet: () => () => Promise.resolve(issuerKeyPair.publicKey),
  }
})

const { authMiddleware } = await import('./middleware.ts')

const makeBackendApp = () =>
  new Hono<{ Variables: { user: AppJWTPayload } }>().use('/api/*', authMiddleware).get('/api/v1/me', (c) => {
    const { sub, email } = c.var.user
    return c.json({ email, id: sub })
  })

const signValidJwt = (overrides: { sub?: string; email?: string } = {}) =>
  new SignJWT({ email: overrides.email ?? 'alice@example.com' })
    .setProtectedHeader({ alg: 'ES256', kid: TEST_KID })
    .setSubject(overrides.sub ?? 'user-alice')
    .setIssuer(IDP_BASE_URL)
    .setAudience(AUDIENCE)
    .setIssuedAt()
    .setExpirationTime('10m')
    .sign(issuerKeyPair.privateKey)

describe('backend JWT verification — real ES256 signing + verification (e2e mock)', () => {
  it('accepts a real ES256 JWT signed by the IdP key and returns the user', async () => {
    const token = await signValidJwt()
    const app = makeBackendApp()
    const res = await app.request('/api/v1/me', {
      headers: { Authorization: `Bearer ${token}` },
    })
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ email: 'alice@example.com', id: 'user-alice' })
  })

  it('returns 401 + WWW-Authenticate when Authorization header is missing', async () => {
    const app = makeBackendApp()
    const res = await app.request('/api/v1/me')
    expect(res.status).toBe(401)
    expect(res.headers.get('WWW-Authenticate')).toBe('Bearer error="invalid_token"')
  })

  it('returns 401 when Authorization header does not use Bearer scheme', async () => {
    const app = makeBackendApp()
    const res = await app.request('/api/v1/me', {
      headers: { Authorization: 'Basic abc123' },
    })
    expect(res.status).toBe(401)
  })

  it('returns 401 when Bearer token is empty', async () => {
    const app = makeBackendApp()
    const res = await app.request('/api/v1/me', {
      headers: { Authorization: 'Bearer ' },
    })
    expect(res.status).toBe(401)
  })

  it('returns 401 for a JWT signed by a different (untrusted) key', async () => {
    const token = await new SignJWT({ email: 'alice@example.com' })
      .setProtectedHeader({ alg: 'ES256', kid: TEST_KID })
      .setSubject('user-alice')
      .setIssuer(IDP_BASE_URL)
      .setAudience(AUDIENCE)
      .setIssuedAt()
      .setExpirationTime('10m')
      .sign(otherKeyPair.privateKey)
    const app = makeBackendApp()
    const res = await app.request('/api/v1/me', {
      headers: { Authorization: `Bearer ${token}` },
    })
    expect(res.status).toBe(401)
  })

  it('returns 401 for a JWT with the wrong issuer claim', async () => {
    const token = await new SignJWT({ email: 'alice@example.com' })
      .setProtectedHeader({ alg: 'ES256', kid: TEST_KID })
      .setSubject('user-alice')
      .setIssuer('https://evil.example.com')
      .setAudience(AUDIENCE)
      .setIssuedAt()
      .setExpirationTime('10m')
      .sign(issuerKeyPair.privateKey)
    const app = makeBackendApp()
    const res = await app.request('/api/v1/me', {
      headers: { Authorization: `Bearer ${token}` },
    })
    expect(res.status).toBe(401)
  })

  it('returns 401 for a JWT with the wrong audience claim', async () => {
    const token = await new SignJWT({ email: 'alice@example.com' })
      .setProtectedHeader({ alg: 'ES256', kid: TEST_KID })
      .setSubject('user-alice')
      .setIssuer(IDP_BASE_URL)
      .setAudience('other-client')
      .setIssuedAt()
      .setExpirationTime('10m')
      .sign(issuerKeyPair.privateKey)
    const app = makeBackendApp()
    const res = await app.request('/api/v1/me', {
      headers: { Authorization: `Bearer ${token}` },
    })
    expect(res.status).toBe(401)
  })

  it('returns 401 for an expired JWT (exp in the past)', async () => {
    const token = await new SignJWT({ email: 'alice@example.com' })
      .setProtectedHeader({ alg: 'ES256', kid: TEST_KID })
      .setSubject('user-alice')
      .setIssuer(IDP_BASE_URL)
      .setAudience(AUDIENCE)
      .setIssuedAt(0)
      .setExpirationTime(1)
      .sign(issuerKeyPair.privateKey)
    const app = makeBackendApp()
    const res = await app.request('/api/v1/me', {
      headers: { Authorization: `Bearer ${token}` },
    })
    expect(res.status).toBe(401)
  })

  it('returns 401 for a JWT signed with HS256 instead of the required ES256', async () => {
    const hsKey = new Uint8Array(32)
    hsKey.fill(0xab)
    const token = await new SignJWT({ email: 'alice@example.com' })
      .setProtectedHeader({ alg: 'HS256' })
      .setSubject('user-alice')
      .setIssuer(IDP_BASE_URL)
      .setAudience(AUDIENCE)
      .setIssuedAt()
      .setExpirationTime('10m')
      .sign(hsKey)
    const app = makeBackendApp()
    const res = await app.request('/api/v1/me', {
      headers: { Authorization: `Bearer ${token}` },
    })
    expect(res.status).toBe(401)
  })
})
