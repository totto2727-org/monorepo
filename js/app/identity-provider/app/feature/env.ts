import { Context, Layer } from 'effect'

import * as HonoContext from '#@/feature/share/lib/hono/context.ts'

export interface BetterAuth {
  BETTER_AUTH_SECRET: string
  OAUTH_VALID_AUDIENCES: string
}

export interface Passkey {
  PASSKEY_RP_ID: string
}

export interface Database {
  DATABASE_URL: string
  DATABASE_AUTH_TOKEN: string
}

export interface Email {
  CLOUDFLARE_ACCOUNT_ID: string
  CLOUDFLARE_EMAIL_API_TOKEN: string
  MAIL_FROM_ADDRESS: string
}

export type Type = BetterAuth & Passkey & Database & Email

export const Service = Context.Service<Type>('@app/identity-provider/feature/env/Service')

export const makeLayer = (env: Type) => Layer.succeed(Service, env)
export const prodLayer = Layer.sync(Service, () => HonoContext.get().env)
export const devLayer = Layer.succeed(Service, {
  BETTER_AUTH_SECRET: '0123456789abcdef0123456789abcdef0123456789abcdef',
  CLOUDFLARE_ACCOUNT_ID: 'dev-account',
  CLOUDFLARE_EMAIL_API_TOKEN: 'dev-token',
  DATABASE_AUTH_TOKEN: '',
  DATABASE_URL: 'http://127.0.0.1:8080',
  MAIL_FROM_ADDRESS: 'auth@dev.example.com',
  OAUTH_VALID_AUDIENCES: 'feed-platform-web,feed-platform-backend,http://127.0.0.1:8789',
  PASSKEY_RP_ID: 'localhost',
} satisfies Type as Type)
