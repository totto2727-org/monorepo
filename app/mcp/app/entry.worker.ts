import { OAuthProvider } from "@package/mcp-oauth-cloudflare-access"
import * as Hono from "./entry.hono.js"
import * as Scheduled from "./entry.scheduled.js"

export { DataSyncWorkflow } from "./entry.workflow.js"

const app = new OAuthProvider({
  apiHandler: {
    // biome-ignore lint/suspicious/noExplicitAny: 解消できないため
    fetch: Hono.mcpApp.fetch as any,
  },
  apiRoute: import.meta.env.PROD ? ["/api/mcp"] : [],
  authorizeEndpoint: "/authorize",
  clientRegistrationEndpoint: "/register",
  // biome-ignore lint/suspicious/noExplicitAny: 解消できないため
  defaultHandler: { fetch: Hono.adminApp.fetch as any },
  tokenEndpoint: "/token",
})

app.fetch = app.fetch.bind(app)

export default {
  fetch: app.fetch,
  scheduled: Scheduled.scheduled,
}
