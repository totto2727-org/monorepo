import type { TaggedErrorBaseType } from '@totto2727/fp/error'
import { Array, Context, Data, Effect, Layer, Predicate, Schema } from 'effect'
import { HttpClient, HttpClientRequest } from 'effect/unstable/http'

import * as Env from '#@/feature/env.ts'
import * as HonoContext from '#@/feature/share/lib/hono/context.ts'

export interface UserDTO {
  readonly email: string
  readonly sub: string
}

export class BackendError extends Data.TaggedError('BackendError')<TaggedErrorBaseType> {}

interface BackendClientService {
  readonly callMe: () => Effect.Effect<UserDTO, BackendError, HttpClient.HttpClient>
}

export const BackendClient = Context.Service<BackendClientService>('BackendClient')

const UserResponse = Schema.Struct({
  email: Schema.String,
  sub: Schema.String,
})

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- backend JSON response is an external boundary with unknown shape.
const decodeUserResponse = Schema.decodeUnknownEffect(UserResponse)

const isBetterAuthCookie = (cookie: string): boolean => {
  const [name] = cookie.trim().split('=')
  if (Predicate.isNullish(name)) {
    return false
  }
  return (
    name === 'better-auth.session_token' ||
    name === '__Secure-better-auth.session_token' ||
    name.startsWith('better-auth.session_token.') ||
    name.startsWith('__Secure-better-auth.session_token.')
  )
}

const filterBetterAuthCookies = (cookie: string): string | null => {
  const filtered = cookie.split(';').filter(isBetterAuthCookie)
  return Array.isArrayEmpty(filtered) ? null : filtered.join('; ')
}

const callBackendApi = (baseUrl: string, cookie: string) =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const request = HttpClientRequest.get(`${baseUrl}/api/v1/me`, {
      headers: { Cookie: cookie },
    })
    const response = yield* client.execute(request)
    if (response.status !== 200) {
      return yield* Effect.fail(new BackendError({ message: `HTTP ${response.status}` }))
    }
    const data: unknown = yield* response.json
    const user = yield* decodeUserResponse(data).pipe(
      Effect.mapError((error) => new BackendError({ error, message: 'invalid response shape' })),
    )
    return { email: user.email, sub: user.sub }
  })

const makeCallMe =
  (baseUrl: string): BackendClientService['callMe'] =>
  () =>
    Effect.gen(function* () {
      const cookie = HonoContext.get().req.header('Cookie')
      if (Predicate.isNullish(cookie)) {
        return yield* Effect.fail(new BackendError({ message: 'missing Better Auth session cookie' }))
      }
      const sessionCookie = filterBetterAuthCookies(cookie)
      if (Predicate.isNullish(sessionCookie)) {
        return yield* Effect.fail(new BackendError({ message: 'missing Better Auth session cookie' }))
      }
      return yield* callBackendApi(baseUrl, sessionCookie).pipe(
        Effect.mapError((failure) => new BackendError({ error: failure })),
      )
    })

export const liveLayer = Layer.effect(
  BackendClient,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return {
      callMe: makeCallMe(env.BACKEND_BASE_URL),
    }
  }),
)

export const mockLayer = Layer.succeed(BackendClient, {
  callMe: () => Effect.succeed({ email: 'mock@example.com', sub: 'mock-user' }),
})
