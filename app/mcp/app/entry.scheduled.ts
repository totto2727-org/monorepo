export async function scheduled(
  _event: ScheduledEvent,
  env: Cloudflare.Env,
): Promise<void> {
  const newId = crypto.randomUUID()
  const instance = await env.DATA_SYNC_WORKFLOW.create({ id: newId })
  console.info(`instance id: ${newId}`)
  console.info(await instance.status())
}
