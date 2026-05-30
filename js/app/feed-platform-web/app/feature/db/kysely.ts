import { LibsqlDialect } from '@libsql/kysely-libsql'
import { Context, Layer } from 'effect'
import { Kysely, sql } from 'kysely'

export interface OauthNonceTable {
  expires_at: number
  nonce: string
  state: string
}

export interface OIDCDB {
  oauth_nonce: OauthNonceTable
}

export type Instance = Kysely<OIDCDB>

export const Service = Context.Service<Instance>('@app/feed-platform-web/feature/db/kysely/Service')

const makeRemote = (): Instance =>
  new Kysely<OIDCDB>({
    dialect: new LibsqlDialect({
      authToken: process.env.DATABASE_AUTH_TOKEN ?? '',
      url: process.env.DATABASE_URL ?? 'http://127.0.0.1:8080',
    }),
  })

export const makeInMemory = (): Instance =>
  new Kysely<OIDCDB>({
    dialect: new LibsqlDialect({ url: ':memory:' }),
  })

export const remoteLayer = Layer.sync(Service, () => makeRemote())
export const inMemoryLayer = Layer.sync(Service, () => makeInMemory())

export const initialize = async (db: Instance): Promise<void> => {
  await sql`
    CREATE TABLE IF NOT EXISTS oauth_nonce (
      state      TEXT PRIMARY KEY,
      nonce      TEXT NOT NULL,
      expires_at INTEGER NOT NULL
    )
  `.execute(db)
}
