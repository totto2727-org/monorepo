import { serve } from '@hono/node-server'
import { Console, Effect } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { rootCommand } from '#@/cli/root.ts'
import { findRepoRoot, listWorktrees } from '#@/lib/git.ts'

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
      const { dir: relativeDir } = yield* rootCommand

      const repoRoot = yield* findRepoRoot(process.cwd())

      const worktrees = yield* listWorktrees(repoRoot)

      const app = createApp({ relativeDir, worktrees })

      yield* Console.log(`Serving roadmap kanban at http://localhost:${port}`)
      yield* Console.log(`Repo root:    ${repoRoot}`)
      yield* Console.log(`Relative dir: ${relativeDir}`)
      yield* Console.log(`Worktrees:    ${worktrees.length}`)
      for (const w of worktrees) {
        yield* Console.log(`  - ${w.id}${w.isMain ? ' (main)' : ''}: ${w.path}`)
      }

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
