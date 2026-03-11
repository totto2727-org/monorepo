import type { Register } from '@tanstack/react-router'
import type { RequestHandler } from '@tanstack/react-start/server'

import { createStartHandler, defaultStreamHandler } from '@tanstack/react-start/server'
import { Effect } from 'effect'

import { app } from './entry.hono.ts'

const fetch = createStartHandler(defaultStreamHandler)

// Providing `RequestHandler` from `@tanstack/react-start/server` is required so that the output types don't import it from `@tanstack/start-server-core`
export interface ServerEntry {
  fetch: RequestHandler<Register>
}

export const createServerEntry = (entry: ServerEntry): ServerEntry => ({
  async fetch(...args) {
    return await entry.fetch(...args)
  },
})

export default app.pipe(Effect.runSync).mount('/', fetch)
