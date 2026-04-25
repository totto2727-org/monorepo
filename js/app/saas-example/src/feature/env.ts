import { Context, Layer } from 'effect'

export interface BetterAuth {
  BETTER_AUTH_URL: string
  BETTER_AUTH_SECRET: string
}

export interface Database {
  DATABASE_URL: string
  DATABASE_AUTH_TOKEN: string
}

export type Type = BetterAuth & Database

export const Service = Context.Service<Type>('@app/saas-example/feature/env/EnvService')

export const makeLayer = (env: Type) => Layer.succeed(Service, env)
