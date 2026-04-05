import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { addCommand } from '#@/cli/skill/add.ts'
import { removeCommand } from '#@/cli/skill/remove.ts'
import { syncCommand } from '#@/cli/skill/sync.ts'
import { updateCommand } from '#@/cli/skill/update.ts'

const skillCommand = Command.make('skill').pipe(
  Command.withDescription('Manage skills from plugin repositories'),
  Command.withSubcommands([addCommand, syncCommand, updateCommand, removeCommand]),
)

const app = Command.make('c-plugin').pipe(
  Command.withDescription('CLI to manage Claude Code Plugin resources'),
  Command.withSubcommands([skillCommand]),
)

const program = app.pipe(Command.run({ version: '0.1.0' }), Effect.provide(NodeServices.layer))

Effect.runFork(program)
