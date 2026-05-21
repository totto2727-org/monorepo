import { describe, expect, test } from 'vite-plus/test'

import { buildAuthorizeUrl, generateChallenge, generateState, generateVerifier } from './oauth-client.ts'

describe('PKCE', () => {
  test('verifier is 43 chars URL-safe base64', () => {
    const verifier = generateVerifier()

    expect(verifier).toMatch(/^[\w-]+$/)
    expect(verifier.length).toBe(43)
  })

  test('challenge is SHA-256 of verifier (S256)', async () => {
    const verifier = generateVerifier()

    const challenge = await generateChallenge(verifier)
    const repeatedChallenge = await generateChallenge(verifier)

    expect(challenge).toBe(repeatedChallenge)
    expect(challenge).toMatch(/^[\w-]+$/)
  })

  test('state is 43 chars URL-safe base64', () => {
    const state = generateState()

    expect(state).toMatch(/^[\w-]+$/)
    expect(state.length).toBe(43)
  })
})

describe('buildAuthorizeUrl', () => {
  test('includes required OAuth 2.1 + PKCE params', async () => {
    const verifier = generateVerifier()
    const challenge = await generateChallenge(verifier)
    const state = generateState()

    const url = buildAuthorizeUrl({
      clientId: 'test-client',
      codeChallenge: challenge,
      idpBaseUrl: 'https://idp.example.com',
      redirectUri: 'https://web.example.com/auth/callback',
      state,
    })

    expect(url.pathname).toBe('/api/v1/auth/oauth2/authorize')
    expect(url.searchParams.get('code_challenge')).toBe(challenge)
    expect(url.searchParams.get('code_challenge_method')).toBe('S256')
    expect(url.searchParams.get('client_id')).toBe('test-client')
    expect(url.searchParams.get('redirect_uri')).toBe('https://web.example.com/auth/callback')
    expect(url.searchParams.get('response_type')).toBe('code')
    expect(url.searchParams.get('scope')).toBe('openid profile email')
    expect(url.searchParams.get('state')).toBe(state)
    expect(url.searchParams.get('code_challenge_method')).not.toBe('plain')
  })
})
