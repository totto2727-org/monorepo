import { Context, Layer } from 'effect'

import * as HonoContext from '#@/feature/share/lib/hono/context.ts'

export interface Backend {
  BACKEND_BASE_URL: string
}

export interface BetterAuth {
  BETTER_AUTH_SECRET: string
}

export interface Database {
  DATABASE_AUTH_TOKEN: string
  DATABASE_URL: string
}

export interface Idp {
  IDP_BASE_URL: string
}

export interface OAuth {
  OAUTH_CLIENT_ID: string
  OAUTH_CLIENT_SECRET: string
}

export type Type = OAuth & Idp & Backend & BetterAuth & Database

export const Service = Context.Service<Type>('@app/feed-platform-web/feature/env/Service')

export const makeLayer = (env: Type) => Layer.succeed(Service, env)

export const prodLayer = Layer.sync(Service, () => HonoContext.get().env)

export const devLayer = Layer.succeed(Service, {
  BACKEND_BASE_URL: 'http://127.0.0.1:8788',
  BETTER_AUTH_SECRET: '0123456789abcdef0123456789abcdef0123456789abcdef',
  DATABASE_AUTH_TOKEN: '',
  DATABASE_URL: 'http://127.0.0.1:8081',
  IDP_BASE_URL: 'http://localhost:8787',
  OAUTH_CLIENT_ID: 'feed-platform-web',
  OAUTH_CLIENT_SECRET: 'dev-secret-do-not-use-in-prod',
} satisfies Type as Type)
