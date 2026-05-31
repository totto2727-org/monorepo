import type { AppJWTPayload } from '#@/feature/auth/jwt-payload.ts'

export interface Variables {
  readonly user: AppJWTPayload
}
