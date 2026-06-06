import { LibsqlDialect } from '@libsql/kysely-libsql'
import { Context, Effect, Layer } from 'effect'
import { Kysely } from 'kysely'

import * as Env from '#@/feature/env.ts'

type RawDatabase = Record<string, Record<string, unknown>>

export type Instance = Kysely<RawDatabase>

export const makeInMemory = (): Instance =>
  new Kysely({
    dialect: new LibsqlDialect({
      url: ':memory:',
    }),
  })

export const makeRemote = (env: Env.Database): Instance =>
  new Kysely({
    dialect: new LibsqlDialect({
      authToken: env.DATABASE_AUTH_TOKEN,
      url: env.DATABASE_URL,
    }),
  })

export const Service = Context.Service<Instance>('@app/identity-provider/feature/db/better-auth-kysely/Service')

export const inMemoryLayer = Layer.sync(Service, () => makeInMemory())

export const remoteLayer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return makeRemote(env)
  }),
)
