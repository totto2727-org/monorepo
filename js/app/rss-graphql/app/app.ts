import type { HttpClient } from '@totto2727/fp/effect/platform'
import type { ElysiaAdapter } from 'elysia'

import { logger } from '@bogeychan/elysia-logger'
import { cors } from '@elysiajs/cors'
import { yoga } from '@elysiajs/graphql-yoga'
import { html } from '@elysiajs/html'
import { Effect } from '@totto2727/fp/effect'
import { FetchHttpClient } from '@totto2727/fp/effect/platform'
import { Elysia } from 'elysia'

import { generateSchema } from './feature/graphql.ts'
import { builder } from './feature/graphql/builder.ts'

export const app = (adapter?: ElysiaAdapter) =>
  Effect.gen(function* () {
    const runtime = yield* Effect.runtime<HttpClient.HttpClient>()

    return new Elysia({
      adapter,
    })
      .use(logger())
      .use(html())
      .use(cors())
      .resolve(() => ({ runtime }))
      .get('/', (c) =>
        c.html(
          `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GraphQL API Information</title>
</head>
<body>
    <p>API Endpoint: <code>${new URL('/api/graphql', c.request.url)}</code></p>
    <p>Schema: <a href="/api/graphql/schema">/api/graphql/schema</a></p>
    <p>GraphiQL: <a href="/api/graphql">/api/graphql</a></p>
</body>
</html>
`.trim(),
        ),
      )
      .get('/api/graphql/schema', () => generateSchema())
      .use(
        yoga({
          context: {
            runtime,
          } satisfies typeof builder.$inferSchemaTypes.Context,
          graphiql: true,
          path: '/api/graphql',
          schema: builder.toSchema(),
        }),
      )
  }).pipe(Effect.provide(FetchHttpClient.layer), Effect.runSync)
