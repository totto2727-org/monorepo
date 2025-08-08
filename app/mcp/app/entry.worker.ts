import * as Hono from "#@/entry.hono.js"
import * as Scheduled from "#@/entry.scheduled.js"

export { DataSyncWorkflow } from "./entry.workflow.js"

export default {
  fetch: Hono.app.fetch,
  scheduled: Scheduled.scheduled,
}
