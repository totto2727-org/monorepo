import { Context, Data, Effect, Layer, Predicate } from 'effect'

export interface UserDTO {
  readonly id: string
  readonly email: string
}

export class BackendError extends Data.TaggedError('BackendError')<{
  cause: unknown
}> {}

interface BackendClientService {
  readonly callMe: (feedSession: string) => Effect.Effect<UserDTO, BackendError>
}

export const BackendClient = Context.Service<BackendClientService>('BackendClient')

const BACKEND_BASE_URL = process.env.BACKEND_BASE_URL ?? 'http://localhost:8789'

export const liveLayer = Layer.succeed(BackendClient, {
  callMe: (feedSession: string) =>
    Effect.tryPromise({
      catch: (cause) => new BackendError({ cause }),
      try: async () => {
        // oxlint-disable-next-line rules/no-fetch -- external backend API
        const res = await fetch(`${BACKEND_BASE_URL}/api/v1/me`, {
          headers: { Authorization: `Bearer ${feedSession}` },
        })
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}`)
        }
        const data: unknown = await res.json()
        if (!Predicate.isObject(data)) {
          throw new TypeError('Invalid response shape')
        }
        const { id } = data
        const { email } = data
        if (!Predicate.isString(id) || !Predicate.isString(email)) {
          throw new TypeError('Invalid response fields')
        }
        return { email, id }
      },
    }),
})

export const mockLayer = Layer.succeed(BackendClient, {
  callMe: () => Effect.succeed({ email: 'mock@example.com', id: 'mock-user' }),
})
