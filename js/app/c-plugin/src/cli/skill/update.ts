import { Effect } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { getGlobalAgentsDir } from '#@/lib/paths.ts'
import * as Discover from '#@/service/discover.ts'
import * as UpdateService from '#@/service/update.ts'

import { searchTopDirOption } from './options.ts'

export const updateCommand = Command.make(
  'update',
  {
    global: Flag.boolean('global').pipe(Flag.withAlias('g')),
    recursive: Flag.boolean('recursive').pipe(Flag.withAlias('r')),
    searchTopDir: searchTopDirOption,
  },
  (config) =>
    Effect.gen(function* () {
      const agentsDirs = config.global
        ? [getGlobalAgentsDir()]
        : yield* Discover.resolveAgentsDirs(config.recursive, process.cwd(), { searchTopDir: config.searchTopDir })
      for (const agentsDir of agentsDirs) {
        yield* UpdateService.run(agentsDir)
      }
    }),
).pipe(Command.withDescription('Update skills to latest'))
