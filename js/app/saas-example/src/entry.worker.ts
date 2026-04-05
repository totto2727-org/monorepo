import type { Register } from '@tanstack/react-router'
import type { RequestHandler } from '@tanstack/react-start/server'
import { createStartHandler, defaultStreamHandler } from '@tanstack/react-start/server'

import { makeHono } from './entry.hono.ts'
import * as Runtime from './feature/runtime/server.ts'

const tanstackStart = createStartHandler(defaultStreamHandler)

export interface ServerEntry {
  fetch: RequestHandler<Register>
}

const hono = makeHono(Runtime.make).mount('/', tanstackStart)

export default hono
