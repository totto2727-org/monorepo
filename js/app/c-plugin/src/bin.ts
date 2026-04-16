import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { devMarketplaceSyncCommand } from '#@/cli/dev/marketplace/sync.ts'
import { addCommand } from '#@/cli/skill/add.ts'
import { removeCommand } from '#@/cli/skill/remove.ts'
import { syncCommand } from '#@/cli/skill/sync.ts'
import { targetAddCommand } from '#@/cli/skill/target/add.ts'
import { targetRemoveCommand } from '#@/cli/skill/target/remove.ts'
import { updateCommand } from '#@/cli/skill/update.ts'

const targetCommand = Command.make('target').pipe(
  Command.withDescription('Manage skill symlink target directories'),
  Command.withSubcommands([targetAddCommand, targetRemoveCommand]),
)

const skillCommand = Command.make('skill').pipe(
  Command.withDescription('Manage skills from plugin repositories'),
  Command.withSubcommands([addCommand, syncCommand, updateCommand, removeCommand, targetCommand]),
)

const marketplaceCommand = Command.make('marketplace').pipe(
  Command.withDescription('Marketplace development tools'),
  Command.withSubcommands([devMarketplaceSyncCommand]),
)

const devCommand = Command.make('dev').pipe(
  Command.withDescription('Development tools for plugin authors'),
  Command.withSubcommands([marketplaceCommand]),
)

const app = Command.make('c-plugin').pipe(
  Command.withDescription('CLI to manage Claude Code Plugin resources'),
  Command.withSubcommands([skillCommand, devCommand]),
)

const program = app.pipe(Command.run({ version: '0.1.0' }), Effect.provide(NodeServices.layer))

Effect.runFork(program)
