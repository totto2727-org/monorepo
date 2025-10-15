import { graphqlServer } from "@hono/graphql-server"
import { printSchema } from "graphql"
import { Hono } from "hono"
import { logger } from "hono/logger"
import { createBuilder } from "@/feature/graphql/builder.js"
import { initializeBuilder } from "@/feature/graphql.js"
import type { Env } from "@/feature/hono.js"

export function createApp() {
  const builder = createBuilder()
  initializeBuilder(builder)
  const schema = builder.toSchema()

  return new Hono<Env>()
    .use(logger())
    .get("/api/graphql/schema", (c) => c.text(printSchema(schema)))
    .use(
      "/api/graphql",
      graphqlServer({
        graphiql: true,
        schema,
      }),
    )
}
