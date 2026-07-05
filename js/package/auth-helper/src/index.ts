export {
  createBetterAuthSetupMiddleware,
  decodeBetterAuthUser,
  getBetterAuthSessionUser,
  getBetterAuthUser,
  toIdentityProviderAuthUser,
  toAuthUser,
} from './better-auth.ts'
export { requireAuthMiddleware } from './require-auth.ts'
export type {
  AuthUser,
  AuthVariables,
  BetterAuthServiceDefinition,
  BetterAuthSetupMiddlewareOptions,
  BetterAuthSetupVariables,
  BetterAuthSessionProvider,
  BetterAuthUser,
  IdentityProviderAuthUser,
  OptionalAuthVariables,
} from './better-auth.ts'
export type * from './jwt-payload.ts'
export type { RequireAuthMiddlewareOptions, RequireAuthVariables } from './require-auth.ts'
