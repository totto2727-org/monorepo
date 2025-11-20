import { graphqlServer } from "@hono/graphql-server"
import * as Tenant from "@package/tenant/hono"
import * as CloudflareAccess from "@package/tenant/hono/cloudflare-access"
import type * as TenantSchema from "@package/tenant/schema"
import {
  createStartHandler,
  defaultStreamHandler,
} from "@tanstack/react-start/server"
import { Effect, Option } from "@totto/function/effect"
import * as CUID from "@totto/function/effect/cuid"
import { printSchema } from "graphql"
import { Hono } from "hono"
import { contextStorage } from "hono/context-storage"
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

  const verifyUserAndOrganizationMiddleware =
    yield* CloudflareAccess.Middleware.makeVerifyUserAndOrganizationMiddleware
  const unauthenticatedMiddleware =
    yield* Tenant.Middleware.makeUnauthenticatedMiddleware

  return new Hono<Env>()
    .use(logger())
    .use(setupMiddleware)
    .use(contextStorage())
    .use(unauthenticatedMiddleware)
    .get("/api/graphql/schema", (c) => c.text(printSchema(schema)))
    .use("*", verifyUserAndOrganizationMiddleware)
    .use(
      "/api/graphql",
      graphqlServer({
        graphiql: true,
        schema,
      }),
    )
    .get("/", (c) => c.redirect("/app"))
    .mount("/", fetch)
})

const devApp = createApp.pipe(
  Effect.provide(CUID.generatorProductionLive),
  Effect.provide(
    Tenant.DB.makeTenantDatabaseInitializer(() => getContext().var.database),
  ),
  Effect.provide(Tenant.DB.live),
  Effect.provide(Tenant.User.live),
  Effect.provide(
    CloudflareAccess.JWT.jwtUserDev(
      Option.some({
        email: "example@example.com",
        id: "1234567890",
        name: "John Doe",
        organizationArray: [
          {
            id: "org-1",
            name: "Organization 1",
          },
          {
            id: "org-2",
            name: "Organization 2",
          },
        ],
      } satisfies typeof TenantSchema.JWTUser.schema.Type),
    ),
  ),
  Effect.provide(
    CloudflareAccess.JWT.applicationAudienceDev("cloudflare-access"),
  ),
  Effect.provide(CloudflareAccess.JWT.jwtAudienceDev(["cloudflare-access"])),
  Effect.provide(Tenant.Context.live),
  Effect.runSync,
)

const _productionApp = createApp.pipe(
  Effect.provide(
    Tenant.DB.makeTenantDatabaseInitializer(() => getContext().var.database),
  ),
  Effect.provide(Tenant.DB.live),
  Effect.provide(Tenant.User.live),
  Effect.provide(CloudflareAccess.JWT.jwtUserLive),
  Effect.provide(
    CloudflareAccess.JWT.applicationAudienceLive(
      () => getContext().env.APPLICATION_AUDIENCE,
    ),
  ),
  Effect.provide(CloudflareAccess.JWT.jwtAudienceLive),
  Effect.provide(Tenant.Context.live),
  Effect.provide(CUID.generatorProductionLive),
  Effect.runSync,
)

export default devApp
