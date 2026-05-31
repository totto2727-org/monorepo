import type { TaggedErrorBaseType } from '@totto2727/fp/error'
import { Context, Data, Effect, Layer, Predicate, Schema } from 'effect'
import { HttpClient, HttpClientRequest } from 'effect/unstable/http'

import * as Env from '#@/feature/env.ts'

export interface UserDTO {
  readonly id: string
  readonly email: string
}

export class BackendError extends Data.TaggedError('BackendError')<TaggedErrorBaseType> {}

interface BackendClientService {
  readonly callMe: (authorization: string | null) => Effect.Effect<UserDTO, BackendError, HttpClient.HttpClient>
}

export const BackendClient = Context.Service<BackendClientService>('BackendClient')

const UserResponse = Schema.Struct({
  email: Schema.String,
  id: Schema.String,
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
    return yield* decodeUserResponse(data).pipe(
      Effect.mapError((error) => new BackendError({ error, message: 'invalid response shape' })),
    )
  })

export const liveLayer = Layer.effect(
  BackendClient,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return {
      callMe: (authorization: string | null) =>
        Predicate.isNullish(authorization)
          ? Effect.fail(new BackendError({ message: 'missing feed-session cookie' }))
          : callBackendApi(env.BACKEND_BASE_URL, authorization).pipe(
              Effect.mapError((failure) => new BackendError({ error: failure })),
            ),
    }
  }),
)

export const mockLayer = Layer.succeed(BackendClient, {
  callMe: () => Effect.succeed({ email: 'mock@example.com', id: 'mock-user' }),
})
