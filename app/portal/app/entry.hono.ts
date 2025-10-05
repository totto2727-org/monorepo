import { graphqlServer } from "@hono/graphql-server"
import { Hono } from "hono"
import { logger } from "hono/logger"
import { builder, generateSchema } from "@/feature/graphql.js"
import type { Env } from "@/feature/hono.js"

export const app = new Hono<Env>()
  .use(logger())
  .get("/api/graphql/schema", (c) => c.text(generateSchema()))
  .use(
    "/api/graphql",
    graphqlServer({
      graphiql: true,
      schema: builder.toSchema(),
    }),
  )
