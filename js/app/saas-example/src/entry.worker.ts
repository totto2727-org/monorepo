import type { Register } from '@tanstack/react-router'
import type { RequestHandler } from '@tanstack/react-start/server'

import { createStartHandler, defaultStreamHandler } from '@tanstack/react-start/server'

import { makeHono } from './entry.hono.ts'
import * as DI from './feature/di/server.ts'

// 呪文
const fetch = createStartHandler(defaultStreamHandler)

export interface ServerEntry {
  fetch: RequestHandler<Register>
}

export const createServerEntry = (entry: ServerEntry): ServerEntry => ({
  async fetch(...args) {
    return await entry.fetch(...args)
  },
})
// 呪文ここまで

const app = makeHono(DI.DisposableRuntime).mount('/', fetch)

export default app
