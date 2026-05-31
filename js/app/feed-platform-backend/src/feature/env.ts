import { Context, Layer } from 'effect'

export interface Type {
  IDP_JWKS_URL: string
  IDP_BASE_URL: string
  FEED_PLATFORM_AUDIENCE: string
}

export const Service = Context.Service<Type>('@app/feed-platform-backend/feature/env/Service')

export const layer = Layer.sync(Service, () => ({
  FEED_PLATFORM_AUDIENCE: process.env.FEED_PLATFORM_AUDIENCE ?? 'feed-platform-web',
  IDP_BASE_URL: process.env.IDP_BASE_URL ?? 'http://localhost:8787',
  IDP_JWKS_URL: process.env.IDP_JWKS_URL ?? 'http://localhost:8787/api/v1/auth/jwks',
}))
