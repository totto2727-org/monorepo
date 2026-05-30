export interface AppJWTPayload {
  readonly sub: string
  readonly email: string
  readonly iat?: number
  readonly exp?: number
}
