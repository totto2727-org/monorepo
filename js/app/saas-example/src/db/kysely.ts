import { LibsqlDialect } from '@libsql/kysely-libsql'
import { Kysely, CamelCasePlugin } from 'kysely'

import type { DB } from './generated.ts'

export * from './generated.ts'

const plugins = [new CamelCasePlugin()]

export const makeInMemoryDB = () =>
  new Kysely<DB>({
    dialect: new LibsqlDialect({
      url: 'libsql://:memory:',
    }),
    plugins,
  })

export const makeLocalDB = () =>
  new Kysely<DB>({
    dialect: new LibsqlDialect({
      url: `file:${import.meta.env.LOCAL_DATABASE_URL}`,
    }),
    plugins,
  })

export const makeRemoteDB = () =>
  new Kysely<DB>({
    dialect: new LibsqlDialect({
      authToken: import.meta.env.DATABASE_AUTH_TOKEN,
      url: import.meta.env.DATABASE_URL ?? '',
    }),
    plugins,
  })
