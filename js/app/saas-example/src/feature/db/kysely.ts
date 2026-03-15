import { LibsqlDialect } from '@libsql/kysely-libsql'
import { Effect, Layer, ServiceMap } from 'effect'
import { CamelCasePlugin, Kysely } from 'kysely'

import type { Type } from '#@/feature/env.ts'
import * as Env from '#@/feature/env.ts'

import type { DB } from './generated.ts'

export type * from './generated.ts'

const plugins = [new CamelCasePlugin()]

export const makeInMemory = () =>
  new Kysely<DB>({
    dialect: new LibsqlDialect({
      url: ':memory:',
    }),
    plugins,
  })

export const makeRemote = (env: Type) =>
  new Kysely<DB>({
    dialect: new LibsqlDialect({
      authToken: env.DATABASE_AUTH_TOKEN,
      url: env.DATABASE_URL,
    }),
    plugins,
  })

export const Service = ServiceMap.Service<Kysely<DB>>('@app/saas-example/feature/db/kysely/Service')

export const remoteLayer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return makeRemote(env)
  }),
)
