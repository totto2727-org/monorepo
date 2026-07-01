export interface AppJWTPayload {
  readonly sub: string
  readonly email: string
  readonly token_use: 'access'
  readonly scope?: string
  readonly iat?: number
  readonly exp?: number
}
