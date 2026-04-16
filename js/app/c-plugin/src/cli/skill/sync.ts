import { Effect } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { getAgentsDir } from '#@/lib/paths.ts'
import * as Discover from '#@/service/discover.ts'
import * as SyncService from '#@/service/sync.ts'

export const syncCommand = Command.make(
  'sync',
  {
    global: Flag.boolean('global').pipe(Flag.withAlias('g')),
    recursive: Flag.boolean('recursive').pipe(Flag.withAlias('r')),
  },
  (config) =>
    Effect.gen(function* () {
      const agentsDirs = config.recursive
        ? yield* Discover.collectAgentsDirs(process.cwd())
        : [getAgentsDir(config.global)]
      for (const agentsDir of agentsDirs) {
        yield* SyncService.run(agentsDir)
      }
    }),
).pipe(Command.withDescription('Sync skills from lock file'))
