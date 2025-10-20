import { graphqlServer } from "@hono/graphql-server"
import * as Tenant from "@package/tenant/hono"
import * as CloudflareAccess from "@package/tenant/hono/cloudflare-access"
import {
  createStartHandler,
  defaultStreamHandler,
} from "@tanstack/react-start/server"
import { Effect } from "@totto/function/effect"
import { printSchema } from "graphql"
import { Hono } from "hono"
import { logger } from "hono/logger"
import * as GraphQLBuilder from "@/feature/graphql/builder.js"
import * as GraphQL from "@/feature/graphql.js"
import { type Env, getContext, setupMiddleware } from "@/feature/hono.js"

// https://github.com/TanStack/router/blob/main/packages/react-start/src/default-entry/server.ts
const fetch = createStartHandler(defaultStreamHandler)

export const createApp = Effect.gen(function* () {
  const builder = GraphQLBuilder.create()
  GraphQL.initializeBuilder(builder)
  const schema = builder.toSchema()

  const tenantMiddleware = yield* Tenant.Middleware.AuthHonoMiddlewares

  return (
    new Hono<Env>()
      .use(logger())
      .use(setupMiddleware)
      .use(tenantMiddleware.contextStorage)
      .use(tenantMiddleware.base)
      .get("/api/graphql/schema", (c) => c.text(printSchema(schema)))
      .use("*", tenantMiddleware.requireUser)
      .use(
        "/api/graphql",
        graphqlServer({
          graphiql: true,
          schema,
        }),
      )
      .get("/", (c) => c.redirect("/app"))
      // Tanstack Startの仕様上、ルートを指定しないと常に404になる
      .mount("/", fetch)
  )
})

const devApp = createApp.pipe(
  Effect.provide(CloudflareAccess.Middleware.live),
  Effect.provide(
    Tenant.DB.makeTenantDatabaseInitializer(() => getContext().var.database),
  ),
  Effect.provide(Tenant.DB.live),
  Effect.provide(
    CloudflareAccess.UserSource.devLive({
      id: "id3",
      organizationIDArray: ["org1", "org2", "org3", "org4", "org5", "org6"],
    }),
  ),
  Effect.provide(Tenant.User.live),
  Effect.provide(Tenant.CUID.productionLive()),
  Effect.runSync,
)

export default devApp
