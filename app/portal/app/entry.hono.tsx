import { graphqlServer } from "@hono/graphql-server"
import { Middleware } from "@package/tenant/hono"
import { Effect } from "@totto/function/effect"
import { printSchema } from "graphql"
import { Hono } from "hono"
import { logger } from "hono/logger"
import { createBuilder } from "@/feature/graphql/builder.js"
import { initializeBuilder } from "@/feature/graphql.js"
import type { Env } from "@/feature/hono.js"

export const createApp = Effect.gen(function* () {
  const builder = createBuilder()
  initializeBuilder(builder)
  const schema = builder.toSchema()

  const tenantMiddleware = yield* Middleware.AuthHonoMiddlewares

  return new Hono<Env>()
    .use(tenantMiddleware.contextStorage)
    .use(logger())
    .use(tenantMiddleware.base)
    .get("/api/graphql/schema", (c) => c.text(printSchema(schema)))
    .use(
      "/api/graphql",
      graphqlServer({
        graphiql: true,
        schema,
      }),
    )
})
