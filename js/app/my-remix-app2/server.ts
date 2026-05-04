import { serve } from '@hono/node-server'

import app from './app/app.tsx'

const port = process.env.PORT ? Number.parseInt(process.env.PORT, 10) : 44_100

const server = serve({ fetch: app.fetch, port }, ({ port }) => {
  console.log(`Server listening on http://localhost:${port}`)
})

let shuttingDown = false

function shutdown() {
  if (shuttingDown) return
  shuttingDown = true
  server.close()
  process.exit(0)
}

process.on('SIGINT', shutdown)
process.on('SIGTERM', shutdown)
