import { CloudflareAdapter } from 'elysia/adapter/cloudflare-worker'

import { app } from './app.ts'

export default app(CloudflareAdapter).compile()
