import { randomUUID } from 'node:crypto'

import { LibsqlDialect } from '@libsql/kysely-libsql'
import { Context, Effect, Layer } from 'effect'
import { CamelCasePlugin, Kysely } from 'kysely'

import * as Env from '#@/feature/env.ts'

import type * as Type from './generated.ts'

export type * as Type from './generated.ts'

const plugins = [new CamelCasePlugin()]

export type Instance = Kysely<Type.DB>

export const makeInMemory = (): Instance =>
  new Kysely({
    dialect: new LibsqlDialect({
      url: `file:${randomUUID()}?mode=memory&cache=shared`,
    }),
    plugins,
  })

export const makeRemote = (env: Env.Database): Instance =>
  new Kysely({
    dialect: new LibsqlDialect({
      authToken: env.DATABASE_AUTH_TOKEN,
      url: env.DATABASE_URL,
    }),
    plugins,
  })

export const Service = Context.Service<Instance>('@app/saas-example/feature/db/kysely/Service')

export const localLayer = Layer.sync(Service, () => makeInMemory())

export const remoteLayer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return makeRemote(env)
  }),
)
