export interface AppJWTPayload {
  readonly sub: string
  readonly iat: number
  readonly exp: number
}
