import { Data, Effect, Option, Predicate } from 'effect'

export class AuthError extends Data.TaggedError('AuthError')<{
  readonly message: string
}> {}

export interface AuthConfig {
  readonly accountId: string
  readonly apiToken: string
}

const resolveValue = (flag: Option.Option<string>, envKey: string, label: string): Effect.Effect<string, AuthError> =>
  Effect.gen(function* () {
    if (Option.isSome(flag)) {
      return flag.value
    }

    const env = process.env[envKey]
    // eslint-disable-next-line rules/prefer-is-nullish -- env is string | undefined, null is not a valid value
    if (!Predicate.isUndefined(env) && env !== '') {
      return env
    }

    return yield* new AuthError({
      message: `${label} is required. Set ${envKey} or use --${label.toLowerCase().replaceAll(' ', '-')}`,
    })
  })

export const resolve = (flags: {
  accountId: Option.Option<string>
  apiToken: Option.Option<string>
}): Effect.Effect<AuthConfig, AuthError> =>
  Effect.gen(function* () {
    const accountId = yield* resolveValue(flags.accountId, 'CLOUDFLARE_ACCOUNT_ID', 'account-id')
    const apiToken = yield* resolveValue(flags.apiToken, 'CLOUDFLARE_API_TOKEN', 'api-token')
    return { accountId, apiToken }
  })
