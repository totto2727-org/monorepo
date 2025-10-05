import { graphqlServer } from "@hono/graphql-server"
import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import {
  AppShell,
  Body,
  BodyTitle,
  SideMenu,
  SideMenuItem,
} from "hono-ui/app-shell"
import * as Icon from "hono-ui/icon"
import { Layout } from "hono-ui/layout"
import { builder, generateSchema } from "@/feature/graphql.js"
import type { Env } from "@/feature/hono.js"

export const app = new Hono<Env>()
  .use(logger())
  .get("/", (c) => c.redirect("/app"))
  .get(
    "/app/*",
    jsxRenderer(({ children }) => (
      <Layout cssPath="../tailwind.css" isProd={import.meta.env.PROD}>
        {children}
      </Layout>
    )),
  )
  .get(
    "/app/admin/*",
    jsxRenderer(({ children, Layout }) => (
      <Layout>
        <AppShell
          side={
            <SideMenu>
              <SideMenuItem href="/app/admin">
                <Icon.Dashboard ariaLabel="Dashboard Icon" />
                Dashboard
              </SideMenuItem>
            </SideMenu>
          }
          title="MCP Admin"
        >
          {children}
        </AppShell>
      </Layout>
    )),
  )
  .get("/app", (c) =>
    c.render(<Body title={<BodyTitle title="Dashboard" />}></Body>),
  )
  .get("/api/graphql/schema", (c) => c.text(generateSchema()))
  .use(
    "/api/graphql",
    graphqlServer({
      graphiql: true,
      schema: builder.toSchema(),
    }),
  )
