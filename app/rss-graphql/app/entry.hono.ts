import { graphqlServer } from "@hono/graphql-server"
import { Effect } from "@totto/function/effect"
import { FetchHttpClient } from "@totto/function/effect/platform"
import { Hono } from "hono"
import { logger } from "hono/logger"
import { builder, generateSchema } from "./feature/graphql.js"
import type { Env } from "./feature/hono.js"
import { fetch } from "./feature/rss.js"

export const app = new Hono<Env>()
  .use(logger())
  .use("*", (c, next) => {
    c.set(
      "rssFetcher",
      fetch.pipe(Effect.provide(FetchHttpClient.layer), Effect.runSync),
    )
    return next()
  })
  .get("/api/graphql/schema", (c) => c.text(generateSchema()))
  .use(
    "/api/graphql",
    graphqlServer({
      graphiql: true,
      schema: builder.toSchema(),
    }),
  )
