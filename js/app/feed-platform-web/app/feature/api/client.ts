import { Context, Data, Effect, Layer, Predicate, Schema } from 'effect'
import { FetchHttpClient, HttpClient, HttpClientRequest } from 'effect/unstable/http'

export interface UserDTO {
  readonly id: string
  readonly email: string
}

export class BackendError extends Data.TaggedError('BackendError')<{
  cause: unknown
}> {}

interface BackendClientService {
  readonly callMe: (authorization: string | null) => Effect.Effect<UserDTO, BackendError>
}

export const BackendClient = Context.Service<BackendClientService>('BackendClient')

const BACKEND_BASE_URL = process.env.BACKEND_BASE_URL ?? 'http://localhost:8789'

const UserResponse = Schema.Struct({
  email: Schema.String,
  id: Schema.String,
})

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- backend JSON response is an external boundary with unknown shape.
const decodeUserResponse = Schema.decodeUnknownEffect(UserResponse)

const callBackendApi = (authorization: string) =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const request = HttpClientRequest.get(`${BACKEND_BASE_URL}/api/v1/me`, {
      headers: { Authorization: authorization },
    })
    const response = yield* client.execute(request)
    if (response.status !== 200) {
      return yield* Effect.fail(new BackendError({ cause: `HTTP ${response.status}` }))
    }
    const data: unknown = yield* response.json
    return yield* decodeUserResponse(data).pipe(
      Effect.mapError(() => new BackendError({ cause: 'invalid response shape' })),
    )
  })

export const liveLayer = Layer.succeed(BackendClient, {
  callMe: (authorization: string | null) =>
    Predicate.isNullish(authorization)
      ? Effect.fail(new BackendError({ cause: 'missing feed-session cookie' }))
      : callBackendApi(authorization).pipe(
          Effect.mapError((failure) => new BackendError({ cause: failure })),
          Effect.provide(FetchHttpClient.layer),
        ),
})

export const mockLayer = Layer.succeed(BackendClient, {
  callMe: () => Effect.succeed({ email: 'mock@example.com', id: 'mock-user' }),
})
