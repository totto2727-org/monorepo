import { Context, Effect, Layer } from 'effect'
import { CamelCasePlugin, Kysely } from 'kysely'
import { D1Dialect } from 'kysely-d1'

import * as Env from '#@/feature/env.ts'

import type * as Type from './generated.ts'

export type * as Type from './generated.ts'

const plugins = [new CamelCasePlugin()]

export type Instance = Kysely<Type.DB>

const makeLocalD1 = (): D1Database =>
  ({
    batch: () => {
      throw new Error('identity-provider local D1 mock only supports query compilation')
    },
    dump: () => {
      throw new Error('identity-provider local D1 mock only supports query compilation')
    },
    exec: () => {
      throw new Error('identity-provider local D1 mock only supports query compilation')
    },
    prepare: () => {
      throw new Error('identity-provider local D1 mock only supports query compilation')
    },
    withSession: () => {
      throw new Error('identity-provider local D1 mock only supports query compilation')
    },
  }) as D1Database

export const makeInMemory = (): Instance =>
  new Kysely({
    dialect: new D1Dialect({
      database: makeLocalD1(),
    }),
    plugins,
  })

export const makeFromD1 = (db: D1Database): Instance =>
  new Kysely({
    dialect: new D1Dialect({ database: db }),
    plugins,
  })

export const makeRemote = (env: Env.Type): Instance => makeFromD1(env.DB)

export const Service = Context.Service<Instance>('@app/identity-provider/feature/db/kysely/Service')

export const localLayer = Layer.sync(Service, () => makeInMemory())

export const remoteLayer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return makeRemote(env)
  }),
)
