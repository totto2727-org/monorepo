import { Context, Layer } from 'effect'

export interface OAuth {
  OAUTH_CLIENT_ID: string
  OAUTH_CLIENT_SECRET: string
}

export interface Idp {
  IDP_BASE_URL: string
}

export interface Web {
  WEB_BASE_URL: string
}

export interface Backend {
  BACKEND_BASE_URL: string
}

export interface Database {
  DATABASE_URL: string
  DATABASE_AUTH_TOKEN: string
}

export type Type = OAuth & Idp & Web & Backend & Database

export const Service = Context.Service<Type>('@app/feed-platform-web/feature/env/Service')

export const makeLayer = (env: Type) => Layer.succeed(Service, env)

export const devLayer = Layer.succeed(Service, {
  BACKEND_BASE_URL: 'http://localhost:8789',
  DATABASE_AUTH_TOKEN: '',
  DATABASE_URL: 'http://127.0.0.1:8080',
  IDP_BASE_URL: 'http://localhost:8787',
  OAUTH_CLIENT_ID: 'feed-platform-web',
  OAUTH_CLIENT_SECRET: 'dev-secret-pkce-not-used',
  WEB_BASE_URL: 'http://localhost:8788',
} satisfies Type as Type)
