import { Effect } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import * as BetterAuthDB from './better-auth-kysely.ts'
import * as DB from './kysely.ts'

describe('Kysely LibSQL service', () => {
  test('inMemoryLayer builds a CamelCase Kysely instance that compiles snake_case SQL', async () => {
    const program = Effect.gen(function* () {
      const db = yield* DB.Service
      return db.selectFrom('user').select(['email', 'createdAt']).compile().sql
    })

    const sql = await Effect.runPromise(Effect.provide(program, DB.inMemoryLayer))

    expect(sql).toContain('"email"')
    expect(sql).toContain('"created_at"')
    expect(sql).toContain('from "user"')
    expect(sql).not.toContain('createdAt')
  })

  test('Better Auth inMemoryLayer builds a raw Kysely instance without CamelCasePlugin', async () => {
    const program = Effect.gen(function* () {
      const db = yield* BetterAuthDB.Service
      return db.selectFrom('jwks').select('public_key').compile().sql
    })

    const sql = await Effect.runPromise(Effect.provide(program, BetterAuthDB.inMemoryLayer))

    expect(sql).toContain('"public_key"')
    expect(sql).toContain('from "jwks"')
    expect(sql).not.toContain('publicKey')
  })
})
