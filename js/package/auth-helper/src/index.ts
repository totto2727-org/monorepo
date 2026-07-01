export {
  createOptionalBetterAuthMiddleware,
  createRequiredBetterAuthMiddleware,
  decodeBetterAuthUser,
  getBetterAuthUser,
  toAuthUser,
} from './better-auth.ts'
export type {
  AuthUser,
  AuthVariables,
  BetterAuthServiceDefinition,
  BetterAuthSessionProvider,
  BetterAuthUser,
  OptionalAuthVariables,
  OptionalBetterAuthMiddlewareOptions,
  RequiredBetterAuthMiddlewareOptions,
} from './better-auth.ts'
export type * from './jwt-payload.ts'
