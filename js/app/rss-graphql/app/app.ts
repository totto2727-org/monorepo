import { graphqlServer } from '@hono/graphql-server'
import { ManagedRuntime } from 'effect'
import { FetchHttpClient } from 'effect/unstable/http'
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'

import { makeSchema, toFormattedString } from './feature/graphql.ts'

const schema = makeSchema()

const runtime = ManagedRuntime.make(FetchHttpClient.layer)

interface AppEnv {
  Variables: {
    runtime: typeof runtime
  }
}

const app = new Hono<AppEnv>()
  .use(logger())
  .use(cors())
  .use(async (ctx, next) => {
    ctx.set('runtime', runtime)
    await next()
  })
  .get('/', (ctx) =>
    ctx.html(
      `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GraphQL API Information</title>
</head>
<body>
    <p>API Endpoint: <code>${new URL('/api/graphql', ctx.req.url).toString()}</code></p>
    <p>Schema: <a href="/api/graphql/schema">/api/graphql/schema</a></p>
    <p>GraphiQL: <a href="/api/graphql">/api/graphql</a></p>
</body>
</html>
`.trim(),
    ),
  )
  .get('/api/graphql/schema', (ctx) => ctx.text(toFormattedString(schema)))
  .use(
    '/api/graphql',
    graphqlServer({
      graphiql: true,
      schema,
    }),
  )

export default app
