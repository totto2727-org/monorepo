const toBase64Url = (buffer: ArrayBuffer): string =>
  btoa(String.fromCodePoint(...new Uint8Array(buffer)))
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '')

export const generateVerifier = (): string => {
  const bytes = new Uint8Array(32)
  crypto.getRandomValues(bytes)
  return toBase64Url(bytes.buffer)
}

export const generateChallenge = async (verifier: string): Promise<string> => {
  const data = new TextEncoder().encode(verifier)
  const hash = await crypto.subtle.digest('SHA-256', data)
  return toBase64Url(hash)
}

export const generateState = (): string => {
  const bytes = new Uint8Array(32)
  crypto.getRandomValues(bytes)
  return toBase64Url(bytes.buffer)
}

export interface AuthorizeParams {
  readonly clientId: string
  readonly redirectUri: string
  readonly idpBaseUrl: string
  readonly codeChallenge: string
  readonly state: string
}

export const buildAuthorizeUrl = (params: AuthorizeParams): URL => {
  const url = new URL('/api/v1/auth/oauth2/authorize', params.idpBaseUrl)
  url.searchParams.set('response_type', 'code')
  url.searchParams.set('client_id', params.clientId)
  url.searchParams.set('redirect_uri', params.redirectUri)
  url.searchParams.set('code_challenge', params.codeChallenge)
  url.searchParams.set('code_challenge_method', 'S256')
  url.searchParams.set('state', params.state)
  url.searchParams.set('scope', 'openid profile email')
  return url
}
