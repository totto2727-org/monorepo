import type { Kysely } from 'kysely'

import { Effect } from '@totto2727/fp/effect'

import type { DB } from './generated.ts'

import { makeRemoteDB, makeLocalDB } from './kysely.ts'

export class DatabaseService extends Effect.Service<Kysely<DB>>()('@app/saas-example/db/DatabaseService', {
  sync: makeRemoteDB,
}) {}

export const makeTestDatabaseService = () => new DatabaseService(makeLocalDB())
