import { Effect } from "@totto/function/effect"

export async function scheduled(
  _event: ScheduledEvent,
  env: Cloudflare.Env,
): Promise<void> {
  const newId = crypto.randomUUID()
  const _instance = await env.DATA_SYNC_WORKFLOW.create({ id: newId })
  Effect.logInfo(`Created workflow instance: ${newId}`).pipe(Effect.runSync)
  Effect.logInfo(`Workflow status: ${_instance.status()}`).pipe(Effect.runSync)
}
