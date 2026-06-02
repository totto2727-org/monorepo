import type { TaggedErrorBaseType } from '@totto2727/fp/error'
import { Context, Data, Effect, Layer, Predicate, Schema } from 'effect'
import { HttpClient, HttpClientRequest } from 'effect/unstable/http'
import { getCookie } from 'hono/cookie'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import * as Env from '#@/feature/env.ts'
import * as HonoContext from '#@/feature/share/lib/hono/context.ts'

export interface UserDTO {
  readonly id: string
  readonly email: string
}

export class BackendError extends Data.TaggedError('BackendError')<TaggedErrorBaseType> {}

interface BackendClientService {
  readonly callMe: () => Effect.Effect<UserDTO, BackendError, HttpClient.HttpClient>
  readonly callMeWithAccessToken: (accessToken: string) => Effect.Effect<UserDTO, BackendError, HttpClient.HttpClient>
}

export const BackendClient = Context.Service<BackendClientService>('BackendClient')

const UserResponse = Schema.Struct({
  email: Schema.String,
  id: Schema.optional(Schema.String),
  sub: Schema.optional(Schema.String),
})

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- backend JSON response is an external boundary with unknown shape.
const decodeUserResponse = Schema.decodeUnknownEffect(UserResponse)

const callBackendApi = (baseUrl: string, authorization: string) =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const request = HttpClientRequest.get(`${baseUrl}/api/v1/me`, {
      headers: { Authorization: authorization },
    })
    const response = yield* client.execute(request)
    if (response.status !== 200) {
      return yield* Effect.fail(new BackendError({ message: `HTTP ${response.status}` }))
    }
    const data: unknown = yield* response.json
    const user = yield* decodeUserResponse(data).pipe(
      Effect.mapError((error) => new BackendError({ error, message: 'invalid response shape' })),
    )
    const id = user.id ?? user.sub
    if (Predicate.isNullish(id)) {
      return yield* Effect.fail(new BackendError({ message: 'missing user id' }))
    }
    return { email: user.email, id }
  })

const getAuthorization = (): string | null => {
  const token = getCookie(HonoContext.get(), FEED_SESSION_COOKIE)
  return Predicate.isNullish(token) ? null : `Bearer ${token}`
}

const callBackendApiWithAuthorization = (baseUrl: string, authorization: string | null) =>
  Predicate.isNullish(authorization)
    ? Effect.fail(new BackendError({ message: 'missing feed-session cookie' }))
    : callBackendApi(baseUrl, authorization).pipe(Effect.mapError((failure) => new BackendError({ error: failure })))

const makeCallMe =
  (baseUrl: string): BackendClientService['callMe'] =>
  () =>
    callBackendApiWithAuthorization(baseUrl, getAuthorization())

const makeCallMeWithAccessToken =
  (baseUrl: string): BackendClientService['callMeWithAccessToken'] =>
  (accessToken) =>
    callBackendApiWithAuthorization(baseUrl, `Bearer ${accessToken}`)

export const liveLayer = Layer.effect(
  BackendClient,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return {
      callMe: makeCallMe(env.BACKEND_BASE_URL),
      callMeWithAccessToken: makeCallMeWithAccessToken(env.BACKEND_BASE_URL),
    }
  }),
)

export const mockLayer = Layer.succeed(BackendClient, {
  callMe: () => Effect.succeed({ email: 'mock@example.com', id: 'mock-user' }),
  callMeWithAccessToken: () => Effect.succeed({ email: 'mock@example.com', id: 'mock-user' }),
})
