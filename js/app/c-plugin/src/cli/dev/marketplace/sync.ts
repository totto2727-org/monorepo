import { Effect } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { allKinds } from '#@/schema/marketplace-kind.ts'
import * as MarketplaceSyncService from '#@/service/marketplace-sync.ts'

export const devMarketplaceSyncCommand = Command.make(
  'sync',
  {
    baseKind: Argument.choice('base-kind', allKinds),
  },
  (config) =>
    Effect.gen(function* () {
      const repoDir = process.cwd()
      yield* Effect.log(`Syncing marketplace from ${config.baseKind}...`)
      yield* MarketplaceSyncService.syncMarketplace(repoDir, config.baseKind)
    }),
).pipe(Command.withDescription('Generate marketplace configs for other tools from a base kind'))
