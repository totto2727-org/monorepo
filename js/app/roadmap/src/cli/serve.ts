// oxlint-disable typescript-eslint/no-unsafe-type-assertion -- Node.js HTTP ↔ Fetch API bridge
// oxlint-disable typescript-eslint/no-explicit-any -- Node.js HTTP headers are incompatible with fetch types
// oxlint-disable typescript-eslint/no-unsafe-assignment -- assigning Node.js header any to Request init
// oxlint-disable eslint-plugin-promise/avoid-new -- server lifecycle requires Promise
// oxlint-disable typescript-eslint/no-misused-promises -- node:http handler must return Promise<void>
// oxlint-disable typescript-eslint/strict-void-return -- node signal handlers and http callback accept void-returning functions
import type { IncomingMessage, ServerResponse } from 'node:http'
import { createServer } from 'node:http'

import { Console, Effect, Predicate } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { rootCommand } from '#@/cli/root.ts'

import { createApp } from '../../app/app.tsx'

const handleRequest =
  (app: ReturnType<typeof createApp>) =>
  async (req: IncomingMessage, res: ServerResponse): Promise<void> => {
    const url = new URL(req.url ?? '/', 'http://localhost')
    const response = await app.fetch(new Request(url, { headers: req.headers as any, method: req.method }))
    res.writeHead(response.status, Object.fromEntries(response.headers))
    if (Predicate.isNotNullish(response.body)) {
      for await (const chunk of response.body as any) {
        res.write(chunk)
      }
    }
    res.end()
  }

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

      yield* Effect.promise(
        () =>
          new Promise<void>((resolve) => {
            const server = createServer(handleRequest(app))
            server.listen(port, () => {
              const shutdown = (): void => {
                server.close(() => {
                  resolve()
                })
              }
              process.on('SIGINT', shutdown)
              process.on('SIGTERM', shutdown)
            })
          }),
      )
    }),
).pipe(Command.withDescription('Start the kanban web UI'))
