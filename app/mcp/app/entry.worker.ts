import OAuthProvider from "@cloudflare/workers-oauth-provider"
import * as Hono from "#@/entry.hono.js"
import * as Scheduled from "#@/entry.scheduled.js"

export { DataSyncWorkflow } from "./entry.workflow.js"

const app = new OAuthProvider({
  apiHandler: {
    fetch: Hono.mcpApp.fetch as any,
  },
  apiRoute: ["/api"],
  authorizeEndpoint: "/authorize",
  clientRegistrationEndpoint: "/register",
  defaultHandler: { fetch: Hono.adminApp.fetch as any },
  tokenEndpoint: "/token",
})

app.fetch = app.fetch.bind(app)

export default {
  fetch: app.fetch,
  scheduled: Scheduled.scheduled,
}
