import { serve } from '@hono/node-server'
import { Console, Effect } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { rootCommand } from '#@/cli/root.ts'

import { createApp } from '../../app/app.tsx'

export const serveCommand = Command.make(
  'serve',
  {
    port: Flag.integer('port').pipe(
      Flag.withAlias('p'),
      Flag.withDefault(3000),
      Flag.withDescription('Port to listen on'),
    ),
  },
  ({ port }) =>
    Effect.gen(function* () {
      const { dir } = yield* rootCommand

      const app = createApp({ dir })

      yield* Console.log(`Serving roadmap kanban at http://localhost:${port}`)
      yield* Console.log(`Reading roadmaps from: ${dir}`)

      yield* Effect.callback((resume) => {
        const server = serve({ fetch: app.fetch, port })
        const shutdown = (): void => {
          server.close(() => {
            resume(Effect.void)
          })
        }
        process.on('SIGINT', shutdown)
        process.on('SIGTERM', shutdown)
      })
    }),
).pipe(Command.withDescription('Start the kanban web UI'))
