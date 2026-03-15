import type { Register } from '@tanstack/react-router'
import type { RequestHandler } from '@tanstack/react-start/server'
import { createStartHandler, defaultStreamHandler } from '@tanstack/react-start/server'

import { makeHono } from './entry.hono.ts'
import * as DI from './feature/di/server.ts'

const tanstackStart = createStartHandler(defaultStreamHandler)

export interface ServerEntry {
  fetch: RequestHandler<Register>
}

const hono = makeHono(DI.DisposableRuntime).mount('/', tanstackStart)

export default hono
