import { app } from "#@/entry.hono.js"
import { scheduled } from "#@/entry.scheduled.js"

export { DataSyncWorkflow } from "./entry.workflow.js"

export default {
  fetch: app.fetch,
  scheduled,
}
