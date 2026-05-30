import { Effect } from 'effect'
import { createMiddleware } from 'hono/factory'

import * as DB from '../db/kysely.ts'
import * as Runtime from './server.ts'

export interface Variables {
  readonly db: DB.Instance
  readonly runtime: Runtime.Runtime
}

export const middleware = createMiddleware<{
  Variables: Variables
}>(async (c, next) => {
  await using runtime = Runtime.make()
  c.set('runtime', runtime.instance)

  const db = await runtime.instance.runPromise(
    Effect.gen(function* () {
      return yield* DB.Service
    }),
  )
  await DB.initialize(db)
  c.set('db', db)

  await next()
})
