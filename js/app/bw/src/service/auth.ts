import { Data, Effect } from 'effect'
import type { Option } from 'effect'

export class AuthError extends Data.TaggedError('AuthError')<{
  readonly message: string
}> {}

export interface AuthConfig {
  readonly accountId: string
  readonly apiToken: string
}

const resolveValue = (flag: Option.Option<string>, envKey: string, label: string): Effect.Effect<string, AuthError> =>
  Effect.gen(function* () {
    if (flag._tag === 'Some') {
      return flag.value
    }

    const env = process.env[envKey]
    if (env !== undefined && env !== '') {
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
