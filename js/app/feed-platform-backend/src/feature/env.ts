import { Context, Layer } from 'effect'

export interface Type {
  IDP_JWKS_URL: string
  IDP_BASE_URL: string
  FEED_PLATFORM_AUDIENCE: string
}

export const Service = Context.Service<Type>('@app/feed-platform-backend/feature/env/Service')

export const makeLayer = (env: Type) => Layer.succeed(Service, env)

export const devLayer = Layer.succeed(Service, {
  FEED_PLATFORM_AUDIENCE: 'feed-platform-web',
  IDP_BASE_URL: 'http://localhost:8787',
  IDP_JWKS_URL: 'http://localhost:8787/api/v1/auth/jwks',
} satisfies Type as Type)
