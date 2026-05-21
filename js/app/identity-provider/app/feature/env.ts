import { Context, Layer } from 'effect'

export interface Type extends Cloudflare.Env {
  readonly BETTER_AUTH_SECRET: string
  readonly CLOUDFLARE_ACCOUNT_ID: string
  readonly CLOUDFLARE_EMAIL_API_TOKEN: string
  readonly MAIL_FROM_ADDRESS: string
  readonly PASSKEY_RP_ID: string
}

export const Service = Context.Service<Type>('@app/identity-provider/feature/env/Service')

export const makeLayer = (env: Type) => Layer.succeed(Service, env)
