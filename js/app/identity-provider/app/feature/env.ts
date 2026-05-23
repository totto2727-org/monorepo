import { Context, Layer } from 'effect'

export interface BetterAuth {
  BASE_URL: string
  BETTER_AUTH_URL: string
  BETTER_AUTH_SECRET: string
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
